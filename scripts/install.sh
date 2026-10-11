#!/bin/sh
# Build Overfold.app, install it to /Applications and relaunch it.
set -eu
cd "$(dirname "$0")/.."

swift build -c release
app=build/Overfold.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/Overfold "$app/Contents/MacOS/Overfold"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"

pkill -x Overfold || true
rm -rf /Applications/Overfold.app
cp -R "$app" /Applications/Overfold.app
open /Applications/Overfold.app
