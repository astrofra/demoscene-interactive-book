#!/bin/sh
# macOS/ARM equivalent of _start.bat
cd "$(dirname "$0")"
export LUA_CPATH="$PWD/bin/hg_lua-macos-arm64/?.so;;"
exec ./bin/hg_lua-macos-arm64/lua main.lua > log.txt 2>&1
