# Contributing

Thanks for helping improve simple_match. A few guidelines to make contributions smooth.

## Tests & Static Analysis

- Run the test suite before opening a PR:

```sh
flutter test
```

- We added an analyzer regression test (`test/analyzer_regression_test.dart`) which runs `flutter analyze` as part of `flutter test`. Running `flutter test` locally will catch analyzer issues that CI enforces.

- To run only static analysis:

```sh
flutter analyze
```

## Schema migrations

- If you change persisted data structures, bump the schema version in `lib/services/persistence_service.dart` and add migration logic in `PersistenceService._migrateSchema()`.
- Add integration tests that simulate older schema payloads and verify the migrated output. Update `data_schema_history.md` and `docs/data_schema_versioning.md` with details.

## CI / Merge Gate

- The repository uses a merge-gate to dispatch parallel workflows. Reusable workflows must include `workflow_call: {}` and accept an optional `workflow_dispatch` input `merge_run` if they will be dispatched by the merge-gate.
- To run the merge-gate controller locally (for debugging), set `GITHUB_TOKEN` and run:

```bash
export GITHUB_TOKEN=<token>
./.github/scripts/dispatch_and_poll.sh <owner> <repo> <ref> flutter-tests.yml integration-tests.yml coverage.yml coverage-web.yml check-settings-view-coverage.yml
```

## Releases

- The project contains a helper to recreate the `v2026-02-19` release at `.github/scripts/recreate_release.py`. This requires a token with repo permissions. Prefer creating releases via GitHub UI unless you need automated recreation.

## Style

- Follow existing project patterns (MVVM, Provider). Keep code lint-free and tests updated.

Thanks! If you want me to open a PR with these docs changes, say so.
