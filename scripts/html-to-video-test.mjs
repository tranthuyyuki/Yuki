// Kiểm tra chuỗi render HTML → khung hình (Chromium headless) → FFmpeg → MP4.
// Đây chính là cơ chế HyperFrames và Remotion dùng bên dưới, nên nếu bài này chạy
// được thì trình duyệt + FFmpeg đã sẵn sàng cho cả hai.
// Dùng: node scripts/html-to-video-test.mjs [out.mp4]
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require('/opt/node22/lib/node_modules/playwright')); }

const OUT = process.argv[2] || 'out/html-render-test.mp4';
const W = 1280, H = 720, FPS = 30, SECONDS = 3, FRAMES = FPS * SECONDS;
mkdirSync(dirname(OUT), { recursive: true });

// Hoạt ảnh được điều khiển hoàn toàn bởi thời gian t (deterministic, giống seek frame).
const html = `<!doctype html><html><body style="margin:0;background:#120d1f;overflow:hidden">
<div id="box" style="position:absolute;width:220px;height:220px;border-radius:32px;
  background:linear-gradient(135deg,#ff5f8f,#ffb86b)"></div>
<h1 id="t" style="position:absolute;width:100%;top:520px;text-align:center;color:#fff;
  font:700 64px DejaVu Sans,sans-serif">HTML → Video</h1>
<script>
window.seek = (t) => {
  const p = t / ${SECONDS};
  const box = document.getElementById('box');
  box.style.left = (100 + p * 860) + 'px';
  box.style.top = (180 + Math.sin(p * Math.PI * 2) * 120) + 'px';
  box.style.transform = 'rotate(' + (p * 360) + 'deg)';
  document.getElementById('t').style.opacity = Math.min(1, t * 2);
};
</script></body></html>`;

const ff = spawn('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y',
  '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'png', '-i', '-',
  '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-movflags', '+faststart', OUT],
  { stdio: ['pipe', 'inherit', 'inherit'] });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: H } });
await page.setContent(html);
for (let f = 0; f < FRAMES; f++) {
  await page.evaluate((t) => window.seek(t), f / FPS);
  const buf = await page.screenshot({ type: 'png' });
  if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
}
await browser.close();
ff.stdin.end();
const code = await new Promise((r) => ff.on('close', r));
if (code !== 0) { console.error('✘ FFmpeg lỗi, mã', code); process.exit(1); }
console.log(`✔ Đã render ${FRAMES} khung hình HTML → ${OUT}`);
