# UI testing notes and layout rationale

This short note explains a small layout decision made in `lib/views/stage_input_view.dart`
to improve widget-test stability across different screen sizes.

Why this exists
---------------

Widget tests run in a headless environment and can be sensitive to layouts that
force important interactive controls off-screen (for example: a very large
ConstrainedBox or a tall minHeight). During development we observed hit-test
failures and `Bad state: No element` errors when tests attempted to tap the
Submit button or radio tiles because those controls were pushed out of the
visible/testable area.

What we changed
---------------

- The `StageInput` view uses a responsive `LayoutBuilder` and `ConstrainedBox`
  to size the main content area.
- To avoid the off-screen/tappable-widget problem, we cap the min-height used
  by the layout on very large screens. The cap is intentionally conservative
  (800 logical pixels) to keep controls visible in the test harness while
  still providing a pleasant layout on mobile and tablet devices.

Notes for future maintainers
---------------------------

- If you change the layout significantly (add large header images, add new
  stacked content, or make the view much taller), update this note and run the
  full test suite. If tests complain about hit-testing or tappable widgets,
  consider moving key actions (submit, validation controls) out of scrollable
  regions or increasing the cap slightly.
- This change is intentionally low-risk and avoids hard-coding a single
  breakpoint for all platforms. The cap exists purely to make automated tests
  reliable; on real devices the view remains responsive and scrollable.

See also: `docs/data_schema_versioning.md` and `data_schema_history.md` for
information about persisted data migration.

Generated: minor note to justify a responsive minHeight cap used for test
stability and to guide future layout changes.
