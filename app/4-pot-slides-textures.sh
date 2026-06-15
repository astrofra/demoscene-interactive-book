#!/bin/sh
# macOS/ARM equivalent of 4-pot-slides-textures.bat
set -eu
cd "$(dirname "$0")"

PYTHON_BIN="${PYTHON_BIN:-}"

if [ -z "$PYTHON_BIN" ]; then
	if command -v python3 >/dev/null 2>&1; then
		PYTHON_BIN="python3"
	elif command -v python >/dev/null 2>&1; then
		PYTHON_BIN="python"
	else
		echo "Python not found. Install python3 to run pot-slides-textures.py." >&2
		exit 1
	fi
fi

exec "$PYTHON_BIN" pot-slides-textures.py --all-textures "$@"
