# ZenZoo CP1 Implementation Summary

## Mục Tiêu

ZenZoo là app Flutter MVP offline dựa trên tài liệu `Check point 1 - Remake.pdf` và thiết kế Figma. Trọng tâm của CP1 là chứng minh core loop: Pomodoro focus, pet companion, token, streak, pet care và shop đơn giản.

Phạm vi đã chọn:

- Mock login, không auth thật.
- Offline/local-first bằng `shared_preferences`.
- 5 màn core: Login, Home, Focus, Pet Profile, Shop.
- UI bám các frame Figma chính.
- Chưa làm selective app blocking, Firebase, online room, guild, premium payment.

## Tech Stack

- Flutter / Dart.
- `provider` cho state management.
- `shared_preferences` cho local persistence.
- `google_fonts` để dùng style gần Montserrat Alternates trong Figma.
- `intl` để hỗ trợ format ngày/streak.

## Cấu Trúc Chính

Các phần đã tạo trong `lib/`:

- `app.dart`: cấu hình `MaterialApp`, theme và route.
- `main.dart`: khởi tạo `SharedPreferences`, repositories và providers.
- `core/theme/`: màu, text style, theme chung.
- `core/constants/`: hằng số Pomodoro, token, reward, streak.
- `models/`: `UserProfile`, `Pet`, `FocusSession`, `ShopItem`.
- `data/repositories/`: local repositories đọc/ghi dữ liệu.
- `providers/`: user, token, pet, streak, focus, shop state.
- `routes/app_routes.dart`: named routes.
- `presentation/`: các màn Login, Home, Focus, Pet Profile, Shop.

## Tính Năng Đã Làm

### Login

- Mock UI theo Figma `Log IN`.
- Nhập email hoặc bấm social login đều lưu user local và chuyển vào Home.
- Không dùng Firebase/Auth SDK.

### Home

- Bám Figma Homepage.
- Có streak, token, VIP token mock, mail icon, timer card, camera/settings buttons, bottom navigation.
- Đã thay scene bằng asset Figma tổng `home_scene.png`, nên hươu cao cổ, ếch, cáo, chim nằm đúng bố cục Figma thay vì emoji đặt lệch.

### Focus

- Bám Figma Frame `Your Process`.
- Có vòng timer, partner panel, reward claim box.
- Pomodoro hiện dùng 25 phút theo logic app, nhưng UI idle hiển thị style giống Figma.
- Timer đang chạy đã được sửa để không wrap/overflow với text dạng `24:59`.
- Claim reward chỉ bật khi hoàn thành focus.

### Pet Profile

- Bám Figma Pet Profile.
- Có fox lớn bên phải, forest background bên trái, skill card, action buttons, status card 2 cột, achievement card.
- Feed/Play/Pet tiêu token và cập nhật stat pet.
- Pet stat clamp 0-100.

### Shop

- Shop Potions/Food với grid item.
- Mua item trừ token, đánh dấu `Owned`, áp effect vào pet.
- Đã sửa overflow card trên emulator.

## Assets Figma Đã Đưa Vào

Các asset nằm trong `assets/images/`:

- `fox.png`: pet fox từ Figma.
- `home_scene.png`: scene đảo Home đầy đủ, gồm hươu cao cổ, ếch, cáo, chim.
- `habitat.png`: island/habitat gốc.
- `profile_forest.png`: forest nền cho Pet Profile.
- `achievement_medal.png`: huy hiệu Achievement.

`pubspec.yaml` đã khai báo:

```yaml
flutter:
  assets:
    - assets/images/
```

## State Và Persistence

Đang lưu local bằng `shared_preferences`:

- User profile.
- Pet stats.
- Token.
- Streak.
- Last focus date.
- Sessions today.
- Total focus minutes.
- Owned shop items.

Soft-streak:

- Ngày đầu focus thì tăng streak.
- Nếu bỏ nhiều ngày thì giảm nhẹ, không reset về 0.

## Kiểm Tra Đã Chạy

Đã chạy nhiều lần:

```powershell
flutter analyze
flutter test
flutter run -d emulator-5554
```

Kết quả hiện tại:

- `flutter analyze`: pass.
- `flutter test`: pass.
- Emulator Pixel 9a: app build/install/run được.
- Đã kiểm tra Home, Focus, Pet Profile, Shop.
- Các overflow chính đã sửa: Shop card, Home timer, Pet Profile skill/status/achievement, Focus timer text.

Một số file screenshot kiểm tra đã tạo trong project:

- `z_home_scene_corrected.png`
- `z_focus_figma_corrected.png`
- `z_profile_figma_final_clean.png`

## Lưu Ý Hiện Tại

- UI đã bám Figma tốt hơn nhưng chưa phải 1:1 tuyệt đối ở mọi chi tiết font/icon.
- Một số icon vẫn dùng Material Icons thay vì asset icon Figma.
- `Focus` giữ logic 25 phút theo tài liệu CP1, dù frame Figma hiển thị `20’`.
- Premium, Guild, Online Room, AI companion, notification thật và app blocking chưa nằm trong CP1.

## Gợi Ý Bước Tiếp Theo

- Export thêm icon/token/fire/zap từ Figma để thay Material Icons.
- Chuẩn hóa kích thước theo responsive scale cho nhiều loại màn hình.
- Thêm chế độ dev/test timer ngắn để demo nhanh claim reward.
- Làm History/Task/Habitat/Settings nếu cần mở rộng checkpoint sau.
