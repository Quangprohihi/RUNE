import { Express, Request } from 'express';
import { z } from 'zod';
import {
  createVnpayPaymentOrder,
  getPaymentOrderStatus,
  handleVnpayIpn,
  recordVnpayReturn,
} from '../services/payment.service';

const createVnpayPaymentSchema = z.object({
  productCode: z.string().trim().min(1),
});

function clientIp(req: Request) {
  const raw =
    req.header('x-forwarded-for')?.split(',')[0]?.trim() ||
    req.ip ||
    req.socket.remoteAddress ||
    '127.0.0.1';
  const normalized = raw.startsWith('::ffff:')
    ? raw.replace('::ffff:', '')
    : raw;
  if (normalized === '::1' || normalized.includes(':')) return '127.0.0.1';
  if (
    normalized.startsWith('10.') ||
    normalized.startsWith('172.') ||
    normalized.startsWith('192.168.')
  ) {
    return '127.0.0.1';
  }
  return normalized;
}

function callbackParams(req: Request) {
  const source = req.method === 'POST' ? req.body : req.query;
  return Object.fromEntries(
    Object.entries(source).map(([key, value]) => {
      const normalized = Array.isArray(value) ? value[0] : value;
      return [key, String(normalized ?? '')];
    }),
  );
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function paymentReturnHtml(appUrl: string) {
  const url = new URL(appUrl);
  const status = url.searchParams.get('status') ?? 'pending';
  const orderId = url.searchParams.get('orderId') ?? '';
  const isSuccess = status === 'success';
  const isFailed = status === 'failed';
  const title = isSuccess
    ? 'Payment received'
    : isFailed
    ? 'Payment not completed'
    : 'Payment is being confirmed';
  const message = isSuccess
    ? 'ZenZoo is confirming your payment with VNPAY. Return to the app to finish activation.'
    : isFailed
    ? 'The payment was not completed or could not be verified. You can return to ZenZoo and try again.'
    : 'ZenZoo is waiting for VNPAY confirmation. Return to the app and refresh the payment status.';
  const color = isSuccess ? '#16a34a' : isFailed ? '#dc2626' : '#2563eb';
  const icon = isSuccess ? '✓' : isFailed ? '×' : '…';

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>ZenZoo payment result</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f8fafc; color: #1d293d; }
    .wrap { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px; }
    .card { width: 100%; max-width: 420px; background: white; border-radius: 24px; padding: 28px; box-shadow: 0 18px 50px rgba(15, 23, 42, 0.14); text-align: center; }
    .icon { width: 80px; height: 80px; margin: 0 auto 18px; border-radius: 999px; display: flex; align-items: center; justify-content: center; font-size: 46px; color: white; background: ${color}; }
    h1 { margin: 0 0 10px; font-size: 26px; }
    p { margin: 0 0 18px; color: #62748e; line-height: 1.5; }
    .order { padding: 12px; border-radius: 12px; background: #f1f5f9; font-size: 13px; word-break: break-all; margin-bottom: 18px; }
    a.button { display: block; padding: 14px 16px; border-radius: 14px; background: #16a34a; color: white; text-decoration: none; font-weight: 800; }
    .hint { margin-top: 14px; font-size: 13px; color: #90a1b9; }
  </style>
</head>
<body>
  <div class="wrap">
    <main class="card">
      <div class="icon">${icon}</div>
      <h1>${escapeHtml(title)}</h1>
      <p>${escapeHtml(message)}</p>
      ${orderId ? `<div class="order">Order ID: ${escapeHtml(orderId)}</div>` : ''}
      <a class="button" href="${escapeHtml(appUrl)}">Open ZenZoo</a>
      <div class="hint">If the app does not open, go back to ZenZoo manually and tap Refresh status.</div>
    </main>
  </div>
  <script>
    setTimeout(function () {
      window.location.href = ${JSON.stringify(appUrl)};
    }, 1200);
  </script>
</body>
</html>`;
}

export function registerPaymentRoutes(app: Express, deps: any) {
  const { requireUser } = deps;

  app.post('/payments/vnpay/create', async (req, res, next) => {
    try {
      const userId = requireUser(req);
      const body = createVnpayPaymentSchema.parse(req.body);
      res.json(
        await createVnpayPaymentOrder({
          userId,
          productCode: body.productCode,
          ipAddress: clientIp(req),
        }),
      );
    } catch (error) {
      next(error);
    }
  });

  app.get('/payments/:id/status', async (req, res, next) => {
    try {
      const userId = requireUser(req);
      res.json(await getPaymentOrderStatus(userId, req.params.id));
    } catch (error) {
      next(error);
    }
  });

  app.get('/payments/vnpay/return', async (req, res, next) => {
    try {
      const appUrl = await recordVnpayReturn(callbackParams(req));
      res.type('html').send(paymentReturnHtml(appUrl));
    } catch (error) {
      next(error);
    }
  });

  const ipnHandler = async (req: Request, res: any, next: any) => {
    try {
      res.json(await handleVnpayIpn(callbackParams(req)));
    } catch (error) {
      next(error);
    }
  };

  app.get('/payments/vnpay/ipn', ipnHandler);
  app.post('/payments/vnpay/ipn', ipnHandler);
}
