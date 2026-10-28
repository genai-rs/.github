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

Check names are stable for branch protection: `fmt`, `clippy (stable)`,
`clippy (msrv)`, `test (ubuntu-latest, stable)`, `test (ubuntu-latest, msrv)`,
`doc`, `semver-checks`, `coverage`. The `msrv` label never changes when the
MSRV is bumped.

Repo-specific jobs (feature-combination tests, live integration tests,
public-API scripts, generator tests) stay in the calling repo's own
workflow next to the `ci` job.

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
