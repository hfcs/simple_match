# Data Schema Versioning

> **Last updated:** 2025-10-03

This document describes the versioning and migration policy for all persisted data in the IPSC Match Management App.

## Versioning Policy
- All persisted data is versioned using a `dataSchemaVersion` key in SharedPreferences.
- Any change to the structure, keys, or logic of persisted data requires incrementing the schema version.
- Schema version must be checked on app startup. If the stored version is less than the current, migration logic must be run before loading data.
- No key or structure should be changed or removed without migration logic for backward compatibility.

## Migration Requirements
- Migration logic is implemented in `PersistenceService._migrateSchema()`.
- All migration logic must be covered by integration tests simulating loading old data and verifying correctness.
- All schema versions and changes must be documented in `data_schema_history.md` and in this file.

## Current Version
- **v1 (Initial Release):**
  - Initial schema for stages, shooters, and stage results.
  - No migrations have occurred as of this date.

## How to Update the Schema Version
1. Increment the schema version in `PersistenceService`.
2. Add migration logic to `PersistenceService._migrateSchema()`.
3. Add or update integration tests to cover migration and backward compatibility.
4. Document the change in `data_schema_history.md` and in this file.

## Example Migration Entry
```
- v2 (2026-01-15):
  - Changed shooter scaleFactor from float to string for locale compatibility.
  - Migration: Convert all stored scaleFactor values to string format.
```

## Notes
- Always ensure backward compatibility for all persisted data.
- Never remove or rename keys without migration logic and documentation.
