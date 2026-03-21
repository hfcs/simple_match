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


```bash
export GITHUB_TOKEN=<token>
./.github/scripts/dispatch_and_poll.sh <owner> <repo> <ref> flutter-tests.yml integration-tests.yml coverage.yml coverage-web.yml check-settings-view-coverage.yml

### Controller script & CI helpers

- The controller script is `.github/scripts/dispatch_and_poll.sh`. It dispatches `workflow_dispatch`-enabled workflows and polls their runs until completion; the top-level `merge-gate.yml` invokes this script to run test suites in parallel.

How to run locally (example):

```bash
export GITHUB_TOKEN=<token-with-repo-scope-or-use-default>
OWNER=hfcs
REPO=simple_match
REF=main
./.github/scripts/dispatch_and_poll.sh "$OWNER" "$REPO" "$REF" flutter-tests.yml integration-tests.yml coverage.yml coverage-web.yml check-settings-view-coverage.yml
```

### Adding a new test workflow

1. Add a workflow file into `.github/workflows/`.
2. Ensure it declares `workflow_call` and `workflow_dispatch` so it is callable by the controller and can still be run manually.
3. Add the new workflow filename to the `files=(...)` list in `.github/workflows/merge-gate.yml` preflight check and to the controller dispatch list.

### CI helpers and diagnostics

- Composite action: `.github/actions/ci-setup` centralizes common CI environment setup (install `poppler-utils`/`pdftotext`, `lcov`, and `git-lfs`, and performs `git lfs pull`).

	Usage (call from a workflow):

	```yaml
	- name: Run common CI setup
		uses: ./.github/actions/ci-setup
		with:
			install_poppler: 'true'
			install_lcov: 'true'
			install_git_lfs: 'true'
	```

- Diagnostic scripts are located in `.github/scripts/` and are intended for manual diagnostics only. Examples:
	- `verify_required_workflows.sh` — verifies that specified workflow names have a successful run for a given commit SHA (requires `GITHUB_TOKEN`, `REPO`, `SHA`).
	- `monitor_merge_gate.sh` — polls the GitHub Actions API for the `Merge Gate` run for a commit SHA, downloads logs, and extracts diagnostics (requires `GITHUB_TOKEN`).

Keep these utilities for debugging; avoid running them in normal automated deploy paths to reduce duplicate work and race conditions.
```

## Releases

- The project contains a helper to recreate the `v2026-02-19` release at `.github/scripts/recreate_release.py`. This requires a token with repo permissions. Prefer creating releases via GitHub UI unless you need automated recreation.

## Style

- Follow existing project patterns (MVVM, Provider). Keep code lint-free and tests updated.

Thanks! If you want me to open a PR with these docs changes, say so.
