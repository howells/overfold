#!/bin/sh
# Build, sign, notarise and staple Overfold.app and build/Overfold-<version>.dmg.
# Needs a Developer ID Application certificate in the keychain and a notarytool
# keychain profile (default "overfold"; set NOTARY_PROFILE to change it).
set -eu
cd "$(dirname "$0")/.."
identity=${IDENTITY:-"Developer ID Application: Daniel Howells (26GV92ZQ4L)"}
profile=${NOTARY_PROFILE:-overfold}
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)

./scripts/bundle.sh "$identity"
app=build/Overfold.app

ditto -c -k --keepParent "$app" build/Overfold.zip
xcrun notarytool submit build/Overfold.zip --keychain-profile "$profile" --wait
xcrun stapler staple "$app"
rm build/Overfold.zip

dmg=build/Overfold-$version.dmg
rm -f "$dmg"
stage=$(mktemp -d)
cp -R "$app" "$stage/"
create-dmg --volname Overfold --volicon Resources/Overfold.icns \
  --window-size 540 340 --icon-size 112 \
  --icon Overfold.app 140 150 --app-drop-link 400 150 \
  --no-internet-enable "$dmg" "$stage"
rm -rf "$stage"

codesign --force --timestamp --sign "$identity" "$dmg"
xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait
xcrun stapler staple "$dmg"

spctl --assess --type execute -vv "$app"
spctl --assess --type open --context context:primary-signature -vv "$dmg"
echo "$dmg"
