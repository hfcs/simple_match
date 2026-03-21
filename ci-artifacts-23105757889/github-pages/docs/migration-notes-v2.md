# Migration notes: schema v2

Schema v2 introduces two new fields on saved `stageResults` records:

- `status` (string) — one of "Completed", "DNF", or "DQ". Defaults to "Completed"
- `roRemark` (string) — optional remark/note from the range officer (defaults to empty string)

On startup `PersistenceService.ensureSchemaUpToDate()` will run `migrateSchema`
to update older data. The migration is conservative: it reads the raw JSON saved
under `stageResults`, adds missing fields with sensible defaults, writes back
the JSON, and updates the `dataSchemaVersion` key.

See `lib/services/persistence_service.dart` for the exact migration logic and
`test/migration_v2_default_fields_test.dart` for an automated test that
verifies behavior.
