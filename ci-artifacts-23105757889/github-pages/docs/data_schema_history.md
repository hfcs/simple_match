# Data Schema History

## v2 (2025-10-07)
- Added `status` field to `StageResult` model to track completion status (Completed, DNF, DQ).
- Migration: Default all existing records to "Completed".
 - Added `roRemark` field to `StageResult` to store a referee/RO remark (string).
 - Migration: Ensure `roRemark` exists on migrated records and default to an empty string.

## v1 (Initial Release)
- Initial schema for stages, shooters, and stage results.
- No migrations have occurred as of this date.