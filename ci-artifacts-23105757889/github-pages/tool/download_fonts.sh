#!/bin/bash
# Download the NotoSerifHK variable font used for PDF export automation
set -euo pipefail
# Font dir and safe filename (avoid brackets which get percent-encoded in web builds)
FONT_DIR="assets/fonts"
FONT_FILE="$FONT_DIR/NotoSerifHK-wght.ttf"
# raw GitHub URL (percent-encoded brackets)
URL="https://github.com/notofonts/noto-cjk/raw/refs/heads/main/google-fonts/NotoSerifHK%5Bwght%5D.ttf"

if [ -f "$FONT_FILE" ]; then
  echo "Font already exists at $FONT_FILE. Skipping download."
  exit 0
fi

mkdir -p "$FONT_DIR"
echo "Downloading NotoSerifHK from $URL and saving as NotoSerifHK-wght.ttf..."

# Use curl with fail/retry and a temporary file
curl --fail --show-error --location --retry 3 --retry-delay 5 "$URL" -o "$FONT_FILE.tmp"

# Validate the downloaded file by checking the first 4 bytes using Python
python3 - <<PY
import sys
try:
    b = open('$FONT_FILE.tmp','rb').read(4)
except Exception as e:
    print('Failed to read downloaded file:', e, file=sys.stderr)
    sys.exit(2)
if b == b'\x00\x01\x00\x00' or b == b'ttcf':
    sys.exit(0)
else:
    print('Downloaded file does not look like a TTF/TTC (first 4 bytes:', b, ')', file=sys.stderr)
    sys.exit(3)
PY

# If validation passed, move into place
mv "$FONT_FILE.tmp" "$FONT_FILE"
echo "Font downloaded to $FONT_FILE."

# Also write a bracketed-filename copy for backward compatibility where some
# tools expect the original bracketed name. This ensures both forms exist in
# local CI/workspace environments.
cp -f "$FONT_FILE" "$FONT_DIR/NotoSerifHK[wght].ttf" || true
echo "Also created compatibility copy $FONT_DIR/NotoSerifHK[wght].ttf if permissions allow."
