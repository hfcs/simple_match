Coverage notes
===============

Why some files are uncovered
----------------------------
This project targets multiple platforms (web + native). Some files under
`lib/views/` are non-web, `dart:io`-based implementations (for example,
`export_utils_io.dart`, `io_file_helpers_io.dart`, and
`non_web_pdf_utils.dart`). The unit/integration tests run in host test
environments that are primarily web-focused, so those IO-only files are
not exercised by default and appear as low/no coverage in `coverage/lcov.info`.

What we changed
---------------
- Added unit tests that exercise the IO helpers (in `test/`) so logic is
  validated. These tests pass locally and in CI.
- To keep the public coverage report focused on code exercised by unit tests
  and avoid skew from platform-only files, we provide a small filtering
  script that removes specific IO-only file blocks from the generated
  LCOV before rendering HTML.

How to generate a filtered coverage HTML report
-----------------------------------------------
1. Run tests and generate LCOV using the existing test workflow:

```bash
flutter test --coverage
```

2. Filter the LCOV to remove IO-only files and regenerate HTML:

```bash
tools/filter_lcov.sh coverage/lcov.info coverage/lcov.filtered.info
genhtml coverage/lcov.filtered.info -o coverage/html
```

Notes for reviewers
-------------------
- The filter is intentionally conservative and only removes the known
  IO-only files. If you later add other platform-only helpers, add them to
  the `FILTER_FILES` list in `tools/filter_lcov.sh`.
- We still keep unit tests that exercise the IO helpers; the filter is only
  for the publicly-visible HTML coverage report to avoid misleading
  percentages when tests are primarily web/VM focused.
