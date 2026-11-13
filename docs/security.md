# Reusable security workflow

[`.github/workflows/rust-security.yml`](../.github/workflows/rust-security.yml)
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
downloads the canonical [`deny.toml`](../deny.toml) from this repository.
cargo-audit, cargo-deny and gitleaks always run, whatever [the gate](gate.md) decides.
