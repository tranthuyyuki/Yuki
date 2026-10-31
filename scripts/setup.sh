#!/usr/bin/env bash
# Cài đặt mọi thứ cần cho Remotion + HyperFrames + FFmpeg.
# Hỗ trợ: Ubuntu/Debian (apt), macOS (Homebrew). Windows: dùng WSL2.
set -uo pipefail
cd "$(dirname "$0")/.."

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

say "1/5 Node.js (cần >= 18; khuyên dùng 22 LTS)"
if ! command -v node >/dev/null || [ "$(node -p 'process.versions.node.split(".")[0]')" -lt 18 ]; then
  if command -v brew >/dev/null; then brew install node@22
  elif command -v apt-get >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | $SUDO bash - && $SUDO apt-get install -y nodejs
  else warn "Hãy cài Node.js 22 từ https://nodejs.org rồi chạy lại."; exit 1; fi
fi
node -v

say "2/5 FFmpeg + FFprobe + font + thư viện hệ thống cho Chromium headless"
if command -v apt-get >/dev/null; then
  $SUDO apt-get update -y
  $SUDO apt-get install -y ffmpeg fonts-dejavu fonts-noto-color-emoji fontconfig \
    libnss3 libdbus-1-3 libatk1.0-0 libgbm-dev libasound2t64 libxrandr2 libxkbcommon-dev \
    libxfixes3 libxcomposite1 libxdamage1 libatk-bridge2.0-0 libpango-1.0-0 libcairo2 libcups2 \
    || $SUDO apt-get install -y ffmpeg fonts-dejavu fontconfig libnss3 libgbm1 libasound2
elif command -v brew >/dev/null; then
  brew install ffmpeg
else
  command -v ffmpeg >/dev/null || { warn "Không tìm thấy apt/brew – hãy tự cài FFmpeg."; exit 1; }
fi
ffmpeg -hide_banner -version | head -1

say "3/5 Gói npm (remotion, @remotion/*, hyperframes, gsap, react, typescript)"
npm install || { warn "npm install thất bại – kiểm tra kết nối tới registry.npmjs.org"; exit 1; }

say "4/5 Trình duyệt headless cho Remotion"
npx --no-install remotion browser ensure || warn "remotion browser ensure lỗi – có thể đặt REMOTION_BROWSER_EXECUTABLE=/đường/dẫn/chrome"

say "5/5 HyperFrames CLI"
npx --no-install hyperframes --version || warn "Không chạy được hyperframes CLI"
npx --no-install hyperframes doctor 2>/dev/null || true

say "Xong. Chạy 'npm run check' để kiểm tra toàn bộ."
