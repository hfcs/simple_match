# Data Schema Versioning

> **Last updated:** 2026-02-19

This document describes the versioning and migration policy for all persisted data in the IPSC Match Management App.

## Versioning Policy
- All persisted data is versioned using a `dataSchemaVersion` key in SharedPreferences (managed by `PersistenceService`).
- Any change to the structure, keys, or logic of persisted data requires incrementing the schema version constant in `PersistenceService` and adding migration logic.
- On app startup the stored schema version is checked; if it is less than the current, migration logic must run before loading data.
- Do not remove or rename keys without providing a migration path and tests.

## Migration Requirements
- Migration logic is implemented in `PersistenceService._migrateSchema()` (or equivalent migration helper).
- All migration logic must be covered by integration tests that simulate older persisted data and validate the migrated result.
- Document every schema change in `data_schema_history.md` and reflect a concise summary here.

## Current Version
- **v2 (2025-10-07):**
  - Added `status` and `roRemark` to `StageResult`.
  - Migration: default `status` to "Completed" and ensure `roRemark` exists (empty string) for migrated records.

- **v4 (2026-02-19):**
  - Purpose: Add per-record audit timestamps and ensure consistent updatedAt stamping.
  - Models changed:
    - `MatchStage` — added `createdAt` (final) and `updatedAt` (mutable) as ISO8601 UTC strings.
    - `Shooter` — added `createdAt` and `updatedAt` as ISO8601 UTC strings.
    - `StageResult` — added `createdAt` and `updatedAt` as ISO8601 UTC strings.
    - `TeamGame` — added `createdAt` and `updatedAt` as ISO8601 UTC strings.
  - Persistence changes:
    - `kDataSchemaVersion` in `PersistenceService` set to `4`.
    - Migration/backfill: when migrating from older versions, missing `createdAt` and `updatedAt` are populated using `DateTime.now().toUtc().toIso8601String()` for both fields. Existing records that lack `createdAt` receive the same timestamp as `updatedAt` during backfill.
    - All model `toJson()`/`fromJson()` implementations were updated to (de)serialize the new fields.
  - Repository behavior:
    - `MatchRepository` centralizes `updatedAt` stamping: repository update/save methods now set `updatedAt = DateTime.now().toUtc().toIso8601String()` for records being modified before persisting.
    - The repository persists models via their `toJson()` so audit fields are stored alongside other fields.
  - ViewModel / API notes:
    - ViewModels were adjusted to preserve existing synchronous validation return types (so UI and tests continue to receive immediate `String?` validation results) while performing persistence asynchronously to avoid UI jank.
    - `StageResultViewModel` was made backwards-compatible for dependency injection (accepting either a `PersistenceService` or a `MatchRepository`) and its local caches are defensive mutable copies to avoid accidental mutation of unmodifiable repo lists in tests.
  - Tests & CI:
    - Add integration tests that simulate older schema payloads and verify the v4 migration produces valid records with `createdAt`/`updatedAt`.
    - Update widget/unit tests that rely on repository providers to use `ChangeNotifierProvider` for `MatchRepository` and to seed repositories deterministically where needed.

## How to Implement a Schema Change (Checklist)
1. Increment `kDataSchemaVersion` in `lib/services/persistence_service.dart`.
2. Implement migration logic in `PersistenceService._migrateSchema()` to transform/backfill old keys to the new shape.
3. Update all affected model `fromJson()` / `toJson()` implementations.
4. Add or update unit/integration tests that:
   - Load a persisted payload at the old schema version and assert migration produces expected results.
   - Validate any behavioral changes (e.g., repository stamping of `updatedAt`).
5. Run the full test-suite locally and in CI. Use deterministic seeding for repository-backed tests to avoid race conditions.
6. Document the change in `data_schema_history.md` with date, version, and migration notes.

## Example Migration Entry (format)
```
- v4 (2026-02-19):
  - Added per-record `createdAt` and `updatedAt` (ISO8601 UTC) to MatchStage, Shooter, StageResult, TeamGame.
  - Migration: backfill missing timestamps using the system UTC now; repository stamps `updatedAt` on updates.
  - Tests: added migration/backfill integration tests and updated provider-based widget tests to seed `MatchRepository` deterministically.
```

## Notes
- Always ensure migrations are reversible where practical for test harnesses (e.g., provide dry-run import paths).
- Keep migration logic small, well-tested, and documented in `data_schema_history.md`.
