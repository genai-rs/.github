# genai-rs/.github

Shared GitHub configuration for the genai-rs Rust crates: reusable CI and
security workflows, a canonical `deny.toml` and a Renovate preset.

## Reusable CI workflow

[`.github/workflows/rust-ci.yml`](.github/workflows/rust-ci.yml) runs fmt,
clippy (stable + MSRV), tests (OS x {stable, MSRV}), docs, semver-checks and
coverage. Minimal call:

```yaml
jobs:
  ci:
    uses: genai-rs/.github/.github/workflows/rust-ci.yml@main
    with: { msrv: "1.88" }
    secrets: inherit
```

Inputs (all optional except `msrv`):

| Input               | Type    | Default                                              | Purpose                                             |
| ------------------- | ------- | ---------------------------------------------------- | --------------------------------------------------- |
| `msrv`              | string  | (required)                                           | Toolchain for the `msrv` matrix entries             |
| `features`          | string  | `--all-features`                                     | Flags passed to clippy, test, doc and coverage      |
| `run-semver-checks` | boolean | `true`                                               | Run `cargo-semver-checks`                           |
| `run-coverage`      | boolean | `true`                                               | Run `cargo-llvm-cov` and upload to Codecov          |
| `run-doc`           | boolean | `true`                                               | Build docs with `RUSTDOCFLAGS=-D warnings`          |
| `generated-crate`   | boolean | `false`                                              | Generated crate: skips semver-checks and coverage   |
| `os-matrix`         | string  | `["ubuntu-latest","macos-latest","windows-latest"]`  | JSON array of runners for the test matrix           |
| `local-ci-wait-seconds` | number | `60`                                            | How long the gate waits for a `local-ci` status     |

Check names are stable for branch protection: `fmt`, `clippy (stable)`,
`clippy (msrv)`, `test (ubuntu-latest, stable)`, `test (ubuntu-latest, msrv)`,
`doc`, `semver-checks`, `coverage`. The `msrv` label never changes when the
MSRV is bumped.

Repo-specific jobs (feature-combination tests, live integration tests,
public-API scripts, generator tests) stay in the calling repo's own
workflow next to the `ci` job.

## Cheap CI: local-ci attestation, release PRs, macOS/Windows on main

A `gate` job (`ci / gate`) decides how much heavy work a commit needs:

| Situation                                                                 | Mode       | Heavy jobs (clippy, test, doc, semver-checks, coverage, repo build/udeps/feature jobs) |
| ------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------ |
| push to `main`, schedule, manual dispatch                                 | `full`     | all, on every OS                                                                     |
| PR (incl. forks) without attestation                                      | `full`     | all on Linux; macOS/Windows entries skipped (label the PR `full-ci` to run them)     |
| same-repo PR whose head commit has a `local-ci` = success status          | `local-ci` | skipped                                                                              |
| release-plz PR (bot author, `release-plz-*` / `automated/release-plz/*`) touching only `Cargo.toml`, `Cargo.lock`, `CHANGELOG.md` | `release` | skipped; `release-sanity` runs `cargo check` + `cargo package --no-verify` |

Skipped jobs keep their matrix and skip at step level on an ubuntu runner, so
every required check (e.g. `ci / test (macos-latest, msrv)`) is still reported
with its usual name and a passing conclusion. `fmt`, cargo-audit, cargo-deny,
gitleaks, Dependency Review, License Compliance and the cheap repo jobs always
run. If the gate itself fails, everything runs (fail open).

Repos gate their own heavy jobs with
[`local-ci-gate.yml`](.github/workflows/local-ci-gate.yml) (same logic,
outputs `mode`, `heavy`, `all-os`, `reason`; usage in its header).

### Running local-ci

From the root of a crate checkout, on a committed branch:

```sh
# commit not pushed yet: check, then push and attest
bash ../.github/scripts/local-ci.sh --push
# commit already pushed (CI already running): attest and re-run the gated runs
bash ../.github/scripts/local-ci.sh --rerun
# without a local clone of genai-rs/.github:
bash <(gh api repos/genai-rs/.github/contents/scripts/local-ci.sh -H 'Accept: application/vnd.github.raw') --push
```

[`scripts/local-ci.sh`](scripts/local-ci.sh) refuses a dirty tree, reads
`msrv`, `features`, `run-doc`, `run-semver-checks` and `generated-crate` from
the repo's `rust-ci.yml` call and runs on the host: `cargo fmt --check`,
`clippy --all-targets -D warnings` and `cargo test` on stable and on the MSRV,
`cargo doc --no-deps` with `RUSTDOCFLAGS=-D warnings`, `cargo semver-checks`
(not for generated crates), the repo's `cargo +nightly udeps` command when a
workflow runs it, and the repo's `.github/local-ci-extra.sh` (local equivalents
of repo-specific jobs such as a release build or feature combinations). When
all pass it posts the commit status `local-ci` = success (with what ran,
toolchains and host) on HEAD; on failure it posts nothing and exits non-zero.

- `--push` pushes the branch right before posting, so the PR's gate (which
  waits up to 60 s for the status) sees it on the first run.
- `--rerun` (for a commit that was already pushed) cancels and re-runs this
  commit's PR workflow runs that have a gate job and are still running or
  failed, so they pick up the attestation.
- `--no-post` only runs the checks.

Needs `gh` (authenticated, write access to the repo), rustup with the MSRV
toolchain (installed on demand) and nightly, `cargo-semver-checks` and
`cargo-udeps`.

What local-ci does not cover: it runs on one host (usually macOS arm64), so
Linux/Windows-specific breakage and coverage are only caught by the full run on
`main`; live integration tests are unaffected by the gate and keep running.
Fork PRs and pushes to `main` always run the full CI.

## Reusable security workflow

[`.github/workflows/rust-security.yml`](.github/workflows/rust-security.yml)
runs `cargo-audit`, `cargo-deny` (advisories, bans, licenses, sources),
`gitleaks` and CodeQL (CodeQL only on `main` pushes and scheduled runs). The
caller supplies the triggers:

```yaml
name: Security
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
  schedule:
    - cron: "0 2 * * *"
  workflow_dispatch:

jobs:
  security:
    uses: genai-rs/.github/.github/workflows/rust-security.yml@main
    secrets: inherit
```

Inputs: `run-codeql` (default `true`), `run-gitleaks` (default `true`).

`cargo-deny` uses the repo's own `deny.toml` when present and otherwise
downloads the canonical [`deny.toml`](deny.toml) from this repository.

## Renovate preset

Extend [`renovate-default.json`](renovate-default.json) from a repo's
`renovate.json5`:

```json5
{
  extends: ['github>genai-rs/.github:renovate-default'],
}
```

It sets the Monday maintenance window, `chore(deps):` commit prefix,
lockfile maintenance, patch/minor grouping with automerge, isolated pre-1.0
and major updates, and grouped GitHub Actions updates. Add repo-specific
`packageRules` or `customManagers` on top.
