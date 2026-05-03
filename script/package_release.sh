#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Codex Pet Overlay"
DIST_DIR="$ROOT_DIR/dist"

APP_BUNDLE="$("$ROOT_DIR/script/make_app_bundle.sh")"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Missing app bundle: $APP_BUNDLE" >&2
  exit 1
fi

if [[ ! -f "$INFO_PLIST" ]]; then
  echo "Missing Info.plist: $INFO_PLIST" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || true)"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || true)"
VERSION="${VERSION:-dev}"
BUILD="${BUILD:-0}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION+$BUILD-$STAMP.zip"

mkdir -p "$DIST_DIR"
ditto -c -k --norsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "$ZIP_PATH"
