# Copilot Instructions for `simple_match`

## Project Overview
- **Type:** Flutter multi-platform IPSC match management application
- **Architecture:** MVVM (Model-View-ViewModel)
- **Entry Point:** `lib/main.dart` (contains main menu and provider setup)
- **Purpose:** Manage IPSC match stages, shooters, and scoring with handicap factors

## Key Structure
- `lib/`
  - `models/` — Data models for match stages, shooters, and stage results
  - `views/` — UI implementations for match setup, shooter setup, and stage input
  - `viewmodel/` — Business logic and state management using Provider
  - `services/` — Data persistence using SharedPreferences
- `test/` — Widget tests using `flutter_test`
- Platform-specific folders (`android/`, `ios/`, etc.) — Auto-generated runners


## Architecture
- **MVVM Pattern:**
   - Views (`lib/views/`) handle only UI and user input
   - ViewModels (`lib/viewmodel/`) manage business logic and state
   - Models (`lib/models/`) define data structures
   - Services (`lib/services/`) handle persistence
- **State Management:** Uses Provider pattern (see `main.dart` for setup)
- **Persistence:**
   - Uses `shared_preferences` for local data storage
   - **Data schema is versioned and backward compatible:**
      - The current schema version is stored in SharedPreferences under `dataSchemaVersion`.
      - Any change to persisted data structure, keys, or logic must increment the schema version.
      - On app startup, the stored schema version is checked. If it is less than the current version, migration logic is run to convert old data to the new format before loading.
      - No key or structure should be changed or removed without migration logic for backward compatibility.
      - Migration logic is implemented in `PersistenceService._migrateSchema()`.
      - All migration logic must be covered by integration tests simulating loading old data and verifying correctness.
      - All schema versions and changes are documented in `data_schema_history.md` and `docs/data_schema_versioning.md`.
- **Data Flow:** ViewModels update state, Views observe changes via `Consumer`

## Data Models
1. **MatchStage** (`models/match_stage.dart`)
   - Stage number (1-30)
   - Scoring shoots count (1-32)
2. **Shooter** (`models/shooter.dart`)
   - Name (unique)
   - Handicap factor (0.00-1.00)
3. **StageResult** (`models/stage_result.dart`)
   - Stage and shooter references
   - Time and hit counts
   - Score calculation logic




## Key Features
- **Match Setup:** Configure stages and scoring shoots (stage number 1-30, scoring shoots 1-32, unique per match)
- **Shooter Management:** Track participants and scale factor (unique name, scale factor 0.10-2.00)
- **Stage Input:** Record and calculate scores with validation. All numeric fields (Time, A, C, D, Misses, No Shoots, Procedure Errors) must support multi-digit input and be mobile-friendly. Input fields for Time, A, C, D, Misses and No Shoots are arranged vertically. Procedure Errors and Submit button are on the same row.
- **Stage Result Table (Mobile-Friendly):**
   - The Stage Result view displays a detailed table with columns: Name, raw hit factor, scaled hit factor, time, A, C, D, misses, no shoots, procedure errors.
   - Table header titles are rotated 90 degrees (vertical) to maximize horizontal space and improve readability on mobile devices.
   - Each column (except the last) has a visible vertical rule (divider) between columns to help users align data to headers.
   - Column widths (in characters): Name: 10, Raw HF: 5, Scaled HF: 5, Time: 5, A: 2, C: 2, D: 2, Misses: 2, No Shoots: 2, Procedure Errors: 2. The largest possible font is used while keeping all columns visible on mobile.
   - Table rows are sorted by scaled hit factor (descending).
   - Table remains visually clear, modern, and mobile-optimized.
- **Overall Result:** Calculate and display hit factor and adjusted hit factor for each shooter, and rank shooters by total adjusted stage point. The PDF export from the Overall Result view must include:
   - An overall ranking table as above
   - For each stage, a detailed table listing all shooters' results for that stage, with columns: Name, raw hit factor, scaled hit factor, time, A, C, D, misses, no shoots, procedure errors
- **Data Persistence:** Auto-saves all changes to local storage using SharedPreferences. All data (stages, shooters, results) must persist to disk and restore on app relaunch.
- **Clear All Data:** User can clear all match data with confirmation.
- **Modern UI:** All pages use cards, icons, and spacing for a visually appealing, mobile-optimized experience. Stage Result table headers are rotated for mobile usability.
- **Unicode PDF Export:** PDF export uses a bundled TTF font (NotoSerifHK) for robust Traditional Chinese and Unicode support across all platforms. Font is downloaded and bundled automatically; no system font dependencies.
- **PDF Export Test:** PDF export is tested using `pdftotext` for robust Unicode extraction. Test will fail if `pdftotext` is not installed.



## Developer Workflows
- **Run app:** `flutter run`
- **Add dependency:** `flutter pub add <package>`
- **Tests:** `flutter test`
- **Test coverage:** `flutter test --coverage` (requires `pdftotext` for PDF export test)
- **Hot Reload:** Supported for rapid UI iteration
- **Schema changes:**
   - Increment schema version in `PersistenceService` if making breaking changes to persisted data.
   - Add migration logic for any schema change.
   - Update `data_schema_history.md` and `docs/data_schema_versioning.md` with details of the change.
   - Add/Update integration tests to cover migration and backward compatibility.


## Project Conventions
- **Test-Driven Development:** All new features and bug fixes must be implemented using a test-driven approach. Always generate or update tests in `test/` before writing or modifying any production code. No code should be added or changed without a corresponding test.
- **Form Validation:** Input constraints enforced in ViewModels. All user input must be validated according to IPSC rules.
- **Error Handling:** Errors returned as strings, displayed via SnackBar. All error cases must be handled with user feedback.
- **State Updates:** All state changes trigger persistence updates. All state changes must trigger persistence.
- **Shared Logic:** Common calculations in model classes.
- **UI Layout:**
   - All input fields must be mobile-friendly and support multi-digit input. Input fields for Time, A, C, D are arranged vertically. Misses and No Shoots are on one row, Procedure Errors and Submit button are on the next row.
   - Stage Result table columns must have vertical rules (dividers) between columns for alignment/readability, and column widths as specified above. Widget tests must verify all columns, rules, and layout on mobile.
   - PDF export must use the bundled Unicode font and be tested for Traditional Chinese/Unicode support.

## Dependencies
- **Flutter SDK:** `^3.9.2`
- **provider:** State management
- **shared_preferences:** Local data persistence

## Example Patterns
- **View Pattern:** See `views/stage_input_view.dart` for complex form handling
- **ViewModel Pattern:** See `viewmodel/stage_input_viewmodel.dart` for business logic
- **Model Pattern:** See `models/stage_result.dart` for domain logic

## Tips for AI Agents
- Maintain MVVM separation of concerns
- Update persistence layer when modifying data models
- Validate inputs according to IPSC rules
- Use Provider for state management
- Handle all error cases with user feedback
- Ensure all UI and logic changes are reflected in tests (test-driven development)
- Ensure all data is persisted and restored using SharedPreferences
- Ensure all UI is mobile-friendly and visually modern

For more, see [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture/guide)
