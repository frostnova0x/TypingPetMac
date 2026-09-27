#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="TypingPetMac.app"
SRC="$SCRIPT_DIR/$APP_NAME"
DEST="/Applications/$APP_NAME"

echo "Installing Typing Pet..."
echo ""

if [ ! -d "$SRC" ]; then
  echo "Couldn't find $APP_NAME next to this installer. Keep this script in the same folder as the .app." >&2
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi

# A copy downloaded from the internet carries a "quarantine" flag that makes
# Gatekeeper block the first launch with an "unidentified developer" warning.
# This app isn't notarized (that requires a paid Apple Developer account), so
# we clear the flag ourselves here -- the same thing you'd otherwise do by
# hand via right-click > Open, just automated.
xattr -dr com.apple.quarantine "$SRC" 2>/dev/null || true

if [ -d "$DEST" ]; then
  echo "Replacing existing installation at $DEST"
  rm -rf "$DEST"
fi

cp -R "$SRC" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "Installed to $DEST"
echo "Launching Typing Pet..."
open "$DEST"

cat <<'EOF'

Typing Pet is running! Look for the paw icon in your menu bar.

First-time setup:
  1. macOS will ask you to grant Accessibility access so the pet can react
     to your keystrokes. Click "Open System Settings" and enable
     TypingPetMac there.
  2. IMPORTANT: after granting it, fully quit Typing Pet (menu bar icon >
     Quit Typing Pet) and reopen it from /Applications once. The
     permission only takes effect on the next launch.
  3. Click the menu bar icon > Settings... > Images tab to pick your own
     character pictures.

EOF
read -n 1 -s -r -p "Press any key to close this window..."
