#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="KillSwitch"
BUNDLE_ID="com.killswitch.app"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
API_KEY_PATH="$DIST_DIR/AuthKey.p8"

resolve_developer_dir() {
  if [[ -n "${DEVELOPER_DIR:-}" ]] && [[ -d "$DEVELOPER_DIR" ]]; then
    printf '%s\n' "$DEVELOPER_DIR"
    return 0
  fi

  local candidates=(
    "/Applications/Xcode.app/Contents/Developer"
    "/Volumes/SSD/Applications/Xcode.app/Contents/Developer"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  xcode-select -p 2>/dev/null || true
}

DEVELOPER_DIR="$(resolve_developer_dir)"
export DEVELOPER_DIR

mkdir -p "$DIST_DIR"

swift ./script/render_app_icon.swift
swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -d "$ROOT_DIR/Resources" ]]; then
  mkdir -p "$APP_RESOURCES"
  cp -R "$ROOT_DIR/Resources/." "$APP_RESOURCES/"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    "$APP_BUNDLE"
fi

package_zip() {
  rm -f "$ZIP_PATH"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
}

package_dmg() {
  local dmg_staging
  dmg_staging="$(mktemp -d "$DIST_DIR/dmg-staging.XXXXXX")"
  rm -f "$DMG_PATH"
  cp -R "$APP_BUNDLE" "$dmg_staging/"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$dmg_staging" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    >/dev/null
  rm -rf "$dmg_staging"

  if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign \
      --force \
      --timestamp \
      --sign "$CODESIGN_IDENTITY" \
      "$DMG_PATH"
  fi
}

package_zip

notary_submit() {
  local artifact_path="$1"

  if [[ -n "${APPLE_API_KEY_P8:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
    if [[ ! -f "$API_KEY_PATH" ]]; then
      printf '%s' "$APPLE_API_KEY_P8" >"$API_KEY_PATH"
      chmod 600 "$API_KEY_PATH"
    fi

    xcrun notarytool submit \
      "$artifact_path" \
      --key "$API_KEY_PATH" \
      --key-id "$APPLE_API_KEY_ID" \
      --issuer "$APPLE_API_ISSUER_ID" \
      --wait
    return
  fi

  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
    xcrun notarytool submit \
      "$artifact_path" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_APP_SPECIFIC_PASSWORD" \
      --wait
  fi
}

if [[ -n "${APPLE_API_KEY_P8:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]] || [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  notary_submit "$ZIP_PATH"

  xcrun stapler staple "$APP_BUNDLE"

  package_zip
  package_dmg

  notary_submit "$DMG_PATH"

  xcrun stapler staple "$DMG_PATH"
else
  package_dmg
fi

rm -f "$API_KEY_PATH"

printf 'Packaged %s\n' "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH"
printf 'Packaged %s\n' "$DMG_PATH"
shasum -a 256 "$DMG_PATH"
