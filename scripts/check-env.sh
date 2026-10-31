#!/usr/bin/env bash
# Kiểm tra môi trường + render thử thật bằng từng công cụ.
# Mỗi mục in PASS / FAIL / SKIP; mã thoát != 0 nếu có FAIL.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
PASS=0; FAIL=0; SKIP=0
pass() { printf '\033[32m PASS\033[0m  %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '\033[31m FAIL\033[0m  %s\n' "$*"; FAIL=$((FAIL+1)); }
skip() { printf '\033[33m SKIP\033[0m  %s\n' "$*"; SKIP=$((SKIP+1)); }
probe() { ffprobe -v error -show_entries format=duration:stream=codec_name,width,height -of compact=p=0:nk=1 "$1" | tr '\n' ' '; }

echo "── Hệ thống ─────────────────────────────"
if command -v node >/dev/null && [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 18 ]; then
  pass "Node.js $(node -v)"; else fail "Node.js >= 18"; fi
command -v ffmpeg  >/dev/null && pass "$(ffmpeg -hide_banner -version | head -1 | cut -d' ' -f1-3)" || fail "ffmpeg"
command -v ffprobe >/dev/null && pass "ffprobe" || fail "ffprobe"
ENC=$(ffmpeg -hide_banner -encoders 2>/dev/null)
for e in libx264 libx265 libvpx-vp9 prores_ks aac libopus; do
  grep -q " $e " <<<"$ENC" && pass "encoder $e" || fail "encoder $e"; done
FLT=$(ffmpeg -hide_banner -filters 2>/dev/null)
for f in zoompan xfade drawtext overlay scale; do
  grep -q " $f " <<<"$FLT" && pass "filter $f" || fail "filter $f"; done
fc-list 2>/dev/null | grep -i dejavu >/dev/null && pass "font DejaVu" || fail "font DejaVu (apt install fonts-dejavu)"

echo "── Render thử ───────────────────────────"
if ls public/photos/*.jpg >/dev/null 2>&1; then
  if bash scripts/ffmpeg-slideshow.sh public/photos out/slideshow-ffmpeg.mp4 >/dev/null; then
    pass "FFmpeg slideshow → out/slideshow-ffmpeg.mp4 ($(probe out/slideshow-ffmpeg.mp4))"
  else fail "FFmpeg slideshow"; fi
else skip "FFmpeg slideshow (chưa có ảnh trong public/photos)"; fi

if node scripts/html-to-video-test.mjs out/html-render-test.mp4 >/dev/null; then
  pass "Chromium headless → FFmpeg ($(probe out/html-render-test.mp4))"
else fail "Chromium headless → FFmpeg (cần playwright/Chromium)"; fi

echo "── Remotion ─────────────────────────────"
if [ -d node_modules/remotion ]; then
  pass "remotion $(node -p 'require("./node_modules/remotion/package.json").version')"
  npx --no-install tsc -p . && pass "TypeScript composition hợp lệ" || fail "TypeScript composition"
  if npx --no-install remotion render remotion/src/index.ts PhotoSlideshow out/slideshow-remotion.mp4 --log=error; then
    pass "Remotion render → out/slideshow-remotion.mp4 ($(probe out/slideshow-remotion.mp4))"
  else fail "Remotion render"; fi
else skip "Remotion chưa cài (chạy: npm run setup)"; fi

echo "── HyperFrames ──────────────────────────"
if [ -x node_modules/.bin/hyperframes ]; then
  pass "hyperframes CLI $(npx --no-install hyperframes --version 2>/dev/null | head -1)"
  (cd hyperframes && npx --no-install hyperframes lint) && pass "hyperframes lint" || fail "hyperframes lint"
  if (cd hyperframes && npx --no-install hyperframes render --output ../out/slideshow-hyperframes.mp4); then
    pass "HyperFrames render → out/slideshow-hyperframes.mp4 ($(probe out/slideshow-hyperframes.mp4))"
  else fail "HyperFrames render"; fi
else skip "HyperFrames chưa cài (chạy: npm run setup)"; fi

echo "─────────────────────────────────────────"
echo "Kết quả: $PASS PASS · $FAIL FAIL · $SKIP SKIP"
[ "$FAIL" -eq 0 ]
