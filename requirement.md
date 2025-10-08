
# Requirements for Stage Result Table (Mobile-Friendly)

## Feature: Mobile-Optimized Table with Rotated Headers and Vertical Rules
- The Stage Result view must display a detailed table with columns:
  - Name
  - Raw Hit Factor
  - Scaled Hit Factor
  - Time
  - A
  - C
  - D
  - Misses
  - No Shoots
  - Procedure Errors
- Table header titles must be rotated 90 degrees (vertical) to maximize horizontal space and improve readability on mobile devices.
- Each column (except the last) must have a visible vertical rule (divider) between columns to help users align data to headers.
- Table must remain visually clear, modern, and mobile-optimized.
- All columns must remain visible and readable on small screens.
- Sorting: Table rows are sorted by scaled hit factor (descending).


## Test Coverage
- Widget test must verify:
  - All headers are present and rotated
  - All columns are visible and correct on mobile-sized screens
  - Vertical rules are present between columns in both header and data rows
- PDF export must be tested for Unicode (Traditional Chinese) support using `pdftotext` for robust extraction

## UI/UX
- Use Flutter's `RotatedBox` or equivalent for header rotation.
- Use a `Container` or similar for vertical rules between columns.
- Maintain card-based, modern UI style.
- Ensure accessibility and legibility of rotated headers and vertical rules.

# Result display rules (added)
- If a StageResult is marked DNF or DQ, the Stage Result table and Stage Input results list must display the status (DNF/DQ) instead of the numeric breakdown (Time, A/C/D, Misses, No Shoots, Procedure Errors).
- The RO remark (if present) must always be shown alongside the status or numeric breakdown.
- These display rules must be covered by widget tests.

## Documentation
- This requirement supersedes any previous table header layout for the Stage Result view.
- All documentation and instructions must reflect this mobile-friendly, rotated-header, vertical-rule design.
