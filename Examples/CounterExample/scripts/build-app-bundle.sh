#!/bin/sh
# Wraps the SwiftPM-built CounterExample executable in a minimal .app bundle
# so XCUIApplication can launch and drive it via the Accessibility API.
# Prints the resulting bundle path on stdout; see
# Tests/CounterExampleUITests/CounterExampleUITests.swift, which reads it
# from the COUNTEREXAMPLE_APP_BUNDLE environment variable.
set -eu

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
swift build --configuration "$CONFIG" >&2

BIN_PATH="$(swift build --configuration "$CONFIG" --show-bin-path)/CounterExample"
APP_DIR=".build/CounterExample.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$BIN_PATH" "$MACOS_DIR/CounterExample"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CounterExample</string>
    <key>CFBundleIdentifier</key>
    <string>com.uniflow.CounterExample</string>
    <key>CFBundleName</key>
    <string>CounterExample</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "$(pwd)/$APP_DIR"
