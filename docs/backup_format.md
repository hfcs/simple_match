# Backup format (MVP)

This document describes the minimal JSON backup format produced/consumed by the app's persistence service (MVP).

Top-level object keys:

- `metadata` — object with:
  - `schemaVersion` (int) — data schema version recorded in SharedPreferences at export time
  - `exportedAt` (string, ISO-8601) — UTC timestamp when export was created
  - `appVersion` (string) — optional, may be `'unknown'` in MVP
  - `platform` (string) — platform where export occurred (e.g., `macos`, `linux`, `android`)

- `stages` — array of stage objects. Each stage object has keys matching the `MatchStage` model:
  - `stage` (int)
  - `scoringShoots` (int)

- `shooters` — array of shooter objects. Each shooter object has keys matching the `Shooter` model:
  - `name` (string)
  - `scaleFactor` (number)

- `stageResults` — array of stage result objects. Each object includes the `StageResult` fields used by the app:
  - `stage` (int)
  - `shooter` (string)
  - `time` (number)
  - `a`, `c`, `d`, `misses`, `noShoots`, `procedureErrors` (ints)
  - `status` (string) — one of `"Completed"`, `"DNF"`, `"DQ"`
  - `roRemark` (string) — referee remark; required (can be empty string)

Notes and behavior
- The import routine performs a basic validation:
  - `stages`, `shooters`, and `stageResults` must exist and be arrays.
  - Individual objects are converted with `Map<String, dynamic>.from(...)` during import.
- The import function supports a `dryRun` mode which validates and returns counts without persisting.
- The import function saves a `backup_before_restore` snapshot in SharedPreferences (MVP) when `backupBeforeRestore` is true.
- Export is plain JSON, written atomically via a temporary file and rename.

Security
- Backups are not encrypted by the MVP; sensitive users should keep backups in secure storage.

Compatibility and migration
- The `metadata.schemaVersion` indicates the data schema version at export time. On import, persisted data is saved using the app's existing persistence APIs which will run migration logic on app startup or on next load.

"MVP" limitation
- No compression, encryption, or large-file streaming is implemented in the MVP. The UI uses the device's application documents directory for saving and listing backups.

