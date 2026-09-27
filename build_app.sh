#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Usage: ./build_app.sh [debug|release|universal] [signing-identity]
#   debug     - fast local iteration, arm64 only, signed with local dev cert
#   release   - optimized, arm64 only, signed with local dev cert
#   universal - optimized, arm64+x86_64 fat binary, ad-hoc signed by default
#               (this is the mode to use for a build you hand to someone else)
MODE="${1:-debug}"
SIGN_IDENTITY="${2:-}"

case "$MODE" in
  universal)
    BUILD_ARGS=(--arch arm64 --arch x86_64 -c release)
    SIGN_IDENTITY="${SIGN_IDENTITY:--}"
    ;;
  release)
    BUILD_ARGS=(-c release)
    SIGN_IDENTITY="${SIGN_IDENTITY:-TypingPetMac Dev}"
    ;;
  *)
    BUILD_ARGS=(-c debug)
    SIGN_IDENTITY="${SIGN_IDENTITY:-TypingPetMac Dev}"
    ;;
esac

swift build "${BUILD_ARGS[@]}"
BIN_PATH=$(swift build "${BUILD_ARGS[@]}" --show-bin-path)
APP="TypingPetMac.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/TypingPetMac" "$APP/Contents/MacOS/TypingPetMac"
cp Info.plist "$APP/Contents/Info.plist"

# SwiftPM's resource bundle for this target (default images).
if [ -d "$BIN_PATH/TypingPetMac_TypingPetMac.bundle" ]; then
  cp -R "$BIN_PATH/TypingPetMac_TypingPetMac.bundle" "$APP/Contents/Resources/"
fi

codesign --force --deep --sign "$SIGN_IDENTITY" "$APP"

echo "Built $APP (mode=$MODE, signed with '$SIGN_IDENTITY')"
lipo -info "$APP/Contents/MacOS/TypingPetMac" 2>/dev/null || file "$APP/Contents/MacOS/TypingPetMac"
