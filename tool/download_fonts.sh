#!/bin/bash
# Download NotoSansTC-Regular.ttf for PDF export automation
set -e
FONT_DIR="assets/fonts"
FONT_FILE="$FONT_DIR/NotoSerifHK[wght].ttf"
URL="https://github.com/notofonts/noto-cjk/raw/refs/heads/main/google-fonts/NotoSerifHK%5Bwght%5D.ttf"

if [ -f "$FONT_FILE" ]; then
  echo "Font already exists at $FONT_FILE. Skipping download."
  exit 0
fi

mkdir -p "$FONT_DIR"
echo "Downloading NotoSerifHK[wght].ttf..."
echo "Font downloaded to $FONT_FILE."

curl -L "$URL" -o "$FONT_FILE.tmp"
if head -c 4 "$FONT_FILE.tmp" | grep -q 'ttcf\|\x00\x01\x00\x00'; then
  mv "$FONT_FILE.tmp" "$FONT_FILE"
  echo "Font downloaded to $FONT_FILE."
else
  echo "Download failed or file is not a valid TTF."
  rm -f "$FONT_FILE.tmp"
  exit 1
fi
