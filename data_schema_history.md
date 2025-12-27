# Data Schema History

> **Last updated:** 2025-10-03

## Version History

- **v1 (Initial Release):**
  - Initial schema for stages, shooters, and stage results.
  - All persisted data is versioned and migration-ready.
  - No breaking changes or migrations have occurred as of this date.

- **v3 (2025-12-28):**
  - Added persisted UI splitter key `stage_input_fraction_v1` to store StageInput preview split (input/results).
  - Migration: On upgrade to v3, a default value of `2/3` (input gets 2/3, results 1/3) is written if missing; existing values are clamped to safe bounds (0.30–0.85).

## Notes
- All schema changes must be documented here with version, date, and migration details.
- If you change any persisted data structure, increment the schema version and update this file.
