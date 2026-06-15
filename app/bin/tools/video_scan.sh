#!/bin/sh
# macOS/POSIX replacement for video_scan.py (no moviepy dependency).
# Scans assets/videos/*.mp4 with ffprobe and writes video_data.lua,
# matching the table format produced by the original Python tool.
#
# Run from the app root (2-build.sh does `cd` there first).
set -eu

VIDEO_DIR="assets/videos"
OUT="video_data.lua"

if ! command -v ffprobe >/dev/null 2>&1; then
	echo "ffprobe not found (brew install ffmpeg)" >&2
	exit 1
fi

printf 'video_metadata = {\n' > "$OUT"

for f in "$VIDEO_DIR"/*.mp4; do
	[ -e "$f" ] || continue
	name=$(basename "$f")

	dur=$(ffprobe -v error -show_entries format=duration \
		-of default=nw=1:nk=1 "$f")
	w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width \
		-of default=nw=1:nk=1 "$f")
	h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height \
		-of default=nw=1:nk=1 "$f")
	rfr=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate \
		-of default=nw=1:nk=1 "$f")   # e.g. 25/1 or 30000/1001

	dur2=$(awk -v d="$dur" 'BEGIN { printf "%.2f", d }')
	fps1=$(echo "$rfr" | awk -F/ '{ printf "%.1f", $1 / $2 }')

	printf "\t['%s'] = { duration = %s, width = %s, height = %s, fps = %s },\n" \
		"$name" "$dur2" "$w" "$h" "$fps1" >> "$OUT"

	echo "Processed $name: ${dur2}s ${w}x${h} ${fps1}fps"
done

printf '}\n' >> "$OUT"
echo "Wrote $OUT"
