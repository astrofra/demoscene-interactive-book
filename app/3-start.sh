#!/bin/sh
# macOS/ARM equivalent of 3-start.bat
cd "$(dirname "$0")"
# Vanilla Lua on macOS does not search next to the interpreter (unlike Windows).
# Point LUA_CPATH at the macOS toolchain so require("harfang") finds harfang.so.
export LUA_CPATH="$PWD/bin/hg_lua-macos-arm64/?.so;;"
exec ./bin/hg_lua-macos-arm64/lua main.lua
