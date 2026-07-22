# Admin Console — "Nhiệm vụ & Mốc" (Tasks & Milestones) design

Date: 2026-06-17 · Phase 2e · Branch `Rune-Dev`

## Goal
Build `/console/tasks` ("Nhiệm vụ & Mốc") — the economy **faucet** editor (token/diamond/point
rewards users earn), the natural counterpart to Shop (the **sink**). Manages `TaskTemplate`
(daily tasks) + `DailyMilestone` (daily point thresholds). Nội dung game nav group.

## Why / live behavior
Verified the end-user app reads these live from the same DB: `/daily-tasks/today` filters
`isActive:true`; claim reads `task.template.rewardTokens` fresh at claim time ([app.ts:1146]).
So editing a reward/active flag goes live (same model as the already-shipped Shop screen).

## Backend

### Pure helpers (TDD) `backend/src/admin/task.metrics.ts`
- `parseReward(v): number` — validates a reward → rounded non-negative int, else throws 400.
- `dailyTokenFaucet(tasks): number` — Σ `rewardTokens` over active templates (max daily token payout).

### Endpoints
- **GET /admin/api/tasks** (reshape; currently returns `{items}`, FE-unused). Return
  `{ kpis: { activeTasks, dailyTokenFaucet, activeMilestones }, tasks: TaskTemplate[], milestones: DailyMilestone[] }`.
  Tasks ordered by rewardTokens; milestones by pointsRequired.
- **PUT /admin/api/tasks/:id** (NET-NEW, `requireAdmin('moderator')`) — edit a template:
  `rewardTokens`, `rewardDiamonds`, `rewardPoints` (via `parseReward`), `isActive` (Boolean).
  Record audit `task.update`.
- **PUT /admin/api/milestones/:id** (NET-NEW, `requireAdmin('moderator')`) — edit a milestone:
  `rewardTokens`, `rewardDiamonds` (via `parseReward`), `isActive`. Record audit `milestone.update`.

(No new model — TaskTemplate + DailyMilestone already exist.)

## Frontend

### types.ts
`TaskTemplate` (id, code, title, description, taskType, targetValue, rewardTokens, rewardDiamonds,
rewardPoints, isActive), `DailyMilestone` (id, pointsRequired, rewardTokens, rewardDiamonds, isActive),
`TaskKpis`, `TaskConfigResponse { kpis, tasks, milestones }`, `TaskUpdate`, `MilestoneUpdate`.

### api.ts
`taskConfig()` (GET /tasks), `updateTask(id, body)`, `updateMilestone(id, body)`.

### TasksPage.tsx (`/console/tasks`)
- 3 `KpiCard` (hideSpark): **Nhiệm vụ đang bật · Token phát/ngày · Mốc đang bật**.
- **Nhiệm vụ hằng ngày** table: Nhiệm vụ (title + code) · Loại (`taskType` Tag) · Mục tiêu (`targetValue`)
  · Thưởng (🪙 tokens · 💎 diamonds · ⭐ points) · Trạng thái · Sửa. Inline edit rewards + active.
- **Mốc điểm ngày** table: Mốc (`pointsRequired` đ) · Thưởng (tokens/diamonds) · Trạng thái · Sửa.
  Inline edit rewards + active.
- Loading `Skeleton`, `ErrorState`. (Catalogs are small; client-side 15/page on the tasks table for
  rule-consistency.)

### nav/route + audit
`nav.ts`: flip `tasks` enabled `to:'/tasks'` + meta. `App.tsx`: `/tasks` route.
AuditPage: add `task.update` ("Sửa nhiệm vụ") + `milestone.update` ("Sửa mốc") labels/filters,
and `task_template`/`milestone` resource labels.

## Tests
- Backend: `task.metrics.test.ts` — `parseReward` (rounds, rejects negative/NaN), `dailyTokenFaucet`
  (sums active only).
- Frontend: `TasksPage.test.tsx` — renders the 3 KPIs + a task row + a milestone row; editing a task
  reward calls updateTask with the new value.

## Verification
Backend + FE tests + typecheck + build; E2E (KPIs + both tables render real data; edit a task reward
live → persists + appears in audit log); diff review (auth gating, validation, best-effort audit,
no secrets); commit on `Rune-Dev`.

## Non-goals
Creating/deleting templates or milestones; editing targetValue / taskType / pointsRequired
(game-design params — out of scope, mirrors not editing shop effectValue); per-user task overrides.
