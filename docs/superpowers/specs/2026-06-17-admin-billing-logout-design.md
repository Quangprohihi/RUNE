# Admin Console — Login redesign + Logout + Billing ("Thanh toán & Gói") Design

> Phase 2a of the ZenZoo admin console. Builds on [Phase 1](2026-06-16-zenzoo-admin-console-design.md).
> Date: 2026-06-17 · Branch: Rune-Dev
> **Implementation order: Login redesign → Logout → Billing.**

## 1. Context & goal

The admin console (React+Vite SPA at `admin-web/`, served by Express at `/console`) is live with Overview + Users. This phase adds (in order):
1. **Login redesign** — replace the current `LoginPage` with the new ManLab "ZenZoo Login.dc.html" design (separate handoff bundle, see §2 below).
2. **Logout** via a topbar avatar dropdown menu.
3. The **"Thanh toán & Gói"** (Billing) screen — a **read-only monitoring** dashboard for revenue, transactions, and package subscribers.

**Payment processing is already fully automatic** and is NOT changed by this work: the mobile app calls `POST /payments/vnpay/create {productCode}`, VNPay redirects, and the **IPN handler** (`/payments/vnpay/ipn`, HMAC-SHA512 verified) runs `confirmPaidOrder` → sets `PaymentOrder.status='paid'` + upserts `Subscription` (plan=premium, expiresAt) + ActivityEvent/Notification. The admin only **observes** this; no admin action mutates payments this phase.

### Existing facts (from subsystem map)
- **Packages** hardcoded in `backend/src/services/payment.service.ts`: `zen_pro_monthly` (29 000 đ / 30d), `zen_pro_yearly` (279 000 đ / 365d), both `plan='premium'`.
- **`PaymentOrder`** fields: id, userId, provider, productType, productCode, amountVnd, currency, status (`pending|paid|failed|review|refunded`), vnpTxnRef, vnpTransactionNo, vnpResponseCode, vnpTransactionStatus, bankCode, payDate, rawReturnJson, rawIpnJson, paidAt, failedAt, createdAt, updatedAt. (`review` = IPN amount mismatch.)
- **`Subscription`**: userId, plan, status, expiresAt, updatedAt. (Does NOT store which package — must derive from latest paid order.)
- **`GET /admin/api/payments`** today: last 50, optional `status`, no pagination/date filter; item = {id, vnpTxnRef, user, productCode, amountVnd, status, bankCode, payDate, paidAt, createdAt}.

### Decisions (chosen with user)
- Scope: **read-only monitoring** (no refund / manual-confirm / package-price management).
- Screens: **only "Thanh toán & Gói"** ("Vận hành & IPN" deferred).
- Logout placement: **topbar avatar dropdown**.
- Billing KPIs: **with a range selector** (Hôm nay / 7 ngày / 30 ngày / Quý), like Overview.

### Out of scope (YAGNI)
Refund / manual-confirm / review-resolution actions; package & price management (would need a DB catalog + migration); the "Vận hành & IPN" screen; subscription cancel/renew.

## 1.5 Login redesign (implement FIRST)

**Source:** new Claude Design handoff (downloaded + extracted to `login_design/thi-t-k-l-i-trang-web-hi-n-i/project/ZenZoo Login.dc.html`, screenshot `…/screenshots/00-login.png`, chat intent in `…/chats/chat1.md`). Same ManLab design system + `zenzoo-mark.png` (already in `admin-web/public/`). Recreate **pixel-faithfully** in `admin-web/src/pages/LoginPage.tsx` (full replace), keeping the real auth wiring.

**Layout** (centered column, max-width 400px, page bg `--slate-50`):
- **Brand** (above card): `zenzoo-mark.png` 52px + "ZenZoo" (`Zen`=#3FB2A6, `Zoo`=#1E6CA1, `--fw-extra` 24px) + eyebrow "ADMIN CONSOLE" (11px uppercase, `.22em`, `--text-faint`).
- **Card** (`--surface-card`, 1px `--border-subtle`, `--radius-lg`, `--shadow-sm`, padding `28px 28px 26px`):
  - H1 "Đăng nhập quản trị" (`--fw-bold` 19px), subtitle "Khu vực giới hạn — chỉ dành cho quản trị viên ZenZoo." (`--text-muted` 13px).
  - Form (gap 16): **Email** (label 12px semibold + input 42px, `--radius-md`, focus ring); **Mật khẩu** (label row with right-aligned "Quên mật khẩu?" link `--text-link`; input 42px with right-side **show/hide eye toggle** button); **"Ghi nhớ thiết bị này"** checkbox (`accent-color:--brand`, default checked); primary **"Đăng nhập"** button (42px, `--brand`, white, log-in SVG icon, hover `--blue-700`).
  - Divider row: hairline — "hoặc" (11px uppercase faint) — hairline.
  - Secondary **"Đăng nhập với Google Workspace"** button (42px, `--surface-card`, 1px `--border-default`, multicolor Google SVG, hover `--slate-50`).
- **Footer** (below card): lock SVG + "Kết nối được mã hóa · ZenZoo Admin v2.4.0" (`--text-faint` 12px).

**Behavior:**
- **Submit** → `api.login(email, password)` → `setToken(token, remember)` + `setAdmin(admin)` → `navigate('/', {replace:true})`. On error → inline alert via `friendlyError` (reuse current pattern + the Phase-1 login-error fix already in place).
- **Show/hide password** → local `showPass` state toggles `type` + eye-open/eye-off icon (icon paths from the design's `eyeOpen`/`eyeOff`).
- **"Ghi nhớ thiết bị này"** → functional: extend `lib/auth.ts` so `setToken(token, remember)` writes to `localStorage` when `remember` (persist) or `sessionStorage` when not (cleared on browser close); `getToken()` reads whichever store holds it; `clearToken()` clears both. Default checked = current localStorage behavior. `api.ts`/`ProtectedRoute` keep using `getToken()` unchanged.
- **"Quên mật khẩu?"** and **"Đăng nhập với Google Workspace"** → render faithfully but **non-functional placeholders** (no admin SSO / reset backend): onClick sets a small dismissible info line "Tính năng đang phát triển — vui lòng liên hệ super-admin." No navigation, no backend call.

**Files:** replace `admin-web/src/pages/LoginPage.tsx`; extend `admin-web/src/lib/auth.ts` (remember/session store). **Test:** `LoginPage.test.tsx` — renders email/password/buttons; eye toggle flips input `type`; wrong password shows the server error; clicking a placeholder shows the "đang phát triển" note; `setToken` honors remember (localStorage vs sessionStorage) via an `auth.test.ts` case.

## 2. Logout (topbar)

- New `admin-web/src/shell/UserMenu.tsx`: wraps the existing topbar avatar+name block in a button that toggles a dropdown (name · email · role, divider, **"Đăng xuất"**). Closes on outside-click and `Esc`.
- "Đăng xuất" → `clearToken()` (from `lib/auth.ts`) → `navigate('/login', { replace: true })`.
- `Topbar.tsx` renders `<UserMenu>` in place of the current static avatar span. No backend change.

## 3. Backend (read-only, extends existing admin API)

### 3a. `GET /admin/api/billing/summary?range=today|7d|30d|quarter`
Gated by `requireAdmin`. Returns:
```ts
{
  range: RangeKey,
  kpis: {
    revenue:    { value: number, deltaPct: number | null },  // paid Σ amountVnd in range vs previous range
    mrr:        { value: number },                            // current snapshot (range-independent)
    arpu:       { value: number },                            // range revenue / active users in range
    refundRate: { value: number },                            // refunded/(paid+refunded) % in range
  },
  packages: [                                                 // current snapshot
    { code: 'free',            label: 'Free',              priceVnd: 0,      subscribers: number },
    { code: 'zen_pro_monthly', label: 'Zen Pro · Monthly', priceVnd: 29000,  subscribers: number },
    { code: 'zen_pro_yearly',  label: 'Zen Pro · Yearly',  priceVnd: 279000, subscribers: number },
  ]
}
```
**KPI definitions (explicit):**
- `revenue.value` = Σ `amountVnd` of `status='paid'` orders with `paidAt` in `[curStart,end]`; `deltaPct` vs the equal-length previous window (reuse `windowFor`/`deltaPct` from `admin.metrics.ts`).
- `mrr.value` = `monthlyCount*29000 + yearlyCount*round(279000/12)` where counts come from the package derivation below (current active-premium users). MRR is a **now** snapshot, not range-scoped.
- `arpu.value` = `revenue.value / activeUsers` where activeUsers = distinct users with a FocusSession/ActivityEvent in `[curStart,end]` (same union as Overview DAU/MAU). 0 if no active users.
- `refundRate.value` = `refunded / (paid + refunded) * 100` counted in range (0 when denominator 0).
- **Package subscribers:** Free = users with no active premium subscription. Monthly/Yearly = active-premium users bucketed by their **latest `paid` subscription order's `productCode`**. (Active-premium users with no paid order — e.g. seeded — are counted in neither Pro card; noted as a known gap.)

### 3b. Extend `GET /admin/api/payments`
Add query params `page`, `pageSize` (default 25, max 100), `from`, `to` (ISO date, filter on `createdAt`), keep `status` (allowlisted). Return `{ total, page, pageSize, items }` (item shape unchanged). Ordering `createdAt desc`. (Phase-1 callers: none besides this console.)

### 3c. `billing.metrics.ts` (pure, DB-agnostic, TDD)
`backend/src/admin/billing.metrics.ts` — testable without Postgres:
- `monthlyEquivalentVnd(productCode): number` — 29000 monthly, `round(279000/12)` yearly, 0 otherwise.
- `computeMrr(monthlyCount, yearlyCount): number`.
- `refundRate(refunded, paid): number` — `paid+refunded===0 ? 0 : round1(refunded/(paid+refunded)*100)`.
- `arpu(revenue, activeUsers): number` — `activeUsers===0 ? 0 : Math.round(revenue/activeUsers)`.
- `bucketLatestPaidByUser(orders: {userId,productCode,paidAt}[], premiumUserIds: Set<string>): { monthly, yearly }` — walk orders newest-first, first occurrence per premium userId tallies monthly/yearly.
Route composes these with Prisma queries. Reuses `windowFor`, `deltaPct`, `round1` from `admin.metrics.ts`.

## 4. Frontend — `BillingPage.tsx` at `/billing`

- **nav.ts:** change `billing` from `wip('billing', …)` to an enabled item `to: '/billing'`; add `/billing` → `{crumb:'Dòng tiền', title:'Thanh toán & Gói'}` in `ROUTE_META` + `metaFor`. **App.tsx:** add `<Route path="/billing" element={<BillingPage/>}>` inside the protected AppShell.
- **Layout** (ManLab, matches design):
  - Range segmented control (Hôm nay/7/30/Quý) — reuse `SegmentedControl`.
  - 4 KPI cards: **Doanh thu** (value + ▲/▼ deltaPct "so với kỳ trước"), **MRR** (value + note "doanh thu định kỳ/tháng"), **ARPU** (value + "trên mỗi người hoạt động"), **Tỉ lệ hoàn tiền** (value% + "trong ngưỡng an toàn"). Reuse `KpiCard` with a new **`hideSpark`** prop (billing cards have no sparkline per design).
  - 2/1 grid: left = **"Giao dịch gần đây"** Card with toolbar (status filter segmented: Tất cả/Thành công/Chờ IPN/Thất bại/Hoàn tiền + date-range inputs + Xuất CSV) and a table (Mã giao dịch=`vnpTxnRef` mono, Người dùng, Gói tag, Số tiền mono, Trạng thái `StatusBadge`) + footer pagination (reuse pattern from Users). Right = 3 **package summary cards** (Free / Zen Pro Monthly / Zen Pro Yearly: price + `subscribers` count).
- **Status → badge map** (`statusFromPaymentStatus` in StatusBadge or BillingPage): paid→approved "Thành công", pending→pending "Chờ IPN", failed→rejected "Thất bại", review→review "Cần đối soát", refunded→suspended "Đã hoàn tiền".
- **Gói label:** `zen_pro_monthly`→"Monthly", `zen_pro_yearly`→"Yearly", else the code.
- **lib/api.ts:** add `billing: { summary(range) }` and extend `payments(params)` to accept `{status,from,to,page,pageSize}`. **types.ts:** `BillingSummary`, `BillingKpis`, `PackageStat`, `PaymentRow`, `PaymentsResponse`, `PaymentStatus`.
- **format/CSV:** reuse `formatVndShort`/`formatInt`/`formatDateTimeUtc`; reuse `toCsv`/`downloadCsv` for transaction export.
- Loading skeleton + `ErrorState` + `friendlyError` like Overview/Users.

## 5. Testing
- **Backend (Vitest):** `billing.metrics.test.ts` — monthlyEquivalentVnd, computeMrr, refundRate (incl. 0-denom), arpu (incl. 0 users), bucketLatestPaidByUser (newest-first, premium filter, dedupe per user). Smoke-test endpoints via curl (admin token) for `/billing/summary?range=` and paginated `/payments`.
- **Frontend (Vitest+RTL):** `BillingPage.test.tsx` (mock api → renders 4 KPI labels, a transaction row's status badge, 3 package cards, status filter calls api); `UserMenu.test.tsx` (open menu → "Đăng xuất" → token cleared + navigate to /login).
- **E2E browser (final):** login → open Billing → KPIs + transaction table + package cards render from real data; change range + status filter; Xuất CSV; then **avatar → Đăng xuất → back at /login**.

## 6. Risks / notes
- **Extending `/payments` response shape** (adds total/page/pageSize) — only this console consumes it; safe.
- **Package counts** rely on latest paid order per premium user; premium users with no paid order aren't in the Monthly/Yearly cards (rare; seeded). Free + Monthly + Yearly may not equal total users — that's expected (cards are informational).
- **MRR/refundRate** with current seed data: refunds = 0 → 0%; MRR reflects the 6 premium subs by their paid package.
- Reuse `windowFor`/`deltaPct` to keep range math consistent with Overview.

## 7. Done criteria
1. **Login** matches the new design (brand, card, show/hide password, Ghi nhớ thiết bị, Quên mật khẩu + Google Workspace placeholders, footer); real email/password login still works; "Ghi nhớ thiết bị" controls localStorage vs sessionStorage.
2. Avatar dropdown → "Đăng xuất" clears token and returns to `/login`.
3. `/console/billing` reachable from sidebar; 4 KPIs from `/admin/api/billing/summary` (range switch works), transaction table from paginated `/admin/api/payments` with status+date filter + CSV, 3 package cards with real subscriber counts.
4. Read-only — no payment/subscription mutation from admin.
5. Backend + frontend tests green; typecheck clean; E2E flow (**new login** → billing → logout) passes in browser.
