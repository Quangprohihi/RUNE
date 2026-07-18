# Báo cáo triển khai (Deployment) — ZenZoo

> Tài liệu nguồn để viết báo cáo đồ án. Toàn bộ hệ thống được triển khai ngày 09–10/07/2026 với tổng chi phí **0 đồng**.

## 1. Mục tiêu

Đưa toàn bộ sản phẩm ZenZoo (ứng dụng Android Pomodoro nuôi thú ảo + trang quản trị + trang giới thiệu) lên hạ tầng cloud công khai, để giảng viên và người dùng truy cập được từ bất kỳ đâu mà không phụ thuộc máy cá nhân của nhóm, với ràng buộc chi phí bằng 0.

## 2. Kiến trúc hệ thống sau triển khai

```
Người dùng ──▶ https://rune.id.vn            Landing page (Render Static Site + CDN)
                     │ nút "Tải cho Android"
                     ▼
              GitHub Releases v1.0.0          APK 68.8MB
                     │ cài đặt
                     ▼
              📱 App Android (Flutter) ──────┐
                                             │ HTTPS REST API
Quản trị viên ─▶ https://admin.rune.id.vn ───┤
              (React+Vite SPA tại /console)  ▼
                                    Backend Node.js/Express + Prisma
                                    (Render Web Service, free tier)
                                             │
                                             ▼
                                    Neon PostgreSQL (Singapore, serverless)
```

- **Tên miền**: `rune.id.vn` — tên miền quốc gia .vn, đăng ký miễn phí 2 năm theo chương trình phổ cập tên miền của VNNIC (Quyết định 826/QĐ-BTTTT) dành cho công dân 18–23 tuổi, qua nhà đăng ký Tenten (eKYC CCCD + xác thực khuôn mặt + ký bản khai điện tử).
- **DNS**: quản lý tại nameserver của Tenten. Bản ghi: `@ A 216.24.57.1` (IP load-balancer chính thức của Render cho apex domain), `admin CNAME rune-api-8cmz.onrender.com`, `www CNAME zenzoo-landing.onrender.com`.
- **CI/CD**: file blueprint `render.yaml` ở gốc repo — mỗi lần `git push` lên nhánh `Rune-Dev` (GitHub `VuDQuang/RUNE`), Render tự build và deploy cả 2 service.
- **Chống "ngủ đông"**: UptimeRobot ping endpoint `/health` mỗi 5 phút (free tier của Render tự tắt sau 15 phút không có truy cập; phản hồi đo được sau khi áp dụng: 274–606ms, không còn cold start 30–60s).

## 3. Các bước đã thực hiện

### Bước 1 — Nghiên cứu phương án tên miền & hosting miễn phí
- Khảo sát các nguồn tên miền miễn phí năm 2026: Freenom (.tk/.ml...) đã đóng cửa từ 2024; các dịch vụ subdomain cho dev (is-a.dev, thedev.id — cấp qua Pull Request GitHub); chương trình quốc gia `.id.vn` miễn phí 2 năm cho công dân 18–23 tuổi.
- Khảo sát hosting free: Cloudflare Pages, Vercel (giới hạn phi thương mại), Netlify (~15GB/tháng), Render (static free + web service free có spin-down), Railway/Fly.io/Koyeb (đã bỏ free tier cho người dùng mới).
- **Quyết định**: domain `rune.id.vn` (0đ, sở hữu thật, có ý nghĩa thương hiệu) + Render cho cả 2 web (một dashboard duy nhất, hỗ trợ apex domain bằng bản ghi A) + Neon cho PostgreSQL.

### Bước 2 — Đăng ký tên miền rune.id.vn (0đ)
- Tạo tài khoản Tenten, hoàn thiện thông tin chủ thể đúng CCCD.
- Xác thực eKYC: chụp CCCD 2 mặt + quét khuôn mặt qua điện thoại.
- Ký chữ ký mẫu điện tử cho bản khai đăng ký tên miền .vn (yêu cầu pháp lý với mọi tên miền .vn).
- Đăng ký combo id.vn giá 0đ (lưu ý thực tế: ô tìm kiếm tên miền thường hiển thị giá bán lẻ 60.000đ/năm — gói 0đ chỉ áp dụng qua luồng chương trình ưu đãi sau khi eKYC được duyệt).
- Kết quả: sở hữu `rune.id.vn` từ 09/07/2026 đến 09/07/2028, hồ sơ VNNIC trạng thái "Đã xác nhận hồ sơ".

### Bước 3 — Chuẩn bị hạ tầng deploy (Infrastructure as Code)
Viết `render.yaml` (blueprint) định nghĩa 2 service và vá các khoảng trống cấu hình:
- Trang admin (`admin-web/`, React+Vite) build ra `backend/admin-web/dist` vốn bị gitignore → đưa lệnh build admin vào build command của Render.
- Database không dùng migration files → dùng `prisma db push` trong pipeline build (đồng nhất với flow docker-compose ở local).
- Bổ sung `.env.example` đầy đủ (JWT, Google OAuth, VietQR, admin...) và pin Node 22 trong `package.json` (khớp image `node:22-alpine` ở local).
- JWT secrets để Render tự sinh ngẫu nhiên (`generateValue: true`); email/mật khẩu admin bắt buộc nhập tay khi tạo blueprint (không dùng giá trị mặc định trong code).
- Thêm redirect `/` → `/console` để truy cập domain admin là vào thẳng trang quản trị.

### Bước 4 — Deploy
- Tạo database PostgreSQL trên **Neon** (region Singapore — gần Việt Nam nhất).
- Trên **Render**: New → Blueprint → chọn repo GitHub → điền biến môi trường → Apply. Render tự build và chạy cả 2 service:
  - `zenzoo-landing` (static): trang giới thiệu (HTML/CSS/JS thuần, không cần build).
  - `rune-api` (Node): backend + trang admin, health check `/health`.
- Kiểm chứng: `/health` trả `{"ok":true}`, `/console` trả trang admin.

### Bước 5 — Chuyển dữ liệu local lên cloud
- Dump toàn bộ PostgreSQL trong Docker local: `pg_dump` (50 users, 50 pets, 171 giao dịch ví, 74 focus sessions, 43 đơn thanh toán, 180 daily tasks...).
- Restore trực tiếp vào Neon qua `psql` chạy trong container. Dashboard admin trên cloud hiển thị đầy đủ dữ liệu thật.

### Bước 6 — Phân phối ứng dụng Android
- Build APK release trỏ về server cloud bằng cơ chế biến build-time của Flutter:
  `flutter build apk --release --dart-define=API_BASE_URL=https://rune-api-8cmz.onrender.com`
- Phát hành APK (68.8MB) lên **GitHub Releases** tag `v1.0.0`.
- Nối nút "Tải cho Android" trên landing page vào link release → người dùng bấm là tải app thật.

### Bước 7 — Trỏ tên miền & xử lý sự cố DNS (phần "thực chiến" nhất)
- Thêm bản ghi `A @ → 216.24.57.1` và `CNAME admin → rune-api-8cmz.onrender.com` tại panel DNS của Tenten; khai custom domain tương ứng trên Render.
- **Sự cố**: nhiều giờ sau, bản ghi vẫn không có hiệu lực. Chẩn đoán bằng `nslookup` trực tiếp vào cả 3 nameserver `ns-b1/b2/b3.tenten.vn`: zone của tên miền **đã tồn tại (có bản ghi SOA) nhưng rỗng** — bản ghi lưu trong panel không được đồng bộ vào zone. Nguyên nhân gốc: trạng thái "Bản khai: chưa có hồ sơ" bị kẹt trên hệ thống DNS của Tenten (lệch với 2 hệ thống khác đã ghi nhận "Đã xác nhận hồ sơ"), chặn pipeline phát hành.
- **Xử lý**: gửi ticket hỗ trợ mô tả chính xác hiện tượng kỹ thuật (zone rỗng, SOA serial, trạng thái lệch giữa các hệ thống); đồng thời chuẩn bị phương án dự phòng chuyển DNS sang Cloudflare (zone + bản ghi đã dựng sẵn ở chế độ DNS-only). Sau khi Phòng kỹ thuật Tenten đồng bộ trạng thái bản khai, nhập lại 2 bản ghi → **publish thành công trong vài phút**.
- Verify domain + cấp SSL tự động trên Render; bổ sung bản ghi `www` theo yêu cầu của Render.
- Kết quả: `https://rune.id.vn` và `https://admin.rune.id.vn` hoạt động với HTTPS.

### Bước 8 — Kiểm thử nghiệm thu toàn hệ thống
Audit 23 hạng mục tự động: endpoint sống (health, redirect, admin, asset, APK), tốc độ phản hồi (không cold start), header CORS, tính nhất quán cấu hình (biến môi trường code đọc vs khai trên Render), kết nối backend↔database (chứng minh qua hành vi 401 của API đăng nhập — truy vấn DB thành công trước khi từ chối), auth production hoạt động đúng (401 chuẩn, không lộ 500). Tất cả hạng mục cốt lõi PASS.

## 4. Bảng dịch vụ & chi phí

| Thành phần | Dịch vụ | Gói | Chi phí |
|---|---|---|---|
| Tên miền `rune.id.vn` (2 năm) | Tenten / chương trình VNNIC | Ưu đãi 18–23 tuổi | 0đ |
| Hosting landing page | Render Static Site | Free | 0đ |
| Hosting backend + admin | Render Web Service | Free (750h/tháng) | 0đ |
| Database PostgreSQL | Neon (Singapore) | Free (0.5GB) | 0đ |
| Giám sát + chống ngủ | UptimeRobot | Free (ping 5 phút) | 0đ |
| Lưu trữ & phát hành APK | GitHub Releases | Free | 0đ |
| SSL/HTTPS (mọi domain) | Render tự cấp (Let's Encrypt) | — | 0đ |
| Email tên miền (tùy chọn) | Tenten Email Server (Startup1, 5GB) | Kèm combo | 0đ |
| **Tổng** | | | **0đ** |

## 5. Khó khăn & bài học

1. **Giá hiển thị ≠ giá chương trình**: ô tìm kiếm tên miền luôn báo giá bán lẻ; gói 0đ chỉ mở khóa sau khi eKYC được duyệt — suýt thanh toán nhầm 112.920đ cho bản đăng ký trả phí của chính tên miền đó.
2. **Bản ghi DNS "lưu được" không có nghĩa là "được phát hành"**: cần kiểm chứng bằng `nslookup`/`Resolve-DnsName` trực tiếp vào nameserver có thẩm quyền, thay vì chỉ tin giao diện panel.
3. **Khi báo lỗi cho nhà cung cấp, mô tả bằng chứng kỹ thuật cụ thể** (zone rỗng, SOA serial, trạng thái lệch giữa các hệ thống) giúp ticket được chuyển đúng bộ phận và xử lý nhanh hơn nhiều so với mô tả chung chung.
4. **Luôn có phương án dự phòng**: zone Cloudflare được dựng sẵn song song trong lúc chờ hỗ trợ — nếu Tenten không xử lý được thì đổi nameserver là chạy ngay, không bị phụ thuộc một nhà cung cấp.
5. **Free tier có điều kiện**: Render free tự tắt sau 15 phút (giải bằng UptimeRobot); Vercel free cấm dùng thương mại; Railway/Fly.io/Koyeb đã bỏ free tier — chọn dịch vụ phải đọc kỹ điều khoản ở thời điểm hiện tại, không tin các bài hướng dẫn cũ.
6. **Tách rủi ro giữa domain và hạ tầng**: APK trỏ thẳng URL Render (không qua domain .vn) — nếu tên miền hết hạn/trục trặc thì web đổi link nhưng app đã cài trên máy người dùng vẫn hoạt động bình thường.

## 6. Kết quả cuối cùng

- 🌐 **https://rune.id.vn** — trang giới thiệu sản phẩm, nút tải APK hoạt động
- 🌐 **https://admin.rune.id.vn** — trang quản trị với dữ liệu thật (50 users)
- 📱 **APK v1.0.0** — cài trên mọi máy Android, kết nối server cloud qua 4G/WiFi bất kỳ
- 🔁 **CI/CD**: push code là tự deploy; ⏱ uptime 100% từ khi triển khai
- 💰 **Tổng chi phí đầu tư và vận hành: 0 đồng**
