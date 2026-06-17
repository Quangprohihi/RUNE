# Handoff: ZenZoo Admin Console (thiết kế lại theo ManLab Design System)

## Overview
Đây là **bảng điều hành quản trị (admin console)** cho **ZenZoo** — một ứng dụng tập trung/năng suất được game-hóa (thú cưng đồng hành "Kiki", phiên focus, nhiệm vụ, streak, cửa hàng token/kim cương, gói **Zen Pro**, thanh toán **VNPay**). Console gồm **20 màn** cho 5 nhóm chức năng: Lõi vận hành, Dòng tiền, Phân tích, Nội dung game, Tiếp cận, Quản trị & bảo mật.

Bản thiết kế dùng hệ thống **ManLab Design System** (xanh institutional + xám slate, font Be Vietnam Pro / JetBrains Mono, icon Lucide), giao diện **tiếng Việt**, mật độ dữ liệu kiểu ERP. Có thêm **trang đăng nhập** riêng (`ZenZoo Login.dc.html`).

## About the Design Files
Các tệp trong gói này là **bản tham chiếu thiết kế viết bằng HTML** (prototype thể hiện diện mạo + hành vi mong muốn) — **không phải code sản xuất để copy nguyên**. Nhiệm vụ là **tái dựng các thiết kế này trong codebase đích** (React, Vue, Next.js, v.v.) theo các pattern/thư viện sẵn có của dự án. Nếu dự án **chưa có** môi trường, hãy chọn framework phù hợp (khuyến nghị **React + Vite/Next.js + CSS variables hoặc Tailwind**) và hiện thực hóa.

File chính `ZenZoo Admin.dc.html` là một "Design Component" — phần markup nằm giữa thẻ `<x-dc>…</x-dc>`, phần logic là class JavaScript ở cuối (`<script type="text/x-dc">`). Hãy đọc nó như **một React component**: `state` + `renderVals()` ↔ state + render của React; các `{{ biến }}` là chỗ chèn giá trị; `<sc-if>` ↔ render có điều kiện; `<x-import component-from-global-scope="ManLabDesignSystem_019e1f.X">` ↔ dùng component `X` của design system.

## Fidelity
**High-fidelity (hifi).** Màu, typography, spacing, bo góc, đổ bóng, trạng thái hover và tương tác đều là giá trị cuối. Hãy tái dựng **pixel-perfect** bằng thư viện/pattern của codebase. Toàn bộ giá trị thiết kế lấy từ token trong `_ds/tokens/*.css` (đã kèm trong gói) — **dùng đúng các token này**, đừng chế thêm màu/spacing mới.

## Kiến trúc & layout chung (app shell)
Mọi màn dùng chung khung:
- **Compare bar** (thanh trên cùng, nền `--slate-950`, cao 46px, sticky): đây là **chrome xem thử** để bật/tắt 2 phương án giao diện A/B. **Trong sản phẩm thật KHÔNG cần thanh này** — chọn 1 phương án (xem mục Theming) rồi bỏ.
- **Sidebar** (rộng 264px, sticky, cuộn dọc): logo (emblem `assets/zenzoo-mark.png` + chữ "ZenZoo") → các nhóm điều hướng (group label in hoa, 10px, letter-spacing .13em) → các mục `<a>` (cao ~34px, gap 11px, icon 18px Lucide + nhãn 13.5px). Mục **active**: nền `--rail-active-bg`, chữ `--rail-active-fg`, **thanh accent trái 2px** `--rail-active-bar` (làm bằng `box-shadow: inset 2px 0 0 0 …`). Footer: phiên bản + môi trường.
- **Main**: topbar (sticky, cao ~62px, có blur nền): breadcrumb (11px hoa) + tiêu đề màn (24px bold) bên trái; ô tìm kiếm (280px) + chuông + cài đặt + avatar admin bên phải. Bên dưới là vùng nội dung, padding `24px 32px 90px`.
- Lưới nội dung dày dữ liệu: thẻ trắng (`--surface-card`) viền 1px (`--border-subtle`) bo góc `--radius-lg` (10px) đổ bóng `--shadow-sm`; bảng hairline; KPI dạng thẻ.

### Điều hướng (data-driven)
- `state.screen` giữ key màn hiện tại (`overview`, `users`, `userDetail`, `moderation`, `billing`, `ops`, `analytics`, `audit`, `tasks`, `shop`, `pets`, `achievements`, `ai`, `notifications`, `rbac`, `adminteam`, `flags`, `gdpr`, `bulk`, `support`).
- Một map `SCREENS` ánh xạ key → `{ title, group }` để đổ vào tiêu đề + breadcrumb.
- Click điều hướng dùng **event delegation**: `<nav onClick=…>` đọc `data-screen` của phần tử gần nhất rồi `setState({screen})`. Mỗi `<a>` có `data-screen="<key>"`. Cùng cơ chế dùng cho liên kết chéo (vd. click dòng người dùng có `data-screen="userDetail"`).
- Mỗi màn là một khối `<sc-if value="show.<key>">` → trong React là `{screen === key && <ScreenX/>}`.

## Theming — 2 phương án A/B (chọn 1 cho production)
Toàn bộ khác biệt giữa 2 phương án được điều khiển bằng **CSS variables đặt trên phần tử gốc** (không nhân đôi markup):
- **Phương án A — "Console"**: sidebar **nền tối** (`--slate-900`), KPI ở màn Tổng quan là **lưới viền liền mạch** (gap 1px, nền lưới = màu viền).
- **Phương án B — "Workspace"**: sidebar **nền sáng** (`--slate-0`), KPI là **thẻ nổi rời** (gap 14px, mỗi thẻ có viền + `--shadow-sm` + bo góc).

Các biến theme (đặt trên gốc, con tham chiếu qua `var(--…)`):
`--rail-bg, --rail-edge, --rail-fg, --rail-fg-strong, --rail-muted, --rail-border, --rail-hover, --rail-active-bg, --rail-active-fg, --rail-active-bar, --rail-group, --rail-plate-bg, --rail-plate-border, --rail-foot` (sidebar) và `--kpi-gap, --kpi-wrap-bg, --kpi-wrap-border, --kpi-wrap-radius, --kpi-wrap-overflow, --kpi-cell-bg, --kpi-cell-border, --kpi-cell-radius, --kpi-cell-shadow` (KPI). Xem giá trị cụ thể của từng phương án trong `renderVals()` (`railA` / `railB`). Ngoài ra `--row-py` điều khiển mật độ bảng (comfortable 13px / compact 8px).

> Gợi ý cho dev: implement theme bằng 2 class (`.theme-console` / `.theme-workspace`) hoặc `data-theme` trên `<body>`, set các biến trên. Bỏ compare bar.

## Screens / Views
> Mọi màn theo cùng shell ở trên. Bên dưới mô tả nội dung chính từng màn (số liệu là dữ liệu mẫu).

1. **Tổng quan (overview)** — Dashboard. Hàng thanh khoảng thời gian (segmented) + nút Xuất; **8 thẻ KPI** (Người dùng hoạt động/ngày, Độ bám DAU/MAU, Tổng phút focus, Phiên hoàn thành, Người Zen Pro, Doanh thu hôm nay, Streak TB, Free→Zen Pro) — mỗi thẻ: eyebrow 11px hoa, số 30px extrabold, delta (mũi tên + %, xanh `--green-600` tăng / đỏ `--red-600` giảm), **sparkline SVG** (polyline + vùng fill opacity .10, màu theo xu hướng). Dưới: lưới 2fr/1fr — trái = thẻ "Hoạt động gần đây" (feed, mỗi dòng: icon tròn nền tint + nội dung + thời gian mono); phải = "Tình trạng hệ thống" (các dòng + `StatusBadge`) và "Mục tiêu quý" (3 `ProgressMeter`).
2. **Người dùng (users)** — Toolbar: ô tìm (Input có icon) + nút Bộ lọc/Xuất CSV/Mời·Tạo; thanh **SegmentedControl** lọc trạng thái (Tất cả/Active/Zen Pro/Tạm khóa/Đang xem xét) + đếm tổng; **bảng** 8 cột (Người dùng [avatar tròn initials + tên + email], Provider [Tag], Gói [Tag accent=Zen Pro / outline=Free], Ngày tạo, Đăng nhập cuối, Streak, Lv. Kiki, Trạng thái [StatusBadge], nút •••). Dòng hover nền `--slate-50`, click mở **Hồ sơ người dùng**. Footer: tổng + phân trang + số dòng/trang.
3. **Hồ sơ người dùng (userDetail)** — Breadcrumb quay lại. Thẻ header (avatar 60px, tên 22px, các chip provider/gói/trạng thái, nút Đặt lại mật khẩu / Tạm khóa[danger]). Lưới 2fr/1fr: trái = thẻ "Thú cưng Kiki" (4 `ProgressMeter`: Năng lượng/Tâm trạng/Đói/Yêu thương) + bảng "Phiên focus gần nhất"; phải = thẻ "Gói đăng ký" (key/value) + thẻ "Điều chỉnh số dư" (eyebrow RBAC, accent cam, nút).
4. **Kiểm duyệt (moderation)** — 4 thẻ KPI (Đang chờ/Tạm khóa/Đã cấm/Báo cáo mới); bảng hàng đợi (Tài khoản, Lý do, Nguồn [Tag], Trạng thái [StatusBadge: pending/suspended/rejected/approved], Thời gian, nút Khóa/Mở khóa/Cấm/Khôi phục).
5. **Thanh toán & Gói (billing)** — 4 KPI (Doanh thu tháng/MRR/ARPU/Tỉ lệ hoàn tiền); lưới 2fr/1fr: bảng Giao dịch VNPay (Mã GD mono, Người dùng, Gói, Số tiền, Trạng thái) + cột phải 3 thẻ gói (Free / Zen Pro Monthly 29.000đ / Yearly 279.000đ, có số người đăng ký, viền trái accent cho gói trả phí).
6. **Vận hành & IPN (ops)** — 4 KPI (IPN nhận/Đối soát khớp/Chờ retry/Độ trễ); bảng nhật ký callback IPN (Mã đơn, Loại, Mã phản hồi, Trạng thái IPN, Thời gian).
7. **Phân tích (analytics)** — **Xem mục "Thanh thời gian" bên dưới** (đây là phần tương tác phức tạp nhất). Có thanh chọn khoảng + độ chi tiết, 4 KPI động, biểu đồ DAU động, phễu chuyển đổi (5 bậc thanh ngang), biểu đồ cột phút-focus-theo-giờ.
8. **Nhật ký kiểm toán (audit)** — Ô lọc + nút Xuất; bảng (Thời gian, Actor, Hành động [Tag mono], Tài nguyên, IP).
9. **Nhiệm vụ & Mốc (tasks)** — 3 KPI + nút Tạo mẫu; bảng TaskTemplate (Mã, Tên, Loại [Hằng ngày/Mốc], Phần thưởng, Trạng thái [StatusBadge public/draft]).
10. **Cửa hàng & Kinh tế (shop)** — 4 KPI kinh tế (token faucet/sink/cân bằng/kim cương bán); bảng vật phẩm (Mã, Tên, Loại [Tag], Giá [token hoặc ◆], Trạng thái).
11. **Thú cưng & Tiến hóa (pets)** — Lưới 2fr/1fr: bảng Đồng hành (Kiki/Eagle/Giraffe, hệ số thưởng, yêu cầu mở khóa) + thẻ "Hằng số decay" (lưới 2 cột ô inset) ; phải = thẻ "Giai đoạn tiến hóa" (timeline 4 bậc, bậc hiện tại có Tag).
12. **Thành tựu & Streak (achievements)** — Lưới 2fr/1fr: bảng thành tựu (Tên, Điều kiện, % mở khóa) + thẻ "Quy tắc Streak" (key/value).
13. **AI Focus Designer (ai)** — 4 KPI (lượt dùng/token/chi phí/tỉ lệ áp dụng); lưới 2 cột: thẻ "Cấu hình mô hình" (Gemini Flash, key/value + StatusBadge) + thẻ "Prompt hệ thống" (khối mono nền inset + nút Chỉnh sửa).
14. **Thông báo & Chiến dịch (notifications)** — Lưới 1fr/1.4fr: thẻ "Soạn thông báo" (Input tiêu đề + textarea nội dung + chip phân khúc + nút Gửi/Lên lịch) + bảng "Chiến dịch gần đây" (Đã gửi, Mở %, Trạng thái).
15. **Vai trò & Bảo mật (rbac)** — Bảng **ma trận phân quyền**: hàng = quyền, cột = 5 vai trò (Super Admin/Quản trị/Kiểm duyệt/Hỗ trợ/Phân tích), ô = ✓ (check xanh) hoặc — (mờ).
16. **Đội quản trị (adminteam)** — Nút Mời; bảng (Thành viên [avatar + tên + email], Vai trò [Tag], Hoạt động cuối, Trạng thái).
17. **Cờ tính năng (flags)** — Thẻ danh sách: mỗi dòng tên flag + mã mono + **công tắc toggle** (bật = `--green-500`, tắt = `--slate-300`; knob trắng 16px).
18. **Quyền riêng tư & Xuất DL (gdpr)** — Lưới 1.6fr/1fr: bảng "Yêu cầu dữ liệu" (Người dùng, Loại [Tag], Trạng thái, Hạn xử lý) + thẻ "Dữ liệu lưu trữ" (key/value thời hạn).
19. **Tác vụ hàng loạt (bulk)** — Lưới 1fr/1.6fr: thẻ "Chạy tác vụ mới" (select giả + Input + nút) + bảng "Hàng đợi" (Tác vụ, Tiến độ [ProgressMeter], Trạng thái).
20. **Hỗ trợ (support)** — 4 KPI (Ticket mở/Chờ phản hồi/Thời gian phản hồi/CSAT); bảng hộp thư (Mã, Người dùng, Chủ đề, Ưu tiên [Tag], Trạng thái).

## Thanh thời gian màn Phân tích (chi tiết — chuẩn báo cáo dashboard)
Thiết kế theo chuẩn Google Analytics / Salesforce CRM Analytics. **Tách 2 khái niệm**:

**(1) Khoảng thời gian (date range)** — nút hiển thị nhãn hiện tại (vd. "Tháng này · 01/06 – 30/06/2026") + icon lịch + chevron. Click mở **popover** (rộng 600px, đổ bóng `--shadow-lg`):
- Cột trái (188px, nền inset): danh sách **preset** — `Hôm nay`, `Tuần này`, `Tháng này`, `Quý này`, `Năm nay`, `Tùy chỉnh…`. Preset đang chọn có nền `--surface-brand-soft`, chữ `--blue-700`.
- Cột phải: **lịch 1 tháng** (header Tháng + nút ‹ ›; hàng thứ T2…CN; lưới ngày). Click ngày → đặt **ngày bắt đầu**; click ngày thứ 2 ≥ bắt đầu → **ngày kết thúc**; vùng giữa tô `--surface-brand-soft`, đầu/cuối nền `--brand` chữ trắng. Chọn ngày tự chuyển preset sang "Tùy chỉnh".
- Footer: toggle **"So sánh với kỳ trước"** (switch xanh) + nút **Hủy** / **Áp dụng**.
- **Quan trọng — pattern "draft → apply"**: các lựa chọn trong popover ghi vào *draft state* (`dRange/dStart/dEnd/dCompare`); chỉ khi bấm **Áp dụng** mới commit sang state đã áp dụng (`anaRange/anaStart/anaEnd/anaCompare`) và đóng popover. Mở popover thì copy state đã áp dụng → draft.

**(2) Độ chi tiết (granularity)** — segmented riêng (Ngày / Tuần / Tháng / Quý) **bên ngoài** popover, **áp dụng ngay khi chọn**. Đổi độ chi tiết → biểu đồ **gom nhóm lại** (số điểm thay đổi). Số bucket = hàm của (khoảng × độ chi tiết) — xem bảng `GRID` trong `computeAnalytics()`.

**Khi khoảng/độ chi tiết/so sánh thay đổi**, các thứ sau tính lại (đều trong `computeAnalytics()`):
- **4 thẻ KPI** (Người dùng hoạt động, Phút focus, Doanh thu, Zen Pro mới) — giá trị + delta theo từng khoảng (bảng `KPI`; với "Tùy chỉnh" tính theo số ngày).
- **Biểu đồ đường DAU** — series sinh bằng seeded RNG (ổn định theo `khoảng|độ chi tiết`); vẽ polyline + vùng fill; **5 nhãn trục X** là 5 mốc ngày trải đều trong khoảng (với "Hôm nay" là 0h/6h/12h/18h/23h).
- **Đường so sánh** (khi bật) — series kỳ trước, vẽ **nét đứt** `--slate-400` + chú thích "Kỳ này / Kỳ trước".

> Khi code thật: thay seeded RNG bằng truy vấn dữ liệu thật theo `{start, end, granularity}`; "So sánh" gọi thêm cho kỳ liền trước cùng độ dài và tính % thay đổi.

## Interactions & Behavior
- **Điều hướng**: click mục sidebar / dòng người dùng → đổi `screen`, cuộn lên đầu.
- **Hover**: mục sidebar đổi nền `--rail-hover` + chữ đậm hơn; dòng bảng nền `--slate-50`; nút theo biến thể (primary đậm hơn, secondary/ghost wash slate-100). Chuyển động 120–180ms `ease`/`ease-out`, **không nảy**.
- **Trạng thái active** mọi segmented/toggle/preset: viền/nền/đậm theo state (xem các style object trong logic).
- **Status dot pulse**: chấm trạng thái "live/đang chạy" có hiệu ứng `ping` nhẹ (keyframes `zzpulse` / `manlab-ping`). Tôn trọng `prefers-reduced-motion`.
- Popover phân tích: bấm Áp dụng để xác nhận; Hủy để đóng không lưu.

## State Management
Biến state cần có (tham chiếu class logic ở cuối file HTML):
- `screen` — màn hiện tại (string key).
- `variant` ('a'|'b') + `density` ('comfortable'|'compact') — theme (prop có thể bỏ ở production nếu chốt 1 phương án).
- Bộ lọc/segmented hiển thị: `range`, `filter` (overview/users).
- **Phân tích**: `anaOpen` (popover), đã-áp-dụng `anaRange/anaStart/anaEnd/anaCompare/anaGran`, draft `dRange/dStart/dEnd/dCompare`, lịch `calY/calM`.
Data fetching (production): mỗi màn bảng → API danh sách phân trang + lọc; analytics → API timeseries theo `{start,end,granularity, compare?}`; các action (khóa/cấm, điều chỉnh ví, gửi thông báo, chạy bulk) → mutation + ghi audit log.

## Design Tokens
**Dùng đúng token trong `_ds/tokens/*.css` (đã kèm).** Tóm tắt:
- **Brand/blue**: `--brand` = `--blue-600` `#1C50C9`; hover `--blue-700` `#163FA3`. **Accent/teal** (verified/public/premium): `--accent` = `--teal-600` `#0D9488`.
- **Slate (trung tính)**: `--slate-0 #FFFFFF`, `25 #FBFCFE`, `50 #F6F8FB`, `100 #EDF1F7`, `200 #DEE5EF`, `300 #C7D1E0`, `400 #9AA8BE`, `500 #6C7B93`, `600 #4E5D74`, `700 #394656`, `800 #28313F`, `900 #18202C`, `950 #0C111B`.
- **Surfaces**: page `--slate-50`, card `#fff`, sunken `--slate-100`, inset `--slate-25`, inverse `--slate-900`.
- **Text**: strong `--slate-900`, body `--slate-700`, muted `--slate-500`, faint `--slate-400`.
- **Border**: subtle `--slate-200`, default `--slate-300`.
- **Status (khóa cứng — 1 màu = 1 nghĩa)**: draft=xám, pending=hổ phách, progress=xanh dương, review=tím, approved=xanh lá, public/live=teal, suspended=cam, rejected=đỏ. Mỗi status có bộ `-bg/-fg/-border/-solid` (xem `colors.css`).
- **Type**: font sans `Be Vietnam Pro`, mono `JetBrains Mono`. Thang: 2xs 11, xs 12, sm 13, base 14, md 16, lg 18, xl 22, 2xl 28, 3xl 36. Weight 400/500/600/700/800.
- **Spacing**: lưới 4px (token `--space-1..14`). Gutter trang 32px. Control height 28/34/42px.
- **Radius**: xs 3, sm 5, md 7 (control), lg 10 (card), xl 14 (panel), pill 999.
- **Shadow**: `--shadow-xs/sm/md/lg/xl` (lạnh, nhẹ — xem `elevation.css`). Focus ring 3px xanh nhạt.
- **Motion**: `--dur-fast 120ms / base 180ms / slow 260ms`; ease `cubic-bezier(.2,0,.1,1)`; không nảy.

## Components (ManLab Design System)
Thiết kế **compose từ các component có sẵn** của ManLab (đừng dựng lại từ đầu). Mã nguồn React `.jsx` + `.d.ts` + `.prompt.md` của từng component nằm trong `_ds/` (và bản đầy đủ trong dự án design system gốc). Các component dùng: **Button** (primary/secondary/ghost/danger/success), **IconButton**, **Input** (label/prefix/suffix/locked), **Select**, **Checkbox**, **SegmentedControl** (toneMap theo nghĩa), **StatusBadge** (status khóa màu + nhãn), **ProgressMeter** (value/threshold/unit), **Card** (eyebrow/title/subtitle/actions/accent), **Tag** (tone neutral/brand/accent/outline, mono), **Avatar** (initials, hue tất định theo tên), **Tabs**.

> Lưu ý: trong file prototype, một số control nhỏ (segmented/toggle/preset/calendar, ô danh tính trong bảng) được dựng bằng markup token thay vì component DS — đó là **giới hạn của môi trường prototype** (không truyền được prop hàm/`name` qua wrapper). Khi code thật bằng React, hãy dùng thẳng component DS với `onChange`/`value`/`name` bình thường.

## Assets
- `assets/zenzoo-mark.png` — **emblem ZenZoo** (biểu tượng lá/chim xanh-teal, đã tách nền trong suốt) — dùng ở sidebar + compare bar.
- `assets/zenzoo-logo.png` — **logo đầy đủ** (emblem + chữ "ZenZoo") — dùng cho màn đăng nhập/splash nếu cần.
- Nguồn: do người dùng cung cấp (file gốc `uploads/`), đã crop + làm trong suốt nền.
- **Icon**: bộ **Lucide** (stroke 1.75, bo tròn đầu, `currentColor`). Trong prototype icon được viết inline SVG; khi code thật dùng `lucide-react`. Map: dashboard=Tổng quan, users=Người dùng, shield-check=Kiểm duyệt, credit-card=Thanh toán, activity=IPN, bar-chart-3=Phân tích, scroll-text=Audit, target=Nhiệm vụ, shopping-bag=Cửa hàng, paw-print=Thú cưng, award=Thành tựu, sparkles=AI, bell=Thông báo, key-round=RBAC, user-check=Đội QT, flag=Cờ, lock=GDPR, layers=Bulk, life-buoy=Hỗ trợ.

## Files
- `ZenZoo Admin.dc.html` — toàn bộ thiết kế 20 màn (markup giữa `<x-dc>` + class logic ở cuối). **Nguồn tham chiếu chính.**
- `ZenZoo Login.dc.html` — **trang đăng nhập quản trị** (màn riêng, không sidebar): logo + thẻ login giữa màn, Email + Mật khẩu (có nút hiện/ẩn), Ghi nhớ thiết bị, Quên mật khẩu, nút Đăng nhập (brand) + Đăng nhập với Google Workspace, footer "kết nối được mã hóa". Đơn giản vì chỉ ít quản trị viên dùng. Sau khi đăng nhập → điều hướng vào màn Tổng quan.
- `screenshots/` — ảnh chụp tham chiếu các màn (`00-login`, `01-overview`, `02-users`, `03-analytics`, `03b-analytics-picker` [popover thời gian đang mở], `04-billing`, `05-moderation`, `07-rbac`). Dùng để đối chiếu nhanh; nguồn chính vẫn là file `.dc.html`.
- `assets/zenzoo-mark.png`, `assets/zenzoo-logo.png` — logo.
- `_ds/manlab-design-system-019e1f11-71f2-7be6-9831-c1db2b42c8f8/` — design system: `tokens/*.css` (token nguồn), `styles.css`, `_ds_manifest.json` (danh sách component + namespace), và mã component trong dự án DS gốc.

> Để xem prototype chạy thật (điều hướng, popover thời gian, A/B), mở file `.dc.html` trong công cụ thiết kế gốc — bản trong gói này dùng để **đọc/đối chiếu**.
