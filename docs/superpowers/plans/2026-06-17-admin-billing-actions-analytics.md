# Admin Console — Billing actions + Analytics Implementation Plan

> **For agentic workers:** executed INLINE by the controller (user prefers no implementer-subagent dispatch). Per-task: TDD where logic exists, run tests/typecheck, smoke backend in-container, commit. Steps use `- [ ]`.

**Goal:** Add admin billing write-actions (confirm stuck order, manage subscription, edit package prices) + build the full Analytics screen with real data; make all lists default to 15 items + pagination.

**Architecture:** Extend the Express+Prisma backend (`backend/`, in Docker) and the React+Vite SPA (`admin-web/`). Order: A1 confirm → A2 subscription+UserDetail → A3 package mgmt (DB) → B Analytics → 15-item rule + verify.

**Tech Stack:** Express 5, Prisma 7 (db push, no migrations dir), Vitest (in-container) · React 18, Vite, react-router-dom 6, Vitest+RTL.

## Global Constraints
- **Docker:** backend tooling in-container (`docker compose exec -T backend ...`); **after editing backend source, `docker compose restart backend`** before smoke. Frontend on host (`cd admin-web && npm ...`). Commit on host, stage only listed paths. After FE change, `cd admin-web && npm run build` (serves at /console).
- **DB:** `prisma db push` (no migrations). Seed via `prisma/seed.ts`.
- **Writes:** `requireAdmin(req, 'moderator')`; log an `ActivityEvent` for each mutation.
- **Design system:** ManLab CSS vars only; Vietnamese copy verbatim from `admin_report/project/ZenZoo Admin.dc.html`. Lists: **default pageSize 15**, pagination via existing `pageList`.
- **A3 safety:** `getProduct` reads DB with hardcoded `paymentProducts` fallback so a missing/empty table never breaks the live payment-create flow.
- Spec: `docs/superpowers/specs/2026-06-17-admin-billing-actions-analytics-design.md`. Design markup: Analytics `ZenZoo Admin.dc.html` L666–768 (+ picker logic L1168–1280); User detail L495–569.

---

## Task A1 — Manual-confirm stuck order

**Files:** `backend/src/services/payment.service.ts` (refactor + export `adminConfirmOrder`), `backend/src/routes/admin.routes.ts` (route); FE `admin-web/src/pages/BillingPage.tsx` (row ⋯ → Xác nhận), `admin-web/src/lib/api.ts` (+`payments.confirm`), `admin-web/src/lib/types.ts`.

**Backend contract:** `adminConfirmOrder(orderId: string, adminId: string): Promise<PaymentOrder>` — loads order; throws `{status:409}` if status ∉ {pending,review}; runs the same paid-cascade as `confirmPaidOrder` (status→paid, paidAt, upsert Subscription active+expiresAt from package durationDays, ActivityEvent, Notification) with an admin-flavored ActivityEvent. Refactor: extract shared `applyPaidCascade(tx, order, opts)` used by both `confirmPaidOrder` (IPN/return) and `adminConfirmOrder` — must not change IPN/return behavior.
Route: `POST /admin/api/payments/:id/confirm` (moderator) → `res.json(await adminConfirmOrder(req.params.id, requireAdmin(req,'moderator').adminId))`.

- [ ] Read `payment.service.ts` confirmPaidOrder/getProduct fully; refactor to `applyPaidCascade` + add `adminConfirmOrder`. Restart; smoke: pick a `pending`/`review` order id (or create one via seed), `POST /payments/:id/confirm` → 200 + order paid + subscription active; confirm a `paid` order → 409.
- [ ] FE: add `api.payments.confirm(id)`; BillingPage row ⋯ menu with "Xác nhận" for pending/review → confirm → refetch summary+tx. Test: clicking confirm calls api + refetches.
- [ ] `npm test` + typecheck green (FE), backend smoke ok. Commit `feat(admin): manual-confirm stuck payment order`.

## Task A2 — Subscription manage + User Detail page

**Files:** `backend/src/routes/admin.routes.ts` (+route); FE replace `admin-web/src/pages/UserDetailPage.tsx`, `admin-web/src/lib/api.ts` (+`users.detail`, `users.subscription`), `types.ts` (`UserDetail`).

**Backend contract:** `POST /admin/api/users/:id/subscription` (moderator), body `{action:'cancel'|'extend', days?}`. cancel → upsert Subscription `{plan:'free',status:'expired',expiresAt:now}`. extend → require `1≤days≤730`; `expiresAt = max(now, existing.expiresAt ?? now) + days*86400000`, `{plan:'premium',status:'active'}`. Log ActivityEvent `subscription_admin`. Return subscription. Pure date helper `extendExpiry(current: Date|null, days: number, now: Date): Date` (TDD).
`GET /users/:id` already exists (returns nested user+subscription+pet+wallet+streak+sessions+events).

- [ ] Backend: add `extendExpiry` helper (TDD in `admin.metrics.test.ts` or new `subscription.metrics.test.ts`) + the route. Restart; smoke extend(+30)/cancel for a user id → subscription updated.
- [ ] FE: `UserDetailPage` per design L495–569 — header (Avatar/name/email/provider/status), cards (Subscription + Hủy/Gia hạn(+30/+365), Ví, Thú cưng, Phiên gần đây, Hoạt động), Buộc đăng xuất (reuse force-logout). `api.users.detail(id)`, `api.users.subscription(id, body)`, `api.users.forceLogout(id)`. Test: cancel/extend calls api + refetches; renders subscription.
- [ ] FE green + commit `feat(admin): user detail page + subscription cancel/extend`.

## Task A3 — Editable subscription packages (DB)

**Files:** `backend/prisma/schema.prisma` (+`SubscriptionPackage`), `backend/prisma/seed.ts` (seed 2), `backend/src/services/payment.service.ts` (async `getProduct` w/ fallback), `backend/src/admin/billing.metrics.ts` (+test) (parameterize `computeMrr`), `backend/src/routes/admin.routes.ts` (GET/PUT packages + billing summary uses DB prices); FE `BillingPage.tsx` (edit package), `api.ts` (+`packages`), `types.ts`.

**Backend contract:**
- Model `SubscriptionPackage` (productCode pk, title, plan, amountVnd, durationDays, isActive, updatedAt). `db push` + seed monthly(29000/30)/yearly(279000/365).
- `getProduct(code): Promise<Product>` reads DB; if missing/inactive → hardcoded `paymentProducts[code]` (fallback). `createVnpayPaymentOrder` + cascade `await` it.
- `billing.metrics.computeMrr(monthlyCount, monthlyVnd, yearlyCount, yearlyVnd): number` (parameterized; update test). 
- `GET /admin/api/packages` → `[{productCode,title,plan,amountVnd,durationDays,isActive}]`. `PUT /admin/api/packages/:code` (moderator) body `{amountVnd?,durationDays?,isActive?}` (validate amountVnd≥0, 1≤durationDays≤730). 
- `/billing/summary` packages array gains `amountVnd`+`isActive` from DB; MRR uses DB prices.

- [ ] Schema + db push + seed (in container); verify table + 2 rows.
- [ ] Refactor `getProduct` async + fallback; update callers; parameterize `computeMrr` + update billing.metrics.test. Restart; smoke: `GET /packages`; `PUT /packages/zen_pro_monthly {amountVnd:39000}`; then `POST /payments/vnpay/create {productCode:'zen_pro_monthly'}` → order amountVnd=39000; reset to 29000.
- [ ] FE: package cards editable (Sửa → form giá/ngày/bật-tắt → PUT → refetch). `api.packages.list/update`. Test render+edit.
- [ ] Backend `npm test` (billing.metrics updated) + FE green + build. Commit `feat(admin): DB-backed subscription packages with admin price editing`.

## Task B1 — Analytics backend

**Files:** `backend/src/admin/analytics.metrics.ts` (+`__tests__/analytics.metrics.test.ts`), `backend/src/routes/admin.routes.ts` (+route).

**Pure helpers (TDD):**
- `analyticsRange(range, now, from?, to?): {curStart, curEnd, prevStart, prevEnd, label}` (presets today/week/month/quarter/year + custom).
- `granularityBuckets(start, end, gran): Date[]` (edges; gran day/week/month/quarter).
- `distinctPerBucket(rows:{userId:string;at:Date}[], edges:Date[]): number[]`.
- `hourlyAverage(points:{at:Date;minutes:number}[], days:number): number[]` (12 two-hour buckets, /days).
- reuse `deltaPct`, `round1`.

**Route** `GET /admin/api/analytics?range=&granularity=&compare=&from=&to=` (requireAdmin) → returns `{range,granularity,compare,rangeLabel,kpis:{activeUsers,focusMinutes,revenue,newPro},series:{label,cur,prev},bucketLabels,funnel[5],hourly[12]}` per spec §B1 definitions. Fetch focus+event rows once per window; bucket in memory.

- [ ] Write `analytics.metrics.test.ts` (RED) → implement `analytics.metrics.ts` (GREEN, in-container).
- [ ] Add route; restart; smoke each range + granularity + compare=true; verify kpis/series/funnel(5)/hourly(12) shapes + funnel pct vs stage1.
- [ ] Backend `npm test` green. Commit `feat(backend): analytics endpoint (KPIs, series, funnel, hourly)`.

## Task B2 — Analytics frontend

**Files (create):** `admin-web/src/pages/AnalyticsPage.tsx` (+test), `admin-web/src/components/RangePicker.tsx`, `LineChart.tsx`, `Funnel.tsx`, `HourlyBars.tsx`; modify `lib/api.ts`, `types.ts`, `shell/nav.ts`, `App.tsx`. Markup ref: design L666–768.

**Contracts:** `api.analytics(params: AnalyticsQuery)`; types `AnalyticsResponse`, `AnalyticsQuery`. RangePicker: controlled `value:{range,granularity,compare,from,to}` + `onApply(value)`; internal draft state, Hủy/Áp dụng. LineChart: `{labels, cur, prev|null}`. Funnel: `{label,value,pct}[]`. HourlyBars: `{label,minutes}[]`.

- [ ] Enable nav `analytics`→`/analytics` + ROUTE_META + metaFor + App route.
- [ ] Build RangePicker (preset list + calendar range + compare toggle + granularity + draft→apply). Test: Áp dụng commits draft, Hủy discards.
- [ ] Build LineChart/Funnel/HourlyBars (SVG, ManLab tokens).
- [ ] Build AnalyticsPage (picker + 4 KpiCard hideSpark + LineChart + Funnel + HourlyBars), wired to `api.analytics`. Test: renders KPIs/chart/funnel/hourly; changing picker re-queries with new params.
- [ ] FE `npm test` + typecheck + build green. Commit `feat(admin-web): Analytics screen (picker, chart, funnel, hourly)`.

## Task C — 15-item lists + final verify

- [ ] Backend: `/admin/api/users` + `/admin/api/payments` default `pageSize` 15 (was 25). Restart; smoke pageSize default = 15.
- [ ] FE: `UsersPage` + `BillingPage` request `pageSize:15`. Build.
- [ ] Full gates: backend `npm test`, FE `npm test` + typecheck + build.
- [ ] E2E browser: login → Analytics (preset+granularity+compare+custom calendar → updates) → Billing (confirm pending order; edit package price; → User detail → extend/cancel sub) → lists show 15 + pagination → no console errors. Commit `chore(admin): 15-item lists + phase-2b verified`.
- [ ] Final controller review of the whole diff (base..HEAD): auth gating on all writes, payment-flow safety (getProduct fallback), no secrets, consistency.

## Self-Review (author)
Spec coverage: A1→Task A1; A2→Task A2; A3→Task A3; B→B1+B2; 15-item→Task C. Type consistency: `adminConfirmOrder`/`applyPaidCascade` (A1), `extendExpiry` (A2), `computeMrr(parameterized)` (A3), `analyticsRange/granularityBuckets/distinctPerBucket/hourlyAverage` (B1) all defined before use; FE `AnalyticsResponse`/`UserDetail`/`packages` types defined in their tasks. Known: `newPro` = paid-sub-order count (proxy); funnel retention via bestStreak≥7; refund excluded.
