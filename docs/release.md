# Release Notes

KillSwitch is packaged from GitHub Actions and intended to ship as a GitHub Release plus a Homebrew cask.

## CI

`.github/workflows/ci.yml` performs a basic macOS build using `swift build`.

## Release packaging

`.github/workflows/release.yml`:

1. Builds a release binary with the full Xcode toolchain
2. Stages `KillSwitch.app`
3. Optionally signs the app when a Developer ID certificate is available
4. Optionally notarizes and staples the app when Apple credentials are available
5. Packages the bundle as both `KillSwitch.zip` and `KillSwitch.dmg`
6. Generates a Sparkle `appcast.xml` using the actual zip artifact and update signature
7. Generates `killswitch.rb` using the actual zip checksum
8. Uploads all release artifacts to the GitHub Release
9. Publishes the latest `appcast.xml` back to the repository for in-app update checks

## Required release secrets

These are needed for signed releases:

- `APPLE_DEVELOPER_ID_CERTIFICATE_P12`
- `APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `APPLE_DEVELOPER_ID_IDENTITY`

For notarization, configure one of these credential sets:

App Store Connect API key:

- `APPLE_API_KEY_P8`
- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`

Apple ID with app-specific password:

- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

If those secrets are absent, the workflow still produces an unsigned artifact for preview/testing.

## Required updater secret

For Sparkle appcast signing in CI, configure:

- `SPARKLE_PRIVATE_ED_KEY`

This is the exported private EdDSA key for the public `SUPublicEDKey` embedded in the app bundle.
The private key must never be committed to the repository.

## Optional Homebrew tap automation

If you want the release workflow to publish the generated cask into a tap automatically, configure:

- `HOMEBREW_TAP_REPOSITORY`
  Example: `your-org/homebrew-tools`
- `HOMEBREW_TAP_GITHUB_TOKEN`
  A token with write access to that tap repository

Optional GitHub Actions variable:

- `HOMEBREW_TAP_CASK_PATH`
  Defaults to `Casks/killswitch.rb`

## Homebrew flow

The workflow generates a ready-to-publish cask file that points at:

`https://github.com/<owner>/<repo>/releases/download/v<version>/KillSwitch.zip`

Recommended flow:

1. Create a tap repository such as `homebrew-tools` or `homebrew-killswitch`
2. Add the tap secrets above if you want GitHub Actions to update the tap automatically
3. Push a release tag such as `v0.1.0`
4. Let the workflow publish `KillSwitch.zip`, `KillSwitch.dmg`, and `killswitch.rb`
5. Let the workflow publish `appcast.xml` back to the repository for Sparkle clients
6. If tap automation is configured, the workflow commits the cask into the tap for you
7. Install with `brew install --cask <tap>/killswitch`

If tap automation is not configured, the workflow still uploads `killswitch.rb` as a release asset so you can copy it into the tap manually.

## Local packaging

You can package locally with:

```bash
./script/package_release.sh 0.1.0
```

If you want signing or notarization locally, export the same environment variables used in CI before running the script.
Local packaging can sign the Sparkle appcast either with:

- `SPARKLE_PRIVATE_ED_KEY` exported in your shell, or
- a local Sparkle key stored in Keychain under account `com.killswitch.sparkle`
