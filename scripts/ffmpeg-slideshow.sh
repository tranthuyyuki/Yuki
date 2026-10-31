#!/usr/bin/env bash
# Tạo video slideshow dọc (1080x1920, 30fps) từ ảnh bằng FFmpeg thuần:
# hiệu ứng Ken Burns (zoom chậm) + chuyển cảnh xfade + tiêu đề drawtext + fade in/out.
#
# Dùng: scripts/ffmpeg-slideshow.sh [thư_mục_ảnh=public/photos] [file_ra.mp4] ["Tiêu đề"]
set -euo pipefail

IN_DIR="${1:-public/photos}"
OUT="${2:-out/slideshow-ffmpeg.mp4}"
TITLE="${3:-Kỷ niệm}"
W=1080; H=1920; FPS=30
SLIDE=4      # giây mỗi ảnh
XF=1         # giây chuyển cảnh
FONT="$(fc-match -f '%{file}' 'DejaVu Sans:bold' 2>/dev/null || echo /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf)"

mapfile -t PHOTOS < <(find "$IN_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)
N=${#PHOTOS[@]}
[ "$N" -ge 1 ] || { echo "Không tìm thấy ảnh trong $IN_DIR" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"

FRAMES=$((SLIDE * FPS))
INPUTS=(); FILTER=""
for i in "${!PHOTOS[@]}"; do
  INPUTS+=(-loop 1 -t "$SLIDE" -i "${PHOTOS[$i]}")
  # Phóng to ảnh rồi cắt vừa khung, sau đó zoom chậm vào giữa (Ken Burns).
  FILTER+="[$i:v]scale=${W}*2:${H}*2:force_original_aspect_ratio=increase,crop=${W}*2:${H}*2,"
  FILTER+="zoompan=z='min(1+0.0008*on,1.12)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${FRAMES}:s=${W}x${H}:fps=${FPS},"
  FILTER+="setsar=1,format=yuv420p[v$i];"
done

# Nối các cảnh bằng xfade.
LAST="v0"
for ((i=1; i<N; i++)); do
  OFF=$(( i * (SLIDE - XF) ))
  FILTER+="[$LAST][v$i]xfade=transition=fade:duration=${XF}:offset=${OFF}[x$i];"
  LAST="x$i"
done
TOTAL=$(( N * SLIDE - (N - 1) * XF ))

FILTER+="[$LAST]drawtext=fontfile='${FONT}':text='${TITLE}':fontsize=84:fontcolor=white"
FILTER+=":borderw=4:bordercolor=black@0.6:x=(w-text_w)/2:y=h*0.12"
FILTER+=":alpha='if(lt(t,0.5),0,if(lt(t,1.5),t-0.5,if(lt(t,3.5),1,if(lt(t,4.5),4.5-t,0))))',"
FILTER+="fade=t=in:st=0:d=0.6,fade=t=out:st=$((TOTAL - 1)):d=1[vout]"

# Âm thanh nền tổng hợp (sine nhẹ) để kiểm tra luôn khâu mã hoá AAC.
ffmpeg -hide_banner -loglevel error -y "${INPUTS[@]}" \
  -f lavfi -t "$TOTAL" -i "sine=frequency=220:sample_rate=48000" \
  -filter_complex "${FILTER};[${N}:a]volume=0.08,afade=t=in:d=1,afade=t=out:st=$((TOTAL - 1)):d=1[aout]" \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -r "$FPS" \
  -c:a aac -b:a 160k -movflags +faststart -t "$TOTAL" "$OUT"

echo "✔ Đã tạo $OUT (${TOTAL}s, ${N} ảnh)"
