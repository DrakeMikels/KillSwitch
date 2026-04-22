#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="KillSwitch"
BUNDLE_ID="com.killswitch.app"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/script/updater_config.sh"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

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

resolve_bundle_version() {
  local version
  version="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
  if [[ -z "$version" ]]; then
    version="0.1.0"
  fi
  printf '%s\n' "$version"
}

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

codesign_debug_bundle() {
  codesign \
    --force \
    --deep \
    --sign - \
    "$APP_BUNDLE"
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift ./script/render_app_icon.swift
swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
BUNDLE_VERSION="$(resolve_bundle_version)"

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
  <string>$BUNDLE_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
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

codesign_debug_bundle

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
