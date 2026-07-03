# VietQR + Manual-Confirm Payment — Design

**Date:** 2026-07-03
**Status:** Approved (pending spec review)
**Author:** ZenZoo team

## Problem

The app currently sells Zen Pro (29k/month, 279k/year) through VNPay **sandbox** —
fake money, and going live needs a merchant contract that requires a company. For a
personal academic demo we want **real money** with the least friction and **no company**.

## Goal

Add a second payment method — **VietQR bank transfer with manual admin confirmation** —
that moves real money into a personal MSB account, while **keeping VNPay untouched** so
existing transactions and the sandbox flow remain intact.

## Non-goals (YAGNI)

- No automated bank webhook (SePay/PayOS) — that is a later upgrade.
- No automated amount reconciliation or auto-refund — the admin eyeballs the transfer
  and taps confirm.
- Do **not** remove VNPay or touch any historical `payment_orders` rows.

## Key insight — most of it already exists

- `PaymentOrder` has `provider` (default `vnpay`) and a unique `vnpTxnRef` we reuse as
  the **bank-transfer content** (reference code).
- `adminConfirmOrder(orderId, adminId)` → `POST /admin/api/payments/:id/confirm` →
  BillingPage "Xác nhận" button already activates the subscription, writes the activity
  event, and sends the notification, for **any** provider. No change needed there.
- `PaymentResultScreen` already polls `GET /payments/:id/status` every 3s until the
  status is terminal (`paid`/`failed`/…) and then reloads the subscription.

So this feature is mostly **wiring**, not new machinery.

## Architecture

Two payment methods coexist. Provider is recorded per order; the app lets the user pick.

```
PremiumScreen "Upgrade"
        │
        ▼
  Payment-method sheet ──► VNPay  ──► (existing) browser checkout ──► IPN/return auto-confirm
        │
        └──────────────► VietQR ──► VietqrPaymentScreen (QR + bank info)
                                         │  user transfers real money to MSB
                                         │  taps "Tôi đã chuyển khoản"
                                         ▼
                                   PaymentResultScreen (polls status)
                                         ▲
                     admin sees money land, taps "Xác nhận" in BillingPage
                                         │
                                   adminConfirmOrder → subscription active
```

### Backend

**New `backend/src/services/vietqr.service.ts`** — one responsibility: build the QR image URL.

- `buildVietQrImageUrl({ amountVnd, addInfo })` returns
  `https://img.vietqr.io/image/{BIN}-{ACCOUNT}-compact2.png?amount={amountVnd}&addInfo={addInfo}&accountName={NAME}`
  using env config. `addInfo` (transfer content) and `accountName` are URL-encoded.
- `getVietqrConfig()` reads and validates env: `VIETQR_BANK_BIN`, `VIETQR_ACCOUNT_NO`,
  `VIETQR_ACCOUNT_NAME`, `VIETQR_BANK_NAME`. Missing config → 500 (same pattern as
  `requiredEnv` in `vnpay.service.ts`).

**New in `backend/src/services/payment.service.ts`** — `createVietqrPaymentOrder({ productCode, userId })`:

- Reuses `getProduct` (admin-editable package, hardcoded fallback) and `createTxnRef`.
- Creates a `PaymentOrder` with `provider: 'vietqr'`, `status: 'pending'`,
  `vnpTxnRef: txnRef`.
- Returns `{ orderId, qrImageUrl, bankName, accountNo, accountName, amountVnd, transferContent }`
  where `transferContent === txnRef`.

**New route** in `backend/src/routes/payments.routes.ts`:
`POST /payments/vietqr/create` — `requireUser`, body `{ productCode }`, returns the payload
above. Status polling reuses the existing `GET /payments/:id/status`.

**Env:** add the four `VIETQR_*` keys to `backend/.env` (MSB: BIN `970426`, account
`6102062004`, name `VU NGOC QUANG`, bank `MSB`) and document them in `.env.example`.

### App (Flutter)

- **`PaymentRepository.createVietqrPayment(productCode)`** → new `VietqrCheckout` model
  (`orderId, qrImageUrl, bankName, accountNo, accountName, amountVnd, transferContent`).
- **`PaymentProvider.createVietqrPayment`** mirrors the existing VNPay method
  (loading/error handling via `friendlyError`).
- **New `lib/presentation/payment/vietqr_payment_screen.dart`**: shows the QR
  (`Image.network(qrImageUrl)`), bank name / account no / account holder / amount /
  transfer content — each copyable — plus a "Tôi đã chuyển khoản" primary button that
  navigates to `PaymentResultScreen` with `{ orderId, status: 'pending' }`, and a clear
  note that activation happens after the transfer is confirmed. Include an image
  loading/error fallback (show the bank details as text if the QR image fails to load).
- **`PremiumScreen._upgrade()`**: instead of launching VNPay directly, open a
  **payment-method bottom sheet** with two options:
  - *Thẻ / VNPay* → existing flow (create VNPay order, launch URL, go to result screen).
  - *Chuyển khoản VietQR* → create VietQR order, push `VietqrPaymentScreen`.
- **`PaymentResultScreen`**: neutralize VNPay-specific copy ("VNPAY" → generic), and
  raise the poll ceiling (manual confirm can take longer than the current 30s window) —
  e.g. keep polling ~2 minutes while pending; the manual "Refresh status" button stays.
- New route `AppRoutes.vietqrPayment` registered in `app_routes.dart`/`main.dart`.

### Admin

Already functional; cosmetic only:

- BillingPage transactions card subtitle "Cổng VNPay" → "VNPay & VietQR".
- Show a small provider tag per row (VNPay / VietQR) so the operator knows a VietQR row
  needs a real bank check before confirming. Requires adding `provider` to the
  `/admin/api/payments` list item mapping (one field).

## Data flow / state

- No schema migration — `provider` and `vnpTxnRef` already exist. Old rows unaffected.
- A VietQR order lives as `pending` until an admin confirms it (→ `paid`) via the
  existing cascade, which upserts the subscription, logs an activity event, and notifies
  the user.

## Error handling

- Missing `VIETQR_*` env → 500 with a clear message (config error, not user-facing).
- QR image fails to load in-app → fall back to showing bank details as selectable text.
- Wrong amount / wrong content transferred → admin decides at confirm time (manual);
  no automatic matching in this iteration.
- Creating an order still requires an authenticated user (`requireUser`).

## Testing

- **Backend unit:** `vietqr.service` builds the correct URL (BIN/account/amount/encoded
  content + name); throws on missing env. `createVietqrPaymentOrder` persists an order
  with `provider: 'vietqr'`, `status: 'pending'`, matching amount, and returns the QR
  payload.
- **Backend route:** `POST /payments/vietqr/create` returns the payload for an authed
  user; `GET /payments/:id/status` reflects `paid` after `adminConfirmOrder`.
- **App:** `PaymentRepository.createVietqrPayment` parses the response;
  `VietqrPaymentScreen` renders bank details and navigates on "Tôi đã chuyển khoản";
  method sheet routes to the correct flow.
- **Manual end-to-end:** real 29k transfer to MSB → admin confirm → app flips to
  "Zen Pro activated".

## Rollout

Config-only to switch environments; no destructive steps. VNPay remains available.
```
VIETQR_BANK_BIN=970426
VIETQR_ACCOUNT_NO=6102062004
VIETQR_ACCOUNT_NAME=VU NGOC QUANG
VIETQR_BANK_NAME=MSB
```
