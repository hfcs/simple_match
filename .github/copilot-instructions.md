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
- **Persistence:** Uses `shared_preferences` for local data storage
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
- **Match Setup:** Configure stages and scoring shoots
- **Shooter Management:** Track participants and handicaps
- **Stage Input:** Record and calculate scores with validation
- **Data Persistence:** Auto-saves all changes to local storage
- **Score Calculation:** Implements IPSC scoring rules with handicap factors

## Developer Workflows
- **Run app:** `flutter run`
- **Add dependency:** `flutter pub add <package>`
- **Tests:** `flutter test`
- **Hot Reload:** Supported for rapid UI iteration

## Project Conventions
- **Form Validation:** Input constraints enforced in ViewModels
- **Error Handling:** Errors returned as strings, displayed via SnackBar
- **State Updates:** All state changes trigger persistence updates
- **Shared Logic:** Common calculations in model classes

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

For more, see [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture/guide)
