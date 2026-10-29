#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

source_app="$PWD/dist/Keep You Mac Up.app"
destination="/Applications/Keep You Mac Up.app"
if [[ ! -d "$source_app" ]]; then
    echo "Сначала собери приложение: ./scripts/build.sh" >&2
    exit 1
fi
codesign --verify --deep --strict "$source_app"

if pgrep -f '/(KeepYouAwake|Keep You Mac Up)\.app/Contents/MacOS/' >/dev/null; then
    echo "Закрой Keep You Mac Up через Quit и повтори установку." >&2
    exit 1
fi

staging=$(mktemp -d /Applications/.KeepYouAwake-install.XXXXXX)
trap 'rm -rf "$staging"' EXIT
ditto "$source_app" "$staging/Keep You Mac Up.app"
codesign --verify --deep --strict "$staging/Keep You Mac Up.app"
if [[ -e "$destination" ]]; then
    mkdir -p build
    mv "$destination" "build/KeepYouMacUp-installed-$(date +%s).app"
fi
legacy_destination="/Applications/KeepYouAwake.app"
if [[ -e "$legacy_destination" ]]; then
    mkdir -p build
    mv "$legacy_destination" "build/KeepYouAwake-installed-$(date +%s).app"
fi
mv "$staging/Keep You Mac Up.app" "$destination"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$destination"
echo "INSTALLED: $destination"
