# Recent changes (summary)

This file summarizes recent small, but important, changes made to the project so maintainers and reviewers can quickly inspect what changed.

- Models:
  - Added `status` (String) and `roRemark` (String) to `StageResult` (schema v2). Migration logic implemented in `PersistenceService._migrateSchema()` that defaults `status` to 'Completed' and `roRemark` to ''.

- UI / Views:
  - `StageInputView` now has a status selector (Completed / DNF / DQ) and an RO remark input.
  - When status != 'Completed', numeric inputs are disabled and submitting will zero numeric fields.
  - Results list and Stage Result view now display DNF/DQ as status-only rows (no Time or numeric breakdown). The RO remark is displayed when present for any status.

- Tests:
  - Added/updated migration and widget tests to exercise schema v2, DNF/DQ behavior, and RO remark display.
  - Stabilized some StageInput widget tests by capping layout heights and increasing test viewport sizes to avoid off-screen hit-test issues.

- CI / Workflows:
  - Fixed Flutter action usage: use `subosito/flutter-action@v2` with `channel: 'stable'` (previously caused resolution errors when `flutter-version` was used incorrectly).
  - Added `flutter --version` debug step to workflows to surface installer issues in logs.
  - Added `actions/cache@v4` to cache `~/.pub-cache` keyed by `pubspec.yaml` hash.
  - Removed a failing `npm ci` step that was not applicable to this repo.

If you're making schema changes, remember to bump the data schema version and add corresponding migrations and integration tests.
