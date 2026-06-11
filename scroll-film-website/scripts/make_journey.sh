#!/usr/bin/env bash
# make_journey.sh — normalize, concatenate, and scrub-encode clips into assets/journey.mp4
# Usage: bash scripts/make_journey.sh assets/clip_01.mp4 assets/clip_02.mp4 ...
#        (or simply: bash scripts/make_journey.sh assets/clip_*.mp4 — shell sorts by name)
# Requires: ffmpeg, ffprobe
set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not found. Install it: brew install ffmpeg | sudo apt install ffmpeg | winget install ffmpeg" >&2
  exit 1
fi
if [ "$#" -lt 2 ]; then
  echo "ERROR: pass at least 2 clip files in story order. Usage: bash scripts/make_journey.sh assets/clip_*.mp4" >&2
  exit 1
fi

OUTDIR="assets"
NORM="$OUTDIR/_norm"
mkdir -p "$NORM"
LIST="$NORM/concat.txt"
: > "$LIST"

echo "== Normalizing ${#} clips (1920x1080, 30fps, yuv420p, silent) =="
i=1
for f in "$@"; do
  [ -f "$f" ] || { echo "ERROR: missing file: $f" >&2; exit 1; }
  n=$(printf '%02d' "$i")
  ffmpeg -y -hide_banner -loglevel error -i "$f" -an \
    -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=30,format=yuv420p" \
    -c:v libx264 -preset slow -crf 20 \
    "$NORM/$n.mp4"
  echo "file '$n.mp4'" >> "$LIST"
  i=$((i+1))
done

echo "== Concatenating + dense-keyframe encode =="
encode() { # $1=scale width:height  $2=keyint  $3=crf  $4=label
  ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$LIST" \
    -vf "scale=$1" \
    -c:v libx264 -preset slow -crf "$3" \
    -x264-params "keyint=$2:min-keyint=$2:scenecut=0" \
    -movflags +faststart -an \
    "$OUTDIR/journey.mp4"
  mb=$(( $(stat -c%s "$OUTDIR/journey.mp4" 2>/dev/null || stat -f%z "$OUTDIR/journey.mp4") / 1048576 ))
  echo "   $4 -> ${mb}MB"
}

MAX_MB=60   # web budget; GitHub hard-rejects >100MB
encode "1920:1080" 2 20 "rung 1: 1080p keyint=2 crf20"
if [ "$mb" -gt "$MAX_MB" ]; then
  echo "   over ${MAX_MB}MB budget — stepping down (scrub stays smooth at keyint 3-4)"
  encode "1920:1080" 3 22 "rung 2: 1080p keyint=3 crf22"
fi
if [ "$mb" -gt "$MAX_MB" ]; then
  encode "1440:810" 4 23 "rung 3: 810p keyint=4 crf23"
fi
if [ "$mb" -gt 95 ]; then
  echo "ERROR: journey.mp4 is ${mb}MB even at the smallest rung — GitHub rejects >100MB and the web load is unacceptable." >&2
  echo "Shorten or remove clips, then re-run. (Git LFS is a workaround for the repo, not for visitors.)" >&2
  exit 1
fi
[ "$mb" -gt "$MAX_MB" ] && echo "WARNING: ${mb}MB exceeds the ${MAX_MB}MB budget but is under GitHub's limit. Consider trimming clips."

echo ""
echo "== Durations (seconds) — record these for the website's beat windows =="
total=0
i=1
for f in "$@"; do
  n=$(printf '%02d' "$i")
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$NORM/$n.mp4")
  echo "  clip $n ($(basename "$f")): $d"
  i=$((i+1))
done
echo "  journey.mp4 total: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUTDIR/journey.mp4")"
size=$(du -h "$OUTDIR/journey.mp4" | cut -f1)
echo ""
echo "DONE -> $OUTDIR/journey.mp4 ($size). Dense keyframes = smooth currentTime scrubbing."
echo "You may delete $NORM/ once satisfied."
