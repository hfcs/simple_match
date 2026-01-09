# Data Schema History

> **Last updated:** 2025-10-03

## Version History

- **v1 (Initial Release):**
  - Initial schema for stages, shooters, and stage results.
  - All persisted data is versioned and migration-ready.
  - No breaking changes or migrations have occurred as of this date.

- **v3 (2026-01-09):**
  - Added `classificationScore` (percentage 0-100) to `Shooter` model. Default value for existing shooters is `100.0`.
  - Migration implemented to populate `classificationScore` with `100.0` for persisted shooters missing the field.
  - Updated persistence and export/import to include `classificationScore` on shooter objects.

## Notes
- All schema changes must be documented here with version, date, and migration details.
- If you change any persisted data structure, increment the schema version and update this file.
