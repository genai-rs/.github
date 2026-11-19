# Reusable Rust CI workflow

[`.github/workflows/rust-ci.yml`](../.github/workflows/rust-ci.yml) runs fmt,
clippy (stable + MSRV), tests (OS x {stable, MSRV}), docs, semver-checks and
coverage. Minimal call:

```yaml
jobs:
  ci:
    permissions:
      contents: read
      issues: write   # the "CI is failing on main" issue
      actions: read   # the failed jobs listed in it
    uses: genai-rs/.github/.github/workflows/rust-ci.yml@main
    with: { msrv: "1.88" }
    secrets: inherit
```

The permissions are for [`main-status`](gate.md#a-red-main): a called workflow
gets no more than its caller grants, and a caller that grants less fails to
start.

## Inputs

All optional except `msrv`:

| Input               | Type    | Default                                              | Purpose                                             |
| ------------------- | ------- | ---------------------------------------------------- | --------------------------------------------------- |
| `msrv`              | string  | (required)                                           | Toolchain for the `msrv` matrix entries             |
| `features`          | string  | `--all-features`                                     | Flags passed to clippy, test, doc and coverage      |
| `run-semver-checks` | boolean | `true`                                               | Run `cargo-semver-checks`                           |
| `run-coverage`      | boolean | `true`                                               | Run `cargo-llvm-cov` and upload to Codecov          |
| `run-doc`           | boolean | `true`                                               | Build docs with `RUSTDOCFLAGS=-D warnings`          |
| `generated-crate`   | boolean | `false`                                              | Generated crate: skips semver-checks and coverage   |
| `os-matrix`         | string  | `["ubuntu-latest","macos-latest","windows-latest"]`  | JSON array of runners for the test matrix           |
| `local-ci-wait-seconds` | number | `60`                                            | How long the [gate](gate.md) waits for a `local-ci` status |
| `wasm-clippy-args`  | string  | `""`                                                 | Lines of `cargo clippy --target wasm32-unknown-unknown <line> -- -D warnings` ([`wasm` job](wasm.md)) |
| `wasm-test-args`    | string  | `""`                                                 | Lines of `cargo test --target wasm32-unknown-unknown <line>` run in Node.js with `wasm-bindgen-test-runner` ([`wasm` job](wasm.md)) |

## Check names

Check names are stable for branch protection: `gate`, `fmt`, `clippy (stable)`,
`clippy (msrv)`, `test (<os>, stable)`, `test (<os>, msrv)`, `doc`,
`semver-checks`. The `msrv` label never changes when the MSRV is bumped.
`main-status` runs on `main` only and is not meant to be required.

The heavy jobs are skipped at step level when the [gate](gate.md) says so, so
they still report under these names with a passing conclusion;
`test (windows-latest, stable)` runs on every pull request. Not meant to be
required checks: `coverage` (informational, `continue-on-error`, and skipped
entirely when the gate skips heavy work), the opt-in [`wasm` job](wasm.md) and
`release-sanity` (runs only for release-plz PRs).

## Repo-specific jobs

Repo-specific jobs (feature-combination tests, live integration tests,
public-API scripts, generator tests) stay in the calling repo's own
workflow next to the `ci` job. Gate the heavy ones with
[`local-ci-gate.yml`](gate.md#gating-a-repos-own-jobs), and add their local
equivalents to `.github/local-ci-extra.sh` so [local-ci](local-ci.md) runs them.

## Triggers and concurrency

Call it from a workflow that runs on `push` to `main` and on `pull_request`
with the default activity types (`opened`, `synchronize`, `reopened`). Do not
add `labeled`, `unlabeled` or `edited`: they start a run without a new commit.
release-plz opens a release PR and labels it within a second, so every label
starts one more run on the same head commit. When those runs share a
`concurrency` group with `cancel-in-progress`, all but one are cancelled, and
the one that survives need not be the newest. A required check counts only its
newest run on the head commit, so a cancelled one leaves the PR blocked until
someone re-runs or reopens it. The jobs that read a label (the `full-ci` label
of the [gate](gate.md#labels), a repo's own label checks) read it from the API
when they run, so a label takes effect with "Re-run all jobs" or the next push.

A `concurrency` group per ref with `cancel-in-progress` is fine with these
triggers: each event starts one run, and the run it cancels is older (a
commit that is no longer the head, or the run a reopen replaces).

```yaml
on:
  push:
    branches: [main]
  pull_request:
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```
