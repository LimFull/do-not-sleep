#!/bin/zsh

set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/dist/DoNotSleep.app"
CONTENTS_DIR="$APP_DIR/Contents"
BINARY_PATH="$PROJECT_DIR/.build/apple/Products/Release/DoNotSleep"

cd "$PROJECT_DIR"
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS"
cp "$BINARY_PATH" "$CONTENTS_DIR/MacOS/DoNotSleep"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
