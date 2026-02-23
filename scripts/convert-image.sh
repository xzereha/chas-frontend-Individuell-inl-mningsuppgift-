#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/convert-hero.sh input_image [output_dir] [sizes_csv]
#   input_image: REQUIRED path to the source image (no default)
#   output_dir: optional, defaults to current working directory (.)
#   sizes_csv: optional, comma-separated widths to generate (e.g. 300,600,900)
# Requires: ffmpeg

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 input_image [output_dir]"
  echo "  input_image: REQUIRED path to the source image (no default)"
  echo "  output_dir: optional, defaults to current working directory (.)"
  exit 1
fi

src="$1"
outdir="${2:-.}"

# derive base filename (without directory or extension) from input
filename=$(basename -- "$src")
name="${filename%.*}"

# default sizes (widths in px)
sizes=(360 412 640 768 1024 1366 1600 1920 2560 5184)

# If a third argument is provided, treat it as a comma-separated override list
if [ "${3:-}" != "" ]; then
  IFS=',' read -r -a sizes <<< "$3"
fi

command -v ffmpeg >/dev/null || { echo "ffmpeg not found in PATH; please install ffmpeg" >&2; exit 1; }

mkdir -p "$outdir"

for w in "${sizes[@]}"; do
  jpg="$outdir/${name}-${w}.jpg"
  webp="$outdir/${name}-${w}.webp"

  # Resize using Lanczos filter; do not upscale (keep original width if smaller)
  ffmpeg -y -i "$src" -vf "scale='if(gt(iw,${w}),${w},iw)':'-1':flags=lanczos" -q:v 3 "$jpg"

  # Encode WebP (lossy) from the resized JPEG
  ffmpeg -y -i "$jpg" -vcodec libwebp -lossless 0 -q:v 75 -preset default "$webp"

  printf "created: %s, %s\n" "$jpg" "$webp"
done
