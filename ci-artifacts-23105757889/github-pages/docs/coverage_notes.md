Coverage notes
===============

This project runs unit/widget tests primarily in the web/test harness. Some
files under `lib/views/` implement non-web (dart:io) platform-specific
behaviour (file I/O, path_provider, platform PDF flows). Those files are
validated by device/integration tests and are not exercised by the web unit
tests.

To keep the unit-test coverage report focused on code exercised by the
unit/widget tests, we provide a small helper that filters LCOV output and
removes SF records for known platform-only files before generating HTML.

How to generate a filtered coverage report
-----------------------------------------

1. Run tests with coverage as usual:

```bash
flutter test --coverage
```

2. Filter the produced LCOV:

```bash
tools/filter_lcov.sh coverage/lcov.info coverage/lcov.filtered.info
```

3. Generate HTML from the filtered LCOV file:

```bash
genhtml coverage/lcov.filtered.info -o coverage/html
```

The default `tools/filter_lcov.sh` script removes the following SF records:

- `lib/views/export_utils_io.dart`
- `lib/views/io_file_helpers_io.dart`
- `lib/views/non_web_pdf_utils.dart`

Edit `tools/filter_lcov.sh` to add or remove paths as your coverage policy
changes.
