# Data Schema Versioning

> **Last updated:** 2026-09-27

This document describes the versioning and migration policy for all persisted data in the IPSC Match Management App.

## Versioning Policy
- All persisted data is versioned using a `dataSchemaVersion` key in SharedPreferences (managed by `PersistenceService`).
- Any change to the structure, keys, or logic of persisted data requires incrementing the schema version constant in `PersistenceService` and adding migration logic.
- On app startup the stored schema version is checked; if it is less than the current, migration logic must run before loading data.
- Do not remove or rename keys without providing a migration path and tests.

## Migration Requirements
- Migration logic is implemented in `PersistenceService.migrateSchema()`.
- All migration logic must be covered by integration tests that simulate older persisted data and validate the migrated result.
- Document every schema change in `data_schema_history.md` and reflect a concise summary here.

## Current Version
- **v2 (2025-10-07):**
  - Added `status` and `roRemark` to `StageResult`.
  - Migration: default `status` to `Completed` and ensure `roRemark` exists as an empty string.

- **v3 (2026-01-09):**
  - Added `classificationScore` to `Shooter`.
  - Migration: backfill missing `classificationScore` to `100.0`.

- **v4 (2026-02-19):**
  - Purpose: add per-record audit timestamps and ensure consistent `updatedAt` stamping.
  - Models changed:
    - `MatchStage` — added `createdAt` / `updatedAt` as ISO8601 UTC strings.
    - `Shooter` — added `createdAt` / `updatedAt` as ISO8601 UTC strings.
    - `StageResult` — added `createdAt` / `updatedAt` as ISO8601 UTC strings.
    - `TeamGame` — added `createdAt` / `updatedAt` as ISO8601 UTC strings.
  - Migration/backfill: missing values are set using `DateTime.now().toUtc().toIso8601String()`.

- **v5 (2026-06-XX):**
  - Normalized timestamp field names to `createdAtUtc` and `updatedAtUtc` across persisted models.
  - Migration: map legacy `createdAt` / `updatedAt` payloads into the UTC-suffixed keys and remove the legacy keys.

- **v6 (2026-09-27):**
  - Added ESS verification metadata to the persisted `Shooter` model: `division`, `shooterClass`, and `category`.
  - Migration/backfill: missing fields are defaulted to empty strings for older shooter records.
  - Export/import behavior: CSV export includes these metadata columns and imported shooter details store the metadata when writing to the repository.
  - Tests: v6 migration and portal importer regression tests assert the data is backfilled and exported correctly.

## How to Implement a Schema Change (Checklist)
1. Increment `kDataSchemaVersion` in `lib/services/persistence_service.dart`.
2. Add migration logic in `PersistenceService.migrateSchema()` to backfill or transform old keys.
3. Update model `fromJson()` / `toJson()` implementations.
4. Add or update tests covering old payloads and the new persisted shape.
5. Run the project test suite locally.
6. Document the change in `data_schema_history.md` and this file.

## Example Migration Entry (format)
```
- v6 (2026-09-27):
  - Added ESS verification metadata to persisted Shooter entries: division, shooterClass, category.
  - Migration: backfill missing fields with empty strings for legacy records.
  - Tests: migration and CSV export regressions validate the new metadata fields.
```

## Notes
- Always keep migrations backward compatible with older persisted payloads.
- Keep migration logic small, well-tested, and documented in the schema history files.
