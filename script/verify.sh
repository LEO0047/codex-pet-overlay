#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Codex Pet Overlay"
PRODUCT_NAME="CodexPetOverlay"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
EXECUTABLE="$ROOT_DIR/.build/release/$PRODUCT_NAME"

[[ -x "$EXECUTABLE" ]] || { echo "Missing executable: $EXECUTABLE" >&2; exit 1; }
[[ -d "$APP_BUNDLE" ]] || { echo "Missing app bundle: $APP_BUNDLE" >&2; exit 1; }
[[ -f "$INFO_PLIST" ]] || { echo "Missing Info.plist: $INFO_PLIST" >&2; exit 1; }

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
[[ -n "$BUNDLE_ID" ]] || { echo "CFBundleIdentifier is empty" >&2; exit 1; }

if ! grep -R "setActivationPolicy(.regular)" "$ROOT_DIR/Sources/CodexPetOverlay/App" >/dev/null; then
  echo "Regular activation policy call was not found." >&2
  exit 1
fi

if ! pgrep -x "$PRODUCT_NAME" >/dev/null; then
  echo "Process is not running: $PRODUCT_NAME" >&2
  exit 1
fi

echo "Verified $APP_NAME ($BUNDLE_ID)."
