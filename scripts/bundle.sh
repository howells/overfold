#!/bin/sh
# Build a universal Overfold.app into build/ and sign it.
# Usage: bundle.sh [signing identity]  — defaults to ad-hoc signing.
set -eu
cd "$(dirname "$0")/.."
identity=${1:--}

swift build -c release --arch arm64 --arch x86_64
bin=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)

app=build/Overfold.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/Overfold" "$app/Contents/MacOS/Overfold"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/Overfold.icns "$app/Contents/Resources/Overfold.icns"

if [ "$identity" = - ]; then
  codesign --force --sign - "$app"
else
  codesign --force --options runtime --timestamp --sign "$identity" "$app"
fi
