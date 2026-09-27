```markdown
# Data Schema History

> **Last updated:** 2026-09-27

## Version History

- **v1 (Initial Release):**
  - Initial schema for stages, shooters, and stage results.
  - All persisted data is versioned and migration-ready.
  - No breaking changes or migrations have occurred as of this date.

- **v3 (2026-01-09):**
  - Added `classificationScore` (percentage 0-100) to `Shooter` model. Default value for existing shooters is `100.0`.
  - Migration implemented to populate `classificationScore` with `100.0` for persisted shooters missing the field.
  - Updated persistence and export/import to include `classificationScore` on shooter objects.

- **v4 (2026-02-19):**
  - Added per-record audit timestamps: `createdAt` and `updatedAt` (ISO8601 UTC) to the following models: `MatchStage`, `Shooter`, `StageResult`, `TeamGame`.
  - Migration/backfill: existing persisted records missing audit fields are backfilled using the system UTC now (`DateTime.now().toUtc().toIso8601String()`). When `createdAt` is missing, it is set equal to the backfilled `updatedAt` value.
  - Repository change: `MatchRepository` now centralizes stamping `updatedAt` on updates before persisting.
  - Tests: added migration/backfill integration tests and updated widget/unit tests to seed `MatchRepository` deterministically and use `ChangeNotifierProvider` where appropriate.

- **v5 (2026-06-XX):**
  - Renamed legacy timestamp keys to explicit UTC-suffixed fields (`createdAtUtc`, `updatedAtUtc`) for all persisted models.
  - Migration/backfill: older `createdAt` / `updatedAt` payloads are remapped to the UTC-suffixed keys while preserving the original values.
  - Model and persistence serialization were aligned with these canonical UTC names.

- **v6 (2026-09-27):**
  - Added ESS verification metadata to each persisted `Shooter`: `division`, `shooterClass`, and `category`.
  - Migration/backfill: previously stored shooter records missing those keys are backfilled to empty strings so older data remains loadable and exportable.
  - `PortalImporter` CSV export paths now include the metadata columns, and imported shooter details persist the values on the repository records.
  - Regression coverage: v6 migration tests now validate backfilled metadata, and portal importer CSV tests assert the metadata columns are emitted.

## Notes
- All schema changes must be documented here with version, date, and migration details.
- If you change any persisted data structure, increment the schema version and update this file.

```