# Báo cáo triển khai hệ thống — ZenZoo

Hệ thống ZenZoo được triển khai vận hành chính thức trên hạ tầng cloud từ ngày 09/07/2026, gồm 5 hạng mục: **web giới thiệu**, **web quản trị**, **hệ thống thanh toán tiền thật**, **hệ thống tên miền** và **hạ tầng triển khai (deploy)**.

## 1. Web giới thiệu (Landing page) — https://rune.id.vn

Trang giới thiệu sản phẩm công khai, là điểm chạm đầu tiên của người dùng:

- Xây dựng bằng HTML/CSS/JavaScript, tối ưu tải nhanh, phục vụ qua CDN toàn cầu với chứng chỉ HTTPS/SSL.
- Nội dung: giới thiệu tính năng Deep Focus, linh vật Kiki, bảng giá gói Zen Pro (chuyển đổi giá theo tháng/năm), mục FAQ dạng accordion, hiệu ứng chuyển động (reveal khi cuộn, đảo bay lơ lửng — tôn trọng thiết lập giảm chuyển động của người dùng).
- **Nút "Tải cho Android" hoạt động thật**: liên kết trực tiếp tới bản phát hành chính thức ZenZoo v1.0.0 (file APK 68.8MB) trên GitHub Releases — người truy cập bấm là tải được ứng dụng về máy.
- Truy cập được qua cả `www.rune.id.vn` (tự chuyển hướng về tên miền chính).

📸 Bằng chứng: `report-assets/evidence-landing-hero.png` (màn hình chính), `report-assets/evidence-landing-full.png` (toàn trang).

## 2. Web quản trị (Admin Console) — https://admin.rune.id.vn

Trang quản trị nội bộ dành cho quản trị viên, chạy trên tên miền con riêng:

- Xây dựng bằng **React + Vite** (SPA), giao diện đăng nhập bảo mật riêng (email/mật khẩu quản trị, phiên đăng nhập mã hóa JWT); truy cập tên miền là vào thẳng màn hình quản trị (tự chuyển hướng `/` → `/console`).
- Các phân hệ: **Tổng quan** (số liệu người dùng, doanh thu, biểu đồ), **Quản lý người dùng** (danh sách, trạng thái gói), **Billing/Giao dịch** (danh sách giao dịch thanh toán kèm cổng thanh toán VNPay/VietQR, thao tác xác nhận đơn chuyển khoản).
- Dữ liệu vận hành thực tế trên hệ thống: 50 tài khoản người dùng, 171 giao dịch ví, 43 đơn thanh toán, 74 phiên tập trung.
- API quản trị được bảo vệ bằng lớp xác thực riêng (`/admin/api/*` — truy cập không có token trả về 401).

📸 Bằng chứng: `report-assets/evidence-admin-login.png` (màn hình đăng nhập trên tên miền admin.rune.id.vn). *(Bổ sung thêm: ảnh dashboard sau đăng nhập — nhóm tự chụp bằng tài khoản quản trị.)*

## 3. Hệ thống thanh toán tiền thật

Ứng dụng tích hợp thanh toán thật để nâng cấp gói Zen Pro, với hai cổng:

### 3.1. VietQR (chuyển khoản ngân hàng — luồng chính)
1. Người dùng chọn gói trong app → backend tạo **đơn thanh toán** (payment order) với mã tham chiếu duy nhất.
2. App hiển thị **mã VietQR chuẩn Napas** gắn số tài khoản ngân hàng nhận tiền + số tiền + nội dung chuyển khoản; người dùng quét bằng app ngân hàng bất kỳ và chuyển khoản thật.
3. Quản trị viên đối soát trên **Admin Console** (mục Billing) → xác nhận đơn → hệ thống tự động kích hoạt gói Zen Pro cho tài khoản và ghi nhận giao dịch vào ví.

### 3.2. VNPay (cổng thanh toán trực tuyến)
- Tích hợp đầy đủ luồng VNPay ở backend: tạo URL thanh toán có chữ ký bảo mật (secure hash), xử lý callback/return URL, đối soát trạng thái đơn.
- Trang quản trị hiển thị và phân loại giao dịch theo từng cổng (VNPay/VietQR).

📸 Bằng chứng: *(nhóm tự chụp: màn hình chọn gói + màn hình mã VietQR trong app, và tab Billing trên Admin Console hiển thị danh sách giao dịch.)*

## 4. Hệ thống tên miền

- Đăng ký **tên miền quốc gia `rune.id.vn`** chính chủ qua nhà đăng ký Tenten (GMO-Z.com RUNSYSTEM), đứng tên thành viên nhóm; hoàn tất đầy đủ thủ tục pháp lý theo quy định VNNIC cho tên miền .vn: xác thực danh tính eKYC (CCCD + nhận diện khuôn mặt) và bản khai đăng ký tên miền có chữ ký điện tử — hồ sơ được VNNIC xác nhận. Thời hạn đăng ký: 09/07/2026 → 09/07/2028.
- Quy hoạch tên miền theo chuẩn sản phẩm:
  | Tên miền | Vai trò |
  |---|---|
  | `rune.id.vn` | Web giới thiệu |
  | `www.rune.id.vn` | Chuyển hướng về tên miền chính |
  | `admin.rune.id.vn` | Web quản trị + API backend |
- Tự cấu hình bản ghi DNS tại nameserver của nhà đăng ký: bản ghi `A` cho tên miền gốc trỏ về load-balancer của hạ tầng hosting, bản ghi `CNAME` cho `admin` và `www` trỏ về từng dịch vụ tương ứng.
- Trong quá trình cấu hình, nhóm đã **tự chẩn đoán và phối hợp với Phòng Kỹ thuật nhà đăng ký xử lý một sự cố đồng bộ DNS** (bản ghi lưu tại panel không được phát hành lên nameserver do trạng thái hồ sơ bản khai chưa đồng bộ giữa các hệ thống): kiểm chứng bằng `nslookup` trực tiếp vào cả 3 nameserver có thẩm quyền, xác định zone tồn tại nhưng rỗng, cung cấp bằng chứng kỹ thuật (SOA serial, trạng thái lệch) qua ticket hỗ trợ — sự cố được xử lý và bản ghi phát hành thành công. Toàn bộ tên miền chạy HTTPS với chứng chỉ SSL tự động.
- Đăng ký kèm dịch vụ **Email Server theo tên miền** (hộp thư `admin@rune.id.vn`) phục vụ liên hệ chính thức của sản phẩm.

📸 Bằng chứng: *(nhóm tự chụp: trang quản lý tên miền/bản ghi DNS tại domain.tenten.vn và hồ sơ "Đã xác nhận" tại hosotenmien.com.)*

## 5. Hạ tầng triển khai (Deploy)

Kiến trúc triển khai theo mô hình cloud hiện đại (managed services + CI/CD):

```
Người dùng ──▶ rune.id.vn ────────▶ Landing (Render Static Site + CDN)
                    │ nút tải app
                    ▼
             GitHub Releases ──────▶ APK v1.0.0 (68.8MB)
                    │ cài đặt
                    ▼
             📱 App Android (Flutter) ──┐
                                        │ HTTPS REST API
Quản trị ──▶ admin.rune.id.vn ─────────┤
                                        ▼
                          Backend Node.js/Express + Prisma
                          (Render Web Service)
                                        │
                                        ▼
                          PostgreSQL — Neon (region Singapore)
```

Các hạng mục đã thực hiện:

1. **Hạ tầng dưới dạng mã (IaC)**: viết blueprint `render.yaml` định nghĩa toàn bộ 2 dịch vụ (landing + backend/admin) — build command, health check, biến môi trường; tạo hạ tầng chỉ bằng một thao tác Apply.
2. **CI/CD tự động**: kết nối GitHub (`VuDQuang/RUNE`, nhánh `Rune-Dev`) — mỗi lần push code, hệ thống tự build (cài dependencies → generate Prisma client → compile TypeScript → build trang admin → đồng bộ schema database) và deploy phiên bản mới.
3. **Database cloud**: PostgreSQL trên Neon đặt tại **Singapore** (tối ưu độ trễ cho người dùng Việt Nam); di trú toàn bộ dữ liệu từ môi trường phát triển lên production bằng `pg_dump`/`psql`.
4. **Quản lý cấu hình & bảo mật**: toàn bộ khóa bí mật (JWT secrets, Google OAuth, thông tin thanh toán) đưa vào biến môi trường trên hạ tầng — không nằm trong mã nguồn; JWT secrets sinh ngẫu nhiên; tài khoản quản trị đặt riêng cho production.
5. **Phát hành ứng dụng**: build APK release trỏ về server production bằng cơ chế cấu hình build-time của Flutter (`--dart-define=API_BASE_URL=...`); phát hành qua GitHub Releases (tag `v1.0.0`) và gắn vào nút tải trên landing.
6. **Giám sát vận hành**: cấu hình UptimeRobot giám sát endpoint `/health` chu kỳ 5 phút — vừa cảnh báo sự cố, vừa duy trì server luôn sẵn sàng; độ trễ phản hồi đo được 274–606ms, uptime 100% từ khi triển khai.
7. **Kiểm thử nghiệm thu**: audit 23 hạng mục trước bàn giao — endpoint sống, chuyển hướng, tài nguyên tĩnh, header CORS, kết nối backend–database, lớp xác thực production, tính nhất quán cấu hình — đạt toàn bộ.

📸 Bằng chứng: `report-assets/evidence-github-release.png` (bản phát hành APK chính thức). *(Bổ sung thêm: ảnh dashboard Render hiển thị 2 service trạng thái Live và ảnh trang Custom Domains đã Verified — nhóm tự chụp trong tài khoản Render.)*

## 6. Kết quả bàn giao

| Hạng mục | Địa chỉ | Trạng thái |
|---|---|---|
| Web giới thiệu | https://rune.id.vn | ✅ Vận hành, HTTPS |
| Web quản trị | https://admin.rune.id.vn | ✅ Vận hành, HTTPS |
| Ứng dụng Android | GitHub Releases v1.0.0 — tải từ landing | ✅ Phát hành |
| API backend | https://admin.rune.id.vn (cùng dịch vụ) | ✅ Vận hành, giám sát 5 phút/lần |
| Thanh toán tiền thật | VietQR (luồng chính) + VNPay | ✅ Hoạt động, đối soát qua Admin Console |
| Tên miền + SSL | rune.id.vn / www / admin | ✅ Chính chủ, hồ sơ VNNIC xác nhận |
