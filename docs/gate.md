# The gate: how much CI a commit needs

The `gate` job of [`rust-ci.yml`](../.github/workflows/rust-ci.yml) (check
`ci / gate`) decides how much heavy work a commit needs. This keeps CI cheap:
pull requests that were checked locally ([local-ci](local-ci.md)) and release
PRs skip the heavy jobs, and macOS/Windows run on `main`.

## Modes

| Situation                                                                 | Mode       | Heavy jobs (clippy, test, doc, semver-checks, coverage, repo build/udeps/feature jobs) |
| ------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------ |
| push to `main`, schedule, manual dispatch                                 | `full`     | all, on every OS                                                                     |
| PR (incl. forks) without attestation                                      | `full`     | all on Linux; macOS/Windows entries skipped (label the PR `full-ci` to run them)     |
| same-repo PR whose head commit has a `local-ci` = success status          | `local-ci` | skipped                                                                              |
| release-plz PR (bot author, `release-plz-*` / `automated/release-plz/*`) touching only `Cargo.toml`, `Cargo.lock`, `CHANGELOG.md` | `release` | skipped; `release-sanity` runs `cargo check` + `cargo package --no-verify` |

For a same-repo PR the gate polls the head commit's statuses for up to
`local-ci-wait-seconds` (default 60) for a `local-ci` = success status. Statuses
created by `github-actions[bot]` are ignored, so CI can never attest itself;
posting one needs write access to the repository.

## What still runs

Skipped jobs keep their matrix and skip at step level on an ubuntu runner, so
every required check (e.g. `ci / test (macos-latest, msrv)`) is still reported
with its usual name and a passing conclusion; only the informational `coverage`
job is skipped entirely. `fmt`, cargo-audit, cargo-deny,
gitleaks, Dependency Review, License Compliance and the cheap repo jobs always
run. Live integration tests are not gated by `local-ci`. If the gate itself
fails, everything runs (fail open).

## Gating a repo's own jobs

Repos gate their own heavy jobs with
[`local-ci-gate.yml`](../.github/workflows/local-ci-gate.yml): the same logic,
with input `wait-seconds` and outputs `mode` (`full` | `local-ci` | `release`),
`heavy` (`"true"` when heavy jobs must run), `all-os` (`"true"` when
macOS/Windows must run too) and `reason`. Skip at step level, not with a
job-level `if:`, so matrix jobs keep their check names:

```yaml
jobs:
  gate:
    uses: genai-rs/.github/.github/workflows/local-ci-gate.yml@main
  build:
    needs: gate
    if: ${{ !cancelled() }}            # fail open if the gate itself fails
    runs-on: ${{ needs.gate.outputs.heavy != 'false' && matrix.os || 'ubuntu-latest' }}
    env:
      RUN: ${{ needs.gate.outputs.heavy != 'false' }}
    steps:
      - if: env.RUN == 'true'
        # ...
```

The decision logic is inlined as the `gate` job of `rust-ci.yml` too; keep
both copies in sync.
