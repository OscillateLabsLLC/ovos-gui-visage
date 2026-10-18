#!/usr/bin/env bash
# Builds, signs, optionally notarises and zips the macOS app. docs/PACKAGING.md has the whole flow.
#
#   SIGN_IDENTITY   codesign identity; "-" (the default) signs ad hoc and skips notarisation.
#   NOTARY_PROFILE  a `xcrun notarytool store-credentials` profile (local use), or
#   NOTARY_KEY_PATH, NOTARY_KEY_ID, NOTARY_ISSUER_ID  an App Store Connect API key (CI).
# With a real identity and no notary credentials the app is signed but not notarised, and says so.
set -euo pipefail

cd "$(dirname "$0")/.."

SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ENTITLEMENTS="macos/Runner/Release.entitlements"
DERIVED="build/macos/derived"
APP="$DERIVED/Build/Products/Release/ovos_gui_visage.app"
OUT_DIR="build/release"

VERSION="$(sed -n 's/^version: *\([^+[:space:]]*\).*$/\1/p' pubspec.yaml)"
if [[ -z "$VERSION" ]]; then
  echo "error: no version in pubspec.yaml" >&2
  exit 1
fi
ZIP_NAME="ovos-gui-visage-$VERSION-macos.zip"
ZIP="$OUT_DIR/$ZIP_NAME"

# Notarisation needs the hardened runtime and a secure timestamp; an ad hoc signature cannot have a timestamp.
SIGN_FLAGS=(--force --sign "$SIGN_IDENTITY" --options runtime)
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  SIGN_FLAGS+=(--timestamp)
fi

NOTARY_AUTH=()
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  NOTARY_AUTH=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n "${NOTARY_KEY_PATH:-}" ]]; then
  NOTARY_AUTH=(--key "$NOTARY_KEY_PATH" --key-id "${NOTARY_KEY_ID:?is required with NOTARY_KEY_PATH}"
    --issuer "${NOTARY_ISSUER_ID:?is required with NOTARY_KEY_PATH}")
fi

build_unsigned() {
  flutter pub get
  flutter build macos --release --config-only
  # The build.yml pattern: the Runner project carries a team, so build unsigned and sign below.
  xcodebuild \
    -workspace macos/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    DEVELOPMENT_TEAM="" \
    build
}

sign_app() {
  # Inside out: nested frameworks and dylibs first, the app bundle with its entitlements last.
  while IFS= read -r -d '' item; do
    codesign "${SIGN_FLAGS[@]}" "$item"
  done < <(find "$APP/Contents/Frameworks" -depth \( -name '*.framework' -o -name '*.dylib' \) -print0)
  codesign "${SIGN_FLAGS[@]}" --entitlements "$ENTITLEMENTS" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
}

zip_app() {
  rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
}

notarise() {
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    echo "notarisation skipped: ad hoc signature (set SIGN_IDENTITY to a Developer ID Application identity)"
    return
  fi
  if [[ ${#NOTARY_AUTH[@]} -eq 0 ]]; then
    echo "notarisation skipped: set NOTARY_PROFILE, or NOTARY_KEY_PATH, NOTARY_KEY_ID and NOTARY_ISSUER_ID"
    return
  fi
  # If Apple rejects the submission there is no ticket, so stapler fails and the script stops.
  # `xcrun notarytool log <id>` with the same credentials says why.
  xcrun notarytool submit "$ZIP" "${NOTARY_AUTH[@]}" --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  zip_app
}

mkdir -p "$OUT_DIR"
build_unsigned
sign_app
zip_app
notarise
(cd "$OUT_DIR" && shasum -a 256 "$ZIP_NAME" | tee "$ZIP_NAME.sha256")
echo "built $ZIP (version $VERSION, identity $SIGN_IDENTITY)"
