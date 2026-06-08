import crypto from 'crypto';
import qs from 'qs';

type VnpayParams = Record<string, string | number | undefined | null>;

function requiredEnv(name: string) {
  const value = process.env[name];
  if (!value) {
    throw Object.assign(new Error(`${name} is not configured`), {
      status: 500,
    });
  }
  return value;
}

function formatVnpayDate(date: Date) {
  const vietnamTime = new Date(date.getTime() + 7 * 60 * 60 * 1000);
  const pad = (value: number) => value.toString().padStart(2, '0');
  return [
    vietnamTime.getUTCFullYear(),
    pad(vietnamTime.getUTCMonth() + 1),
    pad(vietnamTime.getUTCDate()),
    pad(vietnamTime.getUTCHours()),
    pad(vietnamTime.getUTCMinutes()),
    pad(vietnamTime.getUTCSeconds()),
  ].join('');
}

function normalizeParams(params: VnpayParams) {
  return Object.fromEntries(
    Object.entries(params)
      .filter(([, value]) => value !== undefined && value !== null && value !== '')
      .map(([key, value]) => {
        return [
          encodeURIComponent(key),
          encodeURIComponent(String(value)).replace(/%20/g, '+'),
        ] as const;
      })
      .sort(([left], [right]) => left.localeCompare(right)),
  );
}

function buildQuery(params: VnpayParams) {
  return qs.stringify(normalizeParams(params), { encode: false });
}

export function signVnpayParams(params: VnpayParams) {
  const secret = requiredEnv('VNP_HASH_SECRET');
  return crypto
    .createHmac('sha512', secret)
    .update(buildQuery(params), 'utf8')
    .digest('hex');
}

export function verifyVnpayParams(params: VnpayParams) {
  const secureHash = String(params.vnp_SecureHash ?? '');
  if (!secureHash) return false;

  const unsignedParams = { ...params };
  delete unsignedParams.vnp_SecureHash;
  delete unsignedParams.vnp_SecureHashType;

  const expected = signVnpayParams(unsignedParams);
  if (expected.length !== secureHash.length) return false;
  return crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(secureHash, 'hex'),
  );
}

export function buildVnpayPaymentUrl({
  amountVnd,
  ipAddress,
  orderInfo,
  txnRef,
}: {
  amountVnd: number;
  ipAddress: string;
  orderInfo: string;
  txnRef: string;
}) {
  const payUrl = requiredEnv('VNP_PAY_URL');
  const params: VnpayParams = {
    vnp_Amount: amountVnd * 100,
    vnp_Command: 'pay',
    vnp_CreateDate: formatVnpayDate(new Date()),
    vnp_CurrCode: 'VND',
    vnp_IpAddr: ipAddress,
    vnp_Locale: 'vn',
    vnp_OrderInfo: orderInfo,
    vnp_OrderType: 'other',
    vnp_ExpireDate: formatVnpayDate(new Date(Date.now() + 15 * 60 * 1000)),
    vnp_ReturnUrl: requiredEnv('VNP_RETURN_URL'),
    vnp_TmnCode: requiredEnv('VNP_TMN_CODE'),
    vnp_TxnRef: txnRef,
    vnp_Version: '2.1.0',
  };

  return `${payUrl}?${buildQuery({
    ...params,
    vnp_SecureHash: signVnpayParams(params),
  })}`;
}

export function getFrontendPaymentReturnUrl(params: {
  orderId?: string;
  status: string;
  txnRef?: string;
}) {
  const base =
    process.env.VNP_FRONTEND_RETURN_URL ?? 'zenzoo://payment-result';
  const url = new URL(base);
  url.searchParams.set('status', params.status);
  if (params.orderId) url.searchParams.set('orderId', params.orderId);
  if (params.txnRef) url.searchParams.set('txnRef', params.txnRef);
  return url.toString();
}

export function vnpayResponse(code: string, message: string) {
  return { RspCode: code, Message: message };
}
