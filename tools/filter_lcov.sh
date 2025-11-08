#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <in.lcov> <out.lcov>" >&2
  exit 2
fi

IN="$1"
OUT="$2"

# Files (SF: lines) to remove from the LCOV file. These should match the
# 'SF:' prefixes present in coverage/lcov.info. Edit this list when you want
# to exclude other platform-specific files from the unit-test coverage report.
read -r -d '' FILTER_SF <<'EOF' || true
SF:lib/views/export_utils_io.dart
SF:lib/views/io_file_helpers_io.dart
SF:lib/views/non_web_pdf_utils.dart
EOF

# To avoid newline escaping issues when passing multiline strings to awk,
# write the filter entries to a temporary file and have awk read them.
tmpf=$(mktemp)
trap 'rm -f "$tmpf"' EXIT
printf "%s\n" "$FILTER_SF" | sed '/^$/d' > "$tmpf"

awk -v RS="end_of_record\n" -v ORS="end_of_record\n" -v filterfile="$tmpf" '
  BEGIN {
    while ((getline line < filterfile) > 0) {
      remove[line] = 1;
    }
    close(filterfile);
  }
  {
    split($0, lines, "\n");
    first = "";
    for (i = 1; i <= length(lines); ++i) {
      if (lines[i] != "") { first = lines[i]; break }
    }
    if (!(first in remove)) print $0;
  }
' "$IN" > "$OUT"

echo "Filtered $IN -> $OUT"
