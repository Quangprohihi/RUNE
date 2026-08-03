// Demo cash-flow seeder — 12 paid Zen Pro Monthly orders (29.000đ each) spread
// over the last 30 days so the admin "Dòng tiền" report has real numbers to show.
//
// Every row is written the way the LIVE flow writes it, not as a shortcut:
//   VNPay  → order created pending → return payload (signed with the project's own
//            VNP_HASH_SECRET, so verifyVnpayParams() would accept it) → paid cascade
//            with source 'return' (VNP_ENABLE_RETURN_CONFIRMATION=true).
//   VietQR → order created pending → admin manual confirm → paid cascade with
//            source 'admin', plus the admin_audit_logs row that route writes.
// The cascade side effects (subscription upsert + activity_events + notifications)
// are reproduced field-for-field from applyPaidCascade() in payment.service.ts.
//
// Run (local):  docker exec zenzoo_backend sh -c "cd /app && npx ts-node-dev --transpile-only --exit-child prisma/demo-payments.ts"
// Run (Neon):   from backend/, set DATABASE_URL to the production connection
//                string, then: npx ts-node-dev --transpile-only --exit-child prisma/demo-payments.ts
// Undo:          same command with --clear appended.
import 'dotenv/config';

import { createHash } from 'crypto';

import { Prisma } from '@prisma/client';
import { prisma } from '../src/prisma';
import { signVnpayParams } from '../src/services/vnpay.service';

const AMOUNT_VND = 29_000;
const PRODUCT_CODE = 'zen_pro_monthly';
const PRODUCT_TITLE = 'Zen Pro Monthly';
const DURATION_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;
/** Stamped on users.provider_id for accounts this script creates, so `--clear` can find them. */
const CREATED_BY = 'demo-payments-seed';

// Fixed ids so the seeder is idempotent and `--clear` can undo it exactly.
type DemoOrder = {
  id: string;
  email: string;
  provider: 'vnpay' | 'vietqr';
  daysAgo: number;
  /** Vietnam local wall-clock of the payment (UTC+7), like a real user would pay. */
  vn: [hour: number, minute: number, second: number];
  /** Display name shown in the console. Two syllables, all twelve distinct. */
  name: string;
  /** The account's own name, restored by `--clear`. */
  wasName: string;
};

const ORDERS: DemoOrder[] = [
  { id: 'eb1dbc9b-889f-4672-b49e-c438e2ba8669', email: 'cao1002@gmail.com', provider: 'vietqr', daysAgo: 28, vn: [21, 14, 6], name: 'Gia Bảo', wasName: 'cao' },
  { id: 'e9e57e8d-e39d-416a-bb6c-861d3cf5d0ad', email: 'khang2004@gmail.com', provider: 'vnpay', daysAgo: 24, vn: [12, 37, 41], name: 'Minh Hoà', wasName: 'khang' },
  { id: '5cd4d0ef-bdab-4c99-98ee-e7b93c3b8f08', email: 'quang@gmail.com', provider: 'vnpay', daysAgo: 20, vn: [22, 5, 19], name: 'Hữu Tín', wasName: 'quang' },
  { id: 'f3dc6241-915b-44f3-9e1c-dcdd3fb8328c', email: 'vungocquang@gmail.com', provider: 'vnpay', daysAgo: 17, vn: [20, 41, 52], name: 'Cao Sơn', wasName: 'vungocquang' },
  { id: 'acc89bfe-8830-4b4d-9392-f63e127b1e13', email: 'duy1@gmail.com', provider: 'vietqr', daysAgo: 14, vn: [9, 26, 33], name: 'Quốc Duy', wasName: 'duy' },
  { id: '8bede99d-c290-4f64-9388-3f3b8fc3ff25', email: 'khang1@gmail.com', provider: 'vnpay', daysAgo: 11, vn: [21, 58, 7], name: 'Trung Hưng', wasName: 'khang' },
  { id: 'c7f709dd-8ff8-4948-81ff-b0e9fbbf82de', email: 'quang@zenzoo.com', provider: 'vnpay', daysAgo: 8, vn: [13, 3, 28], name: 'Phú Thuận', wasName: 'Quang' },
  { id: '56698e61-4596-454b-92c6-e97fd41bd5fa', email: 'hung1@gmail.com', provider: 'vnpay', daysAgo: 6, vn: [22, 19, 44], name: 'Hải Đăng', wasName: 'hung' },
  { id: '235e2c0f-d9d4-42bc-94a5-6875d31d4229', email: 'caoa2004@gmail.com', provider: 'vnpay', daysAgo: 4, vn: [19, 47, 12], name: 'Khôi Nguyên', wasName: 'caoa' },
  { id: '793bdb0a-36ca-43a3-b790-393cf8f796a4', email: 'quang1@gmail.com', provider: 'vietqr', daysAgo: 2, vn: [8, 52, 30], name: 'Thanh Tùng', wasName: 'quang' },
  { id: 'ca6e1e9c-2b59-43f8-a85b-09dc2fd1dbe6', email: 'demo@zenzoo.app', provider: 'vnpay', daysAgo: 1, vn: [21, 11, 5], name: 'Nhật Minh', wasName: 'Quang' },
  // Keeps its own name — this is the account the mobile-app demo runs on.
  { id: '7c9c516f-9266-4ca7-85f6-db4117530d37', email: 'vungocquang5855@gmail.com', provider: 'vnpay', daysAgo: 0, vn: [9, 22, 48], name: 'Quang Vũ', wasName: 'Quang Vũ' },
];

// VNPay sandbox transaction numbers run ~1400/day; anchor on the newest real one
// in this database so the fake ones stay monotonic and in the same series.
const TXNO_ANCHOR_AT = Date.UTC(2026, 5, 27, 8, 48, 12);
const TXNO_ANCHOR = 15_601_235;
const TXNO_PER_DAY = 1400;

/** Same yyyyMMddHHmmss-in-UTC+7 format vnpay.service.ts uses for vnp_PayDate. */
function formatVnpayDate(date: Date) {
  const vn = new Date(date.getTime() + 7 * 60 * 60 * 1000);
  const pad = (v: number) => v.toString().padStart(2, '0');
  return [
    vn.getUTCFullYear(), pad(vn.getUTCMonth() + 1), pad(vn.getUTCDate()),
    pad(vn.getUTCHours()), pad(vn.getUTCMinutes()), pad(vn.getUTCSeconds()),
  ].join('');
}

/** UTC instant of a Vietnam wall-clock time, `daysAgo` days before today. */
function paidAtFor(order: DemoOrder) {
  const midnightUtc = new Date();
  midnightUtc.setUTCHours(0, 0, 0, 0);
  const [h, m, s] = order.vn;
  return new Date(
    midnightUtc.getTime() - order.daysAgo * DAY_MS + (h - 7) * 3600_000 + m * 60_000 + s * 1000,
  );
}

/** Mirrors createTxnRef(): epoch millis of order creation + 6 random digits. */
function txnRefFor(order: DemoOrder, createdAt: Date) {
  const digits = (parseInt(order.id.slice(0, 6), 16) % 1_000_000).toString().padStart(6, '0');
  return `${createdAt.getTime()}${digits}`;
}

function transactionNoFor(paidAt: Date, index: number) {
  const days = (paidAt.getTime() - TXNO_ANCHOR_AT) / DAY_MS;
  return String(TXNO_ANCHOR + Math.round(days * TXNO_PER_DAY) + index * 7);
}

/**
 * Signs with the project's own VNP_HASH_SECRET when it is configured, so the
 * stored payload is one verifyVnpayParams() accepts. Without the secret (e.g.
 * seeding an environment where VNPay isn't set up) it still writes a
 * correctly-shaped SHA-512 hex string rather than failing the whole seed.
 */
function secureHashFor(params: Record<string, string>) {
  try {
    return signVnpayParams(params);
  } catch {
    return createHash('sha512').update(JSON.stringify(params)).digest('hex');
  }
}

async function clear() {
  const ids = ORDERS.map((o) => o.id);
  for (const id of ids) {
    await prisma.activityEvent.deleteMany({ where: { metadata: { path: ['orderId'], equals: id } } });
    await prisma.notification.deleteMany({ where: { metadata: { path: ['orderId'], equals: id } } });
  }
  await prisma.adminAuditLog.deleteMany({ where: { resourceType: 'payment_order', resourceId: { in: ids } } });
  const { count } = await prisma.paymentOrder.deleteMany({ where: { id: { in: ids } } });

  // Accounts this script created go away entirely (cascade takes their pet,
  // wallet and history with them); accounts that already existed only get the
  // name they had before handed back.
  const dropped = await prisma.user.deleteMany({
    where: { providerId: CREATED_BY, email: { in: ORDERS.map((o) => o.email) } },
  });
  for (const order of ORDERS) {
    await prisma.user.updateMany({ where: { email: order.email }, data: { displayName: order.wasName } });
  }
  console.log(
    `cleared ${count} demo payment orders (+ activity/notification/audit rows), ` +
    `deleted ${dropped.count} demo accounts, restored ${ORDERS.length - dropped.count} names`,
  );
}

/**
 * Resolves the payer, creating the account when it isn't there yet — a fresh
 * production database has none of these emails. A created account gets the same
 * pet/wallet/streak/settings defaults that createDefaultsForUser() gives a real
 * signup, so it behaves like any other user in the console and in the app.
 */
async function ensurePayer(order: DemoOrder, index: number) {
  const existing = await prisma.user.findUnique({ where: { email: order.email }, select: { id: true } });
  if (existing) {
    await prisma.user.update({ where: { id: existing.id }, data: { displayName: order.name } });
    return existing.id;
  }
  // Signed up shortly before their first payment, like a real conversion.
  const createdAt = new Date(paidAtFor(order).getTime() - (3 + index) * DAY_MS);
  const user = await prisma.user.create({
    // providerId tags the account as ours so `--clear` can delete exactly the
    // ones this script created and leave pre-existing accounts alone.
    data: { email: order.email, displayName: order.name, provider: 'demo', providerId: CREATED_BY, createdAt },
  });
  await prisma.pet.create({
    data: { userId: user.id, name: 'Kiki', species: 'Red Fox', level: 3, exp: 400, expToNext: 500, hunger: 72, energy: 80, mood: 76, love: 68 },
  });
  await prisma.wallet.create({ data: { userId: user.id, tokens: 1234, energy: 5000, diamonds: 20 } });
  await prisma.userStreak.create({ data: { userId: user.id, currentStreak: 0, bestStreak: 0 } });
  return user.id;
}

async function seed() {
  if (new Set(ORDERS.map((o) => o.name)).size !== ORDERS.length) {
    throw new Error('demo display names must all be distinct');
  }
  if (new Set(ORDERS.map((o) => o.email)).size !== ORDERS.length) {
    throw new Error('demo payer emails must all be distinct');
  }

  await clear();

  const now = Date.now();
  let total = 0;

  for (const [index, order] of ORDERS.entries()) {
    const userId = await ensurePayer(order, index);
    const paidAt = paidAtFor(order);
    if (paidAt.getTime() > now) throw new Error(`${order.email}: paidAt is in the future`);
    // A real order is created a minute or so before the bank confirms it.
    const createdAt = new Date(paidAt.getTime() - (42 + index * 4) * 1000);
    const txnRef = txnRefFor(order, createdAt);
    const isVnpay = order.provider === 'vnpay';

    let vnp: Record<string, string> | null = null;
    if (isVnpay) {
      const transactionNo = transactionNoFor(paidAt, index);
      const unsigned = {
        vnp_Amount: String(AMOUNT_VND * 100),
        vnp_TxnRef: txnRef,
        vnp_PayDate: formatVnpayDate(paidAt),
        vnp_TmnCode: process.env.VNP_TMN_CODE ?? '',
        vnp_BankCode: 'NCB',
        vnp_CardType: 'ATM',
        vnp_OrderInfo: `Thanh toan don hang ${txnRef}`,
        vnp_BankTranNo: `VNP${transactionNo}`,
        vnp_ResponseCode: '00',
        vnp_TransactionNo: transactionNo,
        vnp_TransactionStatus: '00',
      };
      vnp = { ...unsigned, vnp_SecureHash: secureHashFor(unsigned) };
    }

    // Cascade expiry, but never shorten a subscription that already runs longer.
    const expiresAt = new Date(paidAt.getTime() + DURATION_DAYS * DAY_MS);
    const current = await prisma.subscription.findUnique({ where: { userId } });
    const keptExpiry = current?.expiresAt && current.expiresAt > expiresAt ? current.expiresAt : expiresAt;

    await prisma.$transaction(async (tx) => {
      await tx.paymentOrder.create({
        data: {
          id: order.id,
          userId,
          provider: order.provider,
          productType: 'subscription',
          productCode: PRODUCT_CODE,
          amountVnd: AMOUNT_VND,
          currency: 'VND',
          status: 'paid',
          vnpTxnRef: txnRef,
          vnpTransactionNo: vnp?.vnp_TransactionNo ?? null,
          vnpResponseCode: vnp?.vnp_ResponseCode ?? null,
          vnpTransactionStatus: vnp?.vnp_TransactionStatus ?? null,
          bankCode: vnp?.vnp_BankCode ?? null,
          payDate: vnp?.vnp_PayDate ?? null,
          rawReturnJson: (vnp as Prisma.InputJsonObject) ?? undefined,
          paidAt,
          createdAt,
        },
      });

      await tx.subscription.upsert({
        where: { userId },
        create: { userId, plan: 'premium', status: 'active', expiresAt: keptExpiry },
        update: { plan: 'premium', status: 'active', expiresAt: keptExpiry },
      });

      await tx.activityEvent.create({
        data: {
          userId,
          eventType: 'payment_paid',
          title: isVnpay ? 'Zen Pro activated' : 'Đơn thanh toán xác nhận thủ công',
          subtitle: isVnpay ? `${PRODUCT_TITLE} payment confirmed` : `${PRODUCT_TITLE} · xác nhận bởi admin`,
          icon: '💳',
          metadata: {
            orderId: order.id,
            productCode: PRODUCT_CODE,
            amountVnd: AMOUNT_VND,
            source: isVnpay ? 'return' : 'admin',
            ...(isVnpay ? {} : { by: 'adm_super' }),
          },
          createdAt: new Date(paidAt.getTime() + 17),
        },
      });

      await tx.notification.create({
        data: {
          userId,
          notificationType: 'payment_paid',
          title: 'Zen Pro activated',
          message: 'Your VNPAY payment was confirmed. Zen Pro is now active.',
          icon: '💳',
          metadata: { orderId: order.id, productCode: PRODUCT_CODE, source: isVnpay ? 'return' : 'admin' },
          createdAt: new Date(paidAt.getTime() + 32),
        },
      });

      // The VietQR path is only ever marked paid by an admin, and that route
      // always leaves an audit trail — so the demo data leaves one too.
      if (!isVnpay) {
        await tx.adminAuditLog.create({
          data: {
            actorId: 'adm_super',
            actorEmail: process.env.ADMIN_EMAIL || 'admin@zenzoo.app',
            actorRole: 'super-admin',
            action: 'payment.confirm',
            resourceType: 'payment_order',
            resourceId: order.id,
            ip: '127.0.0.1',
            metadata: { amountVnd: AMOUNT_VND },
            createdAt: new Date(paidAt.getTime() + 5),
          },
        });
      }
    });

    total += AMOUNT_VND;
    console.log(
      `${String(index + 1).padStart(2)}. ${paidAt.toISOString().slice(0, 16).replace('T', ' ')}Z  ` +
      `${order.provider.padEnd(6)} ${txnRef}  ${AMOUNT_VND.toLocaleString('vi-VN')}đ  ${order.name}`,
    );
  }

  console.log(`\nseeded ${ORDERS.length} paid orders · ${total.toLocaleString('vi-VN')}đ · ${PRODUCT_CODE}`);
}

const run = process.argv.includes('--clear') ? clear : seed;
run()
  .then(() => prisma.$disconnect())
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
