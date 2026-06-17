# ZenZoo Admin Console — Thiết kế (Giai đoạn 1: App shell + Tổng quan + Người dùng)

> Spec tái dựng admin console từ bộ handoff `admin_report/` (Claude Design) vào codebase thật.
> Ngày: 2026-06-16 · Nhánh: Rune-Dev

## 1. Bối cảnh & mục tiêu

Bộ `admin_report/project/ZenZoo Admin.dc.html` là bản thiết kế HTML/CSS/JS (Claude Design) cho **ZenZoo Admin Console** — bảng điều khiển vận hành cho ứng dụng focus-timer/thú-cưng ZenZoo. Thiết kế dùng **ManLab Design System** (token CSS thuần + 12 component React đóng gói trong `_ds_bundle.js`). File có 19–20 màn, app shell chung, và bộ chuyển **theme A/B** (Console vs Workspace) bằng CSS variables.

Backend Express/TypeScript đã có sẵn **API admin** tại `/admin/api/*` ([backend/src/routes/admin.routes.ts](../../../backend/src/routes/admin.routes.ts)) và Express đã được cấu hình **serve SPA tĩnh tại `/console`** ([backend/src/app.ts:1649-1672](../../../backend/src/app.ts#L1649-L1672)), nhưng **chưa có thư mục `admin-web/`**.

**Mục tiêu giai đoạn 1:** dựng app shell + 2 màn **Tổng quan** và **Người dùng** + màn **Login** bằng **React + Vite + TypeScript**, build vào `admin-web/dist` để Express serve tại `/console`. Wire vào API thật và **mở rộng backend** để lấp các chỉ số/trường còn thiếu. Trung thành pixel với thiết kế, **cả hai theme A và B** hoạt động.

### Quyết định đã chốt (qua brainstorming)
- **Framework:** React + Vite + TypeScript (SPA tĩnh).
- **Dữ liệu:** wire API thật **và** mở rộng backend cho đầy đủ.
- **DB:** thêm **cả 2 cột** `User.status` và `User.lastLoginAt` (+ migration; cập nhật `lastLoginAt` khi đăng nhập).
- **Theme:** dựng **cả A (Console) và B (Workspace)** với nút chuyển hoạt động.

### Ngoài phạm vi (YAGNI — để giai đoạn sau)
- 17 màn còn lại (chỉ để link trong sidebar, render placeholder "Đang xây dựng").
- Flow tạo/mời user (nút "Mời / Tạo" render nhưng chưa mở modal).
- Export CSV phía server (giai đoạn 1 làm client-side từ trang đang tải).
- Màn chi tiết user `/users/:id` đầy đủ (giai đoạn 1 chỉ làm link điều hướng + trang khung tối giản; nội dung chi tiết để sau).

## 2. Kiến trúc tổng thể

```
rune/
├── admin-web/                      # ★ NET-NEW: dự án Vite (React+TS)
│   ├── package.json                # độc lập với backend/
│   ├── vite.config.ts              # base:'/console/', outDir:'dist', dev proxy /admin/api
│   ├── tsconfig.json
│   ├── index.html                  # entry Vite
│   ├── dist/                       # ★ build output — Express serve tại /console
│   └── src/
│       ├── main.tsx                # bootstrap + Router(basename='/console')
│       ├── App.tsx                 # route table + ProtectedRoute
│       ├── styles/
│       │   └── manlab/             # copy token CSS từ _ds/tokens/*.css + fonts.css
│       ├── ds/                     # ★ port component ManLab → React/TSX
│       │   ├── Card.tsx  Button.tsx  IconButton.tsx  Input.tsx
│       │   ├── Tag.tsx   StatusBadge.tsx  ProgressMeter.tsx
│       │   ├── Avatar.tsx  SegmentedControl.tsx  (+ index.ts)
│       ├── shell/
│       │   ├── AppShell.tsx        # grid sidebar + main
│       │   ├── Sidebar.tsx         # nav nhóm + badge
│       │   ├── Topbar.tsx          # breadcrumb + title + search + avatar
│       │   ├── CompareBar.tsx      # thanh A/B + brand
│       │   └── ThemeProvider.tsx   # set CSS-var railA/railB + density
│       ├── lib/
│       │   ├── api.ts              # fetch wrapper + Bearer + 401→/login
│       │   ├── auth.ts             # lưu/đọc token (localStorage zz_admin_token)
│       │   ├── friendlyError.ts    # mapper lỗi → tiếng Việt (theo pattern app)
│       │   └── format.ts           # số/ngày kiểu vi-VN, tabular
│       ├── components/
│       │   ├── ErrorState.tsx  LoadingSkeleton.tsx  Sparkline.tsx
│       └── pages/
│           ├── LoginPage.tsx
│           ├── OverviewPage.tsx
│           ├── UsersPage.tsx
│           └── UserDetailPage.tsx  # khung tối giản (chi tiết để sau)
└── backend/                        # mở rộng API hiện có
    ├── prisma/schema.prisma        # + User.status, User.lastLoginAt
    └── src/
        ├── routes/admin.routes.ts  # mở rộng /overview, /users, + /health
        ├── admin/admin.metrics.ts  # ★ NET-NEW: hàm tính KPI/sparkline
        └── services/auth.service.ts# set lastLoginAt khi đăng nhập
```

**Nguyên tắc cô lập:** mỗi đơn vị có một trách nhiệm rõ — `ds/*` chỉ là trình bày (không gọi API), `lib/api.ts` là cổng dữ liệu duy nhất, `pages/*` ghép data + DS, `shell/*` là khung điều hướng/theme. Component DS nhận props thuần, không biết tới backend.

## 3. Tích hợp build & deploy

- **Vite config:**
  - `base: '/console/'` — vì Express serve SPA dưới prefix `/console`; mọi asset phải trỏ `/console/assets/...`.
  - `build.outDir: 'dist'` (tức `admin-web/dist`).
  - **Dev proxy:** `server.proxy['/admin/api'] = 'http://localhost:<BACKEND_PORT>'` để dev (Vite :5173) gọi được API.
- **Router:** `react-router-dom` với `basename="/console"`. Asset của Vite tự đúng nhờ `base`.
- **Sửa backend (1 chỗ):** thêm `admin-web/dist` vào đầu mảng `adminWebCandidates` trong [backend/src/app.ts:1651-1655](../../../backend/src/app.ts#L1651-L1655). Giữ nguyên các fallback cũ. Express đã có route regex `/^\/console(\/.*)?$/` + fallback `index.html` cho client-side routing — không cần sửa thêm.
- **Lệnh:** `cd admin-web && npm install && npm run build` → sinh `admin-web/dist`. Backend chạy như cũ; mở `http://localhost:<PORT>/console`.

## 4. Design System — token & component

### 4.1 Token (copy nguyên bản)
Copy `admin_report/project/_ds/manlab-design-system-*/tokens/*.css` (colors, typography, spacing, elevation, base, fonts) vào `admin-web/src/styles/manlab/` và import trong `main.tsx`. **Không sửa giá trị** — dùng đúng `--blue-600`, `--slate-900`, `--status-*`, `--shadow-sm`, `--radius-*`, `--font-sans/mono` v.v. Font Be Vietnam Pro + JetBrains Mono giữ nguồn như `fonts.css` (CDN).

### 4.2 Component (dựng lại bằng React/TSX)
Source `.jsx` **không có** trong bundle (chỉ minified trong `_ds_bundle.js`). Dựng lại từ: markup/props quan sát trong `.dc.html`, `_ds_manifest.json` (hợp đồng props), `styles.css`. Giai đoạn 1 cần (port 1:1 token & style):

| Component | Props chính (theo cách dùng trong design) |
|---|---|
| `Card` | `title?`, `subtitle?`, `padding: 'none'\|'md'`, children |
| `Button` | `variant: 'primary'\|'secondary'`, `size: 'md'`, icon + label |
| `IconButton` | `label` (aria), `variant?`, `size?: 'sm'`, children=svg |
| `Input` | `placeholder`, `prefix?` (icon), value/onChange |
| `Tag` | `tone: 'neutral'\|'accent'\|'outline'`, `size: 'sm'` |
| `StatusBadge` | `status: 'draft'\|'pending'\|'progress'\|'review'\|'approved'\|'public'\|'suspended'\|'rejected'`, `pulse?`, `size: 'sm'` |
| `ProgressMeter` | `label`, `value`, `max?`, `unit?`, `threshold?` |
| `Avatar` | initials, hue suy diễn (deterministic theo tên) |
| `SegmentedControl` | dựng inline theo `segDark`/`segLite` (dark cho nền tối, lite cho nền sáng) |

Các component còn lại (Select, Checkbox, Tabs) port khi màn sau cần.

## 5. App shell

**Layout:** grid `264px minmax(0,1fr)`, chiều cao `100vh - 46px` (trừ CompareBar).

- **CompareBar** (sticky top, slate-950, cao 46px): logo mark + "ZENZOO ADMIN" + nhãn, bên phải là segmented "So sánh" A·Console / B·Workspace → đổi theme.
- **Sidebar** (`shell/Sidebar.tsx`): brand plate (logo + "ZenZoo / Admin Console"); nav 6 nhóm:
  - *Lõi vận hành*: Tổng quan, Người dùng (badge `6.8k`), Kiểm duyệt (badge `5` amber)
  - *Dòng tiền*: Thanh toán & Gói, Vận hành & IPN
  - *Phân tích*: Phân tích, Nhật ký kiểm toán
  - *Nội dung game*: Nhiệm vụ & Mốc, Cửa hàng & Kinh tế, Thú cưng & Tiến hóa, Thành tựu & Streak, AI Focus Designer (badge `Beta`)
  - *Tiếp cận*: Thông báo & Chiến dịch
  - *Quản trị & bảo mật*: Vai trò & Bảo mật, Đội quản trị, Cờ tính năng, Quyền riêng tư & Xuất DL, Tác vụ hàng loạt, Hỗ trợ (badge `12`)
  - Footer: "Phiên bản 2.4.0 · môi trường production".
  - Icon: dùng đúng path SVG Lucide trong design (stroke 1.75). Mục active: `box-shadow: inset 2px 0 0 var(--rail-active-bar)` + nền `--rail-active-bg`.
  - Chỉ Tổng quan / Người dùng điều hướng thật; còn lại trỏ route placeholder.
- **Topbar** (`shell/Topbar.tsx`, sticky, blur): breadcrumb (uppercase) + title (24px bold) theo route; bên phải: Input tìm nhanh (280px), IconButton chuông + cài đặt, divider, avatar admin (initials + tên + vai trò từ `/admin/api/auth/me`).

### Theme A/B (`shell/ThemeProvider.tsx`)
Áp các CSS-var lên `div` bọc shell theo biến thể (trích nguyên từ design):

- **A (Console):** `--rail-bg: slate-900` (sidebar tối); KPI grid là **một card viền chung, cell chia bằng hairline** — `--kpi-gap:1px`, `--kpi-wrap-bg:var(--border-subtle)`, `--kpi-cell-bg:var(--surface-card)`, cell không viền/không bo/không shadow.
- **B (Workspace):** `--rail-bg: slate-0` (sidebar sáng); KPI grid là **các card rời** — `--kpi-gap:14px`, `--kpi-wrap-bg:transparent`, mỗi cell `border:1px var(--border-subtle)` + `radius-lg` + `shadow-sm`.
- Đầy đủ tập biến `--rail-*` (fg/hover/active/plate/group/foot) và `--kpi-*` theo `railA`/`railB` ở [.dc.html:1298-1321]. Thêm `--row-py` (comfortable `13px` / compact `8px`).
- State theme lưu localStorage (`zz_admin_theme`), mặc định `a`.

## 6. Màn Tổng quan (`pages/OverviewPage.tsx`)

### 6.1 UI (theo design)
1. **Range row:** segmented `Hôm nay / 7 ngày / 30 ngày / Quý` + nhãn "Cập nhật N phút trước" + Button "Xuất báo cáo".
2. **KPI grid (8 ô)** — mỗi ô: eyebrow (label in hoa), số lớn (extrabold 30px, `tabular-nums`), dòng delta (▲ xanh `--green-600` / ▼ đỏ `--red-600` + "vs kỳ trước"), **sparkline** SVG (area mờ + polyline). 8 KPI:
   - Người dùng hoạt động/ngày (DAU) · Độ bám DAU/MAU · Tổng phút focus hôm nay · Phiên focus hoàn thành · Người dùng Zen Pro · Doanh thu hôm nay · Streak trung bình · Free → Zen Pro.
3. **Lower grid `2fr / 1fr`:**
   - Card "Hoạt động gần đây" (feed icon+text+thời gian, từ `recent`).
   - Card "Tình trạng hệ thống" (StatusBadge cho Express API / PostgreSQL / VNPay IPN / Gemini Flash + dòng độ trễ).
   - Card "Mục tiêu quý" (ProgressMeter: Doanh thu quý / Zen Pro mục tiêu / Tỉ lệ chuyển đổi).

### 6.2 Backend — mở rộng `GET /admin/api/overview`
Nhận `?range=today|7d|30d|quarter` (mặc định `today`). Trả mỗi KPI dạng `{ value:number, deltaPct:number|null, spark:number[] }` + so kỳ liền trước cùng độ dài. Logic gom vào `src/admin/admin.metrics.ts`:

| KPI | Nguồn |
|---|---|
| `dau` | distinct `userId` có `FocusSession.startedAt` HOẶC `ActivityEvent.createdAt` trong range (NET-NEW) |
| `stickiness` | `dau / mau` (mau = distinct active 30 ngày) ×100 (NET-NEW) |
| `focusMinutes` | `sum(plannedMinutes)` session completed trong range (tái dùng) |
| `focusSessions` | `count` session completed trong range (tái dùng) |
| `premiumUsers` | `count subscription plan≠free, active` (tái dùng) |
| `revenue` | `sum(amountVnd)` paymentOrder paid trong range (tái dùng) |
| `avgStreak` | `avg(currentStreak)` (tái dùng) |
| `conversion` | `premiumUsers / totalUsers` ×100 (NET-NEW) |

- `spark[]`: chuỗi ~7–12 điểm theo bucket thời gian của range (đếm/sum theo ngày). `deltaPct`: so tổng range hiện tại với range trước.
- Giữ `recent` như hiện tại (đổi `take` lên 7 để khớp design).
- **`GET /admin/api/health` (NET-NEW):** `{ db: 'ok'|'down' (prisma $queryRaw SELECT 1), vnpay: boolean (env cấu hình), gemini: boolean (env GEMINI key), apiLatencyMs:number }`.
- **Mục tiêu quý:** target lấy từ hằng số/env (`QUARTER_REVENUE_TARGET`, `QUARTER_PRO_TARGET`, `CONVERSION_TARGET`); actual tính từ range `quarter`. Trả **kèm trong response `/admin/api/overview`** ở khối `goals: [{ label, value, max, unit? }]` (một round-trip, không thêm endpoint riêng).

## 7. Màn Người dùng (`pages/UsersPage.tsx`)

### 7.1 UI (theo design)
- **Toolbar:** Input tìm (tên/email/userId) + Button "Bộ lọc" + "Xuất CSV" + "Mời / Tạo" (primary).
- **Filter row:** segmented `Tất cả / Active / Zen Pro / Tạm khóa / Đang xem xét` + đếm "N người dùng · hiển thị x–y".
- **Bảng** (Card padding=none): cột **Người dùng** (Avatar initials + tên + email), **Provider** (Tag), **Gói** (Tag accent=Zen Pro / outline=Free), **Ngày tạo** (mono dd/MM/yyyy), **Đăng nhập cuối (UTC)** (mono dd/MM · HH:mm), **Streak** (phải, mono), **Lv. Kiki** (phải, mono = pet level), **Trạng thái** (StatusBadge), **⋯** (IconButton). Row click → `/users/:id`.
- **Footer:** tổng đếm + pagination (mono) + "25 / 50 / 100 dòng".
- Map trạng thái → StatusBadge: `active`→`approved` ("Active"), `review`→`pending` ("Đang xem xét"), `suspended`→`suspended` ("Tạm khóa").

### 7.2 Backend — mở rộng `GET /admin/api/users`
- Thêm query `?plan=free|premium` và `?status=active|suspended|review` (kết hợp với `q`, `page`, `pageSize` hiện có).
- Mỗi item trả thêm: `lastLoginAt` (từ `User.lastLoginAt`) và `status` (account moderation, từ `User.status`). Giữ `plan` từ subscription, `level` từ pet, `streak` từ streak.
- **Lưu ý đổi nghĩa:** field `status` cũ map từ `subscription.status` — đổi thành **account status** (`User.status`); thông tin gói vẫn ở `plan`. Endpoint này chỉ admin dùng nên không phá vỡ client khác.

### 7.3 Schema change (Prisma + migration)
Thêm vào `model User`:
```prisma
status       String    @default("active")            // active | suspended | review
lastLoginAt  DateTime? @map("last_login_at") @db.Timestamptz(6)
```
- Migration `prisma migrate dev --name add_user_status_lastlogin`.
- Cập nhật `lastLoginAt = now()` trong `auth.service.ts` ở luồng đăng nhập (demo + google) thành công.
- Seed: gán vài user `status` review/suspended để demo filter (tùy chọn, trong `prisma/seed.ts`).

## 8. Auth, lỗi, định dạng

- **Auth FE:** `lib/auth.ts` lưu token ở `localStorage['zz_admin_token']`. `lib/api.ts` gắn `Authorization: Bearer`; 401 → xóa token + điều hướng `/login`. `LoginPage` POST `/admin/api/auth/login` `{email,password}` → lưu `token`, đọc `admin`. Tài khoản demo: `admin@zenzoo.app` / `zenzoo-admin` (super-admin).
- **Lỗi:** `friendlyError()` map mã/HTTP → tiếng Việt; **không bao giờ** hiển thị `error.toString()` thô (theo memory shared-error-handling). Mọi page có `ErrorState` (retry) + `LoadingSkeleton`.
- **Định dạng:** số kiểu vi-VN (`1.842`, `41.250`), tiền `1,25 tr đ`, ngày `dd/MM/yyyy`, giờ UTC `dd/MM · HH:mm`. Số dùng `font-variant-numeric: tabular-nums` + `--font-mono` ở cột mã/giá trị.

## 9. Kiểm thử (TDD)

- **FE (Vitest + React Testing Library):**
  - `lib/api.ts`: gắn header, xử lý 401, parse lỗi.
  - `lib/format.ts`: số/tiền/ngày vi-VN.
  - DS component: render đúng theo `status`/`tone`/`variant`.
  - `OverviewPage`: render 8 KPI + delta màu đúng dấu; `UsersPage`: render hàng, map StatusBadge, đổi filter gọi đúng query.
- **Backend (Vitest + supertest — NET-NEW, backend hiện chưa có test runner):**
  - `admin.metrics`: DAU/stickiness/conversion/spark trên dữ liệu seed.
  - `/admin/api/users?status=&plan=`: lọc + field `lastLoginAt`/`status`.
  - Gate quyền giữ nguyên (`requireAdmin`).
- Theo TDD: viết test (đỏ) trước mỗi đơn vị logic rồi mới hiện thực.

## 10. Rủi ro & lưu ý
- **Đổi nghĩa `status`** ở `/admin/api/users` — xác nhận không có client nào khác phụ thuộc (hiện chỉ admin console mới dùng).
- **`base:'/console/'` + basename router** phải khớp; sai sẽ vỡ asset/đường dẫn khi serve qua Express.
- **`lastLoginAt`** chỉ có sau khi user đăng nhập lần kế (cột mới); user cũ sẽ là `null` → hiển thị "—".
- **Sparkline/health** là dữ liệu thật nhưng "Mục tiêu quý" dùng target cấu hình — ghi rõ trên UI là chỉ tiêu nội bộ.
- Build `admin-web/dist` cần có trước khi Express phục vụ `/console` (CI/script build).

## 11. Tiêu chí hoàn thành (giai đoạn 1)
1. `npm run build` trong `admin-web/` tạo `dist`; mở `/console` thấy app shell + đăng nhập được bằng tài khoản admin.
2. Màn Tổng quan hiển thị 8 KPI từ API thật (range đổi được), feed hoạt động, tình trạng hệ thống, mục tiêu quý — pixel khớp design ở **cả theme A và B**.
3. Màn Người dùng: bảng phân trang từ API thật, search + filter (plan/status) hoạt động, cột Đăng nhập cuối + Trạng thái đúng, Xuất CSV (client) chạy, row click sang `/users/:id`.
4. Backend: migration áp dụng; `/overview` (range/delta/spark), `/users` (filter + field mới), `/health` trả đúng; test xanh.
5. Không có lỗi `toString()` thô; có skeleton + ErrorState.
