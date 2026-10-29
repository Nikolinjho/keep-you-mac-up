#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build dist
xcodebuild -workspace KeepingYouAwake.xcworkspace -scheme KeepingYouAwake \
    -configuration Release -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO build > build/build.log 2>&1 || {
        tail -80 build/build.log
        exit 1
    }

app="dist/Keep You Mac Up.app"
if [[ -e "$app" ]]; then
    mv "$app" "build/KeepYouAwake-previous-$(date +%s).app"
fi
ditto "build/Build/Products/Release/Keep You Mac Up.app" "$app"
cp LICENSE "$app/Contents/Resources/LICENSE"
codesign --force --sign - "$app/Contents/Helpers/KeepYouAwakeLidGuard"
codesign --force --sign - --options runtime \
    "$app/Contents/Library/LoginItems/KeepingYouAwake Launcher.app"
codesign --force --sign - --options runtime \
    --entitlements KeepingYouAwake/KeepYouAwake-Local.entitlements "$app"
codesign --verify --deep --strict "$app"
echo "BUILD SUCCEEDED: $PWD/$app"
