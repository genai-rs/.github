# Reusable release workflow

[`.github/workflows/release-plz.yml`](../.github/workflows/release-plz.yml) runs
[release-plz](https://release-plz.dev) the same way in every crate:

- **On a push to main**, the `Release` job publishes every crate whose version
  is not on crates.io yet, with a tag and a GitHub release, and the `Release PR`
  job opens or updates the release PR (versions and changelogs from the
  conventional commits). Only `Release` can publish, through
  [Trusted Publishing](trusted-publishing.md).
- So **merging the release PR publishes**. Reviewing that PR is the release
  decision: check the proposed versions, and mark breaking changes with `!` or
  `BREAKING CHANGE:` before merging.
- **Dispatched from another branch**, it runs `release --dry-run`: a check that
  a release would succeed, without a PR or a publish.

A crate's `.github/workflows/release-plz.yml`:

```yaml
name: Release-plz
on:
  push: { branches: [main] }
  workflow_dispatch:
permissions:
  contents: write
  pull-requests: write
  id-token: write
jobs:
  release-plz:
    uses: genai-rs/.github/.github/workflows/release-plz.yml@main
    secrets: inherit
```

A crate that is not at the repo root passes `manifest-path` and `config`
(`with: { manifest-path: runtime/Cargo.toml, config: runtime/release-plz.toml }`).
A caller outside the genai-rs organization passes the secrets by name instead
of `secrets: inherit`.

## Secrets

| Secret | Purpose |
| ------ | ------- |
| `BOT_APP_ID`, `BOT_PRIVATE_KEY` | The GitHub App whose token opens the release PR, so its pushes trigger CI |
| `CARGO_REGISTRY_TOKEN` | Only for a crate's [first release](trusted-publishing.md#a-new-crate), or a repo not on Trusted Publishing yet ([rotating it](token-rotation.md)) |

## Per crate

What differs per crate stays in its `release-plz.toml`: tag names, changelog
and PR text, packages that are never released (`release = false`), version
groups.

## A new repository

A repository that publishes a crate needs:

- **The caller workflow** above, as `.github/workflows/release-plz.yml`, and a
  `release-plz.toml`.
- **`BOT_APP_ID` and `BOT_PRIVATE_KEY`**: organization secrets, available to
  the repository without setting anything.
- **The `release` label**, which release-plz puts on the release PR.
- **A first release with a token.** crates.io has no crate yet to trust a
  workflow for, so the first version is published with a short-lived token
  limited to the crate's name, with the `publish-new` scope: by hand, or as the
  repository's `CARGO_REGISTRY_TOKEN` secret, in which case the first push to
  main publishes it. Then the crate gets its trusted publisher and the secret
  goes: see [a new crate](trusted-publishing.md#a-new-crate).
- **A row** in [`scripts/rotate-crates-token.sh`](../scripts/rotate-crates-token.sh)
  for as long as the repository keeps a token.
