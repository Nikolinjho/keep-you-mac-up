#!/bin/sh
set -eu

output="${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Helpers/KeepYouAwakeLidGuard"
mkdir -p "$(dirname "$output")"
xcrun --sdk macosx clang -O2 -Wall -Wextra -Werror \
    -mmacosx-version-min=12.0 \
    "$SRCROOT/LidGuard/main.c" -framework IOKit -framework CoreFoundation -o "$output"
