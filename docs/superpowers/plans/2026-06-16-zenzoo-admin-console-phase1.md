# ZenZoo Admin Console — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the ZenZoo admin web console (app shell + Tổng quan + Người dùng + Login) as a React+Vite+TS SPA served by the existing Express backend at `/console`, wired to a real (extended) admin API, faithful to the ManLab design in both A/B themes.

**Architecture:** A new standalone Vite project at `admin-web/` builds to `admin-web/dist`, which the existing Express `/console` route serves (one-line candidate change). The backend Prisma schema gains `User.status` + `User.lastLoginAt`; the `/admin/api/overview` and `/users` endpoints are extended and a `/admin/api/health` is added. The frontend reuses ManLab CSS tokens verbatim and re-implements the needed design-system components as React/TSX primitives.

**Tech Stack:** Backend — Express 5, Prisma 7 (PostgreSQL), TypeScript (CommonJS), Vitest (new, unit-only). Frontend — React 18, Vite 5, TypeScript, react-router-dom 6, Vitest + Testing Library + jsdom.

**Reference design files (read-only source of truth):**
- `admin_report/project/ZenZoo Admin.dc.html` — markup. Overview = lines 190–341, Users = lines 344–492, sidebar nav = lines 54–167, topbar = 173–187, theme vars = 1298–1326.
- `admin_report/project/_ds/manlab-design-system-019e1f11-71f2-7be6-9831-c1db2b42c8f8/` — token CSS + `styles.css` + `_ds_manifest.json`.
- Spec: `docs/superpowers/specs/2026-06-16-zenzoo-admin-console-design.md`.

**Conventions for every code step:** keep all Vietnamese UI copy exactly as in the design. Use ManLab CSS variables (`var(--blue-600)`, `var(--status-*)`, etc.) — never hardcode hex. Numbers use `font-variant-numeric: tabular-nums`; codes/IDs/values use `var(--font-mono)`.

---

## File Structure

**Backend (modify/create):**
- `backend/prisma/schema.prisma` — add 2 columns to `model User` (Task 1).
- `backend/prisma/migrations/*` — generated migration (Task 1).
- `backend/src/app.ts:761-763` — set `lastLoginAt` in `issueAuthResponse` (Task 2); add `admin-web/dist` candidate at `:1651-1655` (Task 10).
- `backend/src/admin/admin.metrics.ts` — NEW: pure metric helpers (Task 4).
- `backend/src/admin/__tests__/admin.metrics.test.ts` — NEW (Task 4).
- `backend/src/routes/admin.routes.ts` — extend `/overview`, `/users`; add `/health` (Tasks 5–7).
- `backend/prisma/seed.ts` — seed sample statuses (Task 8).
- `backend/package.json`, `backend/vitest.config.ts`, `backend/tsconfig.json` — Vitest setup (Task 3).

**Frontend (all new, under `admin-web/`):**
- Config: `package.json`, `vite.config.ts`, `tsconfig.json`, `tsconfig.node.json`, `index.html`, `src/test/setup.ts`.
- `src/main.tsx`, `src/App.tsx`.
- `src/styles/manlab/*.css` (copied tokens), `src/styles/global.css`.
- `src/lib/`: `types.ts`, `format.ts`, `friendlyError.ts`, `auth.ts`, `api.ts`.
- `src/ds/`: `Card.tsx`, `Button.tsx`, `IconButton.tsx`, `Input.tsx`, `Tag.tsx`, `StatusBadge.tsx`, `ProgressMeter.tsx`, `Avatar.tsx`, `SegmentedControl.tsx`, `icons.tsx`, `index.ts`.
- `src/shell/`: `ThemeProvider.tsx`, `theme.ts`, `nav.ts`, `Sidebar.tsx`, `Topbar.tsx`, `CompareBar.tsx`, `AppShell.tsx`.
- `src/components/`: `Sparkline.tsx`, `ErrorState.tsx`, `LoadingSkeleton.tsx`, `KpiCard.tsx`.
- `src/pages/`: `LoginPage.tsx`, `OverviewPage.tsx`, `UsersPage.tsx`, `UserDetailPage.tsx`.

---

## Execution Environment (Docker — IMPORTANT)

This repo runs the backend **inside Docker Compose**, not on the host:
- `zenzoo_postgres` (Postgres 16, healthy on `localhost:5432`), `zenzoo_backend` (Node, `ts-node-dev --respawn`, serves `:3000`, mounts `./backend → /app` + a named `node_modules` volume), `zenzoo_adminer` (`:8080`).
- The project syncs schema with **`prisma db push`** — there is **no `prisma/migrations/` directory**. Do **not** use `prisma migrate dev`.

**Command rules for every task:**
- **Edit files** with normal file tools on the host (paths under `e:/ChuyenNha/Prm393/rune/...`). The mount reflects edits into the container, **but the `ts-node-dev` file watcher does NOT fire reliably on this Windows bind-mount (no inotify propagation).** After editing any backend source file, run **`docker compose restart backend`** (wait for "ZenZoo API listening on port 3000") before smoke-testing — otherwise the live server runs stale code.
- **Run backend tooling inside the container:** `docker compose exec -T backend sh -c "<cmd>"` (working dir is `/app` = `backend/`). This covers `prisma db push`, `prisma generate`, `npm test`, `tsc --noEmit`, `npm run prisma:seed`. (Running on the host would update a *different* Prisma client than the live server uses.)
- **Run frontend tooling on the host:** `cd admin-web && npm <...>` (host has Node 22 / npm 11). The Vite dev proxy and prod build both target the container API at `localhost:3000`.
- **Commit on the host:** `cd e:/ChuyenNha/Prm393/rune && git add <paths> && git commit -m "..."` (the container has no `.git`).
- **The SPA build must land under `backend/`** so the running container can serve it: Vite `build.outDir` = `../backend/admin-web/dist` (Task 9). The container resolves it via the `process.cwd()+'admin-web/dist'` = `/app/admin-web/dist` candidate (Task 10).
- Smoke-test the API from the host with `curl localhost:3000/...` (the port is published).

## Phase 0 — Prerequisites

- [ ] **Step 0.1:** Confirm the stack is up: `docker compose ps` shows `zenzoo_postgres` (healthy), `zenzoo_backend`, `zenzoo_adminer` running. If not: `docker compose up -d`.
- [ ] **Step 0.2:** Confirm the API responds: `curl -s localhost:3000/health` (or the health route) returns OK, and `docker compose exec -T backend npx prisma db push` reports the schema in sync (DB reachable). Seed is run automatically by the container on startup; re-run with `docker compose exec -T backend npm run prisma:seed` if needed.

---

## Phase 1 — Backend

### Task 1: Add `User.status` and `User.lastLoginAt` (schema + migration)

**Files:**
- Modify: `backend/prisma/schema.prisma` (model User)

- [ ] **Step 1.1: Add the two columns.** In `model User`, after the `updatedAt` line, add:

```prisma
  status       String   @default("active") @map("status")            // active | suspended | review
  lastLoginAt  DateTime? @map("last_login_at") @db.Timestamptz(6)
```

- [ ] **Step 1.2: Push the schema (db push — this project has no migrations).**

Run: `docker compose exec -T backend npx prisma db push`
Expected: "Your database is now in sync with your Prisma schema"; the Prisma client is regenerated inside the container (the live `ts-node-dev` server respawns).

- [ ] **Step 1.3: Sanity check the client types.**

Run: `docker compose exec -T backend npx prisma generate`
Expected: no error; `status` and `lastLoginAt` now exist on the generated User type.

- [ ] **Step 1.4: Commit (on host).**

```bash
git add backend/prisma/schema.prisma
git commit -m "feat(backend): add User.status and User.lastLoginAt"
```

---

### Task 2: Set `lastLoginAt` on every successful auth

**Files:**
- Modify: `backend/src/app.ts:761-763`

The local `issueAuthResponse(userId)` is the single chokepoint called by `/auth/login`, `/auth/register`, `/auth/google`, `/auth/demo-login` (see `backend/src/routes/auth.routes.ts`). Stamp `lastLoginAt` there.

- [ ] **Step 2.1: Update the function.** Replace lines 761–763:

```ts
async function issueAuthResponse(userId: string) {
  await prisma.user.update({
    where: { id: userId },
    data: { lastLoginAt: new Date() },
  });
  return issueAuthServiceResponse(userId, bootstrap);
}
```

- [ ] **Step 2.2: Verify it compiles & runs.**

Run: `cd backend && npm run dev`
Then in another shell: `curl -s -X POST localhost:3000/auth/demo-login -H "Content-Type: application/json" -d '{"email":"verify.login@zenzoo.local","displayName":"Verify"}' | head -c 200`
Expected: JSON with tokens (200). Stop the server.

- [ ] **Step 2.3: Confirm the column was written.**

Run: `cd backend && npx prisma studio` (or a quick query) and confirm `verify.login@zenzoo.local` has a non-null `last_login_at`. (Alternatively skip Studio and trust Task 7's test.)

- [ ] **Step 2.4: Commit.**

```bash
git add backend/src/app.ts
git commit -m "feat(backend): stamp lastLoginAt on successful auth"
```

---

### Task 3: Add Vitest (unit-only) to the backend

The backend has no test runner. Add Vitest for **pure-function** unit tests only (no test database). Exclude tests from the `tsc` build.

**Files:**
- Modify: `backend/package.json`, `backend/tsconfig.json`
- Create: `backend/vitest.config.ts`

- [ ] **Step 3.1: Install Vitest.**

Run: `cd backend && npm install -D vitest@^2.1.0`
Expected: added to devDependencies.

- [ ] **Step 3.2: Add the test script** to `backend/package.json` `scripts`:

```json
    "test": "vitest run",
    "test:watch": "vitest"
```

- [ ] **Step 3.3: Create `backend/vitest.config.ts`:**

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
});
```

- [ ] **Step 3.4: Keep tests out of the production build.** In `backend/tsconfig.json`, add an `"exclude"` key alongside `"include"`:

```json
  "exclude": ["src/**/*.test.ts", "node_modules", "dist"]
```

- [ ] **Step 3.5: Verify the runner starts.**

Run: `cd backend && npm test`
Expected: "No test files found" (no error). This confirms Vitest is wired before Task 4 adds the first test.

- [ ] **Step 3.6: Commit.**

```bash
git add backend/package.json backend/package-lock.json backend/vitest.config.ts backend/tsconfig.json
git commit -m "chore(backend): add vitest for unit tests"
```

---

### Task 4: `admin.metrics.ts` — pure metric helpers (TDD)

DB-agnostic helpers the overview route composes. Pure → unit-testable without Postgres.

**Files:**
- Create: `backend/src/admin/admin.metrics.ts`
- Test: `backend/src/admin/__tests__/admin.metrics.test.ts`

- [ ] **Step 4.1: Write the failing test.** Create `backend/src/admin/__tests__/admin.metrics.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  rangeDays,
  windowFor,
  deltaPct,
  round1,
  bucketEdges,
  bucketCounts,
  sparkBucketCount,
} from '../admin.metrics';

describe('rangeDays', () => {
  it('maps each range to a day count', () => {
    expect(rangeDays('today')).toBe(1);
    expect(rangeDays('7d')).toBe(7);
    expect(rangeDays('30d')).toBe(30);
    expect(rangeDays('quarter')).toBe(90);
  });
});

describe('deltaPct', () => {
  it('computes signed percentage change rounded to 1dp', () => {
    expect(deltaPct(110, 100)).toBe(10);
    expect(deltaPct(90, 100)).toBe(-10);
    expect(deltaPct(105, 100)).toBe(5);
  });
  it('returns null when the previous value is 0', () => {
    expect(deltaPct(5, 0)).toBeNull();
  });
});

describe('round1', () => {
  it('rounds to one decimal', () => {
    expect(round1(4.24)).toBe(4.2);
    expect(round1(4.25)).toBe(4.3);
  });
});

describe('windowFor', () => {
  it('produces equal-length current and previous windows ending at now', () => {
    const now = new Date('2026-06-16T12:00:00.000Z');
    const w = windowFor('7d', now);
    expect(w.end.toISOString()).toBe('2026-06-16T12:00:00.000Z');
    expect(w.curStart.toISOString()).toBe('2026-06-09T12:00:00.000Z');
    expect(w.prevStart.toISOString()).toBe('2026-06-02T12:00:00.000Z');
    expect(w.prevEnd.toISOString()).toBe(w.curStart.toISOString());
    expect(w.days).toBe(7);
  });
});

describe('bucketEdges + bucketCounts', () => {
  it('splits a window into n buckets and counts timestamps', () => {
    const start = new Date('2026-06-01T00:00:00.000Z');
    const end = new Date('2026-06-05T00:00:00.000Z'); // 4 days
    const edges = bucketEdges(start, end, 4);
    expect(edges).toHaveLength(5);
    const dates = [
      new Date('2026-06-01T01:00:00.000Z'), // bucket 0
      new Date('2026-06-02T01:00:00.000Z'), // bucket 1
      new Date('2026-06-02T05:00:00.000Z'), // bucket 1
      new Date('2026-06-05T00:00:00.000Z'), // last edge → last bucket
    ];
    expect(bucketCounts(dates, edges)).toEqual([1, 2, 0, 1]);
  });
});

describe('sparkBucketCount', () => {
  it('clamps bucket count between 7 and 12', () => {
    expect(sparkBucketCount('today')).toBe(7);
    expect(sparkBucketCount('7d')).toBe(7);
    expect(sparkBucketCount('30d')).toBe(12);
    expect(sparkBucketCount('quarter')).toBe(12);
  });
});
```

- [ ] **Step 4.2: Run it; verify it fails.**

Run: `cd backend && npm test`
Expected: FAIL — cannot find module `../admin.metrics`.

- [ ] **Step 4.3: Implement `backend/src/admin/admin.metrics.ts`:**

```ts
/**
 * Pure, DB-agnostic helpers for the admin overview KPIs.
 * No Prisma here — the route fetches rows and feeds them in, so these
 * stay unit-testable without a database.
 */
export type RangeKey = 'today' | '7d' | '30d' | 'quarter';

const DAY_MS = 24 * 60 * 60 * 1000;

export function rangeDays(range: RangeKey): number {
  switch (range) {
    case 'today': return 1;
    case '7d': return 7;
    case '30d': return 30;
    case 'quarter': return 90;
    default: return 1;
  }
}

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function deltaPct(curr: number, prev: number): number | null {
  if (!prev) return null;
  return round1(((curr - prev) / prev) * 100);
}

export function windowFor(range: RangeKey, now: Date) {
  const days = rangeDays(range);
  const ms = days * DAY_MS;
  const end = new Date(now.getTime());
  const curStart = new Date(now.getTime() - ms);
  const prevStart = new Date(now.getTime() - 2 * ms);
  return { curStart, prevStart, prevEnd: curStart, end, days };
}

export function bucketEdges(start: Date, end: Date, n: number): Date[] {
  const edges: Date[] = [];
  const span = end.getTime() - start.getTime();
  for (let i = 0; i <= n; i++) {
    edges.push(new Date(start.getTime() + (span * i) / n));
  }
  return edges;
}

export function bucketCounts(dates: Date[], edges: Date[]): number[] {
  const n = edges.length - 1;
  const counts = new Array(n).fill(0);
  for (const d of dates) {
    const t = d.getTime();
    for (let i = 0; i < n; i++) {
      const lo = edges[i].getTime();
      const hi = edges[i + 1].getTime();
      const inBucket = i === n - 1 ? t >= lo && t <= hi : t >= lo && t < hi;
      if (inBucket) { counts[i]++; break; }
    }
  }
  return counts;
}

export function sparkBucketCount(range: RangeKey): number {
  return Math.min(12, Math.max(7, rangeDays(range)));
}

/** Bucketed sums (for value-weighted sparks like revenue / focus minutes). */
export function bucketSums(
  points: { at: Date; value: number }[],
  edges: Date[],
): number[] {
  const n = edges.length - 1;
  const sums = new Array(n).fill(0);
  for (const p of points) {
    const t = p.at.getTime();
    for (let i = 0; i < n; i++) {
      const lo = edges[i].getTime();
      const hi = edges[i + 1].getTime();
      const inBucket = i === n - 1 ? t >= lo && t <= hi : t >= lo && t < hi;
      if (inBucket) { sums[i] += p.value; break; }
    }
  }
  return sums;
}
```

- [ ] **Step 4.4: Run it; verify it passes.**

Run: `cd backend && npm test`
Expected: PASS (all cases in `admin.metrics.test.ts`).

- [ ] **Step 4.5: Commit.**

```bash
git add backend/src/admin/admin.metrics.ts backend/src/admin/__tests__/admin.metrics.test.ts
git commit -m "feat(backend): add pure metric helpers for overview KPIs"
```

---

### Task 5: Extend `GET /admin/api/overview` (ranged KPIs + delta + spark + goals)

**Files:**
- Modify: `backend/src/routes/admin.routes.ts:33-82`

Response shape (must match the frontend `OverviewResponse` in Task 11):
```
{ range, kpis: { dau, stickiness, focusMinutes, focusSessions, premiumUsers, revenue, avgStreak, conversion },
  goals: [{label,value,max,unit?}], recent: [{eventType,title,subtitle,actor,at}] }
```
Each KPI = `{ value:number, deltaPct:number|null, spark:number[] }`. Event-based KPIs (dau, focusSessions, focusMinutes, revenue) get real delta + spark; point-in-time KPIs (stickiness, premiumUsers, avgStreak, conversion) get `deltaPct:null, spark:[]`.

- [ ] **Step 5.1: Replace the `/admin/api/overview` handler** (lines 33–82) with:

```ts
  // ---- overview / KPIs (ranged, with delta + sparkline) ----
  app.get('/admin/api/overview', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const range = (['today', '7d', '30d', 'quarter'].includes(String(req.query.range))
        ? String(req.query.range)
        : 'today') as RangeKey;
      const now = new Date();
      const { curStart, prevStart, prevEnd, end } = windowFor(range, now);
      const mauStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      const edges = bucketEdges(curStart, end, sparkBucketCount(range));

      const [
        totalUsers,
        premiumUsers,
        sessionsCur, sessionsPrev, sessionRows,
        minutesCur, minutesPrev, minuteRows,
        revenueCur, revenuePrev, paymentRows,
        avgStreakAgg,
        dauFocus, dauEvents, mauFocus, mauEvents,
        recent,
      ] = await Promise.all([
        prisma.user.count(),
        prisma.subscription.count({ where: { plan: { not: 'free' }, status: 'active' } }),
        prisma.focusSession.count({ where: { status: 'completed', startedAt: { gte: curStart, lte: end } } }),
        prisma.focusSession.count({ where: { status: 'completed', startedAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.focusSession.findMany({ where: { status: 'completed', startedAt: { gte: curStart, lte: end } }, select: { startedAt: true, plannedMinutes: true } }),
        prisma.focusSession.aggregate({ _sum: { plannedMinutes: true }, where: { status: 'completed', startedAt: { gte: curStart, lte: end } } }),
        prisma.focusSession.aggregate({ _sum: { plannedMinutes: true }, where: { status: 'completed', startedAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.focusSession.findMany({ where: { status: 'completed', startedAt: { gte: curStart, lte: end } }, select: { startedAt: true, plannedMinutes: true } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: curStart, lte: end } } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.paymentOrder.findMany({ where: { status: 'paid', paidAt: { gte: curStart, lte: end } }, select: { paidAt: true, amountVnd: true } }),
        prisma.userStreak.aggregate({ _avg: { currentStreak: true } }),
        prisma.focusSession.findMany({ where: { startedAt: { gte: curStart, lte: end } }, select: { userId: true, startedAt: true } }),
        prisma.activityEvent.findMany({ where: { createdAt: { gte: curStart, lte: end } }, select: { userId: true } }),
        prisma.focusSession.findMany({ where: { startedAt: { gte: mauStart, lte: end } }, select: { userId: true } }),
        prisma.activityEvent.findMany({ where: { createdAt: { gte: mauStart, lte: end } }, select: { userId: true } }),
        prisma.activityEvent.findMany({ take: 7, orderBy: { createdAt: 'desc' }, include: { user: { select: { displayName: true } } } }),
      ]);

      const dau = new Set<string>([...dauFocus.map((r: any) => r.userId), ...dauEvents.map((r: any) => r.userId)]).size;
      const mau = new Set<string>([...mauFocus.map((r: any) => r.userId), ...mauEvents.map((r: any) => r.userId)]).size;
      const stickiness = mau ? round1((dau / mau) * 100) : 0;
      const avgStreak = round1(avgStreakAgg._avg.currentStreak ?? 0);
      const conversion = totalUsers ? round1((premiumUsers / totalUsers) * 100) : 0;
      const focusMinutes = minutesCur._sum.plannedMinutes ?? 0;
      const focusMinutesPrev = minutesPrev._sum.plannedMinutes ?? 0;
      const revenue = revenueCur._sum.amountVnd ?? 0;
      const revenuePrevVal = revenuePrev._sum.amountVnd ?? 0;

      const dauSpark = bucketCounts(dauFocus.map((r: any) => new Date(r.startedAt)), edges);
      const sessionSpark = bucketCounts(sessionRows.map((r: any) => new Date(r.startedAt)), edges);
      const minuteSpark = bucketSums(minuteRows.map((r: any) => ({ at: new Date(r.startedAt), value: r.plannedMinutes })), edges);
      const revenueSpark = bucketSums(paymentRows.map((r: any) => ({ at: new Date(r.paidAt), value: r.amountVnd })), edges);

      const point = (value: number) => ({ value, deltaPct: null as number | null, spark: [] as number[] });

      res.json({
        range,
        kpis: {
          dau: { value: dau, deltaPct: null, spark: dauSpark },
          stickiness: point(stickiness),
          focusMinutes: { value: focusMinutes, deltaPct: deltaPct(focusMinutes, focusMinutesPrev), spark: minuteSpark },
          focusSessions: { value: sessionsCur, deltaPct: deltaPct(sessionsCur, sessionsPrev), spark: sessionSpark },
          premiumUsers: point(premiumUsers),
          revenue: { value: revenue, deltaPct: deltaPct(revenue, revenuePrevVal), spark: revenueSpark },
          avgStreak: point(avgStreak),
          conversion: point(conversion),
        },
        goals: [
          { label: 'Doanh thu quý', value: Math.round((revenue / Math.max(1, Number(process.env.QUARTER_REVENUE_TARGET ?? 100000000))) * 100), max: 100, unit: '%' },
          { label: 'Zen Pro · mục tiêu ' + Number(process.env.QUARTER_PRO_TARGET ?? 400), value: premiumUsers, max: Number(process.env.QUARTER_PRO_TARGET ?? 400) },
          { label: 'Tỉ lệ chuyển đổi', value: conversion, max: Number(process.env.CONVERSION_TARGET ?? 8), unit: '%' },
        ],
        recent: recent.map((e: any) => ({
          eventType: e.eventType,
          title: e.title,
          subtitle: e.subtitle,
          actor: e.user?.displayName ?? '—',
          at: e.createdAt,
        })),
      });
    } catch (error) {
      next(error);
    }
  });
```

- [ ] **Step 5.2: Add the import** at the top of `backend/src/routes/admin.routes.ts` (after line 1):

```ts
import {
  windowFor, bucketEdges, bucketCounts, bucketSums, deltaPct, round1, sparkBucketCount, RangeKey,
} from '../admin/admin.metrics';
```

- [ ] **Step 5.3: Type-check & smoke test.**

Run: `cd backend && npx tsc --noEmit && npm run dev`
Then: get an admin token, then call overview:
```bash
TOKEN=$(curl -s -X POST localhost:3000/admin/api/auth/login -H "Content-Type: application/json" -d '{"email":"admin@zenzoo.app","password":"zenzoo-admin"}' | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).token))")
curl -s "localhost:3000/admin/api/overview?range=7d" -H "Authorization: Bearer $TOKEN" | head -c 600
```
Expected: JSON with `range:"7d"`, all 8 `kpis`, `goals` (3), `recent`. Stop the server.

- [ ] **Step 5.4: Commit.**

```bash
git add backend/src/routes/admin.routes.ts
git commit -m "feat(backend): ranged overview KPIs with delta, sparkline, goals"
```

---

### Task 6: Add `GET /admin/api/health`

**Files:**
- Modify: `backend/src/routes/admin.routes.ts` (add a handler near the overview route)

- [ ] **Step 6.1: Add the handler** (place it right after the overview handler):

```ts
  // ---- service health (for the overview "Tình trạng hệ thống" card) ----
  app.get('/admin/api/health', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const t0 = Date.now();
      let db: 'ok' | 'down' = 'ok';
      try {
        await prisma.$queryRaw`SELECT 1`;
      } catch {
        db = 'down';
      }
      const apiLatencyMs = Date.now() - t0;
      res.json({
        db,
        vnpay: Boolean(process.env.VNPAY_TMN_CODE || process.env.VNP_TMN_CODE),
        gemini: Boolean(process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY),
        apiLatencyMs,
      });
    } catch (error) {
      next(error);
    }
  });
```

- [ ] **Step 6.2: Smoke test.**

Run: `cd backend && npm run dev`, then `curl -s localhost:3000/admin/api/health -H "Authorization: Bearer $TOKEN"`
Expected: `{"db":"ok","vnpay":<bool>,"gemini":<bool>,"apiLatencyMs":<n>}`. Stop the server.

- [ ] **Step 6.3: Commit.**

```bash
git add backend/src/routes/admin.routes.ts
git commit -m "feat(backend): add /admin/api/health endpoint"
```

---

### Task 7: Extend `GET /admin/api/users` (filters + new fields)

**Files:**
- Modify: `backend/src/routes/admin.routes.ts:85-134`

- [ ] **Step 7.1: Replace the `/admin/api/users` handler** (lines 85–134) with:

```ts
  // ---- users list (search + plan/status filters) ----
  app.get('/admin/api/users', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const q = String(req.query.q ?? '').trim();
      const plan = String(req.query.plan ?? '').trim();     // 'free' | 'premium'
      const status = String(req.query.status ?? '').trim();  // 'active' | 'suspended' | 'review'
      const page = Math.max(1, Number(req.query.page ?? 1));
      const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize ?? 25)));

      const where: any = {};
      if (q) {
        where.OR = [
          { email: { contains: q, mode: 'insensitive' } },
          { displayName: { contains: q, mode: 'insensitive' } },
        ];
      }
      if (status === 'active' || status === 'suspended' || status === 'review') {
        where.status = status;
      }
      if (plan === 'free') {
        where.OR2 = undefined; // placeholder removed below
        where.subscription = { is: null };
      } else if (plan === 'premium') {
        where.subscription = { plan: { not: 'free' } };
      }
      delete where.OR2;

      const [total, users] = await Promise.all([
        prisma.user.count({ where }),
        prisma.user.findMany({
          where,
          skip: (page - 1) * pageSize,
          take: pageSize,
          orderBy: { createdAt: 'desc' },
          include: {
            subscription: true,
            pet: { select: { level: true } },
            streak: { select: { currentStreak: true } },
          },
        }),
      ]);

      res.json({
        total,
        page,
        pageSize,
        items: users.map((u: any) => ({
          id: u.id,
          email: u.email,
          displayName: u.displayName,
          provider: u.provider,
          createdAt: u.createdAt,
          plan: u.subscription && u.subscription.plan !== 'free' ? u.subscription.plan : 'free',
          status: u.status ?? 'active',
          level: u.pet?.level ?? 1,
          streak: u.streak?.currentStreak ?? 0,
          lastLoginAt: u.lastLoginAt ?? null,
        })),
      });
    } catch (error) {
      next(error);
    }
  });
```

> Note: `plan=free` means "no active premium subscription" — modeled as `subscription is null`. If your data always creates a `subscription` row with `plan:'free'`, change the free branch to `where.subscription = { plan: 'free' }`. Verify against seed data in Step 7.2.

- [ ] **Step 7.2: Smoke test all filters.**

Run: `cd backend && npx tsc --noEmit && npm run dev`, then:
```bash
curl -s "localhost:3000/admin/api/users?pageSize=2" -H "Authorization: Bearer $TOKEN" | head -c 500
curl -s "localhost:3000/admin/api/users?status=active&pageSize=2" -H "Authorization: Bearer $TOKEN" | head -c 300
curl -s "localhost:3000/admin/api/users?plan=premium&pageSize=2" -H "Authorization: Bearer $TOKEN" | head -c 300
```
Expected: items include `status`, `lastLoginAt`, `plan`; filtered queries return subsets. If `plan=free` returns 0 unexpectedly, apply the note in Step 7.1. Stop the server.

- [ ] **Step 7.3: Commit.**

```bash
git add backend/src/routes/admin.routes.ts
git commit -m "feat(backend): users list filters (plan/status) + lastLoginAt/status fields"
```

---

### Task 8: Seed sample statuses (for demoing the filters)

**Files:**
- Modify: `backend/prisma/seed.ts`

- [ ] **Step 8.1: Inspect the seed file** to find where users are created (`grep -n "user.create\|user.upsert\|displayName" backend/prisma/seed.ts`).

- [ ] **Step 8.2: After users are seeded, set a couple of non-active statuses.** Add near the end of the seed's main function (before it closes), adapting the emails to ones that exist in your seed (use `findMany` to be safe):

```ts
  // Demo moderation states for the admin console Users filter
  const someUsers = await prisma.user.findMany({ take: 3, orderBy: { createdAt: 'asc' } });
  if (someUsers[0]) await prisma.user.update({ where: { id: someUsers[0].id }, data: { status: 'review' } });
  if (someUsers[1]) await prisma.user.update({ where: { id: someUsers[1].id }, data: { status: 'suspended' } });
```

- [ ] **Step 8.3: Run the seed.**

Run: `cd backend && npm run prisma:seed`
Expected: completes; at least one `review` and one `suspended` user now exist.

- [ ] **Step 8.4: Commit.**

```bash
git add backend/prisma/seed.ts
git commit -m "chore(backend): seed sample moderation statuses"
```

---

## Phase 2 — Frontend scaffold

### Task 9: Initialize the Vite + React + TS project at `admin-web/`

**Files (create):** `admin-web/package.json`, `admin-web/vite.config.ts`, `admin-web/tsconfig.json`, `admin-web/tsconfig.node.json`, `admin-web/index.html`, `admin-web/.gitignore`, `admin-web/src/test/setup.ts`, `admin-web/src/main.tsx`, `admin-web/src/App.tsx`, `admin-web/src/styles/global.css`.

- [ ] **Step 9.1: Create `admin-web/package.json`:**

```json
{
  "name": "admin-web",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "typecheck": "tsc --noEmit",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.30.0"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.6.0",
    "@testing-library/react": "^16.1.0",
    "@testing-library/user-event": "^14.5.0",
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.4",
    "jsdom": "^25.0.1",
    "typescript": "^5.6.3",
    "vite": "^5.4.11",
    "vitest": "^2.1.8"
  }
}
```

- [ ] **Step 9.2: Create `admin-web/vite.config.ts`:**

```ts
/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/console/',
  plugins: [react()],
  // Build into the mounted backend dir so the running Docker container serves it at /console.
  build: { outDir: '../backend/admin-web/dist', emptyOutDir: true },
  server: {
    port: 5173,
    proxy: {
      '/admin/api': { target: 'http://localhost:3000', changeOrigin: true },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
    css: false,
  },
});
```

- [ ] **Step 9.3: Create `admin-web/tsconfig.json`:**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "types": ["vitest/globals", "@testing-library/jest-dom", "node"]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

- [ ] **Step 9.4: Create `admin-web/tsconfig.node.json`:**

```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "noEmit": true
  },
  "include": ["vite.config.ts"]
}
```

- [ ] **Step 9.5: Create `admin-web/index.html`:**

```html
<!doctype html>
<html lang="vi">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ZenZoo Admin Console</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 9.6: Create `admin-web/.gitignore`:**

```
node_modules
dist
*.local
```

Also append `admin-web/` to `backend/.gitignore` (create it if missing) so the build output `backend/admin-web/dist` is not committed:

```
admin-web/
```

- [ ] **Step 9.7: Create `admin-web/src/test/setup.ts`:**

```ts
import '@testing-library/jest-dom';
```

- [ ] **Step 9.8: Create `admin-web/src/styles/global.css`** (token imports added in Task 11; for now base resets):

```css
* { box-sizing: border-box; }
html, body, #root { margin: 0; height: 100%; }
body { background: var(--slate-50); }
::selection { background: var(--blue-100); }
a { color: inherit; text-decoration: none; }
button { font-family: inherit; }
```

- [ ] **Step 9.9: Create a minimal `admin-web/src/App.tsx`** (replaced fully in Task 19):

```tsx
export default function App() {
  return <div style={{ padding: 24, fontFamily: 'sans-serif' }}>ZenZoo Admin — scaffold OK</div>;
}
```

- [ ] **Step 9.10: Create `admin-web/src/main.tsx`:**

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles/global.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

- [ ] **Step 9.11: Install & verify dev + build.**

Run (on host): `cd admin-web && npm install && npm run build`
Expected: `backend/admin-web/dist/index.html` + `backend/admin-web/dist/assets/*` created (outDir points into the mounted backend dir), no errors.

- [ ] **Step 9.12: Commit.**

```bash
git add admin-web/package.json admin-web/package-lock.json admin-web/vite.config.ts admin-web/tsconfig.json admin-web/tsconfig.node.json admin-web/index.html admin-web/.gitignore admin-web/src
git commit -m "chore(admin-web): scaffold Vite + React + TS project"
```

---

### Task 10: Serve `admin-web/dist` from Express `/console`

**Files:**
- Modify: `backend/src/app.ts:1651-1655`

- [ ] **Step 10.1: Add `admin-web/dist` as the first candidate.** Replace the `adminWebCandidates` array (lines 1651–1655):

```ts
  const adminWebCandidates = [
    path.join(__dirname, '../../admin-web/dist'),
    path.join(process.cwd(), '../admin-web/dist'),
    path.join(process.cwd(), 'admin-web/dist'),
    path.join(__dirname, '../../admin-web'),
    path.join(process.cwd(), '../admin-web'),
    path.join(process.cwd(), 'admin-web'),
  ];
```

- [ ] **Step 10.2: Verify end-to-end.**

Run: `cd backend && npm run dev`. Open `http://localhost:3000/console` in a browser.
Expected: console logs `[admin] console served from ...admin-web\dist`; the page shows "ZenZoo Admin — scaffold OK". (Confirms `base:'/console/'` assets resolve.) Stop the server.

- [ ] **Step 10.3: Commit.**

```bash
git add backend/src/app.ts
git commit -m "feat(backend): serve admin-web/dist at /console"
```

---

### Task 11: Vendor ManLab tokens + shared types

**Files (create):**
- `admin-web/src/styles/manlab/{colors,typography,spacing,elevation,base,fonts}.css`
- `admin-web/src/lib/types.ts`
- Modify: `admin-web/src/styles/global.css`

- [ ] **Step 11.1: Copy the 6 token CSS files verbatim** from `admin_report/project/_ds/manlab-design-system-019e1f11-71f2-7be6-9831-c1db2b42c8f8/tokens/` into `admin-web/src/styles/manlab/` (filenames: `colors.css`, `typography.css`, `spacing.css`, `elevation.css`, `base.css`, `fonts.css`). Do **not** edit values.

- [ ] **Step 11.2: Import tokens first in `global.css`.** Prepend these imports above the existing rules:

```css
@import './manlab/fonts.css';
@import './manlab/colors.css';
@import './manlab/typography.css';
@import './manlab/spacing.css';
@import './manlab/elevation.css';
@import './manlab/base.css';
```

- [ ] **Step 11.3: Create `admin-web/src/lib/types.ts`:**

```ts
export type RangeKey = 'today' | '7d' | '30d' | 'quarter';

export interface Kpi { value: number; deltaPct: number | null; spark: number[]; }

export interface OverviewKpis {
  dau: Kpi; stickiness: Kpi; focusMinutes: Kpi; focusSessions: Kpi;
  premiumUsers: Kpi; revenue: Kpi; avgStreak: Kpi; conversion: Kpi;
}

export interface Goal { label: string; value: number; max: number; unit?: string; }
export interface RecentEvent { eventType: string; title: string; subtitle: string; actor: string; at: string; }
export interface OverviewResponse { range: RangeKey; kpis: OverviewKpis; goals: Goal[]; recent: RecentEvent[]; }

export interface HealthResponse { db: 'ok' | 'down'; vnpay: boolean; gemini: boolean; apiLatencyMs: number; }

export type AdminRole = 'support' | 'moderator' | 'super-admin';
export interface AdminMe { id: string; email: string; name: string; role: AdminRole; }
export interface LoginResponse { token: string; admin: AdminMe; }

export type UserStatus = 'active' | 'suspended' | 'review';
export interface UserRow {
  id: string; email: string; displayName: string; provider: string; createdAt: string;
  plan: string; status: UserStatus; level: number; streak: number; lastLoginAt: string | null;
}
export interface UsersResponse { total: number; page: number; pageSize: number; items: UserRow[]; }
export interface UsersQuery { q?: string; plan?: string; status?: string; page?: number; pageSize?: number; }
```

- [ ] **Step 11.4: Verify build still works.**

Run: `cd admin-web && npm run build`
Expected: success; fonts/colors imported (no missing-file errors).

- [ ] **Step 11.5: Commit.**

```bash
git add admin-web/src/styles admin-web/src/lib/types.ts
git commit -m "feat(admin-web): vendor ManLab tokens + shared types"
```

---

### Task 12: `lib/format.ts` — vi-VN formatting (TDD)

**Files:**
- Create: `admin-web/src/lib/format.ts`
- Test: `admin-web/src/lib/format.test.ts`

- [ ] **Step 12.1: Write the failing test** `admin-web/src/lib/format.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { formatInt, formatPercent, formatVndShort, formatDate, formatDateTimeUtc } from './format';

describe('formatInt', () => {
  it('groups thousands with vi-VN separators', () => {
    expect(formatInt(1842)).toBe('1.842');
    expect(formatInt(41250)).toBe('41.250');
  });
});

describe('formatPercent', () => {
  it('formats with comma decimals and a percent sign', () => {
    expect(formatPercent(27)).toBe('27%');
    expect(formatPercent(4.6)).toBe('4,6%');
  });
});

describe('formatVndShort', () => {
  it('shows millions/thousands shorthand', () => {
    expect(formatVndShort(1247000)).toBe('1,25 tr đ');
    expect(formatVndShort(279000)).toBe('279k đ');
    expect(formatVndShort(500)).toBe('500 đ');
  });
});

describe('formatDate / formatDateTimeUtc', () => {
  it('renders UTC dd/MM/yyyy and dd/MM · HH:mm', () => {
    expect(formatDate('2026-03-12T09:14:00.000Z')).toBe('12/03/2026');
    expect(formatDateTimeUtc('2026-06-13T09:14:00.000Z')).toBe('13/06 · 09:14');
  });
  it('renders an em dash for null/invalid', () => {
    expect(formatDate(null)).toBe('—');
    expect(formatDateTimeUtc(undefined)).toBe('—');
  });
});
```

- [ ] **Step 12.2: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL — cannot find `./format`.

- [ ] **Step 12.3: Implement `admin-web/src/lib/format.ts`:**

```ts
const vi = (opts?: Intl.NumberFormatOptions) => new Intl.NumberFormat('vi-VN', opts);
const pad2 = (x: number) => String(x).padStart(2, '0');

export function formatInt(n: number): string {
  return vi().format(Math.round(n));
}

export function formatPercent(n: number, maxDigits = 1): string {
  return vi({ maximumFractionDigits: maxDigits }).format(n) + '%';
}

function formatDecimal(n: number, maxDigits = 2): string {
  return vi({ maximumFractionDigits: maxDigits }).format(n);
}

export function formatVndShort(n: number): string {
  if (n >= 1_000_000) return formatDecimal(n / 1_000_000) + ' tr đ';
  if (n >= 1_000) return formatDecimal(n / 1_000) + 'k đ';
  return formatInt(n) + ' đ';
}

function toDate(iso: string | Date | null | undefined): Date | null {
  if (!iso) return null;
  const d = iso instanceof Date ? iso : new Date(iso);
  return isNaN(d.getTime()) ? null : d;
}

export function formatDate(iso: string | Date | null | undefined): string {
  const d = toDate(iso);
  if (!d) return '—';
  return `${pad2(d.getUTCDate())}/${pad2(d.getUTCMonth() + 1)}/${d.getUTCFullYear()}`;
}

export function formatDateTimeUtc(iso: string | Date | null | undefined): string {
  const d = toDate(iso);
  if (!d) return '—';
  return `${pad2(d.getUTCDate())}/${pad2(d.getUTCMonth() + 1)} · ${pad2(d.getUTCHours())}:${pad2(d.getUTCMinutes())}`;
}

export function relativeTime(iso: string | Date, now: number = Date.now()): string {
  const d = toDate(iso);
  if (!d) return '—';
  const sec = Math.max(0, Math.round((now - d.getTime()) / 1000));
  if (sec < 60) return `${sec} giây trước`;
  const min = Math.round(sec / 60);
  if (min < 60) return `${min} phút trước`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr} giờ trước`;
  return `${Math.round(hr / 24)} ngày trước`;
}
```

- [ ] **Step 12.4: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS.

> If `formatVndShort(1247000)` yields `1,25 tr đ` but a locale edge differs in CI, the test pins the contract — fix the implementation, not the test.

- [ ] **Step 12.5: Commit.**

```bash
git add admin-web/src/lib/format.ts admin-web/src/lib/format.test.ts
git commit -m "feat(admin-web): vi-VN number/date formatting helpers"
```

---

### Task 13: `lib/friendlyError.ts` (TDD)

**Files:**
- Create: `admin-web/src/lib/friendlyError.ts`
- Test: `admin-web/src/lib/friendlyError.test.ts`

- [ ] **Step 13.1: Write the failing test** `admin-web/src/lib/friendlyError.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { ApiError, friendlyError } from './friendlyError';

describe('friendlyError', () => {
  it('maps known HTTP statuses to Vietnamese messages', () => {
    expect(friendlyError(new ApiError(401, 'x'))).toBe('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    expect(friendlyError(new ApiError(403, 'x'))).toBe('Tài khoản không đủ quyền cho thao tác này.');
    expect(friendlyError(new ApiError(500, 'x'))).toBe('Máy chủ gặp sự cố. Vui lòng thử lại sau.');
  });
  it('passes through a 4xx server message that is not 401/403/404', () => {
    expect(friendlyError(new ApiError(400, 'Thiếu tham số'))).toBe('Thiếu tham số');
  });
  it('detects network failures', () => {
    expect(friendlyError(new TypeError('Failed to fetch'))).toBe('Không kết nối được máy chủ. Kiểm tra mạng và thử lại.');
  });
  it('falls back for unknown shapes', () => {
    expect(friendlyError({})).toBe('Đã có lỗi xảy ra. Vui lòng thử lại.');
  });
});
```

- [ ] **Step 13.2: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL.

- [ ] **Step 13.3: Implement `admin-web/src/lib/friendlyError.ts`:**

```ts
export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

export function friendlyError(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.status === 401) return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    if (err.status === 403) return 'Tài khoản không đủ quyền cho thao tác này.';
    if (err.status === 404) return 'Không tìm thấy dữ liệu.';
    if (err.status >= 500) return 'Máy chủ gặp sự cố. Vui lòng thử lại sau.';
    if (err.message) return err.message;
  }
  if (err instanceof Error && err.message) {
    if (err.message.includes('Failed to fetch') || err.message.includes('NetworkError')) {
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    }
    return err.message;
  }
  if (typeof err === 'string' && err) return err;
  return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
}
```

- [ ] **Step 13.4: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS.

- [ ] **Step 13.5: Commit.**

```bash
git add admin-web/src/lib/friendlyError.ts admin-web/src/lib/friendlyError.test.ts
git commit -m "feat(admin-web): friendlyError mapper + ApiError"
```

---

### Task 14: `lib/auth.ts` + `lib/api.ts` (TDD)

**Files:**
- Create: `admin-web/src/lib/auth.ts`, `admin-web/src/lib/api.ts`
- Test: `admin-web/src/lib/api.test.ts`

- [ ] **Step 14.1: Implement `admin-web/src/lib/auth.ts`** (no test needed — thin localStorage wrapper):

```ts
import type { AdminMe } from './types';

const TOKEN_KEY = 'zz_admin_token';
const ADMIN_KEY = 'zz_admin_user';
const THEME_KEY = 'zz_admin_theme';

export function getToken(): string | null { return localStorage.getItem(TOKEN_KEY); }
export function setToken(t: string): void { localStorage.setItem(TOKEN_KEY, t); }
export function isAuthed(): boolean { return !!getToken(); }
export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(ADMIN_KEY);
}
export function setAdmin(a: AdminMe): void { localStorage.setItem(ADMIN_KEY, JSON.stringify(a)); }
export function getAdmin(): AdminMe | null {
  const raw = localStorage.getItem(ADMIN_KEY);
  try { return raw ? (JSON.parse(raw) as AdminMe) : null; } catch { return null; }
}
export function getTheme(): 'a' | 'b' { return localStorage.getItem(THEME_KEY) === 'b' ? 'b' : 'a'; }
export function setTheme(t: 'a' | 'b'): void { localStorage.setItem(THEME_KEY, t); }
```

- [ ] **Step 14.2: Write the failing test** `admin-web/src/lib/api.test.ts`:

```ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { api } from './api';
import { ApiError } from './friendlyError';
import { setToken, getToken } from './auth';

function mockFetch(status: number, body: unknown) {
  return vi.fn().mockResolvedValue({
    status,
    ok: status >= 200 && status < 300,
    json: async () => body,
  } as Response);
}

describe('api', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('attaches the bearer token when present', async () => {
    setToken('tok123');
    const f = mockFetch(200, { range: '7d' });
    vi.stubGlobal('fetch', f);
    await api.overview('7d');
    const [, init] = f.mock.calls[0];
    expect((init.headers as Record<string, string>)['Authorization']).toBe('Bearer tok123');
    expect(f.mock.calls[0][0]).toBe('/admin/api/overview?range=7d');
  });

  it('clears the token on a 401 when already authed', async () => {
    setToken('tok123');
    vi.stubGlobal('fetch', mockFetch(401, { error: 'nope' }));
    vi.stubGlobal('location', { assign: vi.fn() } as unknown as Location);
    await expect(api.overview('today')).rejects.toBeInstanceOf(ApiError);
    expect(getToken()).toBeNull();
  });

  it('passes a login 401 through with the server message (no redirect)', async () => {
    vi.stubGlobal('fetch', mockFetch(401, { error: 'Sai email hoặc mật khẩu quản trị' }));
    await expect(api.login('a@b.c', 'x')).rejects.toMatchObject({
      status: 401,
      message: 'Sai email hoặc mật khẩu quản trị',
    });
  });
});
```

- [ ] **Step 14.3: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL — cannot find `./api`.

- [ ] **Step 14.4: Implement `admin-web/src/lib/api.ts`:**

```ts
import { ApiError } from './friendlyError';
import { getToken, clearToken } from './auth';
import type {
  AdminMe, LoginResponse, OverviewResponse, HealthResponse,
  UsersResponse, UsersQuery, RangeKey,
} from './types';

const BASE = '/admin/api';

async function request<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = { ...(opts.headers as Record<string, string>) };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (opts.body && !headers['Content-Type']) headers['Content-Type'] = 'application/json';

  const res = await fetch(BASE + path, { ...opts, headers });

  // Session-expired: only when we *were* authed (don't hijack the login form's 401).
  if (res.status === 401 && token) {
    clearToken();
    if (typeof window !== 'undefined' && window.location) window.location.assign('/console/login');
    throw new ApiError(401, 'Unauthorized');
  }

  if (!res.ok) {
    let msg = `Lỗi ${res.status}`;
    try {
      const data = await res.json();
      if (data?.error) msg = data.error;
      else if (data?.message) msg = data.message;
    } catch { /* non-JSON body */ }
    throw new ApiError(res.status, msg);
  }

  return res.json() as Promise<T>;
}

function buildUsersQuery(p: UsersQuery): string {
  const sp = new URLSearchParams();
  if (p.q) sp.set('q', p.q);
  if (p.plan) sp.set('plan', p.plan);
  if (p.status) sp.set('status', p.status);
  if (p.page) sp.set('page', String(p.page));
  if (p.pageSize) sp.set('pageSize', String(p.pageSize));
  const s = sp.toString();
  return s ? `?${s}` : '';
}

export const api = {
  login: (email: string, password: string) =>
    request<LoginResponse>('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  me: () => request<AdminMe>('/auth/me'),
  overview: (range: RangeKey) => request<OverviewResponse>(`/overview?range=${range}`),
  health: () => request<HealthResponse>('/health'),
  users: (params: UsersQuery) => request<UsersResponse>(`/users${buildUsersQuery(params)}`),
};
```

- [ ] **Step 14.5: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS (all api + earlier tests).

- [ ] **Step 14.6: Confirm the backend error shape.** Quick check that the backend error handler returns `{ error }` or `{ message }` (so `request()` surfaces server text). Run: `grep -n "errorHandler\|res.status(.*).json" backend/src/*.ts backend/src/**/*.ts | head`. If it uses a different key, update the two lines in `request()` accordingly.

- [ ] **Step 14.7: Commit.**

```bash
git add admin-web/src/lib/auth.ts admin-web/src/lib/api.ts admin-web/src/lib/api.test.ts
git commit -m "feat(admin-web): typed API client + auth token storage"
```

---

## Phase 3 — Design-system components

### Task 15: `ds.css` + structural primitives (Card, Button, IconButton, Input)

**Files (create):** `admin-web/src/ds/ds.css`, `admin-web/src/ds/Card.tsx`, `admin-web/src/ds/Button.tsx`, `admin-web/src/ds/IconButton.tsx`, `admin-web/src/ds/Input.tsx`. Modify `admin-web/src/styles/global.css`.

- [ ] **Step 15.1: Create `admin-web/src/ds/ds.css`** (class-based styling so hover/focus match the design; all values are tokens):

```css
/* ---- Button ---- */
.zz-btn {
  display: inline-flex; align-items: center; gap: 7px; white-space: nowrap;
  height: 34px; padding: 0 13px; border-radius: var(--radius-md);
  font: var(--fw-semibold) 13px/1 var(--font-sans); cursor: pointer;
  border: 1px solid transparent; transition: var(--transition-control);
}
.zz-btn--sm { height: 28px; padding: 0 10px; font-size: 12px; }
.zz-btn--primary { background: var(--brand); color: #fff; border-color: var(--brand); }
.zz-btn--primary:hover { background: var(--brand-hover); border-color: var(--brand-hover); }
.zz-btn--primary:active { background: var(--brand-active); }
.zz-btn--secondary { background: var(--surface-card); color: var(--text-body); border-color: var(--border-default); }
.zz-btn--secondary:hover { background: var(--surface-hover); }
.zz-btn:focus-visible { outline: none; box-shadow: var(--ring); }
.zz-btn:disabled { opacity: .55; cursor: not-allowed; }

/* ---- IconButton ---- */
.zz-iconbtn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 34px; height: 34px; border-radius: var(--radius-md);
  background: var(--surface-card); color: var(--text-body);
  border: 1px solid var(--border-default); cursor: pointer; transition: var(--transition-control);
}
.zz-iconbtn--sm { width: 28px; height: 28px; border: none; background: transparent; }
.zz-iconbtn:hover { background: var(--surface-hover); }
.zz-iconbtn:focus-visible { outline: none; box-shadow: var(--ring); }

/* ---- Input ---- */
.zz-input-wrap { position: relative; display: flex; align-items: center; width: 100%; }
.zz-input-wrap > svg { position: absolute; left: 10px; width: 16px; height: 16px; color: var(--text-faint); pointer-events: none; }
.zz-input {
  width: 100%; height: 34px; padding: 0 12px; border-radius: var(--radius-md);
  border: 1px solid var(--border-default); background: var(--surface-card);
  color: var(--text-strong); font: var(--fw-regular) 13px/1 var(--font-sans);
  transition: var(--transition-control);
}
.zz-input--with-prefix { padding-left: 32px; }
.zz-input::placeholder { color: var(--text-faint); }
.zz-input:focus { outline: none; border-color: var(--border-focus); box-shadow: var(--ring); }

/* ---- Tag ---- */
.zz-tag {
  display: inline-flex; align-items: center; height: 20px; padding: 0 8px;
  border-radius: var(--radius-pill); font: var(--fw-semibold) 11px/1 var(--font-sans);
  border: 1px solid transparent; white-space: nowrap;
}
.zz-tag--neutral { background: var(--slate-100); color: var(--slate-600); }
.zz-tag--accent { background: var(--accent-soft-bg); color: var(--accent-soft-fg); }
.zz-tag--outline { background: transparent; color: var(--text-muted); border-color: var(--border-default); }

/* ---- StatusBadge ---- */
.zz-badge {
  display: inline-flex; align-items: center; gap: 6px; height: 20px; padding: 0 9px;
  border-radius: var(--radius-pill); font: var(--fw-semibold) 11px/1 var(--font-sans);
  border: 1px solid; white-space: nowrap;
}
.zz-badge__dot { width: 6px; height: 6px; border-radius: 50%; position: relative; flex: none; }
.zz-badge__dot::after {
  content: ''; position: absolute; inset: 0; border-radius: 50%; background: inherit;
}
.zz-badge--pulse .zz-badge__dot::after { animation: zzpulse 1.8s ease-out infinite; }
@keyframes zzpulse { 0% { transform: scale(1); opacity: .55; } 70%, 100% { transform: scale(2.6); opacity: 0; } }

/* ---- SegmentedControl ---- */
.zz-seg { display: inline-flex; padding: 3px; gap: 2px; border-radius: var(--radius-md); }
.zz-seg--lite { background: var(--surface-sunken); border: 1px solid var(--border-subtle); }
.zz-seg--dark { background: rgba(255,255,255,0.08); }
.zz-seg__opt { border: none; cursor: pointer; border-radius: 6px; white-space: nowrap; background: transparent; transition: var(--transition-control); font: var(--fw-medium) 13px/1 var(--font-sans); padding: 0 14px; height: 32px; }
.zz-seg--dark .zz-seg__opt { height: 26px; padding: 0 13px; font-size: 12px; color: var(--slate-300); }
.zz-seg--lite .zz-seg__opt { color: var(--text-muted); }
.zz-seg__opt--on { font-weight: 600; box-shadow: var(--shadow-xs); }
.zz-seg--lite .zz-seg__opt--on { background: var(--surface-card); color: var(--text-strong); }
.zz-seg--dark .zz-seg__opt--on { background: #fff; color: var(--slate-900); }

/* ---- table rows / nav (used by pages + shell) ---- */
.zz-row:hover { background: var(--slate-50); }
.zz-nav:hover { background: var(--rail-hover, rgba(255,255,255,.06)) !important; color: var(--rail-fg-strong, #fff) !important; }
.zz-rail::-webkit-scrollbar { width: 9px; }
.zz-rail::-webkit-scrollbar-thumb { background: var(--rail-border, rgba(255,255,255,.12)); border-radius: 8px; }
.zz-rail::-webkit-scrollbar-track { background: transparent; }
```

- [ ] **Step 15.2: Import `ds.css`** at the end of `admin-web/src/styles/global.css`:

```css
@import '../ds/ds.css';
```

- [ ] **Step 15.3: Create `admin-web/src/ds/Card.tsx`:**

```tsx
import type { CSSProperties, ReactNode } from 'react';

interface CardProps {
  title?: string;
  subtitle?: string;
  padding?: 'none' | 'md';
  actions?: ReactNode;
  style?: CSSProperties;
  children?: ReactNode;
}

export function Card({ title, subtitle, padding = 'md', actions, style, children }: CardProps) {
  const bodyPad = padding === 'none' ? 0 : '16px 18px 18px';
  return (
    <section
      style={{
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-sm)',
        ...style,
      }}
    >
      {(title || subtitle || actions) && (
        <header
          style={{
            display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
            gap: 12, padding: '14px 18px', borderBottom: '1px solid var(--border-subtle)',
          }}
        >
          <div>
            {title && <div style={{ font: 'var(--fw-semibold) 14px/1.2 var(--font-sans)', color: 'var(--text-strong)' }}>{title}</div>}
            {subtitle && <div style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)', marginTop: 3 }}>{subtitle}</div>}
          </div>
          {actions}
        </header>
      )}
      <div style={{ padding: bodyPad }}>{children}</div>
    </section>
  );
}
```

- [ ] **Step 15.4: Create `admin-web/src/ds/Button.tsx`:**

```tsx
import type { ButtonHTMLAttributes, ReactNode } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md';
  children: ReactNode;
}

export function Button({ variant = 'primary', size = 'md', className = '', children, ...rest }: ButtonProps) {
  const cls = ['zz-btn', `zz-btn--${variant}`, size === 'sm' ? 'zz-btn--sm' : '', className].filter(Boolean).join(' ');
  return <button className={cls} {...rest}>{children}</button>;
}
```

- [ ] **Step 15.5: Create `admin-web/src/ds/IconButton.tsx`:**

```tsx
import type { ButtonHTMLAttributes, ReactNode } from 'react';

interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  size?: 'sm' | 'md';
  children: ReactNode;
}

export function IconButton({ label, size = 'md', className = '', children, ...rest }: IconButtonProps) {
  const cls = ['zz-iconbtn', size === 'sm' ? 'zz-iconbtn--sm' : '', className].filter(Boolean).join(' ');
  return <button className={cls} aria-label={label} title={label} {...rest}>{children}</button>;
}
```

- [ ] **Step 15.6: Create `admin-web/src/ds/Input.tsx`:**

```tsx
import type { InputHTMLAttributes, ReactNode } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  prefix?: ReactNode;
}

export function Input({ prefix, className = '', ...rest }: InputProps) {
  const inputCls = ['zz-input', prefix ? 'zz-input--with-prefix' : '', className].filter(Boolean).join(' ');
  return (
    <span className="zz-input-wrap">
      {prefix}
      <input className={inputCls} {...rest} />
    </span>
  );
}
```

- [ ] **Step 15.7: Build sanity.** Run: `cd admin-web && npm run build`. Expected: success.

- [ ] **Step 15.8: Commit.**

```bash
git add admin-web/src/ds admin-web/src/styles/global.css
git commit -m "feat(admin-web): ds.css + Card/Button/IconButton/Input primitives"
```

---

### Task 16: Tag, StatusBadge, Avatar, ProgressMeter, SegmentedControl, icons (TDD on mappers)

**Files (create):** `admin-web/src/ds/Tag.tsx`, `StatusBadge.tsx`, `Avatar.tsx`, `ProgressMeter.tsx`, `SegmentedControl.tsx`, `icons.tsx`, `index.ts`. Test: `admin-web/src/ds/StatusBadge.test.tsx`, `admin-web/src/ds/Avatar.test.tsx`.

- [ ] **Step 16.1: Write failing tests.**

`admin-web/src/ds/Avatar.test.tsx`:
```tsx
import { describe, it, expect } from 'vitest';
import { initialsOf, hueIndexOf } from './Avatar';

describe('Avatar helpers', () => {
  it('builds up-to-2 uppercase initials from a name', () => {
    expect(initialsOf('Nguyễn Thị Hương')).toBe('TH');
    expect(initialsOf('Lan')).toBe('L');
    expect(initialsOf('')).toBe('?');
  });
  it('derives a deterministic hue bucket', () => {
    expect(hueIndexOf('Lan')).toBe(hueIndexOf('Lan'));
    expect(hueIndexOf('Lan')).toBeGreaterThanOrEqual(0);
    expect(hueIndexOf('Lan')).toBeLessThan(5);
  });
});
```

`admin-web/src/ds/StatusBadge.test.tsx`:
```tsx
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { StatusBadge, statusFromUserStatus } from './StatusBadge';

describe('statusFromUserStatus', () => {
  it('maps account status to a design status + label', () => {
    expect(statusFromUserStatus('active')).toEqual({ status: 'approved', label: 'Active' });
    expect(statusFromUserStatus('review')).toEqual({ status: 'pending', label: 'Đang xem xét' });
    expect(statusFromUserStatus('suspended')).toEqual({ status: 'suspended', label: 'Tạm khóa' });
  });
});

describe('StatusBadge', () => {
  it('renders the label and applies the status class', () => {
    const { getByText } = render(<StatusBadge status="public" pulse>Đang chạy</StatusBadge>);
    const el = getByText('Đang chạy').closest('.zz-badge')!;
    expect(el).toBeTruthy();
    expect(el.className).toContain('zz-badge--pulse');
  });
});
```

- [ ] **Step 16.2: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL — modules not found.

- [ ] **Step 16.3: Create `admin-web/src/ds/Tag.tsx`:**

```tsx
import type { ReactNode } from 'react';

export type TagTone = 'neutral' | 'accent' | 'outline';

export function Tag({ tone = 'neutral', children }: { tone?: TagTone; children: ReactNode }) {
  return <span className={`zz-tag zz-tag--${tone}`}>{children}</span>;
}
```

- [ ] **Step 16.4: Create `admin-web/src/ds/StatusBadge.tsx`:**

```tsx
import type { ReactNode } from 'react';
import type { UserStatus } from '../lib/types';

export type DesignStatus =
  | 'draft' | 'pending' | 'progress' | 'review'
  | 'approved' | 'public' | 'suspended' | 'rejected';

const SOLID: Record<DesignStatus, string> = {
  draft: 'var(--status-draft-solid)',
  pending: 'var(--status-pending-solid)',
  progress: 'var(--status-progress-solid)',
  review: 'var(--status-review-solid)',
  approved: 'var(--status-approved-solid)',
  public: 'var(--status-public-solid)',
  suspended: 'var(--status-suspended-solid)',
  rejected: 'var(--status-rejected-solid)',
};

export function StatusBadge({
  status, pulse = false, children,
}: { status: DesignStatus; pulse?: boolean; children: ReactNode }) {
  const cls = ['zz-badge', pulse ? 'zz-badge--pulse' : ''].filter(Boolean).join(' ');
  return (
    <span
      className={cls}
      style={{
        background: `var(--status-${status}-bg)`,
        color: `var(--status-${status}-fg)`,
        borderColor: `var(--status-${status}-border)`,
      }}
    >
      <span className="zz-badge__dot" style={{ background: SOLID[status] }} />
      {children}
    </span>
  );
}

export function statusFromUserStatus(s: UserStatus): { status: DesignStatus; label: string } {
  switch (s) {
    case 'review': return { status: 'pending', label: 'Đang xem xét' };
    case 'suspended': return { status: 'suspended', label: 'Tạm khóa' };
    case 'active':
    default: return { status: 'approved', label: 'Active' };
  }
}
```

- [ ] **Step 16.5: Create `admin-web/src/ds/Avatar.tsx`:**

```tsx
const HUES = [
  { bg: 'var(--blue-100)', fg: 'var(--blue-700)' },
  { bg: 'var(--teal-100)', fg: 'var(--teal-700)' },
  { bg: 'var(--violet-100)', fg: 'var(--violet-700)' },
  { bg: 'var(--amber-100)', fg: 'var(--amber-700)' },
  { bg: 'var(--green-100)', fg: 'var(--green-700)' },
];

export function initialsOf(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0][0]!.toUpperCase();
  return (parts[parts.length - 2][0]! + parts[parts.length - 1][0]!).toUpperCase();
}

export function hueIndexOf(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 100000;
  return h % HUES.length;
}

export function Avatar({ name, size = 36 }: { name: string; size?: number }) {
  const hue = HUES[hueIndexOf(name)];
  return (
    <span
      style={{
        width: size, height: size, flex: 'none', borderRadius: '50%',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        font: `var(--fw-semibold) ${Math.round(size * 0.36)}px/1 var(--font-sans)`,
        background: hue.bg, color: hue.fg,
        border: `1px solid color-mix(in srgb, ${hue.fg} 14%, transparent)`,
      }}
    >
      {initialsOf(name)}
    </span>
  );
}
```

- [ ] **Step 16.6: Create `admin-web/src/ds/ProgressMeter.tsx`:**

```tsx
import { formatPercent, formatInt } from '../lib/format';

interface ProgressMeterProps {
  label: string;
  value: number;
  max?: number;
  unit?: string;
  threshold?: number;
}

export function ProgressMeter({ label, value, max = 100, unit, threshold }: ProgressMeterProps) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  const valueText = unit === '%' ? formatPercent(value) : max !== 100 ? `${formatInt(value)} / ${formatInt(max)}` : formatPercent(value);
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
        <span style={{ font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}>{label}</span>
        <span style={{ font: 'var(--fw-semibold) 13px/1 var(--font-mono)', color: 'var(--text-strong)' }}>{valueText}</span>
      </div>
      <div style={{ position: 'relative', height: 8, borderRadius: 'var(--radius-pill)', background: 'var(--surface-sunken)', overflow: 'hidden' }}>
        <div style={{ width: `${pct}%`, height: '100%', borderRadius: 'var(--radius-pill)', background: 'var(--brand)' }} />
        {threshold != null && (
          <div style={{ position: 'absolute', top: -2, bottom: -2, left: `${Math.min(100, (threshold / max) * 100)}%`, width: 2, background: 'var(--border-strong)' }} />
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 16.7: Create `admin-web/src/ds/SegmentedControl.tsx`:**

```tsx
interface SegOption<T extends string> { value: T; label: string; }

interface SegmentedControlProps<T extends string> {
  variant?: 'lite' | 'dark';
  value: T;
  options: SegOption<T>[];
  onChange: (value: T) => void;
}

export function SegmentedControl<T extends string>({
  variant = 'lite', value, options, onChange,
}: SegmentedControlProps<T>) {
  return (
    <div className={`zz-seg zz-seg--${variant}`}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          className={`zz-seg__opt${o.value === value ? ' zz-seg__opt--on' : ''}`}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
```

- [ ] **Step 16.8: Create `admin-web/src/ds/icons.tsx`** — a small Lucide icon map. Copy the **exact** `<path>`/`<svg>` inner markup from the design file for each key (cited line numbers), wrapped by a shared `<Icon>`:

```tsx
import type { ReactNode } from 'react';

export function Icon({ children, size = 18 }: { children: ReactNode; size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
      strokeWidth={1.75} strokeLinecap="round" strokeLinejoin="round">
      {children}
    </svg>
  );
}

// Each entry's inner paths are copied verbatim from ZenZoo Admin.dc.html.
// search:  overview L72 · users L76 · moderation L81 · billing L88 · ops L92 ·
// analytics L98 · audit L102 · tasks L108 · shop L112 · pets L116 ·
// achievements L120 · ai L124 · notifications L131 · rbac L137 · adminteam L141 ·
// flags L145 · gdpr L149 · bulk L153 · support L157.
// Topbar: bell L182, gear L183, search prefix (magnifier). Buttons: download L204, filter L352, plus L354, dots L396.
export const icons = {
  search: (<><circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" /></>),
  overview: (<><rect width="7" height="9" x="3" y="3" rx="1" /><rect width="7" height="5" x="14" y="3" rx="1" /><rect width="7" height="9" x="14" y="12" rx="1" /><rect width="7" height="5" x="3" y="16" rx="1" /></>),
  users: (<><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M22 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></>),
  download: (<><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" x2="12" y1="15" y2="3" /></>),
  filter: (<><line x1="21" x2="14" y1="4" y2="4" /><line x1="10" x2="3" y1="4" y2="4" /><line x1="21" x2="12" y1="12" y2="12" /><line x1="8" x2="3" y1="12" y2="12" /><line x1="21" x2="16" y1="20" y2="20" /><line x1="12" x2="3" y1="20" y2="20" /><line x1="14" x2="14" y1="2" y2="6" /><line x1="8" x2="8" y1="10" y2="14" /><line x1="16" x2="16" y1="18" y2="22" /></>),
  plus: (<><path d="M5 12h14" /><path d="M12 5v14" /></>),
  dots: (<><circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" /></>),
  bell: (<><path d="M10.268 21a2 2 0 0 0 3.464 0" /><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326" /></>),
  gear: (<><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" /><circle cx="12" cy="12" r="3" /></>),
} as const;

// Sidebar nav icons (moderation, billing, ops, analytics, audit, tasks, shop, pets,
// achievements, ai, notifications, rbac, adminteam, flags, gdpr, bulk, support):
// copy each verbatim from the cited line into navIcons below.
export const navIcons: Record<string, ReactNode> = {
  overview: icons.overview,
  users: icons.users,
  // moderation: (<>…copy L81 paths…</>),
  // billing: (<>…copy L88…</>), ops: (<>…L92…</>), analytics: (<>…L98…</>),
  // audit: (<>…L102…</>), tasks: (<>…L108…</>), shop: (<>…L112…</>), pets: (<>…L116…</>),
  // achievements: (<>…L120…</>), ai: (<>…L124…</>), notifications: (<>…L131…</>),
  // rbac: (<>…L137…</>), adminteam: (<>…L141…</>), flags: (<>…L145…</>),
  // gdpr: (<>…L149…</>), bulk: (<>…L153…</>), support: (<>…L157…</>),
};
```

> The two commented blocks (`navIcons` extras) are the only verbatim-copy chore in the plan: open the cited lines in `ZenZoo Admin.dc.html` and paste each `<svg>`'s inner elements. They are pure static SVG path data — no logic. Task 18 only *requires* `overview`/`users` to be filled to be testable; fill the rest for visual fidelity.

- [ ] **Step 16.9: Create `admin-web/src/ds/index.ts`:**

```ts
export { Card } from './Card';
export { Button } from './Button';
export { IconButton } from './IconButton';
export { Input } from './Input';
export { Tag } from './Tag';
export type { TagTone } from './Tag';
export { StatusBadge, statusFromUserStatus } from './StatusBadge';
export type { DesignStatus } from './StatusBadge';
export { Avatar, initialsOf, hueIndexOf } from './Avatar';
export { ProgressMeter } from './ProgressMeter';
export { SegmentedControl } from './SegmentedControl';
export { Icon, icons, navIcons } from './icons';
```

- [ ] **Step 16.10: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS (Avatar + StatusBadge + earlier suites).

- [ ] **Step 16.11: Commit.**

```bash
git add admin-web/src/ds
git commit -m "feat(admin-web): Tag/StatusBadge/Avatar/ProgressMeter/Segmented + icons"
```

---

## Phase 4 — Shell, theme & routing

### Task 17: Theme system (TDD on the variable map)

**Files:** Create `admin-web/src/shell/theme.ts`, `admin-web/src/shell/ThemeProvider.tsx`. Test: `admin-web/src/shell/theme.test.ts`.

- [ ] **Step 17.1: Write the failing test** `admin-web/src/shell/theme.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { themeVars } from './theme';

describe('themeVars', () => {
  it('theme A = dark rail + flush hairline KPI grid', () => {
    const a = themeVars('a');
    expect(a['--rail-bg']).toBe('var(--slate-900)');
    expect(a['--kpi-gap']).toBe('1px');
    expect(a['--kpi-cell-border']).toBe('none');
  });
  it('theme B = light rail + separated KPI cards', () => {
    const b = themeVars('b');
    expect(b['--rail-bg']).toBe('var(--slate-0)');
    expect(b['--kpi-gap']).toBe('14px');
    expect(b['--kpi-cell-shadow']).toBe('var(--shadow-sm)');
  });
  it('density controls row padding', () => {
    expect(themeVars('a', 'comfortable')['--row-py']).toBe('13px');
    expect(themeVars('a', 'compact')['--row-py']).toBe('8px');
  });
});
```

- [ ] **Step 17.2: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL.

- [ ] **Step 17.3: Implement `admin-web/src/shell/theme.ts`** (values copied verbatim from `ZenZoo Admin.dc.html` lines 1298–1321):

```ts
export type ThemeVariant = 'a' | 'b';
export type Density = 'comfortable' | 'compact';

const railA: Record<string, string> = {
  '--rail-bg': 'var(--slate-900)', '--rail-edge': 'var(--slate-900)',
  '--rail-fg': '#9AA8BE', '--rail-fg-strong': '#FFFFFF', '--rail-muted': '#6C7B93',
  '--rail-border': 'rgba(255,255,255,0.08)', '--rail-hover': 'rgba(255,255,255,0.06)',
  '--rail-active-bg': 'rgba(94,132,240,0.18)', '--rail-active-fg': '#FFFFFF', '--rail-active-bar': '#8FAEF8',
  '--rail-group': '#6C7B93', '--rail-plate-bg': 'rgba(255,255,255,0.04)',
  '--rail-plate-border': 'rgba(255,255,255,0.10)', '--rail-foot': '#6C7B93',
  '--kpi-gap': '1px', '--kpi-wrap-bg': 'var(--border-subtle)',
  '--kpi-wrap-border': '1px solid var(--border-subtle)', '--kpi-wrap-radius': 'var(--radius-lg)',
  '--kpi-wrap-overflow': 'hidden', '--kpi-cell-bg': 'var(--surface-card)',
  '--kpi-cell-border': 'none', '--kpi-cell-radius': '0px', '--kpi-cell-shadow': 'none',
};

const railB: Record<string, string> = {
  '--rail-bg': 'var(--slate-0)', '--rail-edge': 'var(--border-subtle)',
  '--rail-fg': 'var(--slate-600)', '--rail-fg-strong': 'var(--slate-900)', '--rail-muted': 'var(--text-muted)',
  '--rail-border': 'var(--border-subtle)', '--rail-hover': 'var(--surface-hover)',
  '--rail-active-bg': 'var(--surface-brand-soft)', '--rail-active-fg': 'var(--blue-700)', '--rail-active-bar': 'var(--brand)',
  '--rail-group': 'var(--text-faint)', '--rail-plate-bg': 'var(--slate-50)',
  '--rail-plate-border': 'var(--border-subtle)', '--rail-foot': 'var(--text-faint)',
  '--kpi-gap': '14px', '--kpi-wrap-bg': 'transparent',
  '--kpi-wrap-border': '0px solid transparent', '--kpi-wrap-radius': '0px',
  '--kpi-wrap-overflow': 'visible', '--kpi-cell-bg': 'var(--surface-card)',
  '--kpi-cell-border': '1px solid var(--border-subtle)', '--kpi-cell-radius': 'var(--radius-lg)', '--kpi-cell-shadow': 'var(--shadow-sm)',
};

export function themeVars(variant: ThemeVariant, density: Density = 'comfortable'): Record<string, string> {
  return {
    ...(variant === 'a' ? railA : railB),
    '--row-py': density === 'compact' ? '8px' : '13px',
  };
}
```

- [ ] **Step 17.4: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS.

- [ ] **Step 17.5: Implement `admin-web/src/shell/ThemeProvider.tsx`:**

```tsx
import { createContext, useContext, useState } from 'react';
import type { CSSProperties, ReactNode } from 'react';
import { themeVars } from './theme';
import type { ThemeVariant } from './theme';
import { getTheme, setTheme as persistTheme } from '../lib/auth';

interface ThemeCtx { variant: ThemeVariant; setVariant: (v: ThemeVariant) => void; }
const Ctx = createContext<ThemeCtx>({ variant: 'a', setVariant: () => {} });
export const useTheme = () => useContext(Ctx);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [variant, setVariantState] = useState<ThemeVariant>(getTheme());
  const setVariant = (v: ThemeVariant) => { persistTheme(v); setVariantState(v); };
  const style: CSSProperties = {
    ...(themeVars(variant) as CSSProperties),
    background: 'var(--surface-page)',
    color: 'var(--text-body)',
    minHeight: '100vh',
    fontFamily: 'var(--font-sans)',
  };
  return <Ctx.Provider value={{ variant, setVariant }}><div style={style}>{children}</div></Ctx.Provider>;
}
```

- [ ] **Step 17.6: Commit.**

```bash
git add admin-web/src/shell/theme.ts admin-web/src/shell/theme.test.ts admin-web/src/shell/ThemeProvider.tsx
git commit -m "feat(admin-web): A/B theme system (CSS-var sets + provider)"
```

---

### Task 18: Sidebar, Topbar, CompareBar, AppShell

**Files:** Create `admin-web/src/shell/nav.ts`, `Sidebar.tsx`, `Topbar.tsx`, `CompareBar.tsx`, `AppShell.tsx`. Also copy logo assets to `admin-web/public/`.

- [ ] **Step 18.1: Copy logo assets.** Copy `admin_report/project/assets/zenzoo-mark.png` and `zenzoo-logo.png` into `admin-web/public/`. They will be served at `/console/zenzoo-mark.png` (Vite `base`).

- [ ] **Step 18.2: Create `admin-web/src/shell/nav.ts`:**

```ts
export interface NavBadge { text: string; tone: 'amber' | 'muted' | 'teal-outline'; }
export interface NavItem { screen: string; label: string; to: string; enabled: boolean; badge?: NavBadge; }
export interface NavGroup { title: string; items: NavItem[]; }

const wip = (screen: string, label: string, badge?: NavBadge): NavItem =>
  ({ screen, label, to: `/wip/${screen}`, enabled: false, badge });

export const NAV_GROUPS: NavGroup[] = [
  { title: 'Lõi vận hành', items: [
    { screen: 'overview', label: 'Tổng quan', to: '/', enabled: true },
    { screen: 'users', label: 'Người dùng', to: '/users', enabled: true, badge: { text: '6.8k', tone: 'muted' } },
    wip('moderation', 'Kiểm duyệt', { text: '5', tone: 'amber' }),
  ]},
  { title: 'Dòng tiền', items: [
    wip('billing', 'Thanh toán & Gói'),
    wip('ops', 'Vận hành & IPN'),
  ]},
  { title: 'Phân tích', items: [
    wip('analytics', 'Phân tích'),
    wip('audit', 'Nhật ký kiểm toán'),
  ]},
  { title: 'Nội dung game', items: [
    wip('tasks', 'Nhiệm vụ & Mốc'),
    wip('shop', 'Cửa hàng & Kinh tế'),
    wip('pets', 'Thú cưng & Tiến hóa'),
    wip('achievements', 'Thành tựu & Streak'),
    wip('ai', 'AI Focus Designer', { text: 'Beta', tone: 'teal-outline' }),
  ]},
  { title: 'Tiếp cận', items: [
    wip('notifications', 'Thông báo & Chiến dịch'),
  ]},
  { title: 'Quản trị & bảo mật', items: [
    wip('rbac', 'Vai trò & Bảo mật'),
    wip('adminteam', 'Đội quản trị'),
    wip('flags', 'Cờ tính năng'),
    wip('gdpr', 'Quyền riêng tư & Xuất DL'),
    wip('bulk', 'Tác vụ hàng loạt'),
    wip('support', 'Hỗ trợ', { text: '12', tone: 'muted' }),
  ]},
];

export interface RouteMeta { crumb: string; title: string; }
export const ROUTE_META: Record<string, RouteMeta> = {
  '/': { crumb: 'Lõi vận hành', title: 'Tổng quan' },
  '/users': { crumb: 'Lõi vận hành', title: 'Người dùng' },
};
export function metaFor(pathname: string): RouteMeta {
  if (pathname.startsWith('/users')) return ROUTE_META['/users'];
  return ROUTE_META['/'];
}
```

- [ ] **Step 18.3: Create `admin-web/src/shell/Sidebar.tsx`:**

```tsx
import { Link, useLocation } from 'react-router-dom';
import { NAV_GROUPS } from './nav';
import type { NavBadge, NavItem } from './nav';
import { Icon, navIcons } from '../ds';

function Badge({ badge }: { badge: NavBadge }) {
  if (badge.tone === 'teal-outline') {
    return <span style={{ marginLeft: 'auto', font: 'var(--fw-semibold) 9px/1 var(--font-sans)', letterSpacing: '.04em', textTransform: 'uppercase', padding: '2px 6px', borderRadius: 999, color: 'var(--teal-500)', border: '1px solid var(--teal-500)' }}>{badge.text}</span>;
  }
  const bg = badge.tone === 'amber' ? 'var(--amber-500)' : 'var(--rail-hover, rgba(255,255,255,.08))';
  const fg = badge.tone === 'amber' ? '#fff' : 'var(--rail-muted, #6C7B93)';
  return <span style={{ marginLeft: 'auto', font: 'var(--fw-semibold) 10px/1 var(--font-mono)', padding: '2px 7px', borderRadius: 999, background: bg, color: fg }}>{badge.text}</span>;
}

function NavRow({ item, active }: { item: NavItem; active: boolean }) {
  const base = {
    display: 'flex', alignItems: 'center', gap: 11, padding: '8px 11px', borderRadius: 7,
    color: 'var(--rail-fg)', font: 'var(--fw-medium) 13.5px/1 var(--font-sans)',
    position: 'relative' as const, cursor: 'pointer', whiteSpace: 'nowrap' as const,
    ...(active ? { background: 'var(--rail-active-bg)', color: 'var(--rail-active-fg)', fontWeight: 600, boxShadow: 'inset 2px 0 0 0 var(--rail-active-bar)' } : {}),
  };
  const inner = (
    <>
      <span style={{ display: 'inline-flex', flex: 'none' }}><Icon>{navIcons[item.screen] ?? navIcons.overview}</Icon></span>
      <span>{item.label}</span>
      {item.badge && <Badge badge={item.badge} />}
    </>
  );
  return <Link className="zz-nav" to={item.to} style={base}>{inner}</Link>;
}

export function Sidebar() {
  const { pathname } = useLocation();
  const isActive = (to: string) => (to === '/' ? pathname === '/' : pathname.startsWith(to));
  return (
    <aside className="zz-rail" style={{
      gridColumn: 1, background: 'var(--rail-bg, var(--slate-900))', borderRight: '1px solid var(--rail-edge, var(--slate-900))',
      position: 'sticky', top: 46, alignSelf: 'start', height: 'calc(100vh - 46px)', overflowY: 'auto', display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '18px 16px 14px', borderBottom: '1px solid var(--rail-border, rgba(255,255,255,.08))' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '10px 13px', borderRadius: 11, background: 'var(--rail-plate-bg, rgba(255,255,255,.04))', border: '1px solid var(--rail-plate-border, rgba(255,255,255,.10))' }}>
          <img src={`${import.meta.env.BASE_URL}zenzoo-mark.png`} alt="ZenZoo" style={{ width: 34, height: 34, objectFit: 'contain', flex: 'none' }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 3, lineHeight: 1 }}>
            <span style={{ font: 'var(--fw-extra) 19px/1 var(--font-sans)', letterSpacing: '-.01em' }}><span style={{ color: '#3FB2A6' }}>Zen</span><span style={{ color: '#1E6CA1' }}>Zoo</span></span>
            <span style={{ font: 'var(--fw-semibold) 9px/1 var(--font-sans)', letterSpacing: '.2em', textTransform: 'uppercase', color: 'var(--rail-group, #6C7B93)' }}>Admin Console</span>
          </div>
        </div>
      </div>
      <nav style={{ padding: '12px 10px 24px', flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
        {NAV_GROUPS.map((g) => (
          <div key={g.title}>
            <div style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.13em', textTransform: 'uppercase', color: 'var(--rail-group, #6C7B93)', padding: '14px 12px 6px' }}>{g.title}</div>
            {g.items.map((it) => <NavRow key={it.screen} item={it} active={isActive(it.to)} />)}
          </div>
        ))}
      </nav>
      <div style={{ padding: '13px 18px', borderTop: '1px solid var(--rail-border, rgba(255,255,255,.08))', font: 'var(--fw-regular) 11px/1.4 var(--font-sans)', color: 'var(--rail-foot, #6C7B93)' }}>
        Phiên bản 2.4.0 · môi trường <span style={{ fontFamily: 'var(--font-mono)' }}>production</span>
      </div>
    </aside>
  );
}
```

- [ ] **Step 18.4: Create `admin-web/src/shell/Topbar.tsx`:**

```tsx
import { useLocation } from 'react-router-dom';
import { Icon, icons, IconButton, Input } from '../ds';
import { metaFor } from './nav';
import { getAdmin, initialsFromAdmin } from './topbarUtil';

export function Topbar() {
  const { pathname } = useLocation();
  const meta = metaFor(pathname);
  const admin = getAdmin();
  return (
    <header style={{
      position: 'sticky', top: 46, zIndex: 120, background: 'color-mix(in srgb, var(--slate-0) 88%, transparent)',
      backdropFilter: 'blur(10px)', borderBottom: '1px solid var(--border-subtle)', padding: '13px 32px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 24,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.13em', textTransform: 'uppercase', color: 'var(--text-faint)' }}>{meta.crumb}</div>
        <h1 style={{ font: 'var(--fw-bold) 24px/1.1 var(--font-sans)', letterSpacing: '-.02em', color: 'var(--text-strong)', margin: '6px 0 0' }}>{meta.title}</h1>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 'none' }}>
        <div style={{ width: 280 }}>
          <Input placeholder="Tìm nhanh người dùng, giao dịch…" prefix={<Icon size={16}>{icons.search}</Icon>} />
        </div>
        <IconButton label="Thông báo"><Icon>{icons.bell}</Icon></IconButton>
        <IconButton label="Cài đặt"><Icon>{icons.gear}</Icon></IconButton>
        <div style={{ width: 1, height: 30, background: 'var(--border-subtle)' }} />
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>
          <span style={{ width: 36, height: 36, flex: 'none', borderRadius: '50%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', font: 'var(--fw-semibold) 13px/1 var(--font-sans)', background: 'var(--blue-100)', color: 'var(--blue-700)', border: '1px solid color-mix(in srgb, var(--blue-700) 14%, transparent)' }}>{initialsFromAdmin(admin?.name)}</span>
          <span style={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0 }}>
            <span style={{ font: 'var(--fw-semibold) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{admin?.name ?? 'Quản trị viên'}</span>
            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)' }}>{admin?.role ?? '—'}</span>
          </span>
        </span>
      </div>
    </header>
  );
}
```

- [ ] **Step 18.5: Create `admin-web/src/shell/topbarUtil.ts`** (re-export + initials helper):

```ts
export { getAdmin } from '../lib/auth';

export function initialsFromAdmin(name?: string): string {
  if (!name) return 'AD';
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[parts.length - 2][0] + parts[parts.length - 1][0]).toUpperCase();
}
```

- [ ] **Step 18.6: Create `admin-web/src/shell/CompareBar.tsx`:**

```tsx
import { SegmentedControl } from '../ds';
import { useTheme } from './ThemeProvider';

export function CompareBar() {
  const { variant, setVariant } = useTheme();
  return (
    <div style={{
      position: 'sticky', top: 0, zIndex: 300, height: 46, background: 'var(--slate-950)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 18px 0 20px', gap: 16,
      borderBottom: '1px solid rgba(255,255,255,.08)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
        <img src={`${import.meta.env.BASE_URL}zenzoo-mark.png`} alt="ZenZoo" style={{ width: 22, height: 22, objectFit: 'contain', flex: 'none' }} />
        <span style={{ font: 'var(--fw-bold) 12px/1 var(--font-sans)', letterSpacing: '.14em', textTransform: 'uppercase', color: '#fff' }}>ZenZoo Admin</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 'none' }}>
        <span style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.14em', textTransform: 'uppercase', color: 'var(--slate-400)' }}>So sánh</span>
        <SegmentedControl
          variant="dark"
          value={variant}
          onChange={(v) => setVariant(v)}
          options={[{ value: 'a', label: 'A · Console' }, { value: 'b', label: 'B · Workspace' }]}
        />
      </div>
    </div>
  );
}
```

- [ ] **Step 18.7: Create `admin-web/src/shell/AppShell.tsx`:**

```tsx
import { Outlet } from 'react-router-dom';
import { CompareBar } from './CompareBar';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';

export function AppShell() {
  return (
    <>
      <CompareBar />
      <div style={{ display: 'grid', gridTemplateColumns: '264px minmax(0,1fr)', minHeight: 'calc(100vh - 46px)', background: 'var(--surface-page)' }}>
        <Sidebar />
        <div style={{ gridColumn: 2, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <Topbar />
          <Outlet />
        </div>
      </div>
    </>
  );
}
```

- [ ] **Step 18.8: Build sanity.** Run: `cd admin-web && npm run build`. Expected: success (TS may warn about unused until pages exist — fine; `npm run build` does not type-check). If `import.meta.env.BASE_URL` errors in test types, it is only used in components not unit-tested.

- [ ] **Step 18.9: Commit.**

```bash
git add admin-web/src/shell admin-web/public
git commit -m "feat(admin-web): app shell (sidebar, topbar, compare bar, theme wrap)"
```

---

### Task 19: Router, ProtectedRoute, LoginPage, WIP placeholder

**Files:** Replace `admin-web/src/main.tsx`, `admin-web/src/App.tsx`. Create `admin-web/src/shell/ProtectedRoute.tsx`, `admin-web/src/pages/LoginPage.tsx`, `admin-web/src/pages/WipPage.tsx`.

- [ ] **Step 19.1: Replace `admin-web/src/main.tsx`:**

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import './styles/global.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter basename="/console">
      <App />
    </BrowserRouter>
  </React.StrictMode>,
);
```

- [ ] **Step 19.2: Create `admin-web/src/shell/ProtectedRoute.tsx`:**

```tsx
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { isAuthed } from '../lib/auth';

export function ProtectedRoute() {
  const loc = useLocation();
  if (!isAuthed()) return <Navigate to="/login" replace state={{ from: loc.pathname }} />;
  return <Outlet />;
}
```

- [ ] **Step 19.3: Create `admin-web/src/pages/WipPage.tsx`:**

```tsx
import { useParams } from 'react-router-dom';

export function WipPage() {
  const { screen } = useParams();
  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ padding: 40, textAlign: 'center', background: 'var(--surface-card)', border: '1px dashed var(--border-default)', borderRadius: 'var(--radius-lg)', color: 'var(--text-muted)', font: 'var(--fw-medium) 14px/1.5 var(--font-sans)' }}>
        Màn <b style={{ color: 'var(--text-strong)', fontFamily: 'var(--font-mono)' }}>{screen}</b> đang được xây dựng.
      </div>
    </section>
  );
}
```

- [ ] **Step 19.4: Create `admin-web/src/pages/LoginPage.tsx`:**

```tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input } from '../ds';
import { api } from '../lib/api';
import { setToken, setAdmin } from '../lib/auth';
import { friendlyError } from '../lib/friendlyError';

export function LoginPage() {
  const nav = useNavigate();
  const [email, setEmail] = useState('admin@zenzoo.app');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setBusy(true);
    try {
      const res = await api.login(email.trim(), password);
      setToken(res.token);
      setAdmin(res.admin);
      nav('/', { replace: true });
    } catch (ex) {
      setErr(friendlyError(ex));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--surface-page)' }}>
      <form onSubmit={submit} style={{ width: 360, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-xl)', boxShadow: 'var(--shadow-lg)', padding: 28 }}>
        <div style={{ font: 'var(--fw-extra) 22px/1 var(--font-sans)', marginBottom: 4 }}>
          <span style={{ color: '#3FB2A6' }}>Zen</span><span style={{ color: '#1E6CA1' }}>Zoo</span>
          <span style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.2em', textTransform: 'uppercase', color: 'var(--text-faint)', marginLeft: 8 }}>Admin Console</span>
        </div>
        <p style={{ font: 'var(--fw-regular) 13px/1.5 var(--font-sans)', color: 'var(--text-muted)', margin: '0 0 18px' }}>Đăng nhập để vào bảng điều khiển.</p>
        <label style={{ display: 'block', font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)', marginBottom: 6 }}>Email</label>
        <div style={{ marginBottom: 14 }}><Input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@zenzoo.app" autoFocus /></div>
        <label style={{ display: 'block', font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)', marginBottom: 6 }}>Mật khẩu</label>
        <div style={{ marginBottom: 18 }}><Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" /></div>
        {err && <div role="alert" style={{ font: 'var(--fw-medium) 12px/1.4 var(--font-sans)', color: 'var(--danger-fg)', background: 'var(--danger-bg)', border: '1px solid var(--status-rejected-border)', borderRadius: 'var(--radius-md)', padding: '8px 10px', marginBottom: 14 }}>{err}</div>}
        <Button type="submit" disabled={busy} style={{ width: '100%', justifyContent: 'center' }}>{busy ? 'Đang đăng nhập…' : 'Đăng nhập'}</Button>
      </form>
    </div>
  );
}
```

- [ ] **Step 19.5: Replace `admin-web/src/App.tsx`:**

```tsx
import { Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './shell/ThemeProvider';
import { ProtectedRoute } from './shell/ProtectedRoute';
import { AppShell } from './shell/AppShell';
import { LoginPage } from './pages/LoginPage';
import { WipPage } from './pages/WipPage';
import { OverviewPage } from './pages/OverviewPage';
import { UsersPage } from './pages/UsersPage';
import { UserDetailPage } from './pages/UserDetailPage';

export default function App() {
  return (
    <ThemeProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<AppShell />}>
            <Route path="/" element={<OverviewPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/users/:id" element={<UserDetailPage />} />
            <Route path="/wip/:screen" element={<WipPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </ThemeProvider>
  );
}
```

> `App.tsx` imports `OverviewPage`, `UsersPage`, `UserDetailPage` (Tasks 21–23). Until those exist the build will fail — implement Task 20–23 before building. If you want an intermediate green build, temporarily stub them; otherwise proceed straight to Phase 5.

- [ ] **Step 19.6: Commit.**

```bash
git add admin-web/src/main.tsx admin-web/src/App.tsx admin-web/src/shell/ProtectedRoute.tsx admin-web/src/pages/LoginPage.tsx admin-web/src/pages/WipPage.tsx
git commit -m "feat(admin-web): router, protected routes, login page"
```

---

## Phase 5 — Pages

### Task 20: Shared page components (Sparkline, ErrorState, LoadingSkeleton, KpiCard)

**Files (create):** `admin-web/src/components/Sparkline.tsx`, `ErrorState.tsx`, `LoadingSkeleton.tsx`, `KpiCard.tsx`.

- [ ] **Step 20.1: Create `admin-web/src/components/Sparkline.tsx`:**

```tsx
export function Sparkline({ data, color = 'var(--blue-500)' }: { data: number[]; color?: string }) {
  const W = 120, H = 34, P = 3;
  if (!data || data.length < 2) {
    // flat baseline for point-in-time KPIs with no series
    return (
      <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height: 34, marginTop: 'auto', color, display: 'block' }}>
        <line x1={P} y1={H - P} x2={W - P} y2={H - P} stroke="currentColor" strokeWidth={1.75} opacity={0.25} vectorEffect="non-scaling-stroke" />
      </svg>
    );
  }
  const max = Math.max(...data), min = Math.min(...data);
  const span = max - min || 1;
  const n = data.length;
  const x = (i: number) => P + (i * (W - 2 * P)) / (n - 1);
  const y = (v: number) => (H - P) - ((v - min) / span) * (H - 2 * P);
  const line = data.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(' ');
  const area = `${x(0).toFixed(1)},${H - P} ${line} ${x(n - 1).toFixed(1)},${H - P}`;
  return (
    <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height: 34, marginTop: 'auto', color, display: 'block' }}>
      <polygon points={area} fill="currentColor" opacity={0.1} />
      <polyline points={line} fill="none" stroke="currentColor" strokeWidth={1.75} strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}
```

- [ ] **Step 20.2: Create `admin-web/src/components/ErrorState.tsx`:**

```tsx
import { Button } from '../ds';

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div style={{ padding: 32, textAlign: 'center', background: 'var(--surface-card)', border: '1px solid var(--status-rejected-border)', borderRadius: 'var(--radius-lg)' }}>
      <div style={{ font: 'var(--fw-semibold) 14px/1.4 var(--font-sans)', color: 'var(--danger-fg)', marginBottom: 4 }}>Không tải được dữ liệu</div>
      <div style={{ font: 'var(--fw-regular) 13px/1.5 var(--font-sans)', color: 'var(--text-muted)', marginBottom: onRetry ? 14 : 0 }}>{message}</div>
      {onRetry && <Button variant="secondary" size="sm" onClick={onRetry}>Thử lại</Button>}
    </div>
  );
}
```

- [ ] **Step 20.3: Create `admin-web/src/components/LoadingSkeleton.tsx`:**

```tsx
export function Skeleton({ height = 16, width = '100%', radius = 6 }: { height?: number; width?: number | string; radius?: number }) {
  return <span style={{ display: 'block', height, width, borderRadius: radius, background: 'linear-gradient(90deg, var(--slate-100), var(--slate-200), var(--slate-100))', backgroundSize: '200% 100%', animation: 'zzshimmer 1.2s ease-in-out infinite' }} />;
}

export function KpiGridSkeleton() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 14, marginBottom: 22 }}>
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} style={{ minHeight: 150, padding: 16, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)' }}>
          <Skeleton height={12} width="60%" />
          <div style={{ height: 12 }} />
          <Skeleton height={26} width="45%" />
        </div>
      ))}
    </div>
  );
}
```

- [ ] **Step 20.4: Add the shimmer keyframe** to the end of `admin-web/src/ds/ds.css`:

```css
@keyframes zzshimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
```

- [ ] **Step 20.5: Create `admin-web/src/components/KpiCard.tsx`:**

```tsx
import type { Kpi } from '../lib/types';
import { Sparkline } from './Sparkline';
import { formatPercent } from '../lib/format';

interface KpiCardProps {
  label: string;
  valueText: string;
  suffix?: string;
  kpi: Kpi;
  color?: string;
  /** override the delta line note for point-in-time KPIs */
  note?: string;
}

export function KpiCard({ label, valueText, suffix, kpi, color = 'var(--blue-500)', note }: KpiCardProps) {
  const d = kpi.deltaPct;
  const up = d != null && d >= 0;
  return (
    <div style={{
      background: 'var(--kpi-cell-bg, var(--surface-card))', border: 'var(--kpi-cell-border, none)',
      borderRadius: 'var(--kpi-cell-radius, 0px)', boxShadow: 'var(--kpi-cell-shadow, none)',
      padding: '15px 16px 13px', display: 'flex', flexDirection: 'column', minHeight: 150,
    }}>
      <span style={{ font: 'var(--fw-semibold) 11px/1.3 var(--font-sans)', letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--text-muted)' }}>{label}</span>
      <div style={{ font: 'var(--fw-extra) 30px/1 var(--font-sans)', letterSpacing: '-.02em', color: 'var(--text-strong)', marginTop: 13, fontVariantNumeric: 'tabular-nums' }}>
        {valueText}{suffix && <span style={{ fontSize: 16, color: 'var(--text-muted)', fontWeight: 600 }}>{suffix}</span>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-semibold) 12px/1 var(--font-sans)', marginTop: 8, color: d == null ? 'var(--text-faint)' : up ? 'var(--green-600)' : 'var(--red-600)' }}>
        {d == null ? (
          <span style={{ fontWeight: 400 }}>{note ?? '—'}</span>
        ) : (
          <>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              {up ? <><path d="M7 7h10v10" /><path d="M7 17 17 7" /></> : <><path d="M7 7l10 10" /><path d="M17 7v10H7" /></>}
            </svg>
            {formatPercent(Math.abs(d))}
            <span style={{ color: 'var(--text-faint)', fontWeight: 400, marginLeft: 2 }}>vs kỳ trước</span>
          </>
        )}
      </div>
      <Sparkline data={kpi.spark} color={color} />
    </div>
  );
}
```

- [ ] **Step 20.6: Build sanity.** Run: `cd admin-web && npm run build` will still fail on missing pages — instead just typecheck these in isolation later. Skip build here; commit.

- [ ] **Step 20.7: Commit.**

```bash
git add admin-web/src/components admin-web/src/ds/ds.css
git commit -m "feat(admin-web): Sparkline, ErrorState, Skeletons, KpiCard"
```

---

### Task 21: OverviewPage (+ render test)

**Files:** Create `admin-web/src/pages/OverviewPage.tsx`. Test: `admin-web/src/pages/OverviewPage.test.tsx`.

- [ ] **Step 21.1: Write the failing test** `admin-web/src/pages/OverviewPage.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { OverviewPage } from './OverviewPage';
import type { OverviewResponse, HealthResponse } from '../lib/types';

const overview: OverviewResponse = {
  range: 'today',
  kpis: {
    dau: { value: 1842, deltaPct: 6.3, spark: [1, 2, 3, 4] },
    stickiness: { value: 27, deltaPct: null, spark: [] },
    focusMinutes: { value: 41250, deltaPct: 4.8, spark: [1, 2, 3] },
    focusSessions: { value: 1310, deltaPct: -2.1, spark: [3, 2, 1] },
    premiumUsers: { value: 312, deltaPct: null, spark: [] },
    revenue: { value: 1247000, deltaPct: 9.4, spark: [1, 2] },
    avgStreak: { value: 4.2, deltaPct: null, spark: [] },
    conversion: { value: 4.6, deltaPct: null, spark: [] },
  },
  goals: [{ label: 'Doanh thu quý', value: 78, max: 100, unit: '%' }],
  recent: [{ eventType: 'focus_completed', title: 'hoàn thành phiên Deep Focus 45′', subtitle: 'đồng hành Eagle', actor: 'Trần Minh Anh', at: new Date().toISOString() }],
};
const health: HealthResponse = { db: 'ok', vnpay: true, gemini: true, apiLatencyMs: 142 };

vi.mock('../lib/api', () => ({
  api: {
    overview: vi.fn().mockResolvedValue(overview),
    health: vi.fn().mockResolvedValue(health),
  },
}));

function renderPage() {
  return render(<MemoryRouter><OverviewPage /></MemoryRouter>);
}

describe('OverviewPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders the 8 KPI labels and the DAU value once loaded', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Người dùng hoạt động / ngày')).toBeInTheDocument());
    expect(screen.getByText('1.842')).toBeInTheDocument();
    expect(screen.getByText('Doanh thu hôm nay')).toBeInTheDocument();
    expect(screen.getByText('Streak trung bình')).toBeInTheDocument();
  });

  it('shows the recent activity actor', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Trần Minh Anh')).toBeInTheDocument());
  });
});
```

- [ ] **Step 21.2: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL — cannot find `./OverviewPage`.

- [ ] **Step 21.3: Implement `admin-web/src/pages/OverviewPage.tsx`:**

```tsx
import { useEffect, useState } from 'react';
import { Card, Button, SegmentedControl, StatusBadge, ProgressMeter, Icon, icons } from '../ds';
import { KpiCard } from '../components/KpiCard';
import { KpiGridSkeleton } from '../components/LoadingSkeleton';
import { ErrorState } from '../components/ErrorState';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatVndShort, relativeTime } from '../lib/format';
import type { OverviewResponse, HealthResponse, RangeKey, RecentEvent } from '../lib/types';

const dec1 = (n: number) => new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(n);
const pct = (n: number) => new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(n) + '%';

const RANGE_OPTS: { value: RangeKey; label: string }[] = [
  { value: 'today', label: 'Hôm nay' }, { value: '7d', label: '7 ngày' },
  { value: '30d', label: '30 ngày' }, { value: 'quarter', label: 'Quý' },
];

const EVENT_ICON: Record<string, { key: keyof typeof icons; bg: string; fg: string }> = {
  focus_completed: { key: 'overview', bg: 'var(--blue-50)', fg: 'var(--blue-600)' },
  daily_task_claimed: { key: 'overview', bg: 'var(--blue-50)', fg: 'var(--blue-600)' },
  achievement_claimed: { key: 'bell', bg: 'var(--amber-50)', fg: 'var(--amber-600)' },
  shop_purchase: { key: 'gear', bg: 'var(--violet-50)', fg: 'var(--violet-600)' },
  shop_item_used: { key: 'gear', bg: 'var(--violet-50)', fg: 'var(--violet-600)' },
};
function eventStyle(t: string) { return EVENT_ICON[t] ?? { key: 'overview' as const, bg: 'var(--slate-100)', fg: 'var(--slate-600)' }; }

export function OverviewPage() {
  const [range, setRange] = useState<RangeKey>('today');
  const [data, setData] = useState<OverviewResponse | null>(null);
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  function load(r: RangeKey) {
    setLoading(true);
    setError(null);
    api.overview(r)
      .then(setData)
      .catch((e) => setError(friendlyError(e)))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(range); }, [range]);
  useEffect(() => { api.health().then(setHealth).catch(() => setHealth(null)); }, []);

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 20, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <SegmentedControl variant="lite" value={range} options={RANGE_OPTS} onChange={setRange} />
          <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>Cập nhật vừa xong</span>
        </div>
        <Button variant="secondary"><Icon size={16}>{icons.download}</Icon>Xuất báo cáo</Button>
      </div>

      {error ? (
        <ErrorState message={error} onRetry={() => load(range)} />
      ) : loading || !data ? (
        <KpiGridSkeleton />
      ) : (
        <>
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 'var(--kpi-gap, 1px)',
            background: 'var(--kpi-wrap-bg, var(--border-subtle))', border: 'var(--kpi-wrap-border, 1px solid var(--border-subtle))',
            borderRadius: 'var(--kpi-wrap-radius, var(--radius-lg))', overflow: 'var(--kpi-wrap-overflow, hidden)', marginBottom: 22,
          }}>
            <KpiCard label="Người dùng hoạt động / ngày" valueText={formatInt(data.kpis.dau.value)} kpi={data.kpis.dau} color="var(--blue-500)" note="trong kỳ" />
            <KpiCard label="Độ bám DAU/MAU" valueText={pct(data.kpis.stickiness.value)} kpi={data.kpis.stickiness} color="var(--teal-500)" note="dải lành mạnh ≥20%" />
            <KpiCard label="Tổng phút focus" valueText={formatInt(data.kpis.focusMinutes.value)} suffix="′" kpi={data.kpis.focusMinutes} color="var(--blue-500)" />
            <KpiCard label="Phiên focus hoàn thành" valueText={formatInt(data.kpis.focusSessions.value)} kpi={data.kpis.focusSessions} color="var(--blue-500)" />
            <KpiCard label="Người dùng Zen Pro" valueText={formatInt(data.kpis.premiumUsers.value)} kpi={data.kpis.premiumUsers} color="var(--teal-500)" note="tổng hiện tại" />
            <KpiCard label="Doanh thu hôm nay" valueText={formatVndShort(data.kpis.revenue.value)} kpi={data.kpis.revenue} color="var(--blue-500)" />
            <KpiCard label="Streak trung bình" valueText={dec1(data.kpis.avgStreak.value)} suffix=" ngày" kpi={data.kpis.avgStreak} color="var(--green-500)" note="trên toàn hệ thống" />
            <KpiCard label="Free → Zen Pro" valueText={pct(data.kpis.conversion.value)} kpi={data.kpis.conversion} color="var(--green-500)" note="tỉ lệ chuyển đổi" />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', gap: 20, alignItems: 'start' }}>
            <Card title="Hoạt động gần đây" subtitle="Toàn hệ thống · mới nhất trước" padding="none">
              <div style={{ padding: '4px 18px 8px' }}>
                {data.recent.length === 0 && <div style={{ padding: '16px 0', color: 'var(--text-muted)', font: 'var(--fw-regular) 13px/1.5 var(--font-sans)' }}>Chưa có hoạt động.</div>}
                {data.recent.map((e: RecentEvent, i) => {
                  const st = eventStyle(e.eventType);
                  return (
                    <div key={i} style={{ display: 'flex', gap: 13, padding: '12px 0', borderBottom: i < data.recent.length - 1 ? '1px solid var(--border-subtle)' : 'none' }}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 30, height: 30, borderRadius: 8, flex: 'none', background: st.bg, color: st.fg }}><Icon size={15}>{icons[st.key]}</Icon></span>
                      <div style={{ flex: 1, font: 'var(--fw-regular) 13px/1.45 var(--font-sans)', color: 'var(--text-body)' }}>
                        <b style={{ color: 'var(--text-strong)', fontWeight: 600 }}>{e.actor}</b> {e.title}{e.subtitle ? <> · {e.subtitle}</> : null}
                      </div>
                      <span style={{ font: 'var(--fw-medium) 11px/1.6 var(--font-mono)', color: 'var(--text-faint)', whiteSpace: 'nowrap' }}>{relativeTime(e.at)}</span>
                    </div>
                  );
                })}
              </div>
            </Card>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              <Card title="Tình trạng hệ thống" padding="md">
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  <StatusRow name="Express API"><StatusBadge status="public" pulse>Đang chạy</StatusBadge></StatusRow>
                  <StatusRow name="PostgreSQL">{health?.db === 'down' ? <StatusBadge status="rejected">Mất kết nối</StatusBadge> : <StatusBadge status="approved">Kết nối OK</StatusBadge>}</StatusRow>
                  <StatusRow name="VNPay IPN">{health?.vnpay ? <StatusBadge status="approved">Hoạt động</StatusBadge> : <StatusBadge status="draft">Chưa cấu hình</StatusBadge>}</StatusRow>
                  <StatusRow name="Gemini Flash" last>{health?.gemini ? <StatusBadge status="progress" pulse>Đang phục vụ</StatusBadge> : <StatusBadge status="draft">Tắt</StatusBadge>}</StatusRow>
                  <p style={{ font: 'var(--fw-regular) 12px/1.5 var(--font-sans)', color: 'var(--text-muted)', margin: '13px 0 0', borderTop: '1px solid var(--border-subtle)', paddingTop: 12 }}>
                    Độ trễ trung bình API <b style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-strong)' }}>{health ? `${health.apiLatencyMs} ms` : '—'}</b> · cập nhật mỗi lần tải.
                  </p>
                </div>
              </Card>

              <Card title="Mục tiêu quý" subtitle="Tiến độ so với chỉ tiêu" padding="md">
                <div style={{ display: 'flex', flexDirection: 'column', gap: 16, paddingTop: 2 }}>
                  {data.goals.map((g, i) => (
                    <ProgressMeter key={i} label={g.label} value={g.value} max={g.max} unit={g.unit} />
                  ))}
                </div>
              </Card>
            </div>
          </div>
        </>
      )}
    </section>
  );
}

function StatusRow({ name, last, children }: { name: string; last?: boolean; children: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '9px 0', borderBottom: last ? 'none' : '1px solid var(--border-subtle)', font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}>
      {name}
      {children}
    </div>
  );
}
```

- [ ] **Step 21.4: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS (OverviewPage + all earlier suites).

- [ ] **Step 21.5: Commit.**

```bash
git add admin-web/src/pages/OverviewPage.tsx admin-web/src/pages/OverviewPage.test.tsx
git commit -m "feat(admin-web): Overview page (KPIs, activity, health, goals)"
```

---

### Task 22: UsersPage (+ render test) with filters, table, pagination, CSV

**Files:** Create `admin-web/src/pages/UsersPage.tsx`, `admin-web/src/lib/csv.ts`. Test: `admin-web/src/pages/UsersPage.test.tsx`, `admin-web/src/lib/csv.test.ts`.

- [ ] **Step 22.1: Write the failing CSV test** `admin-web/src/lib/csv.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { toCsv } from './csv';

describe('toCsv', () => {
  it('builds a header + rows and quotes values containing commas/quotes', () => {
    const csv = toCsv(
      ['name', 'email'],
      [{ name: 'Lê, Lan', email: 'a@b.c' }, { name: 'Quote "x"', email: 'd@e.f' }],
      (r) => [r.name, r.email],
    );
    expect(csv).toBe('name,email\r\n"Lê, Lan",a@b.c\r\n"Quote ""x""",d@e.f');
  });
});
```

- [ ] **Step 22.2: Implement `admin-web/src/lib/csv.ts`:**

```ts
function escapeCell(v: unknown): string {
  const s = v == null ? '' : String(v);
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export function toCsv<T>(headers: string[], rows: T[], rowMapper: (row: T) => unknown[]): string {
  const lines = [headers.map(escapeCell).join(',')];
  for (const r of rows) lines.push(rowMapper(r).map(escapeCell).join(','));
  return lines.join('\r\n');
}

export function downloadCsv(filename: string, csv: string): void {
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
```

- [ ] **Step 22.3: Run; verify the CSV test passes** (`npm test`) before building the page.

- [ ] **Step 22.4: Write the failing page test** `admin-web/src/pages/UsersPage.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { UsersPage } from './UsersPage';
import type { UsersResponse } from '../lib/types';

const page1: UsersResponse = {
  total: 2, page: 1, pageSize: 25,
  items: [
    { id: 'u1', email: 'huong.nt@gmail.com', displayName: 'Nguyễn Thị Hương', provider: 'google', createdAt: '2026-03-12T00:00:00.000Z', plan: 'premium', status: 'active', level: 12, streak: 17, lastLoginAt: '2026-06-13T09:14:00.000Z' },
    { id: 'u2', email: 'nam.vh@fpt.edu.vn', displayName: 'Vũ Hoàng Nam', provider: 'password', createdAt: '2026-05-07T00:00:00.000Z', plan: 'free', status: 'suspended', level: 5, streak: 0, lastLoginAt: null },
  ],
};

const usersMock = vi.fn().mockResolvedValue(page1);
vi.mock('../lib/api', () => ({ api: { users: (...a: unknown[]) => usersMock(...a) } }));

function renderPage() {
  return render(<MemoryRouter><UsersPage /></MemoryRouter>);
}

describe('UsersPage', () => {
  beforeEach(() => { usersMock.mockClear(); usersMock.mockResolvedValue(page1); });

  it('renders user rows with status labels', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Nguyễn Thị Hương')).toBeInTheDocument());
    expect(screen.getByText('Active')).toBeInTheDocument();
    expect(screen.getByText('Tạm khóa')).toBeInTheDocument();
    expect(screen.getByText('huong.nt@gmail.com')).toBeInTheDocument();
  });

  it('passes the status filter to the API when a tab is clicked', async () => {
    renderPage();
    await waitFor(() => expect(usersMock).toHaveBeenCalled());
    fireEvent.click(screen.getByText('Tạm khóa', { selector: 'button' }));
    await waitFor(() => {
      const lastCall = usersMock.mock.calls.at(-1)![0] as { status?: string };
      expect(lastCall.status).toBe('suspended');
    });
  });

  it('has an export CSV button', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Xuất CSV')).toBeInTheDocument());
  });
});
```

- [ ] **Step 22.5: Run; verify fail.** Run: `cd admin-web && npm test`. Expected: FAIL — cannot find `./UsersPage`.

- [ ] **Step 22.6: Implement `admin-web/src/pages/UsersPage.tsx`:**

```tsx
import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Button, Input, Tag, Avatar, IconButton, StatusBadge, statusFromUserStatus, Icon, icons } from '../ds';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatDate, formatDateTimeUtc } from '../lib/format';
import { toCsv, downloadCsv } from '../lib/csv';
import type { UsersResponse, UserRow, UsersQuery } from '../lib/types';

type FilterKey = 'all' | 'active' | 'pro' | 'lock' | 'review';
const FILTERS: { key: FilterKey; label: string }[] = [
  { key: 'all', label: 'Tất cả' }, { key: 'active', label: 'Active' },
  { key: 'pro', label: 'Zen Pro' }, { key: 'lock', label: 'Tạm khóa' }, { key: 'review', label: 'Đang xem xét' },
];
function filterToQuery(f: FilterKey): Partial<UsersQuery> {
  switch (f) {
    case 'active': return { status: 'active' };
    case 'pro': return { plan: 'premium' };
    case 'lock': return { status: 'suspended' };
    case 'review': return { status: 'review' };
    default: return {};
  }
}

const TH: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '11px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)', whiteSpace: 'nowrap' };
const TD: React.CSSProperties = { padding: 'var(--row-py, 13px) 16px', borderBottom: '1px solid var(--border-subtle)' };
const MONO: React.CSSProperties = { ...TD, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-body)', whiteSpace: 'nowrap' };

export function UsersPage() {
  const nav = useNavigate();
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<FilterKey>('all');
  const [page, setPage] = useState(1);
  const pageSize = 25;
  const [data, setData] = useState<UsersResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    setError(null);
    api.users({ q: q.trim() || undefined, page, pageSize, ...filterToQuery(filter) })
      .then(setData)
      .catch((e) => setError(friendlyError(e)))
      .finally(() => setLoading(false));
  }

  // debounce search; reload on filter/page change
  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, filter, page]);

  const totalPages = data ? Math.max(1, Math.ceil(data.total / data.pageSize)) : 1;
  const pages = useMemo(() => pageList(page, totalPages), [page, totalPages]);

  function exportCsv() {
    const items = data?.items ?? [];
    const csv = toCsv(
      ['Tên', 'Email', 'Provider', 'Gói', 'Ngày tạo', 'Đăng nhập cuối', 'Streak', 'Lv Kiki', 'Trạng thái'],
      items,
      (u) => [u.displayName, u.email, u.provider, u.plan, formatDate(u.createdAt), formatDateTimeUtc(u.lastLoginAt), u.streak, u.level, u.status],
    );
    downloadCsv('zenzoo-users.csv', csv);
  }

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div style={{ flex: 1, minWidth: 240, maxWidth: 400 }}>
          <Input value={q} onChange={(e) => { setPage(1); setQ(e.target.value); }} placeholder="Tìm theo tên, email hoặc userId…" prefix={<Icon size={16}>{icons.search}</Icon>} />
        </div>
        <Button variant="secondary"><Icon size={16}>{icons.filter}</Icon>Bộ lọc</Button>
        <Button variant="secondary" onClick={exportCsv}><Icon size={16}>{icons.download}</Icon>Xuất CSV</Button>
        <Button variant="primary" title="Sẽ bổ sung ở giai đoạn sau"><Icon size={16}>{icons.plus}</Icon>Mời / Tạo</Button>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 14, flexWrap: 'wrap' }}>
        <div className="zz-seg zz-seg--lite">
          {FILTERS.map((f) => (
            <button key={f.key} type="button" className={`zz-seg__opt${filter === f.key ? ' zz-seg__opt--on' : ''}`} onClick={() => { setPage(1); setFilter(f.key); }}>{f.label}</button>
          ))}
        </div>
        <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>
          <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{data ? formatInt(data.total) : '—'}</b> người dùng
        </span>
      </div>

      {error ? (
        <ErrorState message={error} onRetry={load} />
      ) : (
        <Card padding="none">
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
              <thead>
                <tr>
                  <th style={TH}>Người dùng</th><th style={TH}>Provider</th><th style={TH}>Gói</th>
                  <th style={TH}>Ngày tạo</th><th style={TH}>Đăng nhập cuối (UTC)</th>
                  <th style={{ ...TH, textAlign: 'right' }}>Streak</th><th style={{ ...TH, textAlign: 'right' }}>Lv. Kiki</th>
                  <th style={TH}>Trạng thái</th><th style={{ ...TH, width: 44 }}></th>
                </tr>
              </thead>
              <tbody>
                {loading && !data && Array.from({ length: 8 }).map((_, i) => (
                  <tr key={`s${i}`}><td style={TD} colSpan={9}><Skeleton height={28} /></td></tr>
                ))}
                {data?.items.map((u: UserRow) => {
                  const st = statusFromUserStatus(u.status);
                  return (
                    <tr key={u.id} className="zz-row" style={{ cursor: 'pointer' }} onClick={() => nav(`/users/${u.id}`)}>
                      <td style={TD}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>
                          <Avatar name={u.displayName} />
                          <span style={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0 }}>
                            <span style={{ font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)', whiteSpace: 'nowrap' }}>{u.displayName}</span>
                            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>{u.email}</span>
                          </span>
                        </span>
                      </td>
                      <td style={TD}><Tag tone="neutral">{u.provider}</Tag></td>
                      <td style={TD}>{u.plan !== 'free' ? <Tag tone="accent">Zen Pro</Tag> : <Tag tone="outline">Free</Tag>}</td>
                      <td style={MONO}>{formatDate(u.createdAt)}</td>
                      <td style={MONO}>{formatDateTimeUtc(u.lastLoginAt)}</td>
                      <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: u.streak ? 'var(--text-strong)' : 'var(--text-faint)' }}>{u.streak}</td>
                      <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-strong)' }}>{u.level}</td>
                      <td style={TD}><StatusBadge status={st.status}>{st.label}</StatusBadge></td>
                      <td style={{ ...TD, padding: 'var(--row-py, 13px) 8px', textAlign: 'right' }} onClick={(e) => e.stopPropagation()}>
                        <IconButton label="Tùy chọn" size="sm"><Icon size={16}>{icons.dots}</Icon></IconButton>
                      </td>
                    </tr>
                  );
                })}
                {data && data.items.length === 0 && (
                  <tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={9}>Không có người dùng khớp bộ lọc.</td></tr>
                )}
              </tbody>
            </table>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '13px 16px', borderTop: '1px solid var(--border-subtle)', background: 'var(--slate-25)', flexWrap: 'wrap' }}>
            <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>
              <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{data ? formatInt(data.total) : '—'}</b> người dùng
            </span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-medium) 12px/1 var(--font-mono)' }}>
              {pages.map((p, i) => p === '…' ? (
                <span key={`e${i}`} style={{ color: 'var(--text-faint)', padding: '0 4px' }}>…</span>
              ) : (
                <button key={p} type="button" onClick={() => setPage(p as number)} style={{
                  minWidth: 28, height: 28, padding: '0 8px', borderRadius: 7, border: 'none', cursor: 'pointer',
                  fontFamily: 'var(--font-mono)', fontSize: 12,
                  background: p === page ? 'var(--brand)' : 'transparent', color: p === page ? '#fff' : 'var(--text-body)',
                }}>{p}</button>
              ))}
            </div>
            <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>25 / 50 / 100 dòng</span>
          </div>
        </Card>
      )}
    </section>
  );
}

function pageList(current: number, total: number): (number | '…')[] {
  if (total <= 5) return Array.from({ length: total }, (_, i) => i + 1);
  const out: (number | '…')[] = [1, 2, 3];
  if (current > 4) out.push('…');
  if (current > 3 && current < total) out.push(current);
  out.push('…', total);
  return out.filter((v, i, a) => a.indexOf(v) === i || v === '…');
}
```

- [ ] **Step 22.7: Run; verify pass.** Run: `cd admin-web && npm test`. Expected: PASS (Users + CSV + all earlier).

- [ ] **Step 22.8: Commit.**

```bash
git add admin-web/src/pages/UsersPage.tsx admin-web/src/pages/UsersPage.test.tsx admin-web/src/lib/csv.ts admin-web/src/lib/csv.test.ts
git commit -m "feat(admin-web): Users page (filters, table, pagination, CSV)"
```

---

### Task 23: UserDetailPage (minimal stub)

**Files:** Create `admin-web/src/pages/UserDetailPage.tsx`.

- [ ] **Step 23.1: Implement `admin-web/src/pages/UserDetailPage.tsx`:**

```tsx
import { Link, useParams } from 'react-router-dom';

export function UserDetailPage() {
  const { id } = useParams();
  return (
    <section style={{ padding: '20px 32px 90px' }}>
      <div style={{ font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-muted)', marginBottom: 14 }}>
        <Link to="/users" style={{ color: 'var(--text-link)' }}>Người dùng</Link> · <span style={{ fontFamily: 'var(--font-mono)' }}>{id}</span>
      </div>
      <div style={{ padding: 40, textAlign: 'center', background: 'var(--surface-card)', border: '1px dashed var(--border-default)', borderRadius: 'var(--radius-lg)', color: 'var(--text-muted)', font: 'var(--fw-medium) 14px/1.5 var(--font-sans)' }}>
        Hồ sơ chi tiết người dùng <b style={{ color: 'var(--text-strong)', fontFamily: 'var(--font-mono)' }}>{id}</b> sẽ được dựng ở giai đoạn sau.
      </div>
    </section>
  );
}
```

- [ ] **Step 23.2: Commit.**

```bash
git add admin-web/src/pages/UserDetailPage.tsx
git commit -m "feat(admin-web): minimal user detail route stub"
```

---

### Task 24: Full integration, build & manual verification

- [ ] **Step 24.1: Type-check the whole frontend.** Run: `cd admin-web && npm run typecheck`. Fix any type errors (most likely unused imports — safe to remove). Expected: exits 0.

- [ ] **Step 24.2: Run the full frontend test suite.** Run: `cd admin-web && npm test`. Expected: ALL suites pass (format, friendlyError, api, Avatar, StatusBadge, theme, csv, OverviewPage, UsersPage).

- [ ] **Step 24.3: Run the backend test suite.** Run: `cd backend && npm test`. Expected: `admin.metrics` suite passes.

- [ ] **Step 24.4: Build the SPA.** Run: `cd admin-web && npm run build`. Expected: `admin-web/dist` produced, no errors.

- [ ] **Step 24.5: End-to-end manual verification.** Start the backend (`cd backend && npm run dev`), open `http://localhost:3000/console`:
  1. Redirected to `/console/login`. Log in with `admin@zenzoo.app` / `zenzoo-admin`. → lands on Tổng quan.
  2. **Overview**: 8 KPI cells render with real numbers; change range (Hôm nay/7/30/Quý) → numbers + sparklines update; activity feed, system status badges (PostgreSQL = Kết nối OK), and quarterly goals render.
  3. Toggle **A · Console / B · Workspace** in the top bar → sidebar flips dark/light and the KPI grid flips from flush-hairline to separated cards. Reload → theme persists.
  4. **Users**: table loads from API; type in search → list filters (debounced); click tabs Active / Zen Pro / Tạm khóa / Đang xem xét → rows filter; "Đăng nhập cuối" and "Trạng thái" columns populate; click a row → `/console/users/:id` stub; click "Xuất CSV" → a `zenzoo-users.csv` downloads and opens cleanly (UTF-8, Vietnamese intact).
  5. Wrong password on login shows "Sai email hoặc mật khẩu quản trị" (not a raw error). Stop the server.

- [ ] **Step 24.6: Dev-mode check (optional).** `cd admin-web && npm run dev`, open `http://localhost:5173/console/` — confirm the Vite proxy reaches the backend (`/admin/api/*` works) while the backend runs on 3000.

- [ ] **Step 24.7: Final commit.**

```bash
git add -A
git commit -m "chore(admin-web): phase-1 integration verified (overview + users)"
```

---

## Self-Review (completed by plan author)

**Spec coverage:** App shell → Task 18; A/B theme → Tasks 17–18 + KPI grid in 21; Login/auth → Tasks 14, 19; Overview UI → Task 21; Overview backend (range/delta/spark/goals/health) → Tasks 5–6; Users UI (toolbar/filters/table/pagination/CSV/row→detail) → Task 22; Users backend (filters + lastLoginAt/status) → Task 7; DB columns + lastLoginAt-on-login → Tasks 1–2; friendlyError/ErrorState/skeleton → Tasks 13, 20; tests → throughout; serve at /console → Task 10. All spec sections map to a task.

**Type consistency:** `OverviewResponse`/`Kpi`/`Goal`/`RecentEvent`/`HealthResponse`/`UserRow`/`UsersResponse`/`UsersQuery` defined once in `lib/types.ts` (Task 11) and consumed identically by `api.ts` (14), `KpiCard`/`OverviewPage` (20–21), `UsersPage` (22); backend `/overview` (5), `/health` (6), `/users` (7) emit exactly these shapes. `statusFromUserStatus` and `DesignStatus` defined in Task 16, used in 22. `themeVars` defined in 17, used in 17 (provider). `toCsv`/`downloadCsv` defined in 22, used in 22.

**Known deviations (intentional, per spec §10):** sparklines are real only for event-based KPIs (dau/focusSessions/focusMinutes/revenue); point-in-time KPIs (stickiness/premiumUsers/avgStreak/conversion) carry `deltaPct:null` + flat baseline; `range='today'` means a rolling 24h window. Goals use configurable env targets. "Bộ lọc" and "Mời / Tạo" are non-functional placeholders this phase.

