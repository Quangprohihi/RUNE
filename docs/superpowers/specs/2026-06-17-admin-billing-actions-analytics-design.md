# Admin Console — Billing actions + Analytics screen Design

> Phase 2b. Builds on Phase 1 (Overview/Users) and Phase 2a (Login/Logout/Billing read-only).
> Date: 2026-06-17 · Branch: Rune-Dev
> **Implementation order: A1 (confirm) → A2 (subscription mgmt + user detail) → A3 (package price mgmt) → B (Analytics).**

## 1. Context & goal

The billing screen is currently read-only. Post-demo, the user wants to **expand billing with admin write actions** and **build the Analytics screen** (full design, real data). Also a global list rule.

### Decisions (chosen with user)
- **Billing actions** (3, NOT refund): A1 manual-confirm stuck orders · A2 manage a user's subscription (cancel/extend) · A3 edit package prices (Zen Pro monthly/yearly).
- **Analytics**: full design — preset+custom-calendar+compare+granularity picker, 4 KPIs, line chart with compare overlay, conversion funnel, hourly focus distribution — all wired to real data.
- **Global list rule**: every list defaults to **15 items + pagination** (change Users & Billing transactions from 25→15; apply to all new lists).
- All write actions gated `requireAdmin(req, 'moderator')` and log an `ActivityEvent`.

### Existing facts (from subsystem map)
- `confirmPaidOrder(order, params, source)` (payment.service.ts:170-243) does the paid→subscription cascade in a `$transaction` (updates PaymentOrder, upserts Subscription, logs ActivityEvent + Notification). Reusable for admin confirm.
- Packages **hardcoded** in `payment.service.ts` `paymentProducts` (zen_pro_monthly 29000/30d, zen_pro_yearly 279000/365d), read by `getProduct()` → consumed by `createVnpayPaymentOrder` + `confirmPaidOrder`. Prices also duplicated in `billing.metrics.ts` (MONTHLY_VND/YEARLY_VND) and `BillingPage.tsx` package cards.
- `Subscription` model: `userId(pk), plan, status, expiresAt, updatedAt`. `PaymentOrder.status` ∈ pending|paid|failed|review|refunded.
- `GET /admin/api/users/:id` returns user + pet + wallet + streak + subscription + last 5 sessions + 8 events + `_count.refreshTokens`. `POST /admin/api/users/:id/force-logout` (moderator) exists.
- VNPay has **no refund API** (refund deferred / not chosen).
- Shop items (`/admin/api/shop-items`, token-priced in-game) are a **separate** system from subscription packages — do not conflate.

### Out of scope (YAGNI)
Refund; server-side export; "Vận hành & IPN" screen.

---

## PART A — Billing write actions

### A1. Manual-confirm a stuck order
- **Backend:** extract the confirm cascade into an exported `adminConfirmOrder(orderId: string, adminId: string)` in `payment.service.ts` (reuses the same `$transaction` as `confirmPaidOrder` but with `source='admin'`, no VNPay params/signature). Refactor `confirmPaidOrder` to delegate to a shared internal `applyPaidCascade(tx, order, { source, params? })` so both paths share logic (DRY). The ActivityEvent for admin source: title "Đơn thanh toán xác nhận thủ công", metadata `{ orderId, by: adminId }`.
- **Route:** `POST /admin/api/payments/:id/confirm` (moderator). Load order; if status not in {pending, review} → 409 `{error:'Đơn không ở trạng thái chờ xác nhận'}`; else `adminConfirmOrder` → return updated order. 
- **Frontend (BillingPage):** transaction rows gain a `⋯` IconButton → for `pending`/`review` rows a menu/inline "Xác nhận" action → POST confirm → on success refetch transactions + summary. Confirm dialog ("Xác nhận đơn này là đã thanh toán?").

### A2. Manage a user's subscription + build User Detail page
- **Backend route:** `POST /admin/api/users/:id/subscription` (moderator), body `{ action: 'cancel' | 'extend', days?: number }`.
  - `cancel`: upsert Subscription `{ plan:'free', status:'expired', expiresAt: now }`.
  - `extend`: require `days` (1–730); set `plan:'premium', status:'active', expiresAt = max(now, current expiresAt) + days`.
  - Log ActivityEvent (`subscription_admin`, title "Subscription điều chỉnh", metadata `{action, days, by}`). Return updated subscription.
- **Frontend — build `UserDetailPage`** (`/users/:id`, currently a stub) per the design's "Hồ sơ người dùng" screen, wired to `GET /admin/api/users/:id`:
  - Header: avatar + displayName + email + provider + account StatusBadge + breadcrumb back to Người dùng.
  - Cards: **Subscription** (plan/status/expiresAt + **Hủy** / **Gia hạn N ngày** buttons → A2 endpoint), **Ví** (tokens/diamonds/energy), **Thú cưng** (name/species/level), **Phiên gần đây** (last 5), **Hoạt động** (last 8 events).
  - Action: reuse `POST /users/:id/force-logout` → "Buộc đăng xuất" button.
  - Note: `GET /users/:id` returns the raw Prisma object (nested). FE types it as `UserDetail`.

### A3. Editable subscription packages (DB-backed)
- **Schema:** new Prisma model
  ```prisma
  model SubscriptionPackage {
    productCode  String   @id @map("product_code")
    title        String
    plan         String   @default("premium")
    amountVnd    Int      @map("amount_vnd")
    durationDays Int      @map("duration_days")
    isActive     Boolean  @default(true) @map("is_active")
    updatedAt    DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)
    @@map("subscription_packages")
  }
  ```
  `prisma db push` (project convention) + seed the two packages (`prisma/seed.ts`).
- **Refactor `getProduct`** → async `getProduct(code)` reads `prisma.subscriptionPackage.findUnique`; if missing/inactive falls back to the hardcoded `paymentProducts` constant (kept as a safety default). `createVnpayPaymentOrder` + `confirmPaidOrder`/`adminConfirmOrder` already async → `await getProduct(...)`.
- **Routes (moderator for PUT):** `GET /admin/api/packages` (list from DB, fallback to constants) · `PUT /admin/api/packages/:code` body `{ amountVnd?, durationDays?, isActive? }` (validate amountVnd ≥ 0, durationDays 1–730).
- **Billing summary uses DB prices:** the `/billing/summary` route reads the package prices from DB and passes them to the MRR calc. Refactor `billing.metrics.computeMrr` → `computeMrr(monthlyCount, monthlyVnd, yearlyCount, yearlyVnd)` (pure, parameterized); `monthlyEquivalentVnd` dropped or kept only for the constants fallback. Update `billing.metrics.test.ts` accordingly.
- **Frontend (BillingPage):** package cards become editable — each card gets an **"Sửa"** button → inline/modal form (giá VND + số ngày + bật/tắt) → `PUT /packages/:code` → refetch summary. The card subscriber counts/prices now come from `/billing/summary` (already returns packages; extend it to include `amountVnd` + `isActive` from DB).
- ⚠️ **Risk:** touches the live payment-create flow. Test: after editing a price, `POST /payments/vnpay/create {productCode}` reflects the new `amountVnd`; existing paid orders unaffected.

---

## PART B — Analytics screen (`/analytics`, real data, full design)

### B1. Backend `GET /admin/api/analytics`
Query: `range` (today|week|month|quarter|year|custom), `granularity` (day|week|month|quarter), `compare` (bool), `from`/`to` (ISO, for custom). Gated `requireAdmin`. Returns:
```ts
{
  range, granularity, compare,
  rangeLabel: string,            // e.g. "Tháng này · 01/06 – 30/06"
  kpis: {                         // each { value, deltaPct|null }
    activeUsers, focusMinutes, revenue, newPro
  },
  series: { label: string; cur: number[]; prev: number[] | null },  // active-users per bucket; prev = compare period (null if compare off)
  bucketLabels: string[],
  funnel: { label: string; value: number; pct: number }[],  // 5 stages, pct vs stage 1
  hourly: { label: string; minutes: number }[],             // 12 × 2-hour buckets, avg/day
}
```
**Definitions (explicit):**
- Window: reuse/extend `windowFor`; custom uses from/to. Previous window = equal length immediately before.
- `activeUsers` = distinct users with a FocusSession **or** ActivityEvent in the window. `focusMinutes` = Σ `plannedMinutes` of completed sessions. `revenue` = Σ paid `amountVnd`. `newPro` = count of `paid` subscription PaymentOrders in the window. Each KPI `deltaPct` vs previous window.
- `series.cur` = distinct active users per granularity bucket (bucket the window by granularity; count distinct userId per bucket from focus+events fetched once). `series.prev` = same for the previous window (only when `compare`).
- `funnel` (all-time cohort): Cài đặt app = total users · Tạo phiên đầu = distinct users with ≥1 FocusSession · Hoàn thành ≥1 phiên = distinct users with ≥1 `completed` session · Giữ chân ≥7 ngày = users with `UserStreak.bestStreak ≥ 7` · Nâng cấp Zen Pro = active-premium subscribers. pct = value/stage1×100.
- `hourly` = for completed sessions in window, group `plannedMinutes` by hour-of-day (UTC) of `startedAt` into 12 two-hour buckets; divide by number of days in window for a daily average.
- **Pure helpers** in `analytics.metrics.ts` (TDD, DB-agnostic): `granularityBuckets(start, end, granularity): Date[]` (edges); `distinctPerBucket(rows:{userId,at}[], edges): number[]`; `hourlyAverage(points:{hour,minutes}[], days): number[12]`; reuse `deltaPct`/`round1`. Route does the Prisma fetches + calls helpers.

### B2. Frontend `AnalyticsPage` (`/analytics`)
- Enable nav `analytics` (`/analytics`, crumb "Phân tích"); route in App.tsx.
- **Time-range picker** (`components/RangePicker.tsx`): a button showing `rangeLabel` → opens a popover with preset list (left), a **calendar** range-selector (right), "So sánh với kỳ trước" toggle, "Độ chi tiết" segmented (Ngày/Tuần/Tháng/Quý), and **Hủy / Áp dụng** footer. **Draft state** (`dRange/dStart/dEnd/dCompare/dGran`) committed to active state only on Áp dụng. Closes on outside-click/Esc.
- **4 KPI cards** (reuse `KpiCard` with `hideSpark`) + delta.
- **Line chart** (`components/LineChart.tsx`): SVG area+line of `series.cur` with x-axis bucket labels, grid lines, legend "Kỳ này"/"Kỳ trước"; dashed overlay for `series.prev` when compare on.
- **Conversion funnel** (`components/Funnel.tsx`): 5 horizontal bars (count + pct), teal for final stage.
- **Hourly distribution** (`components/HourlyBars.tsx`): 12 vertical bars (avg minutes), peak highlighted.
- `lib/api.ts`: `analytics(params)`; `types.ts`: `AnalyticsResponse` etc. Loading skeletons + ErrorState + friendlyError.

---

## Global: 15-item lists
- Backend: default `pageSize` 15 (cap 100) on `/admin/api/users` and `/admin/api/payments` (currently 25). Any new list endpoint defaults 15.
- Frontend: `UsersPage` and `BillingPage` transactions request `pageSize: 15`; pagination already present (reuses `pageList`).

## Testing
- **Backend (Vitest, pure helpers):** `analytics.metrics.test.ts` (granularityBuckets, distinctPerBucket, hourlyAverage); updated `billing.metrics.test.ts` (parameterized computeMrr); subscription extend/cancel date calc helper if extracted. Endpoint smoke via curl (admin token): analytics (each range/granularity, compare), payments/:id/confirm, users/:id/subscription, packages GET/PUT.
- **Frontend (Vitest+RTL):** AnalyticsPage (mock api → KPIs, chart svg, funnel rows, hourly bars; picker draft→apply changes query); RangePicker (draft commit on Áp dụng, discard on Hủy); BillingPage confirm action calls API + refetch; package edit PUT; UserDetailPage subscription cancel/extend.
- **E2E browser (final):** Analytics (switch preset + granularity + compare → chart/KPIs update; custom calendar range), Billing (confirm a pending order; edit a package price; → user detail → extend/cancel subscription), confirm lists show 15/pagination.

## Risks / notes
- **A3 touches live payments** — `getProduct` async DB read with hardcoded fallback; verify create-order uses DB price; keep `paymentProducts` constant as fallback so a missing table never breaks payments.
- `confirmPaidOrder` refactor must not change the IPN/return behavior — share logic via `applyPaidCascade`, keep the existing call sites green (no backend test suite for the VNPay flow; verify by reading + the existing return/IPN smoke is manual).
- Analytics `series` distinct-per-bucket can be heavy for many buckets — fetch focus+event rows once for the window, bucket in memory (bucket count ≤ ~31).
- `newPro` counts paid sub orders (a renewal counts as "new" — acceptable proxy; noted on UI as "Zen Pro mới (đơn)").
- "Giữ chân ≥7 ngày" uses `UserStreak.bestStreak ≥ 7` (retention proxy; real cohort retention deferred).

## Done criteria
1. Billing: confirm a pending/review order (→ paid + sub active); edit a package price (→ reflected in new create-order + MRR); user detail page shows subscription with working Cancel/Extend.
2. Analytics screen matches the design (picker incl. custom calendar + compare + granularity; KPIs; line chart with compare overlay; funnel; hourly) — all from real data; range/granularity/compare switches re-query.
3. All lists default 15 + pagination.
4. Writes are moderator-gated + log ActivityEvent; payment-create flow still works post-refactor.
5. Backend + frontend tests green; typecheck clean; E2E flow passes in browser.
