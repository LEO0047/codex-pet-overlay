#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="CodexPetOverlay"
VERIFY=false

for arg in "$@"; do
  case "$arg" in
    --verify) VERIFY=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

APP_BUNDLE="$("$ROOT_DIR/script/make_app_bundle.sh")"

pkill -x "$PRODUCT_NAME" >/dev/null 2>&1 || true
/usr/bin/open -n "$APP_BUNDLE"
sleep 2

if [[ "$VERIFY" == "true" ]]; then
  "$ROOT_DIR/script/verify.sh"
fi
