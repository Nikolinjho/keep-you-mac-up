#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

codesign --verify --deep --strict "dist/Keep You Mac Up.app"
staging=$(mktemp -d "${TMPDIR:-/tmp}/KeepYouAwake-dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT
ditto "dist/Keep You Mac Up.app" "$staging/Keep You Mac Up.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname "Keep You Mac Up" -srcfolder "$staging" \
    -format UDZO -ov "dist/Keep You Mac Up.dmg"
hdiutil verify "dist/Keep You Mac Up.dmg"
echo "PACKAGE CREATED: $PWD/dist/Keep You Mac Up.dmg"
