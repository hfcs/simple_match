# Data Schema History

## Version 1 (2025-09-26)
- Initial schema for all persisted data (shooters, stages, stageResults)
- Keys: 'shooters', 'stages', 'stageResults'
- Structure:
  - shooters: List of {name: String, scaleFactor: double}
  - stages: List of {stage: int, scoringShoots: int}
  - stageResults: List of {stage: int, shooter: String, time: double, a: int, c: int, d: int, misses: int, noShoots: int, procedureErrors: int}
- All persisted as JSON-encoded lists in SharedPreferences

## Changelog
- 2025-09-26: Version 1 grounded. All future changes must be backward compatible. Migration logic and versioning required for any schema change.
