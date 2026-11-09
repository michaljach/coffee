#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=Coffee.app
rm -rf $APP
mkdir -p $APP/Contents/MacOS
swiftc -O main.swift -o $APP/Contents/MacOS/Coffee
cat > $APP/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Coffee</string>
  <key>CFBundleIdentifier</key><string>com.michaljach.coffee</string>
  <key>CFBundleName</key><string>Coffee</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict></plist>
PLIST
codesign --force -s - $APP
echo "Built $PWD/$APP"
# Install over the copy in /Applications (bundle is user-owned, no sudo needed) and relaunch
pkill -f Contents/MacOS/Coffee || true
rsync -a --delete $APP/ /Applications/Coffee.app/ && rm -rf $APP
open /Applications/Coffee.app
