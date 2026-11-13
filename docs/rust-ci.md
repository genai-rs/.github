# Reusable Rust CI workflow

[`.github/workflows/rust-ci.yml`](../.github/workflows/rust-ci.yml) runs fmt,
clippy (stable + MSRV), tests (OS x {stable, MSRV}), docs, semver-checks and
coverage. Minimal call:

```yaml
jobs:
  ci:
    uses: genai-rs/.github/.github/workflows/rust-ci.yml@main
    with: { msrv: "1.88" }
    secrets: inherit
```

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

Check names are stable for branch protection: `fmt`, `clippy (stable)`,
`clippy (msrv)`, `test (ubuntu-latest, stable)`, `test (ubuntu-latest, msrv)`,
`doc`, `semver-checks`, `coverage`. The `msrv` label never changes when the
MSRV is bumped.

The heavy jobs are skipped at step level when the [gate](gate.md) says so, so
they still report under these names with a passing conclusion. The opt-in
[`wasm` job](wasm.md) is not meant to be a required check.

## Repo-specific jobs

Repo-specific jobs (feature-combination tests, live integration tests,
public-API scripts, generator tests) stay in the calling repo's own
workflow next to the `ci` job. Gate the heavy ones with
[`local-ci-gate.yml`](gate.md#gating-a-repos-own-jobs), and add their local
equivalents to `.github/local-ci-extra.sh` so [local-ci](local-ci.md) runs them.
