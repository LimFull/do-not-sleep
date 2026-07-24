#!/bin/zsh

set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
VERSION="${1:-1.1.0}"
APP_PATH="$PROJECT_DIR/dist/DoNotSleep.app"
DMG_PATH="$PROJECT_DIR/dist/DoNotSleep-$VERSION-universal.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/do-not-sleep-dmg.XXXXXX")"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if [[ ! -d "$APP_PATH" ]]; then
    "$PROJECT_DIR/scripts/build-app.sh"
fi

cp -R "$APP_PATH" "$STAGING_DIR/DoNotSleep.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "Do Not Sleep" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_PATH"

echo "$DMG_PATH"
