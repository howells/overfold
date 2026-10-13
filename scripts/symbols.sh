#!/bin/sh
# Rebuild site/src/menubar.svg (inlined into site/public/index.html): SF Symbols rendered large,
# traced to vectors with potrace.
set -eu
cd "$(dirname "$0")/.."
trace=$(mktemp -d)
swiftc -O scripts/symbols.swift -o .build/symbols
.build/symbols "$trace" >/dev/null
for f in "$trace"/*.pgm; do potrace -s --flat -r 2304 -t 4 -a 1 -O 0.2 "$f" -o "${f%.pgm}.svg"; done
python3 scripts/sprite.py "$trace" site/src/menubar.svg
rm -rf "$trace"
