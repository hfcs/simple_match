# Data Schema Versioning and Migration

## Principles
- The data schema is versioned. The current version is stored in SharedPreferences under the key `dataSchemaVersion`.
- Any change to persisted data structure, keys, or logic must increment the schema version.
- On app startup, the stored schema version is checked. If it is less than the current version, migration logic is run to convert old data to the new format before loading.
- No key or structure should be changed or removed without migration logic for backward compatibility.
- Migration logic is implemented in `PersistenceService._migrateSchema()`.
- All migration logic must be covered by integration tests simulating loading old data and verifying correctness.
- All schema versions and changes are documented in `data_schema_history.md`.

## Implementation
- See `lib/services/persistence_service.dart` for schema versioning and migration logic.
- See `lib/repository/match_repository.dart` for integration of migration on load.
- See `data_schema_history.md` for version history and changelog.

## Testing
- Add integration tests for migration in `test/persistence_test.dart` or similar.
- Simulate loading data from previous schema versions and verify migration and loading are correct.
