/**
 * Phản hồi người dùng thử ZenZoo (đợt khảo sát v1.0.0).
 *
 * `text` là nội dung THẬT do người dùng viết, giữ nguyên văn (kể cả lỗi chính tả).
 * `author`, `at`, `rating` và `tags` là dữ liệu đội ngũ gán thêm để hiển thị trên
 * console: tên hiển thị được ẩn danh hóa, ngày rải đều đợt khảo sát, số sao và
 * chủ đề suy ra từ sắc thái của chính nội dung. Sửa trực tiếp trong file này khi
 * có đánh giá thật kèm số sao — cấu trúc không đổi.
 *
 * Khi có bảng Review trong DB, thay mảng này bằng truy vấn Prisma; phần tổng hợp
 * ở review.metrics.ts nhận vào đúng shape AppReview nên không phải sửa gì.
 */

export type ReviewTone = 'praise' | 'request' | 'issue';

export type ReviewThemeKey =
  | 'pomodoro' | 'pet' | 'ai' | 'blocking' | 'pro'
  | 'ui' | 'performance' | 'social' | 'audio' | 'concept';

export interface ReviewTag { theme: ReviewThemeKey; tone: ReviewTone; }

export interface AppReview {
  id: string;
  author: string;
  rating: number;      // 1..5
  at: string;          // ISO 8601 (UTC)
  platform: string;
  appVersion: string;
  text: string;
  tags: ReviewTag[];
}

export interface ReviewTheme { key: ReviewThemeKey; label: string; }

/** Thứ tự ở đây là thứ tự mặc định khi hai chủ đề bằng điểm nhắc. */
export const REVIEW_THEMES: ReviewTheme[] = [
  { key: 'pet', label: 'Nuôi pet & sưu tầm' },
  { key: 'pomodoro', label: 'Pomodoro' },
  { key: 'blocking', label: 'Chặn ứng dụng' },
  { key: 'ui', label: 'Giao diện & trải nghiệm' },
  { key: 'concept', label: 'Ý tưởng tổng thể' },
  { key: 'ai', label: 'AI xếp lịch học' },
  { key: 'pro', label: 'Giá trị gói Zen Pro' },
  { key: 'performance', label: 'Hiệu năng & lỗi' },
  { key: 'social', label: 'Bạn bè & cộng đồng' },
  { key: 'audio', label: 'Nhạc nền khi học' },
];

const V = '1.0.0';
const ANDROID = 'Android';

export const APP_REVIEWS: AppReview[] = [
  {
    id: 'rv-01', author: 'Nguyễn Ngọc Ánh', rating: 4, at: '2026-07-14T09:12:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'App giao diện nhìn bắt mắt, nhưng còn thiếu các tính năng nuôi pet. Mong update sớm!',
    tags: [{ theme: 'ui', tone: 'praise' }, { theme: 'pet', tone: 'request' }],
  },
  {
    id: 'rv-02', author: 'Lê Minh Quân', rating: 3, at: '2026-07-15T20:41:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Mình dùng tính năng Pomodoro chạy ổn không block tất cả các app nên rất dễ dùng. Nhưng mua xong gói pro thì không có sự khác biệt gì mấy nên hơi thấy phí tiền.',
    tags: [{ theme: 'pomodoro', tone: 'praise' }, { theme: 'blocking', tone: 'praise' }, { theme: 'pro', tone: 'issue' }],
  },
  {
    id: 'rv-03', author: 'Trần Thu Hà', rating: 3, at: '2026-07-16T08:05:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'App có sử dụng tính năng pomodoro, nhưng tính năng nuôi pet hay tính năng AI setup lịch học vẫn chưa có. Cần nhanh chóng để cải thiện.',
    tags: [{ theme: 'pomodoro', tone: 'praise' }, { theme: 'pet', tone: 'request' }, { theme: 'ai', tone: 'request' }],
  },
  {
    id: 'rv-04', author: 'Phạm Gia Bảo', rating: 4, at: '2026-07-17T13:22:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Mình tải vì thấy có nuôi pet nhưng cuối cùng lại ở lại vì Pomodoro khá tiện. Mong app ra nhìu pet hơn để sưu tầm.',
    tags: [{ theme: 'pomodoro', tone: 'praise' }, { theme: 'pet', tone: 'request' }],
  },
  {
    id: 'rv-05', author: 'Đỗ Khánh Linh', rating: 3, at: '2026-07-18T21:07:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Dù có tính năng là pomodoro nhưng cảm thấy vẫn chưa hài lòng lắm về các tính năng nuôi pet hay là AI.',
    tags: [{ theme: 'pet', tone: 'request' }, { theme: 'ai', tone: 'request' }],
  },
  {
    id: 'rv-06', author: 'Vũ Đình Nam', rating: 3, at: '2026-07-19T10:48:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Pet vẫn đang bị khóa nhưng tôi muốn có thêm nhiều Pet để có thêm động lực sài APP.',
    tags: [{ theme: 'pet', tone: 'request' }],
  },
  {
    id: 'rv-07', author: 'Hoàng Mai Chi', rating: 4, at: '2026-07-20T16:31:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Tính năng chặn ứng dụng hoạt động khá ok. Chỉ mong sau này có thể tùy chọn chặn theo từng khung giờ.',
    tags: [{ theme: 'blocking', tone: 'praise' }, { theme: 'blocking', tone: 'request' }],
  },
  {
    id: 'rv-08', author: 'Bùi Tuấn Kiệt', rating: 2, at: '2026-07-21T09:56:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Giao diện thì dễ dùng, các tính năng chưa mở khóa hết. hơi hụt hẫn về chi phí bỏ ra.',
    tags: [{ theme: 'ui', tone: 'praise' }, { theme: 'pro', tone: 'issue' }],
  },
  {
    id: 'rv-09', author: 'Đặng Thảo Vy', rating: 3, at: '2026-07-22T19:14:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'App còn cần cải thiện các tính năng mượt hơn xíu.',
    tags: [{ theme: 'performance', tone: 'issue' }],
  },
  {
    id: 'rv-10', author: 'Ngô Hải Đăng', rating: 4, at: '2026-07-23T11:03:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'App có ý tưởng khá khác so với mấy app học tập khác mình từng thử.',
    tags: [{ theme: 'concept', tone: 'praise' }],
  },
  {
    id: 'rv-11', author: 'Lý Phương Thảo', rating: 5, at: '2026-07-24T08:27:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Mình thích việc chỉ cần bấm một cái là bắt đầu phiên Pomodoro luôn. Cảm giác mọi thứ đơn giản nên đỡ lười.',
    tags: [{ theme: 'pomodoro', tone: 'praise' }, { theme: 'ui', tone: 'praise' }],
  },
  {
    id: 'rv-12', author: 'Trịnh Bảo Ngọc', rating: 4, at: '2026-07-25T22:19:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Pet trong app nhìn đáng yêu. Sau này nếu có thêm hiệu ứng hoặc animation khi pet lên level thì sẽ cuốn hơn nữa.',
    tags: [{ theme: 'pet', tone: 'praise' }, { theme: 'pet', tone: 'request' }],
  },
  {
    id: 'rv-13', author: 'Cao Minh Hiếu', rating: 5, at: '2026-07-26T14:45:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Chặn app xao nhãng khá hiệu quả, nhất là lúc ôn thi. Mình gần như không còn bị kéo sang mạng xã hội nữa.',
    tags: [{ theme: 'blocking', tone: 'praise' }],
  },
  {
    id: 'rv-14', author: 'Dương Tùng Lâm', rating: 4, at: '2026-07-27T17:36:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'App có triển vọng. Mong đội ngũ phát triển cập nhật thêm nhiều tính năng để giữ người dùng lâu hơn.',
    tags: [{ theme: 'concept', tone: 'praise' }, { theme: 'concept', tone: 'request' }],
  },
  {
    id: 'rv-15', author: 'Phan Yến Nhi', rating: 5, at: '2026-07-28T09:41:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Mình thích cách app kết hợp giữa POMODORO và nuôi pet, hứng thú lắm.',
    tags: [{ theme: 'concept', tone: 'praise' }, { theme: 'pomodoro', tone: 'praise' }, { theme: 'pet', tone: 'praise' }],
  },
  {
    id: 'rv-16', author: 'Võ Quốc Huy', rating: 4, at: '2026-07-29T21:58:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Nếu dùng với bạn bè chung coi số giờ học tập của nhau thì có thể vui hơn=))))',
    tags: [{ theme: 'social', tone: 'request' }],
  },
  {
    id: 'rv-17', author: 'Tạ Thùy Dương', rating: 4, at: '2026-07-30T12:16:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Rất hứng thú khi dùng app với POMODORO, có thêm nhạc lúc học nửa thì hài lòng <3',
    tags: [{ theme: 'pomodoro', tone: 'praise' }, { theme: 'audio', tone: 'request' }],
  },
  {
    id: 'rv-18', author: 'Chu Anh Khoa', rating: 2, at: '2026-07-31T15:04:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Giao diện app khá thô sơ, cần một giao diện tối ưu các tính năng hơn.',
    tags: [{ theme: 'ui', tone: 'issue' }],
  },
  {
    id: 'rv-19', author: 'Hồ Ngọc Trâm', rating: 3, at: '2026-08-01T20:22:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'App sài vẫn có vài lỗi. Có vài chỗ vẫn cần tối ưu nhưng tổng thể nhìn chung vẫn sài được với mục tiêu là tập trung học tập là POMODORO.',
    tags: [{ theme: 'performance', tone: 'issue' }, { theme: 'pomodoro', tone: 'praise' }],
  },
  {
    id: 'rv-20', author: 'Đinh Trung Kiên', rating: 3, at: '2026-08-02T10:37:00.000Z',
    platform: ANDROID, appVersion: V,
    text: 'Cần có thêm pet để có động lực cho tôi dùng app.',
    tags: [{ theme: 'pet', tone: 'request' }],
  },
];
