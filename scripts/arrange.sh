#!/bin/sh
# Move one menu bar icon into an Overfold section by ⌘-dragging it.
# Usage: arrange.sh <process name> visible|hidden|always
# Overfold must be showing everything.
set -eu
cd "$(dirname "$0")/.."
name=$1 section=$2

from=$(./scripts/positions.sh | awk -v n="$name" '{ x=$1; w=$2; $1=$2=""; sub(/^ +/, ""); if ($0 == n) print x + w / 2 }')
[ -n "$from" ] || { echo "no menu bar icon for $name" >&2; exit 1; }

# Overfold's items, right to left: arrow, Hidden divider, Always hidden divider.
set -- $(osascript -e 'tell application "System Events" to get position of menu bar items of menu bar 1 of process "Overfold"' | tr -d ',')
arrow=$1 hidden=$3 always=$5

case $section in
  visible) to=$((arrow + 34)) ;;
  hidden) to=$((hidden + 2)) ;;
  always) to=$((always - 4)) ;;
  *) echo "section must be visible, hidden or always" >&2; exit 1 ;;
esac

.build/cmddrag "$from" "$to"
sleep 1
