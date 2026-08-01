# Stability & CI Hardening Plan

## Objective
Harden the import/export and `SettingsView` stability surface so the app can safely support the next feature: multiple clients scoring the same match.

## Scope
- `lib/views/settings_view.dart`
- Portal import UI and validation logic
- Backup import/export flows
- Existing `tools/check_settings_view_coverage.sh` coverage gate
- Regression test coverage for all user-facing import/error branches

## Tasks

### Task 1: Document the hardening plan
- Entry criteria: current feature wiring is stable and import/export is in daily use.
- Exit criteria: `docs/stability_ci_plan.md` exists with task definitions, risk areas, and acceptance criteria.

### Task 2: Add portal import validation regression tests
- Entry criteria: portal import UI branches are exercised in existing tests, but a few validation/error branches are still missing.
- Exit criteria:
  - Negative/zero scale factor validation is covered.
  - Invalid portal URL/shooter number validation is covered.
  - Completed tests pass.

### Task 3: Add import/export fallback and error-handling regression tests
- Entry criteria: import/export paths use test overrides and have broad coverage, but file picker fallback or reload error handling may still be under-tested.
- Exit criteria:
  - Import/export failure branches are explicitly covered.
  - Backup file list/read override paths are covered.
  - Completed tests pass.

### Task 4: Verify coverage gates and CI readiness
- Entry criteria: local `coverage/lcov.info` exists and targeted tests pass.
- Exit criteria:
  - `flutter test` passes for the relevant widget test files.
  - `./tools/check_settings_view_coverage.sh` passes.

### Task 5: Add regression coverage for scroll/overflow stability in `SettingsView`
- Entry criteria: `SettingsView` has a `SingleChildScrollView` wrapper and UI content may still overflow in constrained sizes.
- Exit criteria:
  - A widget test covers `SettingsView` in a narrow viewport.
  - The view renders without overflow exceptions.

## Metrics
- `SettingsView` branch coverage remains above 95%
- No new `SettingsView` overflow regressions
- Import/export stable regression tests added

## Plan execution order
1. Document the plan (`docs/stability_ci_plan.md`).
2. Add missing portal import validation tests.
3. Add import/export fallback/error handling tests.
4. Run coverage gate and fix any remaining issues.
5. Add overflow regression test if needed.

## Progress
- Task 1: completed.
- Task 2: completed. Added portal import validation tests for negative/zero scale factor and invalid portal URL/shooter number.
- Task 3: coverage review shows extensive existing tests for import/export fallback with `pickBackupOverride`, `listBackupsOverride`, `readFileBytesOverride`, `saveExportOverride`, and `postExportOverride` paths. No new gaps were identified in the current `SettingsView` regression coverage.
- Task 4: completed. `flutter test` passes for the updated `SettingsView` widget tests and `tools/check_settings_view_coverage.sh` passes with `97.46%` coverage.
- Task 5: completed. Added a narrow viewport regression test for `SettingsView` and verified no overflow exception.

## Notes
- Keep new tests deterministic by using the existing test overrides in `SettingsView`.
- Focus on user-visible status messaging and branch coverage for failure modes.
- Preserve the existing MVVM/persistence patterns; do not change production runtime behavior for coverage purposes.
+## Next steps
+- Add a future integration test covering import -> score edit -> export to lock in the multi-client scoring readiness path.
+- Continue monitoring `SettingsView` coverage and import/export error handling as the next feature adds shared scoring and collaboration.
