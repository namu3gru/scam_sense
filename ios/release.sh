#!/bin/zsh
# Builds a signed Release archive of ScamSense and uploads it to App Store Connect (TestFlight).
# LOCAL=1 ./release.sh only exports the .ipa (no upload), e.g. before the App Store Connect record exists.
# Needs, on this Mac only (same setup as daily_trio/ios/release.sh):
#   ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8   App Store Connect API key
#   ~/Library/Keychains/sayvroom-signing.keychain-db          Apple Distribution identity
#   ~/.appstoreconnect/signing/keychain.pw                    that keychain's password
#   "ScamSense App Store" provisioning profile installed
set -euo pipefail
cd "$(dirname "$0")"
# The app can't talk to the backend without the real token (README section 5).
# Escape hatches, both explicit:
#   ALLOW_PLACEHOLDER_TOKEN=1 LOCAL=1   signed local export only (no upload)
#   TESTFLIGHT_PLACEHOLDER=1            upload for TestFlight while the server isn't live (AI checks fail);
#                                       never submit such a build for review
if grep -q 'REPLACE_WITH_APP_TOKEN' ScamSense/Core/AppConfig.swift; then
  if [[ -n "${TESTFLIGHT_PLACEHOLDER:-}" ]]; then
    echo "warning: uploading with the placeholder token for TestFlight only. AI checks won't work in this build." >&2
  elif [[ -n "${ALLOW_PLACEHOLDER_TOKEN:-}" && -n "${LOCAL:-}" ]]; then
    echo "warning: placeholder token, local export only." >&2
  else
    echo "error: ScamSense/Core/AppConfig.swift still has REPLACE_WITH_APP_TOKEN. Paste the real APP_TOKEN first." >&2
    exit 1
  fi
fi
ASC_KEY_ID=NNSGPWHMLB
ASC_ISSUER=bb989c3b-f475-4517-80f3-ce12ae4e0c86
AUTH=(-authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8
      -authenticationKeyID $ASC_KEY_ID -authenticationKeyIssuerID $ASC_ISSUER)
OUT=${TMPDIR:-/tmp}/scamsense-release
BUILD=$(date +%Y%m%d%H%M)  # always increasing, so every upload gets a new build number

security unlock-keychain -p "$(cat ~/.appstoreconnect/signing/keychain.pw)" ~/Library/Keychains/sayvroom-signing.keychain-db
rm -rf "$OUT" && mkdir -p "$OUT"
xcodebuild -project ScamSense.xcodeproj -scheme ScamSense -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/ScamSense.xcarchive" archive \
  CURRENT_PROJECT_VERSION=$BUILD \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution" DEVELOPMENT_TEAM=3W7W37MU3Z \
  PROVISIONING_PROFILE_SPECIFIER="ScamSense App Store" \
  OTHER_CODE_SIGN_FLAGS="--keychain $HOME/Library/Keychains/sayvroom-signing.keychain-db" | tail -1
OPTS=ExportOptions.plist
if [[ -n "${LOCAL:-}" ]]; then
  OPTS="$OUT/ExportOptions-local.plist"; cp ExportOptions.plist "$OPTS"
  /usr/libexec/PlistBuddy -c "Set :destination export" "$OPTS"
fi
xcodebuild -exportArchive -archivePath "$OUT/ScamSense.xcarchive" -exportOptionsPlist "$OPTS" \
  -exportPath "$OUT/export" "${AUTH[@]}" | tail -1
if [[ -n "${LOCAL:-}" ]]; then echo "Exported $OUT/export (build $BUILD)"; else echo "Uploaded build $BUILD"; fi
