#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
APP="$PWD/build/Payload/PocketSnake.app"
mkdir -p "$APP"
xcrun swiftc Snake.swift -parse-as-library -O -sdk "$SDK" \
  -target arm64-apple-ios15.0 -framework SwiftUI -framework UIKit \
  -o "$APP/PocketSnake"
cp Info.plist "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Add :DTPlatformName string iphoneos" "$APP/Info.plist"
plutil -convert binary1 "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"
file "$APP/PocketSnake"
cd build
zip -qry PocketSnake-unsigned.ipa Payload
echo "IPA ready: build/PocketSnake-unsigned.ipa (sign with Sideloadly)"
