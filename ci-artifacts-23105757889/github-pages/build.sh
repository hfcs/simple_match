#!/bin/bash
# build.sh - Ensures font is present, then runs flutter build with all arguments
set -e
bash tool/download_fonts.sh
flutter build "$@"
