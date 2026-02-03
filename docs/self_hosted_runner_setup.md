# Self-hosted runner setup for core dumps and Flutter

This document describes how to prepare a Linux self-hosted runner to execute the `gdb-capture-self-hosted` workflow in this repository. The workflow assumes the runner has Flutter installed and is configured to produce core dumps (ulimit/core_pattern).

Prerequisites
- A Linux VM or host (Ubuntu 22.04/24.04 recommended).
- Root or sudo access to configure kernel settings and systemd service settings.

Steps

1. Install and register a GitHub Actions self-hosted runner

- Follow GitHub docs to create and register a runner for your repository/org:
  - https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners

2. Install Flutter for the runner user

- Install Flutter (stable) and add it to PATH for the `runner` user or the account the actions runner uses.
  - Example (for `runner` user):

```bash
sudo -u runner -i bash <<'B'
git clone https://github.com/flutter/flutter.git /home/runner/flutter
echo 'export PATH="$PATH:/home/runner/flutter/bin"' >> /home/runner/.profile
source /home/runner/.profile
flutter --version
B
```

3. Configure core dump generation

- Enable core dumps and set a useful core_pattern. As root:

```bash
# set core pattern (example: core.<exe>.<pid>.<time>)
sudo sysctl -w kernel.core_pattern='core.%e.%p.%t'

# make persistent across reboots (add to /etc/sysctl.d/99-core.conf)
echo "kernel.core_pattern=core.%e.%p.%t" | sudo tee /etc/sysctl.d/99-core.conf

# Allow unlimited core size for the runner user. If the runner is managed by systemd, create a drop-in
sudo mkdir -p /etc/systemd/system/actions.runner.<your_repo>_service.service.d || true
cat <<'EOF' | sudo tee /etc/systemd/system/actions.runner.service.d/limits.conf
[Service]
LimitCORE=infinity
EOF

# Or add to /etc/security/limits.d/99-runner-limits.conf for PAM sessions:
echo "runner soft core unlimited" | sudo tee /etc/security/limits.d/99-runner-limits.conf
echo "runner hard core unlimited" | sudo tee -a /etc/security/limits.d/99-runner-limits.conf

sudo systemctl daemon-reload
sudo systemctl restart actions.runner.* || true
```

Notes:
- If your runner service runs as a specific user, ensure the `limits.conf` entries are for that user.
- `LimitCORE=infinity` is a systemd setting applied to the runner service unit; use a drop-in file to set it for the runner service.

4. Verify settings on the runner

```bash
# On the runner host
ulimit -c
sysctl kernel.core_pattern
which flutter
flutter --version
```

`ulimit -c` should print `unlimited` (or a large value) and `kernel.core_pattern` should show the pattern you configured.

5. (Optional) Allow non-root access to write cores to workspace

By default, core files might be written to the working directory, /var/crash, or handled by apport. To ensure you can locate them from the workflow:

- Create a directory under the runner workspace that is writable by the runner user and set `kernel.core_uses_pid` if needed.

6. Trigger the workflow

Once the runner is registered and verified, trigger the `gdb-capture-self-hosted` workflow from the Actions UI (or via `gh workflow run`) and choose the test path. The workflow will verify `flutter` and core settings, run the test, then search for core files and upload diagnostics.

If you want, I can dispatch the workflow for `test/debug_main_menu_with_data_test.dart` once you confirm the runner is online and ready.

Runner setup helper scripts
---------------------------

This repository includes three helper scripts to speed up preparing a Linux self-hosted runner. They are not fully-automatic — you must run them on the target host (with root/sudo) and supply the registration token when registering the runner.

- `scripts/setup_selfhosted_runner.sh`: installs common package prerequisites and clones the Flutter SDK into `/opt/flutter`. Run on Ubuntu 22.04/24.04 as root:

```bash
sudo bash scripts/setup_selfhosted_runner.sh
```

- `scripts/configure_core_dumps.sh`: configures `/var/crash`, persistent `kernel.core_pattern`, and writes a limits file `/etc/security/limits.d/99-runner-limits.conf` and a systemd drop-in to permit `LimitCORE=infinity`. Run as root:

```bash
sudo bash scripts/configure_core_dumps.sh
```

- `scripts/register_github_runner.sh`: template helper to download the GitHub Actions runner binary, configure it for your repository, and install/start the runner service. Usage (replace args):

```bash
sudo bash scripts/register_github_runner.sh <owner> <repo> <registration_token> <runner_name> "self-hosted,linux,x64"
```

Notes and next steps
- After running `configure_core_dumps.sh`, verify `sysctl kernel.core_pattern` and `ulimit -c` as the runner user.
- Make sure the user the actions runner service uses (usually `runner`) matches the entries in `/etc/security/limits.d/99-runner-limits.conf` or adjust accordingly.
- Once the runner reports as online in GitHub, trigger the `gdb-capture-self-hosted` workflow. I can dispatch it and help analyze artifacts.

