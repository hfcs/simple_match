# Requirements for Stage Result Table (Mobile-Friendly)

## Feature: Rotated Table Headers for Mobile
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
- Table must remain visually clear, modern, and mobile-optimized.
- All columns must remain visible and readable on small screens.
- Sorting: Table rows are sorted by scaled hit factor (descending).

## Test Coverage
- Widget test must verify that all headers are present and rotated, and that all columns are visible and correct on mobile-sized screens.

## UI/UX
- Use Flutter's `RotatedBox` or equivalent for header rotation.
- Maintain card-based, modern UI style.
- Ensure accessibility and legibility of rotated headers.

## Documentation
- This requirement supersedes any previous table header layout for the Stage Result view.
- All documentation and instructions must reflect this mobile-friendly, rotated-header design.
