# Báo cáo dự án — ZenZoo

**ZenZoo** là ứng dụng hỗ trợ tập trung học tập/làm việc theo cơ chế Pomodoro, kết hợp nuôi thú cưng ảo  làm động lực — *không cày cuốc, không pay-to-win*. Sản phẩm đã vận hành thật: app Android, backend + web quản trị, web giới thiệu tại **https://rune.id.vn**, kèm **thanh toán tiền thật** để nâng cấp gói Zen Pro.


## Thanh toán tiền thật

Người dùng trả tiền thật để nâng cấp **Zen Pro** (29.000đ/tháng · 279.000đ/năm), qua **2 cổng**:

- **VietQR (luồng chính, đang chạy thật):** app tạo đơn + sinh mã QR chuẩn Napas (số tài khoản + số tiền + nội dung) → người dùng quét app ngân hàng chuyển khoản → **quản trị viên đối soát và xác nhận trên Admin Console** → hệ thống tự kích hoạt gói.
- **VNPay (đã tích hợp đầy đủ):** tạo URL thanh toán có **chữ ký HMAC-SHA512**, xử lý callback **IPN server-to-server** (đối chiếu số tiền, chống trùng) và return về app. Sẵn sàng bật khi nạp khóa merchant.

Kích hoạt gói chạy trong transaction (đặt gói `premium`/`active`, hạn theo số ngày, ghi nhật ký + thông báo). Bảo mật: ký/verify HMAC-SHA512, đối chiếu số tiền, chống xử lý trùng, secret để ở biến môi trường.

## Kết quả

| Hạng mục | Địa chỉ | Trạng thái |
|---|---|---|
| Web giới thiệu | https://rune.id.vn | ✅ Vận hành, HTTPS |
| Web quản trị | https://admin.rune.id.vn | ✅ Vận hành, HTTPS |
| App Android | GitHub Releases v1.0.0 | ✅ Phát hành |
| Thanh toán tiền thật | VietQR (chính) + VNPay (đã tích hợp) | ✅ VietQR hoạt động |
| Tên miền + SSL | rune.id.vn / www / admin | ✅ Chính chủ, VNNIC |
