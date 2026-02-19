
# IPSC Match Management App

A robust, test-driven Flutter MVVM application for managing IPSC match stages, shooters, and scoring with scale factors. Modern UI, persistent storage, Unicode PDF export, and advanced test coverage.

## Purpose

- **What:** A cross-platform (mobile & desktop) Flutter app to run IPSC-style matches — configure stages, manage shooters, record stage input, and produce ranked results.
- **Who:** Range officers, match directors, and competitors who need a compact, mobile-first scoring tool that preserves data locally and exports official-looking PDFs.
- **Why:** Provides a fast, validated, and auditable workflow for score capture and result calculation with backward-compatible persistence and reproducible tests.
- **Core guarantees:** mobile-optimized input, versioned persistence with migrations, Unicode PDF export using a bundled font, and test-driven development supported by CI.


## Features
- **Match Setup:** Configure stages (1-30) and scoring shoots (1-32)
- **Shooter Management:** Add shooters with unique names and scale factors (0.100–20.000)
- **Stage Input:** Record scores with mobile-friendly numeric input, validation, and error feedback
  - New: results can be marked with a Status ("Completed", "DNF", "DQ"). When a result is not "Completed" numeric inputs are disabled and submitted values are zeroed by the ViewModel. An RO remark field is available for match officials to record notes.
- **Results:** Calculate and display hit factors, adjusted hit factors, and rank shooters
- **Stage Result Table:**
  - Rotated (vertical) header labels for all columns to maximize mobile readability
  - Fixed column widths (in characters): Name: 10, Raw HF: 5, Scaled HF: 5, Time: 5, A: 2, C: 2, D: 2, Misses: 2, No Shoots: 2, Procedure Errors: 2
  - Vertical rules (dividers) between columns for improved alignment and readability on mobile
- **Export:** Export all stage results to PDF (Unicode support, including Traditional Chinese; uses bundled font for cross-platform reliability)
- **Persistence:** All data is auto-saved and restored using SharedPreferences
  - Note: The persisted schema was recently extended (schema v2) to include `status` and `roRemark` on `StageResult`. `PersistenceService` implements a migration path that upgrades older data to the new schema on app startup.
- **Clear All Data:** One-tap clear with confirmation
- **Modern UI:** Card-based, mobile-optimized, visually appealing

## Architecture
- **MVVM Pattern:**
  - Views: UI only (`lib/views/`)
  - ViewModels: Business logic (`lib/viewmodel/`)
  - Models: Data structures (`lib/models/`)
  - Services: Persistence (`lib/services/`)
- **State Management:** Provider
- **Persistence:**
  - Uses `shared_preferences` for local storage
  - **Data schema is versioned and backward compatible**
    - Schema version stored as `dataSchemaVersion` in SharedPreferences
    - Any schema change requires version bump, migration logic, and integration test
    - See `data_schema_history.md` and `docs/data_schema_versioning.md`

## Developer Workflow
- **Run app:** `flutter run`
- **Add dependency:** `flutter pub add <package>`
- **Test:** `flutter test`
  - New/Updated tests: migration tests (schema v2), widget tests for DNF/DQ + RO remark behavior, and additional stability improvements to StageInput widget tests.
  - Note: Shooter `scaleFactor` validation now accepts values in the range 0.100–20.000. Validation is enforced in `lib/viewmodel/shooter_setup_viewmodel.dart` and reflected in `lib/views/shooter_setup_view.dart`.
- **Hot Reload:** Supported
- **Schema changes:**
  - Increment schema version in `PersistenceService` for breaking changes
  - Add migration logic and integration tests
  - Update `data_schema_history.md` and `docs/data_schema_versioning.md`

## Testing
- All features are covered by widget and logic tests (test-driven development)
  - Migration logic is covered by integration tests simulating older schema data being loaded and verified.
- Stage Result table tests verify:
  - All columns and headers are present and rotated
  - All columns are visible and correct on mobile-sized screens
  - Vertical rules are present between columns in both header and data rows
- Migration logic is covered by integration tests in `test/persistence_test.dart`


## Test Coverage
- All core features are covered by unit, widget, and integration tests in `test/`
- ViewModel logic is tested (e.g., `test/viewmodel_main_menu_test.dart`, `test/viewmodel_match_setup_test.dart`)
- Persistence logic is tested (e.g., `test/services_test.dart`)
- Widget navigation and UI are tested (e.g., `test/widget_test.dart`)
- PDF export is tested for Unicode (Traditional Chinese) using `pdftotext` for robust extraction
- All TODOs for tests have been implemented and committed


## How to Run All Tests

```sh
flutter test --coverage
```

## Continuous Integration (CI)

- The repository uses a parallel test controller to run long-running test workflows in parallel. The controller dispatches and polls these reusable workflows:
  - `flutter-tests.yml` — unit tests (Flutter)
  - `integration-tests.yml` — integration tests
  - `coverage.yml` and `coverage-web.yml` — coverage collection (VM + Chrome)
  - `check-settings-view-coverage.yml` — focused coverage check for `settings_view.dart`

- The controller is implemented at `.github/scripts/dispatch_and_poll.sh` and is invoked by the top-level `merge-gate.yml` workflow. It uses `GITHUB_TOKEN` (same-repo) to dispatch workflows and poll runs. For cross-repo dispatch or broader permissions use a PAT with `repo` scope stored in a secret and referenced instead of `GITHUB_TOKEN`.

- To run the controller locally (requires a token):

```bash
export GITHUB_TOKEN=<token>
./.github/scripts/dispatch_and_poll.sh <owner> <repo> <ref> flutter-tests.yml integration-tests.yml coverage.yml coverage-web.yml check-settings-view-coverage.yml
```

## Web + VM Coverage (merged HTML)

To collect merged VM+Chrome coverage and generate an HTML report locally run:

```bash
chmod +x ./scripts/collect_coverage.sh
./scripts/collect_coverage.sh
```

Notes:
- The script tries `flutter test -d chrome --coverage` first (some Flutter versions write lcov that way).
- If that fails it falls back to `--platform chrome` and finally attempts a VM-service based collection (requires `dart` and `dart pub global activate coverage`).
- On CI, ensure Chrome is installed and `CHROME_EXECUTABLE` is set or Chrome is on PATH.


Recent CI notes
- The GitHub workflows were hardened after CI troubleshooting: the Flutter installer action is invoked with `channel: 'stable'`, the job now prints `flutter --version` to logs for easier debugging, and `actions/cache` is used to cache `~/.pub-cache`. An earlier `npm ci` step that caused failures was removed.

### PDF Export Test Requirements
- The PDF export test requires `pdftotext` (from poppler-utils) to be installed for Unicode extraction verification.
- On macOS: `brew install poppler`

## Contributing
- Follow MVVM and Provider patterns
- Write or update tests for all new features and bug fixes
- Keep the codebase warning- and lint-free (`flutter analyze`)
- Document all schema changes and migrations


## Documentation
- Data schema history: `data_schema_history.md`
- Schema versioning and migration: `docs/data_schema_versioning.md`
- Developer/contributor instructions: `.github/copilot-instructions.md`
- Unicode PDF export and font bundling: see `.github/copilot-instructions.md`

## Recent Schema Update (v4)

- The persisted data schema was bumped to **v4** (2026-02-19): per-record audit timestamps `createdAt` and `updatedAt` (ISO8601 UTC) were added to `MatchStage`, `Shooter`, `StageResult`, and `TeamGame`.
- Migration/backfill is performed on app startup by `PersistenceService`; missing timestamps are backfilled using the system UTC now. See `data_schema_history.md` for the changelog and `docs/data_schema_versioning.md` for migration guidance.

## Release tooling

- A helper script to recreate the GitHub release/tag `v2026-02-19` is available at `.github/scripts/recreate_release.py`. It deletes any existing release with that tag and recreates it to point at `main` (requires `GITHUB_TOKEN` with repo access). Use with caution — this modifies releases and git refs.

## CI & Merge-Gate notes

- The repository uses a merge-gate controller `merge-gate.yml` that runs on pushes to `main`. It validates reusable workflows and dispatches parallel test workflows using `.github/scripts/dispatch_and_poll.sh`.
- Reusable workflows must declare `workflow_call` and (when dispatched by the merge-gate) accept an optional `workflow_dispatch` input named `merge_run` so the controller can dispatch them via the API. See `.github/workflows/*.yml` for examples.

## Analyzer Regression Test

- To prevent analyzer regressions from reaching CI we added `test/analyzer_regression_test.dart`. This test runs `flutter analyze` and fails if the analyzer reports issues — run `flutter test` locally to run it.
- Before pushing, run:

```sh
flutter analyze
flutter test
```

The CI runs `flutter analyze` as part of the `flutter-tests.yml` workflow; the merge-gate will fail dispatch if the workflows are not callable or mismatch expected inputs.

## Getting Started (Flutter)
- [Flutter: Get Started](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Docs](https://docs.flutter.dev/)
