#!/bin/zsh
# Builds a signed Release archive of ScamSense and uploads it to App Store Connect (TestFlight).
# LOCAL=1 ./release.sh only exports the .ipa (no upload), e.g. before the App Store Connect record exists.
# Needs, on this Mac only (same setup as daily_trio/ios/release.sh):
#   ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8   App Store Connect API key
#   ~/Library/Keychains/sayvroom-signing.keychain-db          Apple Distribution identity
#   ~/.appstoreconnect/signing/keychain.pw                    that keychain's password
#   ~/.appstoreconnect/apps_api_token                         apps_api APP_TOKEN (64 hex, chmod 600)
#   "ScamSense App Store" provisioning profile installed
set -euo pipefail
cd "$(dirname "$0")"
# The backend token is never committed: it comes from this file and is passed as the APP_TOKEN build setting
# (Info.plist "AppToken"). Refuse to build without it.
TOKEN_FILE=~/.appstoreconnect/apps_api_token
if [[ ! -s $TOKEN_FILE ]] || ! tr -d '\n' < $TOKEN_FILE | grep -Eq '^[0-9a-f]{64}$'; then
  echo "error: $TOKEN_FILE is missing, empty or not a 64-hex token." >&2
  exit 1
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
  CURRENT_PROJECT_VERSION=$BUILD APP_TOKEN="$(tr -d '\n' < $TOKEN_FILE)" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution" DEVELOPMENT_TEAM=3W7W37MU3Z \
  PROVISIONING_PROFILE_SPECIFIER="ScamSense App Store" \
  OTHER_CODE_SIGN_FLAGS="--keychain $HOME/Library/Keychains/sayvroom-signing.keychain-db" | tail -1
OPTS=ExportOptions.plist
if [[ -n "${LOCAL:-}" ]]; then
  OPTS="$OUT/ExportOptions-local.plist"; cp ExportOptions.plist "$OPTS"
  /usr/libexec/PlistBuddy -c "Set :destination export" "$OPTS"
fi
# The archived app must carry a real token (checked by shape only, never printed).
plutil -extract AppToken raw "$OUT/ScamSense.xcarchive/Products/Applications/ScamSense.app/Info.plist" | grep -Eq '^[0-9a-f]{64}$' \
  || { echo "error: archived Info.plist has no valid AppToken." >&2; exit 1; }
echo "archive: AppToken present (64 hex)"
xcodebuild -exportArchive -archivePath "$OUT/ScamSense.xcarchive" -exportOptionsPlist "$OPTS" \
  -exportPath "$OUT/export" "${AUTH[@]}" | tail -1
if [[ -n "${LOCAL:-}" ]]; then echo "Exported $OUT/export (build $BUILD)"; else echo "Uploaded build $BUILD"; fi
