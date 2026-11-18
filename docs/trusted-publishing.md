# Trusted Publishing

The crates publish to crates.io through
[Trusted Publishing](https://crates.io/docs/trusted-publishing): no crates.io
token is stored, in a repo or anywhere else. The one exception lasts a few
days: a [new crate](#a-new-crate)'s first release. Each crate names, on crates.io, the one workflow
that may publish it. At a release, the workflow proves to crates.io which repo
and workflow it is (a GitHub OIDC token) and gets a publish token that lasts
minutes; release-plz revokes it when the release is done.

## What a crate needs

On crates.io, under the crate's **Settings → Trusted Publishing → Add**
(`https://crates.io/crates/<crate>/settings/new-trusted-publisher`):

| Field | Value |
| ----- | ----- |
| Repository owner | `genai-rs` |
| Repository name | the repo that publishes the crate (for a `-macros` or other secondary crate, the main crate's repo) |
| Workflow filename | `release-plz.yml` (the file name only; the repo's own workflow, not the shared one it calls) |
| Environment | empty |

In the repo:

- `.github/workflows/release-plz.yml` grants `id-token: write`
  ([release workflow](release.md)).
- There is **no** `CARGO_REGISTRY_TOKEN` secret. If one exists, the release
  workflow publishes with it instead: that is only for a new crate.

## A new crate

crates.io cannot set a trusted publisher on a crate that does not exist yet, so
the first version needs a token:

1. Create a crates.io token with the `publish-new` and `publish-update` scopes,
   limited to the crate's name, expiring in a few days.
2. Either publish the first version yourself (`cargo publish -p <crate>`), or
   set the token as the repo's `CARGO_REGISTRY_TOKEN` secret and merge the
   release PR.
3. Add the crate's trusted publisher as above, delete the secret, and revoke
   the token.

## Trusted Publishing only

Once a release has gone out this way, a crate can be set to refuse API tokens
altogether: its crates.io settings have a switch that accepts new versions
through Trusted Publishing only.
