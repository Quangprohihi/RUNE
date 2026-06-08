# ZenZoo Full Conversation Context

File này ghi lại đầy đủ bối cảnh làm việc của dự án ZenZoo từ đầu cuộc trò chuyện đến hiện tại. Mục đích là để khi đưa file này cho AI đọc lại, AI có thể hiểu dự án đã làm gì, quyết định kỹ thuật nào đã được chốt, phần nào đã code, phần nào chưa làm, lỗi nào đã gặp, và hướng tiếp theo nên là gì.

## 1. Mục Tiêu Dự Án

ZenZoo là ứng dụng mobile hỗ trợ học tập/làm việc tập trung bằng Pomodoro, kết hợp pet companion và gamification nhẹ.

Ý tưởng chính:

- User nhập mục tiêu học/làm.
- App gợi ý cách focus hợp lý.
- User chạy focus timer/Pomodoro.
- Hoàn thành focus nhận token/EXP.
- Pet phát triển, companion/shop tạo động lực.
- History/analytics giúp user thấy tiến độ tập trung.

App không nên trở thành app dạy học chi tiết. Vai trò đúng của app là **Focus Coach / Study Focus Planner**, không phải **AI Tutor**.

Ví dụ đúng scope:

- User nhập `Tôi muốn học tốt môn Toán`.
- App không dạy công thức Toán.
- App nhận diện đây là mục tiêu rộng, đề xuất `Practice Focus`, 45 phút, chia block chuẩn bị/làm bài/review lỗi.

Ví dụ không đúng scope giai đoạn 1:

- App tự dạy Toán từng công thức.
- App tạo giáo trình 14 ngày quá chi tiết như giáo viên.
- App deepfake/AI tutor toàn diện.

## 2. Tài Liệu Và Thiết Kế Đã Dùng

Nguồn yêu cầu ban đầu:

- File checkpoint/document bài tập do user gửi.
- Figma `Zenzoo Demo Figma`.
- File mô tả sản phẩm: `docs/rune.md`.
- Các trao đổi liên tục với user về flow, MVP, AI, Pomodoro, Shop, Companion.

Các node Figma đã được tham khảo nhiều lần:

- Login.
- Home page.
- Pet Profile.
- Focus / Your Process.
- Shop.
- Premium / Go Pro.
- Companion/Home island.

Figma có vai trò làm chuẩn UI, nhưng code được điều chỉnh theo Flutter hiện có và khả năng MVP.

## 3. Tech Stack Đã Chốt

Frontend:

- Flutter.
- Dart.
- Provider state management.
- SharedPreferences cho local cache/user state.
- HTTP package gọi backend.

Backend:

- Node.js.
- Express.
- TypeScript.
- Prisma ORM.
- PostgreSQL.

Infrastructure:

- Docker Compose cho PostgreSQL, Adminer, backend container.
- Local dev có thể chạy backend bằng `npm run dev`.

API flow:

```text
Flutter app -> ApiClient -> Express API -> Prisma -> PostgreSQL
```

User identification hiện tại:

- Chưa có auth thật.
- Dùng demo login bằng email.
- Backend trả user id.
- Flutter lưu user profile local và gửi `x-user-id` cho API.

## 4. Các Quyết Định Quan Trọng Đã Chốt

### 4.1 Mobile trước, không web trước

User đang có project Flutter, nên giai đoạn 1 làm mobile app trước. Web app không phải ưu tiên hiện tại.

### 4.2 MVP trước, AI thật để sau

AI thật chưa cần ở giai đoạn đầu. Giai đoạn 1 dùng rule-based logic để demo tốt và kiểm soát được.

AI sau này nên đóng vai trò:

- Focus advisor.
- Cá nhân hóa theo lịch sử focus.
- Gợi ý mục tiêu tiếp theo.
- Không biến thành giáo viên dạy học toàn diện.

### 4.3 PostgreSQL + Docker là hợp lý

User chọn PostgreSQL + Docker thay vì Firebase. Backend Node/Express/Prisma đã được tạo để thay mock data bằng real data.

### 4.4 App chính là Focus Coach

Sau nhiều trao đổi, đã chốt:

- App không dạy học chi tiết.
- App phân tích mục tiêu học ở mức focus.
- App gợi ý thời lượng, mode, Pomodoro, thứ tự tập trung.
- App dùng pet/reward để tạo động lực.

### 4.5 Companion system

Mặc định user chỉ có Kiki/cáo.

Các companion khác:

- Eagle.
- Frog.
- Giraffe.

Chỉ xuất hiện trên Home island và mở khóa trong Set Timer sau khi mua trong Shop.

## 5. Kiến Trúc Hiện Tại

Các route chính nằm trong:

- `lib/routes/app_routes.dart`

Các màn hiện có:

- `LoginScreen`
- `HomeScreen`
- `SetFocusTimerScreen`
- `FocusScreen`
- `FocusSummaryScreen`
- `PetProfileScreen`
- `ShopScreen`
- `DailyTasksScreen`
- `NotificationsScreen`
- `HistoryScreen`
- `AnalyticsScreen`
- `SettingsScreen`
- `PremiumScreen`

Tổng hiện tại có khoảng 13 màn hình chính.

## 6. Backend Đã Làm

Backend chính nằm ở:

- `backend/src/server.ts`
- `backend/src/prisma.ts`
- `backend/prisma/schema.prisma`
- `backend/prisma/seed.ts`

### 6.1 Prisma/env fix

Đã gặp lỗi:

```text
SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string
```

Nguyên nhân:

- `server.ts` import Prisma trước khi `dotenv.config()` chạy.
- Khi `PrismaPg` tạo adapter, `process.env.DATABASE_URL` có thể là `undefined`.

Fix đã làm:

- Thêm `import 'dotenv/config';` vào `backend/src/prisma.ts`.

Ý nghĩa:

- Prisma client tự load `.env` trước khi tạo connection.
- UI login không cần password, vì lỗi này là password PostgreSQL, không phải password user.

### 6.2 Demo auth

Endpoint:

- `POST /auth/demo-login`
- `GET /me/bootstrap`

Chức năng:

- Tạo hoặc lấy user theo email.
- Tạo default pet/wallet/streak/settings/subscription.
- Trả bootstrap data cho Flutter.

### 6.3 Focus sessions

Endpoint:

- `POST /focus-sessions/start`
- `POST /focus-sessions/:id/complete`

Chức năng:

- Tạo focus session.
- Complete session.
- Tính reward token/EXP.
- Cập nhật pet EXP/stat.
- Cập nhật streak.
- Cập nhật daily task progress.
- Tạo activity event và notification.

### 6.4 Daily tasks

Endpoint:

- `GET /daily-tasks/today`
- `POST /daily-tasks/:id/claim`

Đã có task template và user daily task.

Task đã được chỉnh để có nhiệm vụ liên quan Pomodoro:

- `Complete 1 Pomodoro`
- task type `pomodoro_count`

### 6.5 Notifications và Activity History

Endpoint:

- `GET /notifications`
- `PATCH /notifications/:id/read`
- `GET /activity-events`

Đã chuyển từ mock sang data thật backend.

Activity focus completed có metadata:

- `focusSessionId`
- `goalLabel`
- `plannedMinutes`
- `pomodoroCount`
- `category`
- `rewardTokens`
- `rewardExp`

### 6.6 Shop

Endpoint:

- `GET /shop/items`
- `POST /shop/items/:id/buy`

Shop item thật trong database.

Đã có các item:

- Energy Potion
- Mood Booster
- Fresh Berries
- Cozy Pet
- Eagle companion
- Frog companion
- Giraffe companion

Companion purchase:

- Trừ token.
- Ghi vào `user_inventory`.
- Không cộng stat pet thật để tránh bonus ảnh hưởng balance.
- Nếu companion đã mua rồi, backend không trừ token lần nữa.

### 6.7 Settings

Endpoint:

- `GET /me/settings`
- `PATCH /me/settings`

Settings:

- soundEnabled
- vibrationEnabled
- focusReminders

### 6.8 Subscription/Premium

Endpoint:

- `GET /me/subscription`
- `POST /me/subscription/demo-upgrade`

Hiện chỉ là demo upgrade, chưa payment thật.

### 6.9 Analytics

Endpoint:

- `GET /analytics/summary`

Trả:

- total focus minutes.
- sessions today.
- pomodoros today/week.
- current/best streak.
- focus by day.
- category breakdown.

### 6.10 Focus Intent Analyzer

Endpoint mới:

- `POST /focus-plans/analyze`

Đây là giai đoạn 1 cho chức năng chính học/focus.

Request:

- `goal`
- `selectedMinutes`
- `selectedTask`

Response:

- `normalizedLabel`
- `subject`
- `subjects`
- `action`
- `topic`
- `clarityLevel`
- `focusMode`
- `recommendedMinutes`
- `pomodoroCount`
- `advice`
- `steps`
- `warnings`

Rule-based analyzer hiện nhận diện:

- Math / Toán
- English / Tiếng Anh
- Literature / Ngữ Văn
- Code
- General

Nhận diện action:

- study
- review
- practice
- exam
- write
- read

Nhận diện clarity:

- vague
- medium
- detailed

Test API đã chạy:

- `Toi muon hoc tot mon Toan`
  - Math
  - vague
  - Practice Focus
  - 45 min
- `Toi muon on Toan chuong dao ham`
  - Math
  - medium
  - Review + Practice
  - 45 min
- `Toi muon lam 20 bai dao ham trong 1 tieng`
  - Math
  - detailed
  - Practice Focus
  - 60 min

## 7. Database Models Chính

Trong `backend/prisma/schema.prisma` đã có:

- User
- Pet
- Wallet
- WalletTransaction
- FocusSession
- UserStreak
- TaskTemplate
- UserDailyTask
- DailyMilestone
- UserDailyMilestone
- ShopItem
- UserInventory
- ActivityEvent
- Notification
- UserSettings
- Subscription

Hiện `FocusSession` lưu:

- label
- plannedMinutes
- actualSeconds
- status
- startedAt
- completedAt
- claimedAt

Chưa thêm `metadata` cho focus session. Nếu sau này muốn lưu full FocusPlan thì nên thêm `metadata Json` ở giai đoạn 2.

## 8. Frontend Đã Làm

### 8.1 Login

File:

- `lib/presentation/login/login_screen.dart`

Đã có:

- UI login theo Figma.
- Nhập email.
- Continue gọi demo login backend.
- Social buttons UI.

Chưa có:

- Google/Facebook/Apple auth thật.
- Password field. Không cần password trong demo flow.

### 8.2 Home

File:

- `lib/presentation/home/home_screen.dart`

Đã có:

- UI Home theo Figma.
- Streak.
- Wallet resource chips.
- Timer card.
- Mail icon vào notifications.
- Camera/settings buttons.
- Bottom nav.
- Tap timer card để vào Focus đang chạy hoặc Set Timer nếu idle.
- Island dùng `home_habitat_figma.png` + overlay companion thật theo inventory.

Companion logic:

- Kiki luôn hiện.
- Eagle chỉ hiện sau khi mua.
- Frog chỉ hiện sau khi mua.
- Giraffe chỉ hiện sau khi mua.

Đã sửa vị trí:

- Frog là nguyên con trên lá súng, không phải icon đầu ếch.
- Giraffe đứng đảo dưới bên trái đúng Figma hơn.
- Eagle đã chỉnh xuống để chân bám đỉnh núi trái.

Đã thêm try/catch quanh `ShopProvider.loadCatalog()` để Home không crash khi backend DB chưa sẵn sàng.

### 8.3 Set Focus Timer

File:

- `lib/presentation/timer/set_focus_timer_screen.dart`

Đã có:

- Goal input.
- Task chips: Study / Write / Break.
- Duration presets: 25 / 45 / 50.
- Timer dial.
- Companion selector.
- Focus Plan Preview.
- Analyze Focus.
- Apply Plan.
- Potential rewards bar.
- Start Focus.

Focus Plan Preview hiện đọc từ:

- `FocusPlanProvider`
- `FocusPlan`
- API `/focus-plans/analyze`

Nếu backend lỗi:

- Provider fallback local để UI vẫn dùng được.

Apply Plan:

- Set `_selectedMinutes = plan.recommendedMinutes`.
- Set `_appliedPlan`.
- Start Focus dùng `plan.normalizedLabel`.

Lưu ý:

- Nếu plan trả 60 phút nhưng duration presets chỉ có 25/45/50, Timer dial vẫn hiển thị 60 phút được vì `_selectedMinutes` là int tự do.

### 8.4 Focus / Your Process

Files:

- `lib/presentation/focus/focus_screen.dart`
- `lib/providers/focus_provider.dart`

Đã có:

- Timer running screen.
- Focus phase.
- Break phase.
- Done phase.
- Start break sau focus.
- Claim reward.
- Return focus if session active.
- Focus summary navigation.

Pomodoro:

- plannedFocusMinutes <= 25 -> 1 Pomodoro.
- > 25 -> 2 Pomodoros.

Test mode:

- Có test duration 3s để demo nhanh.
- UI vẫn hiển thị planned minutes, nhưng thực tế chạy nhanh nếu `AppConstants.useTestFocusDuration` bật.

### 8.5 Focus Summary

File:

- `lib/presentation/focus/focus_summary_screen.dart`

Đã có:

- Summary sau khi claim reward.
- Label.
- Planned minutes.
- Category.
- Pomodoro count.
- Reward.
- Pet/wallet/streak.
- Link Home/Analytics.

### 8.6 Pet Profile

File:

- `lib/presentation/pet/pet_profile_screen.dart`

Đã có:

- UI theo Figma.
- Kiki fox lớn.
- Forest background.
- Skill card.
- Feed/Play/Pet.
- Status stats.
- Achievement section.

Pet actions dùng token thật qua backend/local provider tùy flow.

### 8.7 Shop

File:

- `lib/presentation/shop/shop_screen.dart`

Đã có:

- Tabs: Potions / Food / Pets.
- Cards item.
- Buy/Owned.
- Token header.
- Companion image thật từ Figma.

Companion items:

- Eagle.
- Frog.
- Giraffe.

Đã test:

- Mua Frog -> token giảm, Owned, Home hiện Frog, Set Timer unlock Frog.
- Mua Giraffe -> token giảm, Owned, Home hiện Giraffe đúng vị trí.
- Mua Eagle -> Home hiện Eagle, đã chỉnh vị trí.

### 8.8 Daily Tasks

File:

- `lib/presentation/tasks/daily_tasks_screen.dart`

Đã có:

- Daily task UI.
- Data thật từ backend.
- Task progress.
- Claim reward.
- Milestones.

Đã sửa overflow trước đó.

### 8.9 Notifications

File:

- `lib/presentation/notifications/notifications_screen.dart`

Đã chuyển từ mock sang backend thật.

### 8.10 Activity History

File:

- `lib/presentation/history/history_screen.dart`

Đã có:

- Activity events từ backend.
- Focus completed metadata chips.
- Category.
- Pomodoro count.
- Reward token/EXP.
- Link View Stats sang Analytics.

### 8.11 Analytics / Focus Stats

File:

- `lib/presentation/analytics/analytics_screen.dart`

Đây là màn tự thêm, không chắc có trong Figma ban đầu.

Đã có:

- Total focus.
- Sessions today.
- Pomodoros today/week.
- Streak.
- 7-day chart.
- Category breakdown.

### 8.12 Settings

File:

- `lib/presentation/settings/settings_screen.dart`

Đã có:

- User info.
- Settings toggles.
- Backend status.
- Logout.
- Link Premium.

### 8.13 Premium / Go Pro

File:

- `lib/presentation/premium/premium_screen.dart`

Đã refactor để bám Figma Go Pro:

- Header `ELEVATE YOUR FOCUS`.
- Billing toggle.
- Standard/Zen Pro/Master plan cards.
- Demo upgrade button.

Chưa có payment thật.

## 9. Models/Providers Đã Thêm

Models:

- `UserProfile`
- `Pet`
- `Wallet`
- `ShopItem`
- `ActivityEvent`
- `AppNotification`
- `DailyTask`
- `DailyMilestone`
- `UserSettings`
- `Subscription`
- `AnalyticsSummary`
- `FocusSummary`
- `FocusPlan`

Providers:

- `UserProvider`
- `TokenProvider`
- `PetProvider`
- `StreakProvider`
- `FocusProvider`
- `ShopProvider`
- `DailyTaskProvider`
- `ActivityProvider`
- `NotificationProvider`
- `SettingsProvider`
- `AnalyticsProvider`
- `SubscriptionProvider`
- `FocusPlanProvider`

## 10. Assets Đã Dùng

Trong `assets/images/`:

- `fox.png`
- `habitat.png`
- `home_scene.png`
- `home_habitat_figma.png`
- `companion_eagle.png`
- `companion_frog.png`
- `companion_giraffe.png`
- `profile_forest.png`
- `achievement_medal.png`

`pubspec.yaml` đã khai báo:

```yaml
assets:
  - assets/images/
```

## 11. Các Lỗi Đã Gặp Và Đã Sửa

### 11.1 Flutter overflow

Đã gặp overflow ở:

- Login.
- Daily Tasks.
- Shop.
- Home.
- Pet Profile.
- Set Focus Timer.
- Focus.
- Premium title.

Đã sửa bằng:

- Scroll view.
- FittedBox.
- Expanded.
- Giảm font/spacing.
- Chỉnh card ratio/height.

### 11.2 Backend Prisma env/password

Lỗi:

```text
client password must be a string
```

Fix:

- `backend/src/prisma.ts` import `dotenv/config`.

### 11.3 Docker/DB chưa chạy

Nếu Docker Desktop/Postgres chưa chạy:

- Login/backend có thể fail.
- Shop catalog có thể fail.
- Home trước đây crash vì `ShopProvider.loadCatalog()`.

Đã thêm try/catch để Home vẫn usable hơn.

Để chạy full data thật:

```powershell
docker compose up
```

Hoặc chạy backend riêng:

```powershell
cd backend
npm run dev
```

Nhưng backend thật vẫn cần PostgreSQL.

### 11.4 ADB input text không nhập vào Flutter TextField

Khi test Focus Intent trên emulator, ADB `input text` không inject vào Flutter TextField dù field focus. Vì vậy không chụp đủ 3 case UI bằng tự động.

API analyzer đã test bằng command.

### 11.5 Android emulator không hiện trong Flutter devices

Đã hướng dẫn user:

- Mở emulator trước.
- `flutter devices`
- `flutter emulators`
- `flutter emulators --launch Pixel_9a`
- `flutter run -d emulator-5554`

### 11.6 Emulator quá to

Đã hướng dẫn:

- Đóng Extended Controls.
- Kéo cửa sổ emulator.
- Bỏ device skin nếu có.
- Tạo device nhỏ hơn nếu cần.

### 11.7 Git CRLF warning

Git warning:

```text
LF will be replaced by CRLF
```

Đã giải thích:

- Không ảnh hưởng commit/push.
- Chỉ là warning line ending Windows.
- Có thể thêm `.gitattributes` sau nếu muốn.

### 11.8 Lỡ add docs vào git

Đã hướng dẫn:

```powershell
git restore --staged docs/...
git rm --cached docs/...
```

Và thêm vào `.gitignore` nếu muốn giữ local nhưng không push.

## 12. Test Đã Chạy

Đã chạy nhiều lần:

```powershell
dart format lib test
flutter analyze
flutter test
npm run build
npm run prisma:seed
```

Kết quả gần đây:

- `flutter analyze`: pass.
- `flutter test`: pass.
- `npm run build`: pass.

Đã test emulator nhiều flow:

- Home.
- Shop companion.
- Buy Frog.
- Buy Giraffe.
- Buy Eagle.
- Home companion visibility.
- Set Timer companion unlock.
- Focus Plan Preview UI xuất hiện.

Lưu ý:

- Một số screenshot test đã bị xóa sau khi dùng để tránh rác.
- Hiện vẫn còn file `focus_intent_buttons.png` trong project, là screenshot UI Focus Plan Preview.

## 13. Đánh Giá Mức Độ Hoàn Thiện

Nếu tính MVP học/focus cá nhân:

- Khoảng 75-80%.

Đã đủ để demo:

- Login demo.
- Home.
- Set Focus Timer.
- Focus timer.
- Reward.
- Pet.
- Shop.
- Companion unlock.
- Tasks.
- History.
- Notifications.
- Analytics.
- Settings.
- Premium demo.
- Focus Intent analyzer giai đoạn 1.

Nếu tính toàn bộ vision trong `docs/rune.md`:

- Khoảng 45-55%.

Vì còn nhiều scope lớn chưa làm:

- App blocking.
- Focus mềm/nghiêm túc.
- Weekly/monthly goals.
- Online room.
- Guild.
- Farm chung.
- Season pass.
- Event theo mùa.
- AI pet dialogue thật.
- Mini-game break.
- Advanced stats.

## 14. So Sánh Với App Trên Mạng

### 14.1 Forest

Forest có:

- Timer.
- Trồng cây.
- Nếu rời app thì cây chết.
- App blocking/deep focus.
- Focus stats.
- Group focus.
- Shop cây.

ZenZoo hiện có:

- Timer.
- Pet/shop/reward.
- Stats cơ bản.
- Companion unlock.

ZenZoo còn thiếu so với Forest:

- App blocking mạnh.
- Allowlist.
- Group focus.
- Loss aversion mechanic kiểu cây chết.

### 14.2 Study Bunny

Study Bunny có:

- Pet bunny.
- Timer.
- Coins.
- Shop/decor.
- To-do.
- Flashcards.
- Study tracker.

ZenZoo gần giống Study Bunny nhất.

ZenZoo mạnh ở:

- Companion đa dạng.
- Backend thật.
- Focus Coach analyzer.
- Pet island Figma đẹp hơn nếu polish tiếp.

ZenZoo còn thiếu:

- Flashcards.
- Study tracker sâu.
- Decor room/farm.

### 14.3 Focus To-Do

Focus To-Do có:

- Pomodoro.
- Tasks.
- Subtasks.
- Projects.
- Estimated pomodoro.
- Reports.
- App blocking.
- Cross-device sync.

ZenZoo còn thiếu:

- Task management sâu.
- Subtasks.
- Priority.
- Reminders.
- Calendar/project view.

### 14.4 TickTick

TickTick có:

- To-do/calendar/habit.
- Pomodoro.
- Natural language parsing.
- Stats.
- Task-linked focus sessions.

ZenZoo không nên cạnh tranh trực tiếp productivity suite như TickTick.

ZenZoo khác biệt ở:

- Pet companion.
- Gamified focus.
- Student-friendly, cute UX.
- Focus Coach theo mục tiêu học.

## 15. Màn Hình Còn Thiếu Nếu Theo Full Vision

Các màn/chức năng lớn còn thiếu:

1. App Blocking / Allowlist setup.
2. Focus Mode screen: Focus mềm / Focus nghiêm túc.
3. Weekly/Monthly Goal screen.
4. Goal Progress dashboard.
5. Online Room public.
6. Private Room management.
7. Guild / Farm chung.
8. Season Pass.
9. Seasonal Event.
10. Mini-game Break.
11. AI Pet Dialogue / Coach settings.
12. Advanced Analytics / Heatmap.
13. App whitelist/preset management.
14. Decor/Farm customization.

## 16. Ưu Tiên Tiếp Theo Được Khuyên Làm

Thứ tự nên làm tiếp:

1. Hoàn thiện Focus Intent / Focus Coach.
   - Polish UI.
   - Test nhập tiếng Việt thật bằng tay.
   - Save plan metadata nếu cần.

2. App Blocking + Allowlist.
   - Đây là core trong `docs/rune.md`.
   - Là điểm khác biệt thật với timer thường.

3. Weekly/Monthly Goals.
   - User đặt mục tiêu học tuần/tháng.
   - App chia tiến độ theo ngày.

4. Analytics theo môn/mục tiêu.
   - Heatmap.
   - Category detail.
   - Goal progress.

5. Polish UI theo Figma.
   - Home.
   - Set Timer.
   - Focus.
   - Shop/Pet.

6. Social/online sau.
   - Room.
   - Guild.
   - Farm.

7. AI thật cuối cùng.
   - Sau khi rule-based Focus Coach ổn.

## 17. Các File Quan Trọng Cần Đọc Khi Tiếp Tục

Tài liệu:

- `docs/rune.md`
- `docs/zenzoo_full_conversation_context.md`
- `docs/zenzoo_cp1_implementation_summary.md`

Backend:

- `backend/src/server.ts`
- `backend/src/prisma.ts`
- `backend/prisma/schema.prisma`
- `backend/prisma/seed.ts`
- `docker-compose.yml`

Flutter core:

- `lib/main.dart`
- `lib/routes/app_routes.dart`
- `lib/data/api/api_client.dart`

Focus:

- `lib/presentation/timer/set_focus_timer_screen.dart`
- `lib/presentation/focus/focus_screen.dart`
- `lib/presentation/focus/focus_summary_screen.dart`
- `lib/providers/focus_provider.dart`
- `lib/models/focus_plan.dart`
- `lib/providers/focus_plan_provider.dart`

Home/Pet/Shop:

- `lib/presentation/home/home_screen.dart`
- `lib/presentation/pet/pet_profile_screen.dart`
- `lib/presentation/shop/shop_screen.dart`
- `lib/providers/shop_provider.dart`
- `lib/models/shop_item.dart`

Real data:

- `lib/presentation/tasks/daily_tasks_screen.dart`
- `lib/presentation/notifications/notifications_screen.dart`
- `lib/presentation/history/history_screen.dart`
- `lib/presentation/analytics/analytics_screen.dart`

Settings/Premium:

- `lib/presentation/settings/settings_screen.dart`
- `lib/presentation/premium/premium_screen.dart`
- `lib/providers/settings_provider.dart`
- `lib/providers/subscription_provider.dart`

## 18. Chạy Project

Nếu dùng Docker full stack:

```powershell
docker compose up
```

Nếu chạy backend local:

```powershell
cd backend
npm run dev
```

Backend cần PostgreSQL đang chạy với:

```text
DATABASE_URL=postgresql://zenzoo:zenzoo_dev@localhost:5432/zenzoo?schema=public
```

Flutter:

```powershell
flutter devices
flutter run
```

Hoặc:

```powershell
flutter run -d emulator-5554
```

Nếu emulator chưa hiện:

```powershell
flutter emulators
flutter emulators --launch Pixel_9a
flutter devices
```

## 19. Git Notes

User đã từng hỏi về `.gitignore`.

Không nên commit:

- `node_modules/`
- `backend/node_modules/`
- `backend/dist/`
- `backend/.env`
- screenshot test tạm.
- file docs riêng nếu user không muốn đẩy.

Nếu lỡ tracked file muốn giữ local nhưng xóa khỏi git:

```powershell
git rm --cached path/to/file
```

Nếu chỉ lỡ add chưa commit:

```powershell
git restore --staged path/to/file
```

## 20. Trạng Thái Hiện Tại Sau Cùng

Trạng thái gần nhất:

- Đã thêm Focus Intent Phase 1.
- Đã sửa backend dotenv/Prisma password issue.
- User đang test app trên emulator.
- Có thể cần bật Docker/Postgres để login/backend data thật chạy ổn.
- Full MVP gần xong, nhưng full `docs/rune.md` còn nhiều module lớn.

Nếu tiếp tục code, ưu tiên nên là:

1. Test lại login với backend + PostgreSQL chạy.
2. Test Focus Intent bằng nhập tay trên emulator.
3. Polish Focus Plan Preview UI.
4. Làm App Blocking/Allowlist.

## 21. Báo Cáo Rà Soát Source Code Ngày 2026-06-06

Mục này được bổ sung sau khi đọc lại source code hiện tại của dự án. Nội dung cũ phía trên không bị xoá. Vì repo Flutter này không có thư mục `src` ở root, phạm vi rà soát được hiểu là:

- Flutter app: `lib/`
- Backend API: `backend/src/`
- Database schema/seed: `backend/prisma/`
- Android native source phục vụ Focus Guard và Focus Silence: `android/app/src/main/kotlin/com/zenzoo/app/`
- Cấu hình liên quan: `pubspec.yaml`, `docker-compose.yml`, `backend/package.json`, Android manifest/build config, test smoke hiện có.

### 21.1. Tổng Quan Trạng Thái Hiện Tại

Tính đến snapshot này, ZenZoo đã vượt mức prototype UI đơn giản. App hiện đã có một MVP khá đầy đủ cho trục chính:

```text
Login/Register/Google Auth
-> Home dashboard
-> Set Focus Timer + Focus Plan heuristic
-> Focus session + optional Focus Guard/DND
-> Claim reward
-> Sync wallet/pet/streak/daily tasks/activity/notifications
-> Shop/Pet/Achievement/History/Analytics/Premium/Settings
```

Luồng frontend không còn chỉ lưu local. Nhiều module đã nối backend thật qua `ApiClient`:

- User/auth/session restore.
- Wallet/token/energy/diamond bootstrap.
- Pet state, passive decay, EXP, level, selected skin.
- Focus session start/complete.
- Daily task và daily milestone.
- Shop catalog, buy item, use item, inventory quantity.
- Achievement `productive_partner_i`.
- Activity history và notifications.
- Settings và subscription demo.
- Analytics summary.

Một số phần vẫn có fallback local để app không chết khi backend tạm lỗi, nhất là timer, focus plan fallback, pet local cache, shop catalog local cũ. Nhưng các flow chính như login thật, shop mua/dùng item, claim task, claim achievement, analytics, notification đều cần backend/PostgreSQL chạy ổn.

### 21.2. Những Phần Đã Hoàn Thành Hoặc Đã Có Code Hoạt Động

#### App bootstrap, routing, state management

Các file chính:

- `lib/main.dart`
- `lib/app.dart`
- `lib/routes/app_routes.dart`

Đã làm:

- App khởi tạo `SharedPreferences`, `AuthTokenRepository`, `ApiClient`.
- Đăng ký provider bằng `MultiProvider`.
- Có route đầy đủ cho các màn:
  - login
  - home
  - focus
  - pet profile
  - shop
  - history
  - notifications
  - set focus timer
  - daily tasks
  - focus summary
  - settings
  - analytics
  - premium
  - app blocking
- `ZenZooApp` tự quyết định mở `HomeScreen` hay `LoginScreen` dựa vào `UserProvider.hasLoggedIn`.
- Có trạng thái `isRestoringSession` để hiện loading khi đang khôi phục access token/refresh token.

Ý nghĩa:

- App đã có khung navigation hoàn chỉnh cho MVP.
- Các màn chính đã được gắn route, không còn nằm rời rạc.

#### API client và auth token

Các file chính:

- `lib/data/api/api_client.dart`
- `lib/data/repositories/auth_token_repository.dart`
- `lib/providers/user_provider.dart`
- `backend/src/auth.ts`
- `backend/src/server.ts`
- `backend/prisma/schema.prisma`

Đã làm:

- `ApiClient` dùng base URL mặc định `http://10.0.2.2:3000`, có thể override bằng `--dart-define=API_BASE_URL=...`.
- Request tự thêm header:
  - `Authorization: Bearer <accessToken>` nếu có token.
  - fallback `x-user-id` nếu còn dùng legacy user id.
- Khi API trả `401`, client thử gọi `/auth/refresh`.
- Access token và refresh token lưu bằng `flutter_secure_storage`.
- Có repository decode JWT payload, dù hiện chưa thấy flow dùng sâu phần decode này.
- Backend có JWT access token, refresh token rotation, revoke logout.
- Refresh token được hash bằng HMAC SHA-256 trước khi lưu database.
- Backend có Google ID token verification bằng `google-auth-library`.
- Backend vẫn giữ fallback `x-user-id` qua `resolveUserIdFromRequest`, giúp tương thích với flow cũ.

Auth endpoints đã có:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/google`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/demo-login`

Ý nghĩa:

- Đăng nhập email/password đã có backend thật.
- Đăng ký account đã có backend thật.
- Google login đã có code frontend/backend, nhưng cần cấu hình Google client id đúng ở cả app/backend trước khi coi là production-ready.
- Session restore đã có, app không bắt user login lại nếu token còn hợp lệ hoặc refresh được.

#### Backend Prisma/PostgreSQL

Các file chính:

- `backend/src/prisma.ts`
- `backend/prisma/schema.prisma`
- `backend/prisma/seed.ts`
- `backend/prisma.config.ts`
- `docker-compose.yml`

Đã làm:

- Backend dùng Express + TypeScript + Prisma + PostgreSQL.
- Prisma đang dùng adapter `@prisma/adapter-pg`.
- `docker-compose.yml` có:
  - PostgreSQL container `zenzoo_postgres`.
  - Adminer container `zenzoo_adminer`.
  - Backend container `zenzoo_backend`.
- Backend container chạy chuỗi:
  - `npm install`
  - `npx prisma db push`
  - `npx prisma generate`
  - `npm run prisma:seed`
  - `npm run dev`
- Docker compose đã thêm env:
  - `JWT_ACCESS_SECRET`
  - `JWT_REFRESH_SECRET`
  - `GOOGLE_WEB_CLIENT_ID`
- Seed tạo:
  - daily task templates
  - daily milestones
  - shop items

Models chính trong Prisma đã có:

- `User`
- `RefreshToken`
- `UserSettings`
- `Subscription`
- `Pet`
- `Wallet`
- `WalletTransaction`
- `FocusSession`
- `UserStreak`
- `TaskTemplate`
- `UserDailyTask`
- `DailyMilestone`
- `UserDailyMilestone`
- `UserAchievement`
- `ShopItem`
- `UserInventory`
- `ActivityEvent`
- `Notification`

Ý nghĩa:

- Backend đã đủ data model cho MVP gamification.
- Không còn chỉ mock local.
- App có thể có tài khoản, wallet, pet, shop, task, analytics theo user.

#### Login/Register UI

File chính:

- `lib/presentation/login/login_screen.dart`

Đã làm:

- UI login có animation logo, pet Kiki, panel form.
- Có switch login/register.
- Login yêu cầu email/password.
- Register yêu cầu name/email/password/confirm password.
- Có validation:
  - email/password không rỗng.
  - name tối thiểu 2 ký tự khi register.
  - password tối thiểu 6 ký tự khi register.
  - confirm password phải khớp.
- Sau login/register thành công:
  - sync wallet vào `TokenProvider`.
  - sync pet vào `PetProvider`.
  - sync streak vào `StreakProvider`.
  - navigate sang Home.
- Google login gọi `UserProvider.loginWithGoogle()`.
- Apple/Facebook hiện chỉ báo social login sẽ thêm sau.

Những phần đã sửa so với context cũ:

- Login không còn chỉ demo local.
- Đã nối với backend auth thật.
- Đã thêm register mode.
- Đã thêm secure token/session restore qua provider.

Phần còn lưu ý:

- Back button trên login hiện `onPressed: () {}` nên chưa có hành vi rõ.
- Google login phụ thuộc config Google thật, không chỉ code.
- Apple/Facebook chưa làm.

#### Home dashboard

File chính:

- `lib/presentation/home/home_screen.dart`

Đã làm:

- Home có animated entrance.
- Gọi `_loadBootstrap()` sau frame đầu:
  - refresh bootstrap từ backend.
  - sync wallet.
  - sync pet.
  - sync streak.
  - load shop catalog.
- Hiển thị:
  - streak badge.
  - notifications/mail icon.
  - resource pills: energy, tokens, diamonds.
  - timer card.
  - daily goal card.
  - habitat với pet và companion đã sở hữu.
  - bottom nav tới Focus, Shop, Tasks, Premium.
  - settings popover.
- Timer card tự mở:
  - set focus timer nếu chưa có focus.
  - focus screen nếu đang chạy session.
- Camera hiện coming soon.

Ý nghĩa:

- Home đã là hub chính cho MVP.
- Dữ liệu Home đã được sync từ backend khi app mở.

Phần còn lưu ý:

- UI dùng nhiều `Positioned` theo scale từ width 402, cần test thêm trên nhiều màn hình nhỏ/lớn.
- Camera chưa làm.
- Settings menu có nút login thay vì logout trực tiếp, còn logout thật nằm trong Settings screen.

#### Set Focus Timer và Focus Plan

File chính:

- `lib/presentation/timer/set_focus_timer_screen.dart`
- `lib/providers/focus_plan_provider.dart`
- `lib/models/focus_plan.dart`
- Backend: `POST /focus-plans/analyze`

Đã làm:

- User nhập goal bằng text field.
- Có task chips: Study, Write, Break.
- Có preset duration: 25, 45, 50 phút.
- Có companion selector:
  - Kiki mặc định.
  - Eagle.
  - Frog.
  - Giraffe.
- Companion ngoài Kiki yêu cầu đã mua trong Shop.
- Có Focus Plan Preview:
  - gọi backend analyze nếu goal có text.
  - fallback local nếu backend lỗi hoặc goal rỗng.
  - hiển thị clarity, mode, suggested minutes/pomodoro, advice, steps, warnings.
  - có nút Analyze Focus.
  - có nút Apply Plan để áp dụng recommended minutes và normalized label.
- Reward preview tính theo companion:
  - Kiki: thêm EXP.
  - Eagle: thêm token.
  - Frog: giảm energy cost.
  - Giraffe: thêm token cho session từ 45 phút.
- Khi Start Focus:
  - nếu đang có session thì chuyển thẳng sang Focus screen.
  - nếu Focus Guard bật thì thử start app blocking.
  - nếu setting silence notification bật thì kiểm tra quyền DND và bật DND.
  - gọi `FocusProvider.start(...)`.

Backend focus plan hiện là heuristic local server, chưa gọi OpenAI/API AI ngoài:

- Detect subject/action/duration/quantity/topic bằng keyword.
- Xác định clarity: detailed/medium/vague.
- Gợi ý focus mode: Practice Focus, Deep Focus, Review + Practice, Focused Study.
- Gợi ý recommended minutes.
- Sinh 3 bước chuẩn bị/làm/review.
- Sinh warning nếu goal quá rộng hoặc nhiều subject.

Ý nghĩa:

- Đúng scope đã chốt: Focus Coach/Study Focus Planner, không phải AI Tutor.
- App không dạy nội dung môn học, chỉ gợi ý cách focus.

Phần còn lưu ý:

- Đây chưa phải AI thật. Nếu báo cáo với giáo viên/mentor cần gọi là heuristic focus planner hoặc AI-like planner.
- `AppConstants.useTestFocusDuration` đang bật `true`, nên UI hiển thị planned minutes nhưng timer thực tế chạy 10 giây để test.

#### Focus session, timer, reward claim

Các file chính:

- `lib/providers/focus_provider.dart`
- `lib/presentation/focus/focus_screen.dart`
- `lib/presentation/focus/focus_summary_screen.dart`
- Backend:
  - `POST /focus-sessions/start`
  - `POST /focus-sessions/:id/complete`

Đã làm:

- `FocusProvider` quản lý phase:
  - idle
  - focusing
  - breakTime
  - done
- Timer dùng `Timer.periodic`.
- Có planned duration và actual test duration tách nhau:
  - planned vẫn là 25/45/50 phút.
  - nếu test mode bật thì focus/break chạy 10 giây.
- Khi start focus:
  - tạo remote focus session trên backend.
  - nếu API lỗi, timer vẫn chạy local.
- Khi complete/claim:
  - tăng local sessionsToday, todayFocusMinutes, totalFocusMinutes.
  - gọi backend complete nếu có remote session id.
  - reset phase về idle sau claim.
- Focus screen có:
  - animated progress ring.
  - Kiki animated state.
  - phrase theo phase.
  - break sau focus.
  - cancel focus.
  - claim panel.
  - particles khi done/claim.
  - indicator `Notifications silenced` nếu setting bật và focus đang chạy.
- Claim reward sync:
  - wallet.
  - pet.
  - streak.
  - tắt Focus Guard.
  - tắt DND.
  - chuyển sang Focus Summary nếu backend trả result.

Backend complete session làm trong transaction:

- Mark session completed.
- Tính category từ label.
- Resolve companion hợp lệ theo inventory.
- Tính reward token/EXP/energy theo companion.
- Update daily task progress.
- Update streak.
- Apply pet passive decay.
- Update pet EXP, level, mood, love, energy.
- Increment wallet tokens.
- Ghi wallet transaction.
- Tạo activity event và notification.
- Trả breakdown cho focus summary.

Ý nghĩa:

- Đây là xương sống MVP đã hoạt động.
- Reward không chỉ cộng local mà đã được backend tính và lưu.

Phần còn lưu ý:

- Nếu backend không tạo được remote session, user vẫn thấy local timer và claim local progress, nhưng sẽ không có reward result backend để sync đầy đủ.
- `FocusProvider._completeRemoteSession()` gửi `actualSeconds` bằng `_plannedFocusDurationSeconds`, tức khi test mode chạy 10 giây backend vẫn nhận actual seconds bằng planned duration. Việc này hợp lý cho demo/test reward nhưng cần chỉnh khi production.

#### Focus Summary

File chính:

- `lib/presentation/focus/focus_summary_screen.dart`
- `lib/models/focus_summary.dart`

Đã làm:

- Có màn tổng kết sau claim.
- Hiển thị metric reward token, EXP, companion bonus, daily progress, pet progress.
- Có nút Back Home.
- Có nút View Analytics.
- Summary lấy dữ liệu từ backend claim result:
  - session label.
  - planned minutes.
  - reward tokens/EXP.
  - companion code/name/skill.
  - base reward và bonus.
  - energy saved.
  - wallet/pet/streak.
  - daily goal progress.

Ý nghĩa:

- Flow focus đã có feedback rõ ràng sau khi hoàn thành.

#### Pet Profile, care item, evolution, achievement

File chính:

- `lib/presentation/pet/pet_profile_screen.dart`
- `lib/providers/pet_provider.dart`
- `lib/providers/achievement_provider.dart`
- `lib/models/pet.dart`
- `lib/models/pet_evolution.dart`
- `lib/models/achievement_progress.dart`
- Backend:
  - `POST /pet/actions`
  - `POST /pet/evolution/select`
  - `GET /achievements`
  - `POST /achievements/:code/claim`

Đã làm:

- Pet Kiki có các chỉ số:
  - level
  - EXP/EXP to next
  - hunger
  - energy
  - mood
  - love
  - selected skin
  - lastUpdatedAt
- Có passive decay local và backend:
  - mỗi 30 phút giảm hunger/mood/love.
  - giới hạn tối đa 24 ticks/lần.
- Pet Profile có:
  - hình Kiki theo selected skin.
  - floating particles khi feed/play/pet.
  - bottom sheet dùng item chăm sóc mua từ Shop.
  - evolution path bottom sheet.
  - achievement card.
- Care item flow:
  - kiểm tra stat đã full chưa.
  - gọi ShopProvider.useItem.
  - sync PetProvider.
  - giảm inventory ở backend.
- Evolution:
  - standard unlock level 1.
  - spirit unlock level 10.
  - celestial unlock level 30.
  - frontend check level trước.
  - backend cũng check level trước khi update selected skin.
- Achievement hiện có:
  - `productive_partner_i`.
  - 5 task/star:
    - complete 1 focus session.
    - reach 60 total focus minutes.
    - complete 3 focus sessions.
    - complete today's goal once.
    - reach 300 total minutes hoặc 3-day streak.
  - claim reward +100 tokens và +100 EXP.

Ý nghĩa:

- Pet companion không chỉ là hình trang trí; đã gắn với reward, inventory, evolution, achievement.

Phần còn lưu ý:

- `PetProvider.addFocusReward()` vẫn tồn tại cho local reward nhưng flow claim hiện ưu tiên backend result.
- Evolution flavor hiện là preview text, chưa có reward/effect thật cho skin.

#### Shop và inventory

Các file chính:

- `lib/presentation/shop/shop_screen.dart`
- `lib/providers/shop_provider.dart`
- `lib/data/repositories/shop_repository.dart`
- `lib/models/shop_item.dart`
- Backend:
  - `GET /shop/items`
  - `POST /shop/items/:id/buy`
  - `POST /shop/items/:id/use`

Đã làm:

- Shop có tab:
  - Potions
  - Food
  - Pets/Companions
- Catalog lấy từ backend, fallback còn có local catalog trong repository.
- Item hiện có trong seed/local:
  - Energy Potion.
  - Mood Booster.
  - Fresh Berries.
  - Cozy Pet.
  - Eagle companion.
  - Frog companion.
  - Giraffe companion.
- Inventory lưu quantity.
- Potion/food có thể mua nhiều lần.
- Companion chỉ mua một lần; mua rồi button thành Owned.
- Buy flow backend:
  - kiểm tra đủ token.
  - trừ token.
  - ghi wallet transaction.
  - upsert inventory.
  - tạo event/notification.
  - trả wallet/pet/inventory.
- Use item flow backend:
  - không cho dùng companion.
  - kiểm tra sở hữu.
  - không cho dùng nếu stat đã full.
  - update pet stat.
  - decrement/delete inventory.
  - tạo event/notification.

Ý nghĩa:

- Shop đã nối trực tiếp với token economy và pet care.

Phần còn lưu ý:

- Không thấy UI loading/error rõ trong Shop nếu load catalog lỗi; nếu backend tắt thì Grid vẫn dùng catalog local nhưng thao tác buy/use sẽ lỗi.

#### Daily tasks và milestones

Các file chính:

- `lib/presentation/tasks/daily_tasks_screen.dart`
- `lib/providers/daily_task_provider.dart`
- `lib/models/daily_task.dart`
- Backend:
  - `GET /daily-tasks/today`
  - `POST /daily-tasks/:id/claim`
  - `POST /daily-milestones/:id/claim`

Đã làm:

- Daily tasks được tạo theo ngày từ templates.
- `daily_login` tự progress 1 và completed khi user vào ngày đó.
- Focus complete update task progress:
  - pomodoro_count.
  - deep_focus nếu minutes đủ target.
  - focus_minutes cũng có code support, dù seed hiện chưa có template loại này.
- Claim task:
  - chuyển status sang claimed.
  - cộng tokens/diamonds.
  - ghi wallet transaction.
  - tạo event/notification.
- Milestone:
  - tính điểm từ các task đã claimed.
  - chỉ cho claim nếu đủ points.
  - cộng tokens/diamonds.
  - chống claim lại cùng milestone/ngày.

Ý nghĩa:

- Daily quest loop đã hoạt động và gắn với focus session.

Phần còn lưu ý:

- UI Daily Tasks chủ yếu render 3 task known code. Nếu seed thêm task mới, màn này chưa tự render dynamic list đầy đủ.

#### Activity history, analytics, notifications

Các file chính:

- `lib/presentation/history/history_screen.dart`
- `lib/presentation/analytics/analytics_screen.dart`
- `lib/presentation/notifications/notifications_screen.dart`
- `lib/providers/activity_provider.dart`
- `lib/providers/analytics_provider.dart`
- `lib/providers/notification_provider.dart`
- Backend:
  - `GET /activity-events`
  - `GET /analytics/summary`
  - `GET /notifications`
  - `POST /notifications/mark-all-read`

Đã làm:

- Backend tạo activity event và notification cho nhiều hành động:
  - welcome.
  - focus completed.
  - daily task claimed.
  - daily milestone claimed.
  - achievement claimed.
  - shop purchase.
  - shop item used.
  - pet action.
- History screen load:
  - activity events.
  - analytics summary.
  - streak.
- History có chart custom painter, overview metrics, distribution/category, recent activity.
- Analytics screen hiển thị:
  - total focus minutes.
  - sessions today.
  - pomodoros today.
  - best streak.
  - last 7 days chart.
  - category breakdown.
- Notifications screen load list notification và mark all read.

Ý nghĩa:

- App đã có vòng phản hồi sau focus và gamification event.

Phần còn lưu ý:

- Analytics category dựa trên metadata event `focus_completed`; nếu event thiếu metadata category thì fallback `Focus`.
- History/Analytics cần backend data thật để có ý nghĩa.

#### Settings, subscription, premium

Các file chính:

- `lib/presentation/settings/settings_screen.dart`
- `lib/providers/settings_provider.dart`
- `lib/presentation/premium/premium_screen.dart`
- `lib/providers/subscription_provider.dart`
- `lib/models/user_settings.dart`
- `lib/models/subscription.dart`
- Backend:
  - `GET /me/settings`
  - `PATCH /me/settings`
  - `GET /me/subscription`
  - `POST /me/subscription/demo-upgrade`

Đã làm:

- Settings load profile/settings/subscription.
- Có các toggle:
  - sound
  - vibration
  - focus reminders
  - silence notifications during focus
- Toggle silence notification kiểm tra quyền DND và mở settings nếu thiếu quyền.
- Có runtime info:
  - test timer đang bật hay production timer.
  - backend connected through Docker service.
- Có link tới Focus Guard.
- Có link Manage Go Pro.
- Có logout thật:
  - gọi backend logout nếu có refresh token.
  - sign out Google.
  - clear local tokens/profile.
  - về login.
- Premium screen có:
  - monthly/yearly toggle.
  - standard plan.
  - Zen Pro plan.
  - Master plan planned after MVP.
  - demo upgrade Zen Pro 30 ngày.

Ý nghĩa:

- Settings đã là màn quản lý account/runtime thật.
- Premium hiện là demo subscription, chưa tích hợp thanh toán.

#### Focus Guard và Focus Silence Android native

Các file chính:

- `lib/data/native/app_block_channel.dart`
- `lib/data/native/focus_silence_service.dart`
- `lib/providers/app_block_provider.dart`
- `lib/presentation/blocking/app_blocking_screen.dart`
- `android/app/src/main/kotlin/com/zenzoo/app/MainActivity.kt`
- `android/app/src/main/kotlin/com/zenzoo/app/AppBlockState.kt`
- `android/app/src/main/kotlin/com/zenzoo/app/FocusBlockService.kt`
- `android/app/src/main/kotlin/com/zenzoo/app/ZenZooAccessibilityService.kt`
- `android/app/src/main/res/xml/zenzoo_accessibility_service.xml`
- `android/app/src/main/AndroidManifest.xml`

Đã làm:

- Android package/namespace/applicationId hiện là `com.zenzoo.app`.
- Có MethodChannel `zenzoo/app_block` cho:
  - check usage access.
  - open usage access settings.
  - check notification permission.
  - request notification permission.
  - check accessibility permission.
  - open accessibility settings.
  - start blocking.
  - stop blocking.
- Có MethodChannel `zenzoo/focus_silence` cho:
  - check notification policy access.
  - open notification policy settings.
  - enable DND/silence.
  - disable DND/silence.
- Focus Guard UI yêu cầu 3 quyền:
  - Usage Access.
  - Notifications.
  - Accessibility.
- AppBlockProvider lưu:
  - blocking enabled.
  - blocked packages.
  - permission states.
  - active state.
- Nếu user chưa chọn app cụ thể, start blocking dùng strict package mặc định:
  - Chrome.
  - YouTube.
  - TikTok.
  - Instagram.
  - Facebook.
  - Play Store.
- Native service:
  - foreground service giữ guard active.
  - đọc foreground app qua UsageStats/Events.
  - nếu vào app bị block thì relaunch ZenZoo.
  - có burst relaunch để giảm khả năng user thoát.
- Accessibility service:
  - nghe window state/content changes.
  - relaunch ZenZoo nếu foreground package bị block hoặc home launcher trong lúc active.
- Manifest đã khai báo:
  - PACKAGE_USAGE_STATS.
  - FOREGROUND_SERVICE.
  - FOREGROUND_SERVICE_SPECIAL_USE.
  - INTERNET.
  - POST_NOTIFICATIONS.
  - ACCESS_NOTIFICATION_POLICY.
  - FocusBlockService.
  - ZenZooAccessibilityService.

Ý nghĩa:

- App Blocking/Allowlist từ phần ưu tiên cũ đã được triển khai thành Focus Guard tương đối đầy đủ cho Android.

Phần còn lưu ý:

- Cần test thật trên Android device/emulator vì quyền Usage Access/Accessibility/DND có hành vi phụ thuộc version Android.
- iOS/web sẽ không có Focus Guard/DND, các method native return false/true mềm theo platform.
- Android label trong manifest vẫn là `rune`, nên nếu muốn brand đúng thì nên đổi thành `ZenZoo`.

### 21.3. Những Phần Đã Sửa/Đã Thay Đổi Rõ Trong Worktree Hiện Tại

Theo `git status` và `git diff --stat`, worktree hiện có nhiều thay đổi chưa commit. Các thay đổi chính:

- Android:
  - đổi namespace/applicationId sang `com.zenzoo.app`.
  - thêm quyền `ACCESS_NOTIFICATION_POLICY`.
  - chuyển Kotlin source từ `com/example/rune` sang `com/zenzoo/app`.
  - các file cũ dưới `com/example/rune` đang bị delete.
  - thư mục mới `android/app/src/main/kotlin/com/zenzoo/` đang untracked.
- Backend:
  - thêm `backend/src/auth.ts`.
  - thêm dependency auth/security:
    - `google-auth-library`
    - `jsonwebtoken`
    - related types.
  - schema Prisma thêm auth/session/settings/subscription field/model.
  - server thêm auth endpoints, refresh token, Google auth, settings, subscription.
  - docker-compose thêm JWT env và Google client id env.
- Flutter:
  - `ApiClient` thêm token auth, refresh-on-401, configurable base URL.
  - thêm `AuthTokenRepository`.
  - `UserProvider` đổi sang login/register/google/session restore/logout thật.
  - `LoginScreen` thêm register form, password fields, Google login.
  - `SettingsScreen` thêm DND silence, logout, Focus Guard/Premium links.
  - `FocusScreen` và `SetFocusTimerScreen` tích hợp DND silence.
  - `UserSettings` thêm `silenceNotificationsDuringFocus`.
  - `main.dart` thêm providers/repositories mới.
  - `app.dart` thêm restoring session loading state.
  - `test/widget_test.dart` cập nhật smoke test login.
- Dependency:
  - `pubspec.yaml/pubspec.lock` thêm:
    - `google_sign_in`
    - `flutter_secure_storage`
  - `backend/package.json/package-lock.json` thêm auth dependencies.

Lưu ý quan trọng:

- Đây là snapshot worktree hiện tại. Vì có file untracked và file deleted, trước khi commit cần chạy `git status` và đảm bảo add đúng file mới `android/app/src/main/kotlin/com/zenzoo/app/*`.
- Không nên commit `backend/node_modules/`, `backend/dist/`, build output hoặc asset test tạm nếu không cần.

### 21.4. Kiểm Tra Đã Chạy Trong Lượt Rà Soát Này

Đã chạy:

```powershell
flutter analyze
```

Kết quả:

```text
No issues found!
```

Đã chạy:

```powershell
cd backend
npm run build
```

Kết quả:

```text
tsc build thành công
```

Đã chạy:

```powershell
flutter test
```

Kết quả:

```text
All tests passed!
```

Ý nghĩa:

- Dart analyzer hiện không báo lỗi.
- Backend TypeScript compile được.
- Smoke test Flutter hiện pass.

Phần chưa verify trong lượt này:

- Chưa chạy app thật trên emulator/device.
- Chưa test login thật với PostgreSQL đang chạy.
- Chưa test Google Sign-In end-to-end.
- Chưa test Focus Guard trên Android sau khi đổi package sang `com.zenzoo.app`.
- Chưa test DND permission end-to-end trên Android.
- Chưa test Docker compose full cold start trong lượt này.

### 21.5. Các Rủi Ro/Khoảng Trống Cần Nhớ

#### Test mode timer đang bật

File:

- `lib/core/constants/app_constants.dart`

Hiện trạng:

```dart
static const bool useTestFocusDuration = true;
```

Kết quả:

- Focus và break chạy 10 giây để test nhanh.
- UI vẫn hiển thị planned minutes.
- Backend reward vẫn tính theo planned minutes.

Trước demo production cần quyết định:

- Giữ test mode nếu đang quay demo nhanh.
- Tắt test mode nếu cần Pomodoro thật.

#### Google auth cần cấu hình thật

Hiện code đã có, nhưng để chạy end-to-end cần:

- `GOOGLE_WEB_CLIENT_ID` đúng ở Flutter `--dart-define` hoặc default hợp lệ.
- `GOOGLE_WEB_CLIENT_ID`/`GOOGLE_CLIENT_ID` đúng ở backend env.
- Android signing SHA/client config đúng cho Google Sign-In.

Nếu thiếu, lỗi có thể xuất hiện ở:

- Flutter không lấy được `idToken`.
- Backend báo Google auth not configured.
- Backend verify audience không khớp.

#### Focus Guard cần test thủ công

Mặc dù `flutter analyze` pass, Focus Guard phụ thuộc native Android behavior:

- Usage Access.
- Accessibility service.
- Foreground service.
- Notification permission Android 13+.
- Background activity start policy Android 14+.

Cần test các case:

- Bật Focus Guard nhưng thiếu quyền.
- Cấp đủ quyền rồi start focus.
- Mở Chrome/YouTube/TikTok khi focus đang chạy.
- Bấm Home khi focus đang chạy.
- Cancel focus phải stop service.
- Claim reward phải stop service.
- Done phase phải stop service.

#### DND silence cần test thủ công

Cần test:

- Bật setting khi chưa có Notification Policy Access.
- App mở đúng settings.
- Sau khi cấp quyền, start focus bật DND.
- Done/cancel/claim đều tắt DND.
- Nếu app crash giữa focus, DND có thể cần recovery ở lần mở lại.

#### Backend fallback và local state có thể lệch

Một số flow vẫn cho app chạy khi backend lỗi:

- Focus timer vẫn chạy nếu start remote session fail.
- Focus plan có fallback.
- Pet có local cache/decay.
- Shop catalog có local fallback.

Điểm cần chú ý:

- Nếu backend lỗi lúc focus complete, user có thể thấy local progress tăng nhưng wallet/pet backend không tăng.
- Nếu sau đó bootstrap lại từ backend, local progress có thể bị override theo backend.

#### UI có một số phần planned/coming soon

Chưa hoàn thành:

- Camera.
- Apple login.
- Facebook login.
- Payment thật cho Premium.
- Master plan.
- AI thật nếu muốn gọi model ngoài heuristic.
- Dynamic rendering cho daily tasks nếu seed mở rộng nhiều task hơn.
- iOS implementation cho Focus Guard/DND.

#### Brand/name còn lẫn `rune`

Hiện app name trong project vẫn là `rune` ở nhiều chỗ:

- package Flutter name trong `pubspec.yaml`.
- Android label manifest là `rune`.
- import package vẫn là `package:rune/...`.

Điều này không sai kỹ thuật, nhưng nếu muốn polish brand ZenZoo thì nên đổi có kiểm soát.

### 21.6. Kết Luận Snapshot

Những gì đã hoàn thành tốt:

- MVP flow chính đã có code nối nhau từ login đến focus, reward, pet, shop, daily task, history, analytics.
- Backend đã có data model đủ rộng cho MVP.
- Auth thật đã được thêm bằng email/password, JWT refresh token và Google login.
- Pet companion/gamification không còn mock đơn giản; đã có wallet, inventory, EXP, evolution, achievement.
- Focus Guard và notification silence đã được triển khai tới native Android layer.
- Các kiểm tra `flutter analyze`, `flutter test`, `npm run build` đều pass tại thời điểm rà soát.

Những gì nên làm tiếp theo:

1. Chạy `docker compose up` cold start và test login/register thật.
2. Chạy app trên emulator/device và test toàn bộ flow:
   - register/login
   - focus plan analyze/apply
   - start focus
   - claim reward
   - daily task claim
   - shop buy/use
   - pet evolution
   - achievement claim
   - history/analytics/notifications
3. Test riêng Focus Guard và DND trên Android.
4. Quyết định bật/tắt `useTestFocusDuration` cho demo cuối.
5. Commit có chọn lọc, nhớ add các file Kotlin mới dưới `com/zenzoo/app`.

