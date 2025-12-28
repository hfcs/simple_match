# Data Schema History

> **Last updated:** 2025-10-03

## Version History

- **v1 (Initial Release):**
  - Initial schema for stages, shooters, and stage results.
  - All persisted data is versioned and migration-ready.
  - No breaking changes or migrations have occurred as of this date.

- **v3 (2025-12-28):**
  - (Removed) Previous experimental v3 entry that persisted a UI-only splitter preference has been reverted.
  - UI client preferences (window/splitter positions) are not part of the persisted match data model and are excluded from backups/imports.

## Notes
- All schema changes must be documented here with version, date, and migration details.
- If you change any persisted data structure, increment the schema version and update this file.
