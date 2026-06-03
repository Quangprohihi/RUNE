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

