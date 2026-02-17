# Release Notes (central)

This file collects the major features, bug fixes, and notable changes across the project's history. Entries are grouped by timeframe and highlight the most significant user-visible or architectural changes.

Unreleased / 2026-02-17
- Interactive time-entry: plain-digit input interprets digits as fixed two-decimal values (e.g. `1234` → `12.34`) and displays an inserted decimal interactively while typing. Backspace fully clears field; explicit `.` edits are preserved. (`stage_input` time-field work)
- Several refinements and bugfixes to time-field deletion, caret behavior, and analyzer warnings.
- Immediate UI refresh when selecting stage/shooter (viewmodel now notifies listeners).

February 2026
- Stabilized test export/import helpers and fixed async test hang by making persistence test helpers deterministic.
- CI diagnostics and self-hosted runner improvements: new diagnostics workflows, gdb capture workflow, and test-chunking/diagnostics improvements.

January 2026
- PDF export improvements: per-stage column widths tuned to match requested character counts; numeric column width adjustments to improve readability on small screens and in PDFs.
- Team match support: added team viewmodel, UI, and tests; ensure assignment refresh on team rename.
- Adjust scaling UI and schema v3 migration for scale-factor changes.

December 2025
- Resizable Stage Input preview, persisted splitter position and improved StageInput UX (resizable panes).
- CI and test infra: many CI workflow fixes (GitHub Actions), LFS/font handling, and desktop/web test improvements.

October — November 2025
- Settings export/import: web-safe exporters, file picker overrides for tests, testing hooks and robust widget tests for import/export flows.
- Robust test suite: many widget/integration tests added to improve coverage and reliability; test harness improvements for CI stability.
- Unicode PDF export: bundled `NotoSerifHK` font to support Traditional Chinese and improve cross-platform PDF rendering.

September 2025 — Initial Feature Set
- MVVM architecture with Provider wiring, persistence repository and `SharedPreferences`-backed storage.
- Implemented core features:
  - Stage input UI (multi-digit numeric fields, +/− buttons, validation, RO/DQ handling)
  - Shooter setup and match setup flows
  - Stage result collection and Overall Result view
  - PDF export of overall results and per-stage tables (TDD)
  - Mobile-friendly Stage Result table with rotated headers and vertical rules between columns
  - Data schema versioning and migration logic with tests

Notes & next steps
- Consider replacing the synchronous test-only IO helper with an in-memory/mock persistence for better test fidelity.
- Improve caret placement behavior for mid-string edits in the time field (future UX enhancement).
- This centralized file is generated from git history (commits and messages). If you'd like, I can refine sections, add links to PRs, or tag notable commits/releases.
