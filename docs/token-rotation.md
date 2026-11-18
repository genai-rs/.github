# Rotating the crates.io token

Each repo that publishes crates has its own `CARGO_REGISTRY_TOKEN` secret, used
by the [release workflow](release.md). There is no organization secret.
[`scripts/rotate-crates-token.sh`](../scripts/rotate-crates-token.sh) sets a new
token in one or more of those repos.

## 1. Create the token on crates.io

On [crates.io/settings/tokens](https://crates.io/settings/tokens), create a new
token with:

- **Scope:** `publish-update` only. The crates exist already, so
  `publish-new` is not needed; add it only for a release that publishes a new
  crate.
- **Crates:** only the crates the repo publishes. `scripts/rotate-crates-token.sh --list`
  prints them per repo; a pattern such as `genai-agents*` covers a family.
- **Expiry:** a date, so a leaked token stops working by itself; 90 days is a
  reasonable default.

One token per repo, scoped to that repo's crates, limits what a leaked token can
publish. One token for several repos is simpler to rotate; scope it to all of
their crates.

The script cannot check the token's scopes: crates.io does not show them for a
token without using it. A token that does not cover a crate fails at the next
publish, with a 403 in the release workflow's `Release` job.

## 2. Set it in the repos

You need admin access to the repos and `gh` logged in.

```sh
# Check first: which repos, which crates, and when each secret last changed.
bash scripts/rotate-crates-token.sh --dry-run all

# One token for every repo, pasted at a hidden prompt:
bash scripts/rotate-crates-token.sh all

# One token per repo, from a password manager:
bash scripts/rotate-crates-token.sh --from-cmd 'op read op://ci/genai-agents/token' genai-rs/genai-agents
```

The token comes from stdin, a hidden prompt, or the output of `--from-cmd`. It
is never a command-line argument, never written to disk and never printed. The
script checks that every named repo's secrets can be read before it changes
anything, then reports each secret's new update time.

## 3. Revoke the old token

After the next release has published with the new token, revoke the old one on
crates.io.
