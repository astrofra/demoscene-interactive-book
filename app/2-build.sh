#!/bin/sh
# macOS/ARM equivalent of 2-build.bat
# 1. (re)generate video_data.lua from assets/videos via ffprobe
# 2. compile assets/ -> assets_compiled/ with HARFANG assetc (Metal shaders)
set -eu
cd "$(dirname "$0")"

BIN="bin/hg_lua-macos-arm64"
ASSETC="$BIN/harfang/assetc/assetc"

sh bin/tools/video_scan.sh

if [ ! -x "$ASSETC" ]; then
	echo "assetc not found at $ASSETC" >&2
	echo "Build/assemble the macOS toolchain first." >&2
	exit 1
fi

"$ASSETC" assets
echo "Assets compiled to assets_compiled/"
