#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version is required}"
ZIP_PATH="${2:?zip path is required}"
OUTPUT_PATH="${3:-dist/release/killswitch.rb}"
REPOSITORY="${GITHUB_REPOSITORY:-}"
BUNDLE_ID="com.killswitch.app"

if [[ -z "$REPOSITORY" ]]; then
  echo "GITHUB_REPOSITORY must be set to render the cask file." >&2
  exit 2
fi

SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
HOMEPAGE="https://github.com/$REPOSITORY"
URL="$HOMEPAGE/releases/download/v$VERSION/KillSwitch.zip"

cat >"$OUTPUT_PATH" <<EOF
cask "killswitch" do
  version "$VERSION"
  sha256 "$SHA256"

  url "$URL"
  name "KillSwitch"
  desc "Lightweight macOS menu bar utility for seeing memory pressure and quickly quitting heavy apps"
  homepage "$HOMEPAGE"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "KillSwitch.app"

  zap trash: [
    "~/Library/Application Support/KillSwitch",
    "~/Library/Preferences/$BUNDLE_ID.plist",
  ]
end
EOF

printf 'Wrote %s\n' "$OUTPUT_PATH"
