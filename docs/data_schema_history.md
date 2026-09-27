# Data Schema History

> **Last updated:** 2026-09-27

## v1 (Initial Release)
- Initial schema for stages, shooters, and stage results.
- No migrations have occurred as of this date.

## v2 (2025-10-07)
- Added `status` to `StageResult` to track completion status (`Completed`, `DNF`, `DQ`).
- Migration: default existing records to `Completed`.
- Added `roRemark` to `StageResult` for referee/RO notes.
- Migration: ensure `roRemark` exists on migrated records and defaults to an empty string.

## v3 (2026-01-09)
- Added `classificationScore` to the persisted `Shooter` model (default `100.0`).
- Migration: backfill missing `classificationScore` for older stored shooter records.

## v4 (2026-02-19)
- Added per-record UTC audit timestamps (`createdAt` and `updatedAt`) to `MatchStage`, `Shooter`, `StageResult`, and `TeamGame`.
- Migration: backfill missing fields using the current UTC timestamp.

## v5 (2026-06-XX)
- Converted legacy timestamp keys to UTC-suffixed names: `createdAtUtc` and `updatedAtUtc`.
- Migration: map legacy values into the UTC-suffixed keys and remove the legacy keys.

## v6 (2026-09-27)
- Added ESS verification metadata to each persisted `Shooter`: `division`, `shooterClass`, and `category`.
- Migration: backfill missing metadata with empty strings for historical shooter data.
- Export/import behavior: CSV export includes the metadata columns and importer persistence writes the metadata back into the repository.
