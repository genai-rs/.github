# Generated-client compatibility and release decision

Status: **proposed; maintainer or designated senior reviewer acceptance pending**.
Evidence reviewed on 17 October 2026 for ORG03 (`genai-rs#gbsx`). Existing
repository rules remain authoritative; this proposal changes no crate, Rust
minimum, release configuration, or publication authority.

## Decision and supported boundaries

Keep the repositories, dependency contracts, and releases independent. A shared
generator policy must not erase the following provider-specific contracts.

- **OpenAI:** mirror the upstream OpenAI/Stainless specification. Do not invent
  or backfill absent schemas. Fail fast, document missing upstream definitions,
  and link the upstream issue in the PR. Generation must be reproducible; bespoke
  spec caching or pinning needs explicit approval. Langfuse compatibility data
  is not permission to apply overlays to OpenAI. This preserves
  [OpenAI's repository instructions][oa-rules].
- **Langfuse:** retain the published v3 ingestion, traces, sessions, dataset-run,
  observations, metrics, and score bindings described by the merged
  [PR 238][lf-pr] and [README][lf-readme], alongside current upstream additions.
  This is a Rust client compatibility boundary for servers that still implement
  those endpoints, not a guarantee of their availability on Cloud or v4 servers.
  Use the README's server migration guidance when choosing endpoints.

Langfuse's [versioned compatibility input][lf-data] cites the upstream snapshot
at client commit `28f072145f3e340274a18e0d477a186a3977edfc`. Its bounded inventory
contains 17 removed or renamed operations and their model definitions. The
[composition step][lf-compose] restores absent operations/models, retains
published operation identities, and preserves both `CreateScoresRequest` and
`CreateScoresResponse` single-score/batch unions. Raw `openapi.yml` stays separate
from the composed generation input, and compatibility is reapplied even after an
unchanged download. This exception preserves evidenced historical definitions;
automation must not fabricate schemas or extend the inventory without review.
Changes belong in generator inputs or patches, with regression fixtures.

## Rust compatibility and review triggers

A generated diff can break Rust consumers even when upstream calls it additive.
Treat removed or renamed public modules, functions, types, fields or enum
variants; changed argument/return types, field types or requiredness; new required
struct fields; exhaustive-enum additions; and removed trait implementations or
features as potential source breaks. Review serialized names, enum wire values,
null/omitted behavior, unions, request encoding and response decoding separately:
compilation alone does not prove wire compatibility. Public dependency types and
TLS/default-feature changes can also alter the consumer contract.

Require explicit maintainer or designated senior reviewer approval before
merging generated updates that affect those boundaries, remove upstream APIs,
change compatibility data or generation strategy, or raise the effective Rust
minimum. Record the affected surface, evidence, migration and version decision;
stop and request review when classification is uncertain. A regeneration bot's
successful run or a release bot's version proposal is insufficient approval.

Both base crates currently declare Rust **1.88**. Neither automation nor a
transitive dependency update may silently raise that minimum: test the declared
toolchain, and obtain an explicit decision with manifest, CI and documentation
changes before increasing it. Do not infer that all organization crates share
this minimum.

## Downstream and release evidence

The reviewed manifests declare the following boundaries (not a claim about the
latest published registry versions):

| Consumer | Dependency requirement | Declared Rust minimum |
| --- | --- | --- |
| [openai-ergonomic 0.6.0][oe-manifest] | `openai-client-base = "^0.15.0"` | 1.88 |
| [langfuse-ergonomic 0.7.0][le-manifest] | `langfuse-client-base = "^0.15.0"` | 1.88 |
| [opentelemetry-langfuse 0.7.0][ot-manifest] | `langfuse-ergonomic = "^0.7.0"` (development only) | 1.93.1 |

Both [OpenAI][oa-manifest] and [Langfuse][lf-manifest] base manifests are 0.15.0.
The wrappers' base ranges allow 0.15.x, not 0.16.0. For this proposal, intentional
breaking changes require a separately reviewed incompatible release line
(e.g. 0.15.x to 0.16.0 while below 1.0), migration notes and explicit wrapper
adaptation; once stable, use a major version. Do not synchronize package versions
or widen downstream ranges merely because generation succeeded.

Before accepting a generated or release PR, record:

1. Base/head SHAs, upstream source revision or digest, generator version and
   commands, compatibility-data provenance, and repeat-generation diff results.
2. Public Rust API and wire-contract comparison against the previous release,
   breaking-change classification, proposed version, changelog and migration.
   Mark breaking commits with `!` or `BREAKING CHANGE:`.
3. Exact stable/MSRV build and test commands and results, feature/TLS coverage,
   compiled README/examples, and applicable mock wire and generator fixtures.
   Preserve lockfile/resolution evidence; check fresh resolution at the declared
   Rust minimum as well as the repository's locked CI path where present.
4. Downstream wrapper compilation/tests using the candidate base via a temporary
   Cargo patch in an isolated checkout. Record consumer SHAs, resolutions and
   compared baseline failures; do not call a failing consumer compatible. Check
   the exporter development integration when its wrapper dependency is affected.
   Live service tests need separate credentials and execution authorization.
5. The reviewer identity, accepted head SHA, evidence links and unresolved gaps.
   Review and release authorization are separate from implementation permission.

Both base [release-plz configurations][oa-release] enable publication and release
PR creation; [Langfuse's configuration][lf-release] remains independent.
OpenAI explicitly disables `semver_check` because rustdoc exceeds standard runner
memory and asks for manual API/version review. Langfuse has no such explicit
opt-out in the reviewed file. Neither configuration substitutes for the evidence
above or authorizes an agent to publish, change settings, or merge.

PR 238 reports passing generator regressions, stable/MSRV tests and repeat Docker
generation, but also reports two pre-existing `CreateDatasetRequest` type
mismatches in `langfuse-ergonomic` on both baseline and candidate. Those reported
results establish neither current downstream success nor complete server
compatibility; release review must refresh and resolve or explicitly disposition
the relevant failures. This documentation task has not rerun those Rust tests.

## Retiring compatibility data

Keep the current Langfuse inventory until a maintainer or designated senior
reviewer accepts a retirement proposal. That proposal must identify every removed
operation/model, its provenance and server boundary, affected consumers, a
replacement/migration path, owner, and announced target release and timeline.
Deprecate and document migration before removal; validate consumer adaptations
with mocks and compile checks. Remove data, generation rules and fixtures together
in the explicitly reviewed breaking release, retaining historical provenance in
Git and release notes. Upstream deletion or an unchanged download alone must
never trigger retirement. New compatibility exceptions require the same bounded
inventory, owner and retirement plan; they cannot override OpenAI's rules without
an explicit repository policy decision.

## Acceptance record

Pending: the maintainer or designated senior reviewer must record acceptance or
requested revisions in this PR and Kata `genai-rs#gbsx`, naming the exact document
commit, provider boundaries, retirement process and any conditions. Until that
evidence exists, this is a draft decision and ORG03 remains open with
`needs-review`. Merging code or publishing a package requires separate authority.

[oa-rules]: https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/AGENTS.md
[oa-manifest]: https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/Cargo.toml
[oa-release]: https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/release-plz.toml
[lf-pr]: https://github.com/genai-rs/langfuse-client-base/pull/238
[lf-readme]: https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/README.md
[lf-data]: https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/scripts/legacy_v3_compatibility.json
[lf-compose]: https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/scripts/prepare_compatible_spec.py
[lf-manifest]: https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/Cargo.toml
[lf-release]: https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/release-plz.toml
[oe-manifest]: https://github.com/genai-rs/openai-ergonomic/blob/8717a622373d565d3d9511ba7150dca245b4fcfa/Cargo.toml
[le-manifest]: https://github.com/genai-rs/langfuse-ergonomic/blob/e314906103419ef15807eb7b8061e8e35937d3e1/Cargo.toml
[ot-manifest]: https://github.com/genai-rs/opentelemetry-langfuse/blob/9a13be1ead6f9274eacef1b2c023b863b4dd2360/Cargo.toml
