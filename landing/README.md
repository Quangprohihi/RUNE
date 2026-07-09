# ZenZoo Landing Page

Trang landing giới thiệu ZenZoo — ứng dụng Pomodoro nuôi thú ảo (Kiki 🦊).
Site tĩnh thuần (HTML + CSS + vanilla JS), không cần build, tách riêng khỏi
source app trong `rune/`.

Nguồn thiết kế: dự án Claude Design "ZenZoo Landing" (`ZenZoo Landing.dc.html`).

## Cấu trúc

```
zenzoo-landing/
├── index.html            # Toàn bộ markup (style từng section nằm inline, theo thiết kế)
├── assets/
│   ├── css/style.css     # Style toàn cục, keyframes, hover states
│   ├── js/main.js        # Hiệu ứng reveal, toggle giá tháng/năm, FAQ accordion
│   └── img/              # Kiki, companions, hòn đảo bay
└── README.md
```

## Chạy local

Mở thẳng `index.html` bằng trình duyệt (đường dẫn tương đối, chạy được từ file),
hoặc chạy một static server bất kỳ:

```bash
npx serve .
```

## Deploy

Là site tĩnh nên deploy được lên bất kỳ static host nào — Render Static Site,
Vercel, Netlify, GitHub Pages — chỉ cần trỏ vào thư mục này, không cần build step.

## Tính năng tương tác

- **Bảng giá**: nút Hàng tháng / Hàng năm đổi giá gói Zen Pro (29.000đ/tháng ↔ 279.000đ/năm), mặc định hàng năm.
- **FAQ**: accordion `<details>`, dấu `+` xoay 45° khi mở.
- **Reveal khi cuộn**: các khối `[data-reveal]` hiện dần bằng IntersectionObserver; tôn trọng `prefers-reduced-motion`.
- **Hiệu ứng bay lơ lửng**: đảo, mây, thẻ nổi (`[data-float]`) — cũng tắt khi người dùng giảm chuyển động.
