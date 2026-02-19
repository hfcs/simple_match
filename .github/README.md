CI helper documentation

This folder contains actions and scripts used by the repository CI workflows.

Controller script
- `.github/scripts/dispatch_and_poll.sh` — reusable controller script that dispatches `workflow_dispatch`-enabled workflows and polls their runs until completion. The merge-gate invokes this script to run the suite of tests in parallel.

How to run locally

```bash
export GITHUB_TOKEN=<token-with-repo-scope-or-use-default>
OWNER=hfcs
REPO=simple_match
REF=main
./.github/scripts/dispatch_and_poll.sh "$OWNER" "$REPO" "$REF" flutter-tests.yml integration-tests.yml coverage.yml coverage-web.yml check-settings-view-coverage.yml
```

Adding a new test workflow

1. Add a workflow file into `.github/workflows/`.
2. Ensure it declares `workflow_call` and `workflow_dispatch` so it is callable by the controller and can still be run manually.
3. Add the new workflow filename to the `files=(...)` list in `.github/workflows/merge-gate.yml` preflight check and to the controller dispatch list.
**CI helpers and diagnostics**

This folder documents small CI helpers and diagnostic scripts used by the repository.

- **Composite action:** `.github/actions/ci-setup`
  - Purpose: centralizes common CI environment setup (install `poppler-utils`/`pdftotext`, `lcov`, and `git-lfs`, and performs `git lfs pull`).
  - Inputs:
    - `install_poppler` (true/false)
    - `install_lcov` (true/false)
    - `install_git_lfs` (true/false)
  - Usage (call from a workflow):
    ```yaml
    - name: Run common CI setup
      uses: ./.github/actions/ci-setup
      with:
        install_poppler: 'true'
        install_lcov: 'true'
        install_git_lfs: 'true'
    ```

- **Diagnostic scripts:** `.github/scripts`
  - `verify_required_workflows.sh` — verifies that specified workflow names have a successful run for a given commit SHA.
    - Requires: `GITHUB_TOKEN`, `REPO` (owner/repo), `SHA` (commit). Example:
      ```bash
      GITHUB_TOKEN=$GITHUB_TOKEN REPO=owner/repo SHA=$COMMIT_SHA .github/scripts/verify_required_workflows.sh "Coverage (VM + Chrome)" "coverage-web"
      ```
    - Note: this script is kept for manual diagnostics. The automated Firebase deploy no longer runs this check (Merge Gate is the canonical gate).

  - `monitor_merge_gate.sh` — polls the GitHub Actions API for the `Merge Gate` run corresponding to a commit SHA, downloads logs, and extracts useful diagnostics.
    - Requires: `GITHUB_TOKEN` in the environment. Optional `REPO` env; otherwise derived from `git remote`.
    - Example:
      ```bash
      export GITHUB_TOKEN=ghp_xxx
      export REPO=owner/repo
      .github/scripts/monitor_merge_gate.sh $(git rev-parse HEAD)
      ```
    - Output: logs and extracted archives are saved under `/tmp/monitor_merge_gate` by default.

Keep these utilities as diagnostics (they are safe to run locally) and avoid running them as part of normal automated deploy paths to reduce duplicate work and race conditions.

CI: noop trigger — please ignore this line (used to exercise workflows).
