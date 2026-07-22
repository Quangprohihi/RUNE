# Admin Console — "Nhật ký kiểm toán" (Audit Log) design

Date: 2026-06-17 · Phase 2c · Branch `Rune-Dev`

## Goal
Build the `/console/audit` screen ("Nhật ký kiểm toán"), the sibling of Analytics
in the "Phân tích" nav group. The ManLab handoff depicts an **admin-action audit**
(Timestamp · Actor · Action · Resource · IP). The pre-existing `/admin/api/audit`
endpoint instead returns a **wallet/economy ledger** (WalletTransaction). User chose
**both, as two tabs** in one screen.

## Scope (user-approved)
One screen, segmented tabs:
- **Tab A — "Hành động admin"**: a real admin-action audit trail. Records every
  privileged mutation (confirm stuck order, cancel/extend subscription, edit package
  price, force-logout) with actor, action, resource, IP, timestamp. NET-NEW.
- **Tab B — "Giao dịch ví"**: the existing wallet ledger, now paginated. Read-only.

Global rule (carried from Phase 2b): lists default **15/page + pagination**.

## Backend

### Model (NET-NEW) `AdminAuditLog` → table `admin_audit_logs`
`id` uuid pk · `createdAt` timestamptz · `actorId` · `actorEmail` · `actorRole`
· `action` (dotted code, e.g. `payment.confirm`) · `resourceType` (e.g. `payment_order`)
· `resourceId` · `ip` (nullable) · `metadata` Json? . Indexes: `createdAt`, `actorId`, `action`.

### Recording — `recordAdminAction(req, admin, {action, resourceType, resourceId, metadata})`
Thin closure over `prisma` in `admin.routes.ts`. **Best-effort**: wrapped in try/catch so
an audit-write failure can NEVER break the underlying admin action. Called AFTER the action
succeeds. IP via pure helper `clientIp(xff, reqIp)` (x-forwarded-for first, else `req.ip`),
mirroring `payments.routes.ts`.

Instrumented endpoints (all already gate `requireAdmin('moderator')`):
| Endpoint | action | resourceType | resourceId | metadata |
|---|---|---|---|---|
| POST /payments/:id/confirm | `payment.confirm` | payment_order | :id | — |
| POST /users/:id/subscription (cancel) | `subscription.cancel` | user | :id | — |
| POST /users/:id/subscription (extend) | `subscription.extend` | user | :id | `{days}` |
| PUT /packages/:code | `package.update` | package | :code | `{changes}` |
| POST /users/:id/force-logout | `user.force_logout` | user | :id | `{revoked}` |

### Endpoints
- **GET /admin/api/admin-audit** (NET-NEW, `requireAdmin` base) — paginated 15/page.
  Query: `action?`, `q?` (actor-email contains), `page?`, `pageSize?` (clamp 1..100).
  Returns `{ total, page, pageSize, items: [{ id, at, actorId, actorEmail, actorRole,
  action, resourceType, resourceId, ip, metadata }] }`.
- **GET /admin/api/audit** (reshape; currently unused by FE) — add `page/pageSize` (15) + `total`.
  Items unchanged shape `{ id, at, actor, reason, amount, currency, refType }` (add `id`).

### Pure helper (TDD) `backend/src/admin/audit.util.ts`
`clientIp(xff?: string, reqIp?: string): string | null`. Unit-tested.

### Seed
Idempotent guard: if `adminAuditLog.count() === 0`, insert ~4 sample rows (one per action type,
actor = `adm_super` / `admin@zenzoo.app`) so the screen demos with data even before live actions.

## Frontend

### types.ts
`AdminAuditRow`, `AdminAuditResponse`, `WalletAuditRow`, `WalletAuditResponse`, `AuditQuery`.

### api.ts
`adminAudit(query)`, `walletAudit({page,pageSize})`.

### Shared `pageList` (cleanup)
Extract the `pageList(current,total)` helper (currently duplicated in UsersPage + BillingPage —
the Phase-2b known-minor) into `admin-web/src/lib/pageList.ts`; import in Users, Billing, Audit.

### AuditPage.tsx (`/console/audit`)
Segmented tabs (`zz-seg`): **Hành động admin** | **Giao dịch ví**. Per tab: filter row
(admin tab: action `<select>` + actor search input; wallet tab: none) + **Xuất CSV** + table +
pagination (shared `pageList`). Loading `Skeleton`, `ErrorState` on failure (established pattern).
- Admin cols: Thời gian · Admin (email + role tag) · Hành động (mono `Tag`) · Đối tượng
  (`resourceType:resourceId`) · IP.
- Wallet cols: Thời gian · Người dùng · Lý do · Số tiền (signed) · Loại (`refType`).
- Action-code → Vietnamese label map lives on the frontend (UI concern).

### nav/route
`nav.ts`: flip `audit` to enabled `to:'/audit'`; add `ROUTE_META['/audit']` + `metaFor`.
`App.tsx`: add `/audit` route → `AuditPage`.

## Tests
- Backend (in-container, unit): `audit.util.test.ts` — `clientIp` (xff priority, trims, fallback, null).
- Frontend (Vitest+RTL): `AuditPage.test.tsx` — renders admin rows; switching to wallet tab
  re-queries the wallet API + renders; action filter passes `action` param.

## Verification
Backend tests + FE tests + typecheck + build green; E2E in browser (both tabs render real data,
tab switch, filter, pagination; perform one live admin action and confirm a new audit row appears);
final review of the diff (auth gating unchanged, best-effort recording never throws, no secrets);
commit on `Rune-Dev`.

## Non-goals
Editing/deleting audit rows; exporting the full server-side dataset (CSV exports the current page,
matching the Users screen); IP geolocation; admin-action audit for read endpoints.
