# Copilot Instructions for `simple_match`

## Project Overview
- **Type:** Flutter multi-platform app (mobile, web, desktop)
- **Entry Point:** `lib/main.dart` (contains `MyApp` and `MyHomePage`)
- **Purpose:** Starter template for a Flutter application; currently implements a simple counter example.

## Key Structure
- `lib/` — Main Dart source code. All app logic and UI starts from `main.dart`.
- `test/` — Dart widget tests using `flutter_test`. Example: `widget_test.dart` verifies counter increment.
- `android/`, `ios/`, `macos/`, `linux/`, `windows/` — Platform-specific build and runner files. Do not edit unless customizing platform integration.
- `web/` — Web entrypoint and assets.
- `pubspec.yaml` — Declares dependencies, assets, and Flutter settings.
- `analysis_options.yaml` — Linting rules (inherits from `flutter_lints`).

## Developer Workflows
- **Run app:** `flutter run` (auto-detects platform)
- **Build release:** `flutter build <platform>` (e.g., `flutter build apk`, `flutter build ios`, `flutter build web`)
- **Analyze code:** `flutter analyze` (uses rules from `analysis_options.yaml`)
- **Run tests:** `flutter test` (runs all Dart tests in `test/`)
- **Hot reload:** Supported during `flutter run` for rapid UI iteration

## Project Conventions
- **Stateful widgets:** Use `StatefulWidget` for UI with mutable state (see `MyHomePage`).
- **Stateless widgets:** Use `StatelessWidget` for static UI (see `MyApp`).
- **UI structure:** Follows standard Flutter widget tree patterns. No custom architectural patterns (e.g., BLoC, Provider) are present by default.◊◊◊
- **Linting:** Follows `flutter_lints` recommendations. Customize in `analysis_options.yaml` if needed.
- **Assets:** Add to `pubspec.yaml` under `flutter/assets` and place in appropriate directory.

## Integration & Dependencies
- **Flutter SDK**: Version specified in `pubspec.yaml` (`sdk: ^3.9.2`)
- **No custom plugins or external APIs** are integrated by default.
- **Platform code:** Native code in `android/`, `ios/`, etc. is auto-generated; only modify for advanced platform-specific features.

## Example Patterns
- **Widget test:** See `test/widget_test.dart` for a template on UI interaction testing.
- **App entry:** `void main() => runApp(const MyApp());` in `lib/main.dart`.

## Tips for AI Agents
- Focus on `lib/` for app logic and UI.
- Use `flutter` CLI for all builds, tests, and analysis.
- Follow standard Flutter/Dart idioms unless project-specific patterns are introduced.
- When adding features, update `pubspec.yaml` for new dependencies and assets.

---
For more, see [Flutter documentation](https://docs.flutter.dev/).
