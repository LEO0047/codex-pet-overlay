#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="CodexPetOverlay"
APP_NAME="Codex Pet Overlay"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

cd "$ROOT_DIR"

SPM_LOG="$(mktemp -t codex-pet-overlay-spm.XXXXXX.log)"
if ! swift build -c "$BUILD_CONFIG" --product "$PRODUCT_NAME" >"$SPM_LOG" 2>&1; then
  echo "SwiftPM build failed; falling back to direct swiftc compilation. Log: $SPM_LOG" >&2
  mkdir -p "$ROOT_DIR/.build/$BUILD_CONFIG"
  # Keep the source layout SwiftPM-compatible while supporting Command Line Tools
  # installations where the PackageDescription manifest API is broken.
  SWIFT_SOURCES=()
  while IFS= read -r source_file; do
    SWIFT_SOURCES+=("$source_file")
  done < <(find "$ROOT_DIR/Sources/CodexPetOverlay" -name '*.swift' | sort)
  swiftc -O -parse-as-library \
    "${SWIFT_SOURCES[@]}" \
    -o "$ROOT_DIR/.build/$BUILD_CONFIG/$PRODUCT_NAME" \
    -framework AppKit \
    -framework SwiftUI \
    -framework ApplicationServices \
    -framework ImageIO
fi

EXECUTABLE="$ROOT_DIR/.build/$BUILD_CONFIG/$PRODUCT_NAME"
if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Missing built executable: $EXECUTABLE" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"
cp "$EXECUTABLE" "$MACOS/$PRODUCT_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS/Info.plist"
cp -R "$ROOT_DIR/Assets" "$RESOURCES/Assets"
cp -R "$ROOT_DIR/config" "$RESOURCES/config"
if [[ -d "$ROOT_DIR/output/lucy-v2/run/overlay-highres" ]]; then
  mkdir -p "$RESOURCES/output/lucy-v2/run"
  cp -R "$ROOT_DIR/output/lucy-v2/run/overlay-highres" "$RESOURCES/output/lucy-v2/run/overlay-highres"
fi

if [[ -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
  cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$CONTENTS/Info.plist" >/dev/null 2>&1 \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS/Info.plist" >/dev/null
fi

codesign --force --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true

echo "$APP_BUNDLE"
