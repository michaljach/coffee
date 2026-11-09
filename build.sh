#!/bin/zsh
# Usage: ./build.sh            build Coffee.app (universal)
#        ./build.sh install    build, replace /Applications/Coffee.app, relaunch
#        ./build.sh release    build and zip to Coffee-<version>.zip (for the Homebrew cask)
set -e
cd "$(dirname "$0")"
VERSION=1.0.0
APP=Coffee.app
TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

rm -rf $APP
mkdir -p $APP/Contents/MacOS
swiftc -O -target arm64-apple-macos12 main.swift -o $TMP/arm64
swiftc -O -target x86_64-apple-macos12 main.swift -o $TMP/x86_64
lipo -create $TMP/arm64 $TMP/x86_64 -output $APP/Contents/MacOS/Coffee
cat > $APP/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Coffee</string>
  <key>CFBundleIdentifier</key><string>com.michaljach.coffee</string>
  <key>CFBundleName</key><string>Coffee</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict></plist>
PLIST
codesign --force -s - $APP
echo "Built $PWD/$APP ($VERSION)"

case "$1" in
  install)
    # /Applications/Coffee.app is user-owned, so no sudo needed to replace it
    pkill -f Contents/MacOS/Coffee || true
    rsync -a --delete $APP/ /Applications/Coffee.app/ && rm -rf $APP
    open /Applications/Coffee.app
    ;;
  release)
    rm -f Coffee-$VERSION.zip
    ditto -c -k --norsrc --noextattr --keepParent $APP Coffee-$VERSION.zip && rm -rf $APP
    shasum -a 256 Coffee-$VERSION.zip
    ;;
esac
