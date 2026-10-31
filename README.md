# Yuki Video Studio

Bộ công cụ để tạo, chỉnh sửa, làm hoạt ảnh và render video với **Remotion**, **HyperFrames** và **FFmpeg**.

## Cài đặt (một lệnh)

```bash
npm run setup      # = bash scripts/setup.sh
npm run check      # kiểm tra toàn bộ + render thử bằng từng công cụ
```

`setup.sh` cài: Node.js 22 (nếu thiếu), FFmpeg/FFprobe, font, các thư viện hệ thống cho Chromium headless,
các gói npm (`remotion`, `@remotion/cli|renderer|bundler|transitions`, `hyperframes`, `gsap`, `react`, `typescript`)
và trình duyệt headless cho Remotion. Hỗ trợ Ubuntu/Debian và macOS; trên Windows dùng WSL2.

## Cấu trúc

| Đường dẫn | Nội dung |
|---|---|
| `public/photos/` | Ảnh đầu vào (dùng chung cho cả 3 công cụ; không đẩy lên GitHub) |
| `remotion/src/` | Composition Remotion `PhotoSlideshow` (React, 1080×1920, 30fps) |
| `remotion.config.ts` | Cấu hình xuất của Remotion (H.264, CRF 18) |
| `hyperframes/index.html` | Composition HyperFrames (HTML + GSAP timeline) |
| `scripts/ffmpeg-slideshow.sh` | Slideshow chỉ bằng FFmpeg: Ken Burns, xfade, tiêu đề, nhạc nền |
| `scripts/html-to-video-test.mjs` | Kiểm tra chuỗi Chromium headless → FFmpeg |
| `scripts/check-env.sh` | Báo cáo PASS/FAIL/SKIP |
| `out/` | Video xuất ra |

## Lệnh thường dùng

```bash
npm run ffmpeg:slideshow -- public/photos out/video.mp4 "Tiêu đề"
npm run remotion:studio    # chỉnh sửa trực quan trên trình duyệt
npm run remotion:render    # → out/slideshow-remotion.mp4
npm run hf:preview         # xem trước HyperFrames
npm run hf:render          # → out/slideshow-hyperframes.mp4
```

Cả ba bản đều cùng một kịch bản: 3 ảnh × 4 giây, chuyển cảnh 1 giây, zoom chậm, tiêu đề, mờ dần cuối video (10 giây).
