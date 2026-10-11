#!/bin/sh
# Build Overfold.app, install it to /Applications and relaunch it.
set -eu
cd "$(dirname "$0")/.."

./scripts/bundle.sh
app=build/Overfold.app

pkill -x Overfold || true
rm -rf /Applications/Overfold.app
cp -R "$app" /Applications/Overfold.app
open /Applications/Overfold.app
