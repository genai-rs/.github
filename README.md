# genai-rs/.github

Shared GitHub configuration for the genai-rs Rust crates: reusable CI and
security workflows, a canonical `deny.toml` and a Renovate preset. The
organization profile lives in [`profile/README.md`](profile/README.md).

## Quick start

A crate's `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push: { branches: [main] }
  pull_request:

jobs:
  ci:
    uses: genai-rs/.github/.github/workflows/rust-ci.yml@main
    with: { msrv: "1.88" }   # the crate's rust-version
    secrets: inherit
```

Then, before opening a pull request, run the checks on your machine and attest
them so the PR skips the heavy CI jobs:

```sh
bash ../.github/scripts/local-ci.sh --push
```

## What is here

- **[Reusable Rust CI](docs/rust-ci.md)**: [`rust-ci.yml`](.github/workflows/rust-ci.yml)
  runs fmt, clippy (stable + MSRV), tests (OS x {stable, MSRV}), docs,
  semver-checks and coverage, with stable check names for branch protection.
- **[The gate](docs/gate.md)**: decides per commit whether the heavy jobs run
  (`full`, `local-ci` or `release` mode); repos gate their own heavy jobs with
  [`local-ci-gate.yml`](.github/workflows/local-ci-gate.yml).
- **[local-ci](docs/local-ci.md)**: [`scripts/local-ci.sh`](scripts/local-ci.sh)
  runs the CI checks on your host and posts a `local-ci` commit status.
- **[WebAssembly job](docs/wasm.md)**: the opt-in `wasm` job builds and tests
  for `wasm32-unknown-unknown` in Node.js.
- **[Security workflow](docs/security.md)**: [`rust-security.yml`](.github/workflows/rust-security.yml)
  runs cargo-audit, cargo-deny (with the canonical [`deny.toml`](deny.toml)),
  gitleaks and CodeQL.
- **[Renovate preset](docs/renovate.md)**: [`renovate-default.json`](renovate-default.json).

## Documentation

| Page | Contents |
| ---- | -------- |
| [docs/rust-ci.md](docs/rust-ci.md) | Calling `rust-ci.yml`, its inputs, check names, repo-specific jobs |
| [docs/gate.md](docs/gate.md) | How the gate picks a mode, what is skipped, `local-ci-gate.yml` for repo jobs |
| [docs/local-ci.md](docs/local-ci.md) | Running `local-ci.sh`, what it runs and attests, what it does not cover |
| [docs/wasm.md](docs/wasm.md) | The opt-in `wasm` job |
| [docs/security.md](docs/security.md) | The reusable security workflow and `deny.toml` |
| [docs/renovate.md](docs/renovate.md) | The Renovate preset |
| [docs/client-generation-strategy.md](docs/client-generation-strategy.md) | Client generation strategy by provider, October 2026 decision (history; [evidence](docs/client-generation-strategy-evidence.md)) |
| [docs/client-compatibility-policy.md](docs/client-compatibility-policy.md) | Generated-client compatibility and release decisions |
| [docs/agent-task-contract.md](docs/agent-task-contract.md) | Agent task delivery contract |
| [tools/generator-evaluation](tools/generator-evaluation/README.md) | OpenAPI generator evaluation harness |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributing to this repository |
