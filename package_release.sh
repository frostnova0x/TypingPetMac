#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

./build_app.sh universal

STAGE="dist_out/TypingPetMac"
rm -rf dist_out
mkdir -p "$STAGE"

cp -R TypingPetMac.app "$STAGE/"
cp dist_template/Install.command "$STAGE/"
cp dist_template/README.txt "$STAGE/"
chmod +x "$STAGE/Install.command"

ZIP_NAME="TypingPetMac.zip"
(cd dist_out && ditto -c -k --sequesterRsrc --keepParent TypingPetMac "$ZIP_NAME")
mv "dist_out/$ZIP_NAME" "./$ZIP_NAME"
rm -rf dist_out

echo "Packaged ./$ZIP_NAME"
