# local-ci: run CI on your machine and attest it

[`scripts/local-ci.sh`](../scripts/local-ci.sh) runs the CI checks on your
host and, when they pass, posts a `local-ci` = success commit status on HEAD.
The [gate](gate.md) then skips the heavy jobs for a same-repo PR whose head is
that commit.

## Running it

From the root of a crate checkout, on a committed branch:

```sh
# commit not pushed yet: check, then push and attest
bash ../.github/scripts/local-ci.sh --push
# commit already pushed (CI already running): attest and re-run the gated runs
bash ../.github/scripts/local-ci.sh --rerun
# without a local clone of genai-rs/.github:
bash <(gh api repos/genai-rs/.github/contents/scripts/local-ci.sh -H 'Accept: application/vnd.github.raw') --push
```

- `--push` pushes the branch right before posting, so the PR's gate (which
  waits up to 60 s for the status) sees it on the first run.
- `--rerun` (for a commit that was already pushed) cancels and re-runs this
  commit's PR workflow runs that have a gate job and are still running or
  failed, so they pick up the attestation.
- `--no-post` only runs the checks.

Needs `gh` (authenticated, write access to the repo), rustup with the MSRV
toolchain (installed on demand) and nightly, `cargo-semver-checks` and
`cargo-udeps`.

## What it runs

The script refuses a dirty tree, reads `msrv`, `features`, `run-doc`,
`run-semver-checks` and `generated-crate` from the repo's
[`rust-ci.yml`](rust-ci.md) call and runs on the host:

- `cargo fmt --check`;
- `clippy --all-targets -D warnings` and `cargo test` on stable and on the MSRV;
- `cargo doc --no-deps` with `RUSTDOCFLAGS=-D warnings`;
- `cargo semver-checks` (not for generated crates);
- the repo's `cargo +nightly udeps` command when a workflow runs it;
- the repo's `.github/local-ci-extra.sh` (local equivalents of repo-specific
  jobs such as a release build or feature combinations);
- the [`wasm` job](wasm.md)'s commands when the call sets `wasm-*-args` and the
  host has the `wasm32-unknown-unknown` target, `node` and a
  `wasm-bindgen-test-runner` of the `Cargo.lock` version (otherwise they are
  skipped with a message, and the status says `wasm-SKIPPED`).

When all pass it posts the commit status `local-ci` = success (with what ran,
toolchains and host) on HEAD; on failure it posts nothing and exits non-zero.

## What it does not cover

It runs on one host (usually macOS arm64), so Linux/Windows-specific breakage
and coverage are only caught by the full run on `main`. Live integration tests
are unaffected by the gate and keep running. Fork PRs and pushes to `main`
always run the full CI.
