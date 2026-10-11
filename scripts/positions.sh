#!/bin/sh
# Print every third-party menu bar item as "x width process", left to right.
osascript -e 'tell application "System Events"
set out to ""
repeat with p in (every process)
try
repeat with i in menu bar items of menu bar 2 of p
set out to out & (item 1 of (position of i as list)) & " " & (item 1 of (size of i as list)) & " " & (name of p) & linefeed
end repeat
end try
end repeat
return out
end tell' | sort -n
