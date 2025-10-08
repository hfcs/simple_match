
# IPSC Match Management App

A robust, test-driven Flutter MVVM application for managing IPSC match stages, shooters, and scoring with scale factors. Modern UI, persistent storage, Unicode PDF export, and advanced test coverage.

## Features
- **Match Setup:** Configure stages (1-30) and scoring shoots (1-32)
- **Shooter Management:** Add shooters with unique names and scale factors (0.10–2.00)
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

## Getting Started (Flutter)
- [Flutter: Get Started](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Docs](https://docs.flutter.dev/)
