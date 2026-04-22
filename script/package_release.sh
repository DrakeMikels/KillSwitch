#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="KillSwitch"
BUNDLE_ID="com.killswitch.app"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/script/updater_config.sh"
DIST_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
APPCAST_PATH="$DIST_DIR/appcast.xml"
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

copy_sparkle_framework() {
  local sparkle_framework
  sparkle_framework="$("$ROOT_DIR/script/resolve_sparkle_distribution.sh" --framework)"

  mkdir -p "$APP_FRAMEWORKS"
  /usr/bin/ditto "$sparkle_framework" "$APP_FRAMEWORKS/Sparkle.framework"
}

ensure_app_framework_rpath() {
  if ! otool -l "$APP_BINARY" | grep -A2 LC_RPATH | grep -q "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY"
  fi
}

codesign_artifact() {
  local artifact_path="$1"

  [[ -n "${CODESIGN_IDENTITY:-}" ]] || return 0

  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    "$artifact_path"
}

codesign_embedded_sparkle() {
  local sparkle_framework="$APP_FRAMEWORKS/Sparkle.framework"

  [[ -n "${CODESIGN_IDENTITY:-}" ]] || return 0
  [[ -d "$sparkle_framework" ]] || return 0

  codesign_artifact "$sparkle_framework/Versions/B/Autoupdate"
  codesign_artifact "$sparkle_framework/Versions/B/XPCServices/Downloader.xpc"
  codesign_artifact "$sparkle_framework/Versions/B/XPCServices/Installer.xpc"
  codesign_artifact "$sparkle_framework/Versions/B/Updater.app"
  codesign_artifact "$sparkle_framework"
}

mkdir -p "$DIST_DIR"

swift ./script/render_app_icon.swift
swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
ensure_app_framework_rpath

if [[ -d "$ROOT_DIR/Resources" ]]; then
  mkdir -p "$APP_RESOURCES"
  cp -R "$ROOT_DIR/Resources/." "$APP_RESOURCES/"
fi

copy_sparkle_framework

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
  <key>SUAutomaticallyUpdate</key>
  <true/>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUFeedURL</key>
  <string>$SPARKLE_APPCAST_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_ED_KEY</string>
  <key>SUVerifyUpdateBeforeExtraction</key>
  <true/>
</dict>
</plist>
PLIST

codesign_embedded_sparkle
codesign_artifact "$APP_BUNDLE"

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

"$ROOT_DIR/script/generate_appcast.sh" "$VERSION" "$ZIP_PATH" "$APPCAST_PATH"

rm -f "$API_KEY_PATH"

printf 'Packaged %s\n' "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH"
printf 'Packaged %s\n' "$DMG_PATH"
shasum -a 256 "$DMG_PATH"
printf 'Packaged %s\n' "$APPCAST_PATH"
