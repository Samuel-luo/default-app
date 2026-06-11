#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/DefaultApp.xcodeproj"
SCHEME="DefaultApp"
BUILD_DIR="$ROOT_DIR/build"
DMG_PATH="$BUILD_DIR/DefaultApp.dmg"
STAGING_DIR="$BUILD_DIR/dmg-staging"

# Local unsigned DMG (default):
#   ./Scripts/build-dmg.sh
#
# Signed release DMG:
#   DEVELOPMENT_TEAM=XXXXXXXXXX \
#   SIGNING_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)" \
#   NOTARY_PROFILE=your-notary-profile \
#   ./Scripts/build-dmg.sh --release

RELEASE_BUILD=0
if [[ "${1:-}" == "--release" ]]; then
  RELEASE_BUILD=1
fi

mkdir -p "$BUILD_DIR"
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

if [[ "$RELEASE_BUILD" -eq 1 ]]; then
  ARCHIVE_PATH="$BUILD_DIR/DefaultApp.xcarchive"
  EXPORT_DIR="$BUILD_DIR/export"
  APP_PATH="$EXPORT_DIR/DefaultApp.app"

  echo "==> Building signed Release archive"
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    CODE_SIGN_STYLE="${SIGNING_IDENTITY:+Manual}" \
    ${DEVELOPMENT_TEAM:+DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"} \
    ${SIGNING_IDENTITY:+CODE_SIGN_IDENTITY="$SIGNING_IDENTITY"}

  echo "==> Exporting .app"
  rm -rf "$EXPORT_DIR"
  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$ROOT_DIR/Scripts/ExportOptions.plist"

  cp -R "$APP_PATH" "$STAGING_DIR/"
else
  echo "==> Building unsigned Release .app"
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    build

  cp -R "$BUILD_DIR/DerivedData/Build/Products/Release/DefaultApp.app" "$STAGING_DIR/"
fi

ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG"
hdiutil create \
  -volname "DefaultApp" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  echo "==> Signing DMG"
  codesign --force --sign "$SIGNING_IDENTITY" "$DMG_PATH"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "==> Notarizing DMG"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo "Done: $DMG_PATH"
