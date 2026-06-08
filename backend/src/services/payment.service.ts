import { Prisma } from '@prisma/client';
import { prisma } from '../prisma';
import {
  buildVnpayPaymentUrl,
  getFrontendPaymentReturnUrl,
  verifyVnpayParams,
  vnpayResponse,
} from './vnpay.service';

const paymentProducts = {
  zen_pro_monthly: {
    productCode: 'zen_pro_monthly',
    productType: 'subscription',
    plan: 'premium',
    amountVnd: 29000,
    durationDays: 30,
    title: 'Zen Pro Monthly',
  },
  zen_pro_yearly: {
    productCode: 'zen_pro_yearly',
    productType: 'subscription',
    plan: 'premium',
    amountVnd: 279000,
    durationDays: 365,
    title: 'Zen Pro Yearly',
  },
} as const;

type ProductCode = keyof typeof paymentProducts;
type VnpayCallbackParams = Record<string, string>;

function getProduct(productCode: string) {
  const product = paymentProducts[productCode as ProductCode];
  if (!product) {
    throw Object.assign(new Error('Unsupported payment product'), {
      status: 400,
    });
  }
  return product;
}

function createTxnRef() {
  const random = Math.floor(Math.random() * 1_000_000)
    .toString()
    .padStart(6, '0');
  return `${Date.now()}${random}`;
}

function paidExpiresAt(durationDays: number) {
  const expiresAt = new Date();
  expiresAt.setUTCDate(expiresAt.getUTCDate() + durationDays);
  return expiresAt;
}

function isVnpayPaid(params: VnpayCallbackParams) {
  return (
    params.vnp_ResponseCode === '00' && params.vnp_TransactionStatus === '00'
  );
}

function callbackStatus(params: VnpayCallbackParams, verified: boolean) {
  if (!verified) return 'failed';
  return isVnpayPaid(params) ? 'success' : 'failed';
}

function returnConfirmationEnabled() {
  return process.env.VNP_ENABLE_RETURN_CONFIRMATION === 'true';
}

export async function createVnpayPaymentOrder({
  ipAddress,
  productCode,
  userId,
}: {
  ipAddress: string;
  productCode: string;
  userId: string;
}) {
  const product = getProduct(productCode);
  const txnRef = createTxnRef();
  const order = await prisma.paymentOrder.create({
    data: {
      userId,
      provider: 'vnpay',
      productType: product.productType,
      productCode: product.productCode,
      amountVnd: product.amountVnd,
      currency: 'VND',
      status: 'pending',
      vnpTxnRef: txnRef,
    },
  });

  const paymentUrl = buildVnpayPaymentUrl({
    amountVnd: product.amountVnd,
    ipAddress,
    orderInfo: `Thanh toan don hang ${txnRef}`,
    txnRef,
  });

  return { orderId: order.id, paymentUrl };
}

export async function getPaymentOrderStatus(userId: string, orderId: string) {
  const order = await prisma.paymentOrder.findFirst({
    where: { id: orderId, userId },
  });
  if (!order) {
    throw Object.assign(new Error('Payment order not found'), { status: 404 });
  }

  const subscription = await prisma.subscription.findUnique({
    where: { userId },
  });

  return {
    order: {
      id: order.id,
      amountVnd: order.amountVnd,
      productCode: order.productCode,
      productType: order.productType,
      status: order.status,
      paidAt: order.paidAt,
      failedAt: order.failedAt,
    },
    subscription,
  };
}

export async function recordVnpayReturn(params: VnpayCallbackParams) {
  const verified = verifyVnpayParams(params);
  const txnRef = params.vnp_TxnRef;
  const order = txnRef
    ? await prisma.paymentOrder.findUnique({ where: { vnpTxnRef: txnRef } })
    : null;

  if (order) {
    await prisma.paymentOrder.update({
      where: { id: order.id },
      data: {
        rawReturnJson: params as Prisma.InputJsonObject,
        vnpResponseCode: params.vnp_ResponseCode,
        vnpTransactionNo: params.vnp_TransactionNo,
        vnpTransactionStatus: params.vnp_TransactionStatus,
        bankCode: params.vnp_BankCode,
        payDate: params.vnp_PayDate,
      },
    });
  }
  if (
    order &&
    order.status === 'pending' &&
    verified &&
    isVnpayPaid(params) &&
    returnConfirmationEnabled()
  ) {
    const paidAmountVnd = Math.round(Number(params.vnp_Amount ?? 0) / 100);
    if (paidAmountVnd === order.amountVnd) {
      await confirmPaidOrder(order, params, 'return');
    }
  }

  return getFrontendPaymentReturnUrl({
    orderId: order?.id,
    status: callbackStatus(params, verified),
    txnRef,
  });
}

async function confirmPaidOrder(
  order: NonNullable<
    Awaited<ReturnType<typeof prisma.paymentOrder.findUnique>>
  >,
  params: VnpayCallbackParams,
  source: 'ipn' | 'return',
) {
  const product = getProduct(order.productCode);
  const expiresAt = paidExpiresAt(product.durationDays);
  const paidAt = new Date();
  await prisma.$transaction(async (tx) => {
    await tx.paymentOrder.update({
      where: { id: order.id },
      data: {
        status: 'paid',
        paidAt,
        rawIpnJson:
          source === 'ipn' ? (params as Prisma.InputJsonObject) : undefined,
        rawReturnJson:
          source === 'return'
            ? (params as Prisma.InputJsonObject)
            : undefined,
        vnpResponseCode: params.vnp_ResponseCode,
        vnpTransactionNo: params.vnp_TransactionNo,
        vnpTransactionStatus: params.vnp_TransactionStatus,
        bankCode: params.vnp_BankCode,
        payDate: params.vnp_PayDate,
      },
    });
    await tx.subscription.upsert({
      where: { userId: order.userId },
      create: {
        userId: order.userId,
        plan: product.plan,
        status: 'active',
        expiresAt,
      },
      update: {
        plan: product.plan,
        status: 'active',
        expiresAt,
      },
    });
    await tx.activityEvent.create({
      data: {
        userId: order.userId,
        eventType: 'payment_paid',
        title: 'Zen Pro activated',
        subtitle: `${product.title} payment confirmed`,
        icon: '💳',
        metadata: {
          orderId: order.id,
          productCode: order.productCode,
          amountVnd: order.amountVnd,
          source,
        },
      },
    });
    await tx.notification.create({
      data: {
        userId: order.userId,
        notificationType: 'payment_paid',
        title: 'Zen Pro activated',
        message: 'Your VNPAY payment was confirmed. Zen Pro is now active.',
        icon: '💳',
        metadata: {
          orderId: order.id,
          productCode: order.productCode,
          source,
        },
      },
    });
  });
}

export async function handleVnpayIpn(params: VnpayCallbackParams) {
  const verified = verifyVnpayParams(params);
  const txnRef = params.vnp_TxnRef;
  if (!verified) {
    return vnpayResponse('97', 'Invalid signature');
  }

  const order = txnRef
    ? await prisma.paymentOrder.findUnique({ where: { vnpTxnRef: txnRef } })
    : null;
  if (!order) {
    return vnpayResponse('01', 'Order not found');
  }

  const paidAmountVnd = Math.round(Number(params.vnp_Amount ?? 0) / 100);
  if (paidAmountVnd !== order.amountVnd) {
    await prisma.paymentOrder.update({
      where: { id: order.id },
      data: {
        status: 'review',
        rawIpnJson: params as Prisma.InputJsonObject,
        vnpResponseCode: params.vnp_ResponseCode,
        vnpTransactionNo: params.vnp_TransactionNo,
        vnpTransactionStatus: params.vnp_TransactionStatus,
        bankCode: params.vnp_BankCode,
        payDate: params.vnp_PayDate,
      },
    });
    return vnpayResponse('04', 'Invalid amount');
  }

  if (order.status === 'paid') {
    return vnpayResponse('02', 'Order already confirmed');
  }

  if (!isVnpayPaid(params)) {
    await prisma.paymentOrder.update({
      where: { id: order.id },
      data: {
        status: 'failed',
        failedAt: new Date(),
        rawIpnJson: params as Prisma.InputJsonObject,
        vnpResponseCode: params.vnp_ResponseCode,
        vnpTransactionNo: params.vnp_TransactionNo,
        vnpTransactionStatus: params.vnp_TransactionStatus,
        bankCode: params.vnp_BankCode,
        payDate: params.vnp_PayDate,
      },
    });
    return vnpayResponse('00', 'Confirm success');
  }

  await confirmPaidOrder(order, params, 'ipn');

  return vnpayResponse('00', 'Confirm success');
}
