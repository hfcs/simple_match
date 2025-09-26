# IPSC Match Management App

A robust, test-driven Flutter MVVM application for managing IPSC match stages, shooters, and scoring with scale factors. Modern UI, persistent storage, and export features.

## Features
- **Match Setup:** Configure stages (1-30) and scoring shoots (1-32)
- **Shooter Management:** Add shooters with unique names and scale factors (0.10–2.00)
- **Stage Input:** Record scores with mobile-friendly numeric input, validation, and error feedback
- **Results:** Calculate and display hit factors, adjusted hit factors, and rank shooters
- **Export:** Export all stage results to PDF
- **Persistence:** All data is auto-saved and restored using SharedPreferences
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
- **Hot Reload:** Supported
- **Schema changes:**
  - Increment schema version in `PersistenceService` for breaking changes
  - Add migration logic and integration tests
  - Update `data_schema_history.md` and `docs/data_schema_versioning.md`

## Testing
- All features are covered by widget and logic tests (test-driven development)
- Migration logic is covered by integration tests in `test/persistence_test.dart`

## Documentation
- Data schema history: `data_schema_history.md`
- Schema versioning and migration: `docs/data_schema_versioning.md`
- Developer/contributor instructions: `.github/copilot-instructions.md`

## Getting Started (Flutter)
- [Flutter: Get Started](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Docs](https://docs.flutter.dev/)
