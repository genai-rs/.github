# Client-generation strategy evidence ledger

This checked-in ledger makes the decision in
[`client-generation-strategy.md`](client-generation-strategy.md) reviewable
without relying on a worker's local files or private handoff archives. It
records accepted bounded evaluations and the GEN06 spot reruns. Results apply
only to the inputs and source snapshots below. “Untested” is an unknown, not a
pass or a failure.

## Inputs and pinned source revisions

| Evaluation | Source revision | Input identity |
| --- | --- | --- |
| GEN02 OpenAPI Generator baseline | [openai-client-base `806bd829`](https://github.com/genai-rs/openai-client-base/tree/806bd82935d1455f1dde6551d37e26291b35f2f4) | [OpenAI OpenAPI input](https://github.com/openai/openai-openapi/blob/main/openapi.yaml), SHA-256 `2fa40050a4a4a85c3bf16bb20f3083fd32674cab360cb0aa98d05d2693f96025` |
| GEN03 Progenitor | [Progenitor `23accc9`](https://github.com/oxidecomputer/progenitor/tree/23accc9f63cf3a56ac697ba92ac3d176c940dbdb) | Raw Langfuse SHA-256 `301fc5d38a5d4bc2dc97f517e205ea2b0c145a993eec93f490e3a958408de6f6`; normalized SHA-256 `098a6fc2d18f232ad17459842e10587fb5fbac9639f6e789117ce11c647e20b9`; composed SHA-256 `0c893866b052fb257659a4fc091a9a98c984b8d0ce570b2b4facdbfb46c7b004` |
| GEN04 `openapi-to-rust` | [source `2a226e4`](https://github.com/gpu-cli/openapi-to-rust/tree/2a226e4f6574451d5d88eb004ebbb99897be2467) | Same OpenAI input URL and hash as GEN02 |
| GEN05 `async-openai` | [source `c2deb88`](https://github.com/64bit/async-openai/tree/c2deb8880566c3db35979654ea9dd45dc3deffd9); [wrapper baseline `8717a62`](https://github.com/genai-rs/openai-ergonomic/tree/8717a622373d565d3d9511ba7150dca245b4fcfa) | Same OpenAI input URL and hash as GEN02 |

The OpenAI and Langfuse upstream URLs are mutable branch URLs. The hashes above
identify the bytes evaluated, but the public URLs do not provide immutable
content-addressed downloads. Candidate source links point to immutable commits.
The Progenitor snapshot declares version 0.15.1 and is three commits beyond the
peeled release commit `da76239296829cf58dd532729ce49274e9c1227f`. Generator
versions were OpenAPI Generator 7.15.0 baseline and 7.26.0 candidate for
OpenAI, and 7.25.0 for the Langfuse pipeline.

## GEN02 — OpenAPI Generator collision and patch audit

The normal-path inventory contains 360 operations. Both baseline and 7.26.0
candidate emitted 317; 43 were lost because the untagged normal operation and a
webhook operation both write `default_api.rs`. The later webhook write
overwrites the untagged operation. A tagged normal endpoint survives in
`probe_api.rs`. The 30 webhook operations are a separate inventory and are not
part of the 360 normal paths. The 7.26.0 full run had 24 compile errors (23
missing model references and one undeclared `chrono`); the baseline full run
was killed with exit 137 after about 607 seconds. These results do not support
a generation-speed comparison.

The accepted patch-necessity diagnostic classified 26 patch steps: **1 required,
4 unsafe, 21 untested**. This is not a maintenance-cost measurement and does not
authorize deleting or revising patches.

The bounded collision case is reproducible with OpenAPI Generator 7.26.0 and
the pinned image digest
`a304ddf1e2e5f24f68fa3153568d6174cea4959d09aa8e3db6d526fd0782326d`. The
self-contained fixture is
[`fixtures/gen02-collision.json`](fixtures/gen02-collision.json), SHA-256
`08b88c4e13b9b84cb7f9332b5908a150432cb38007085b77d876d950759a225d`. It yielded
`FILEPATH_COLLISION`, emitted the webhook and tagged endpoint, and omitted the
untagged endpoint. OA06 owns the actual repository repair and fail-closed full
inventory gate: OA06 (`genai-rs-openai-client-base#vdm6`).

Replay from this directory (Docker must support the `linux/arm64` image):

```sh
docker run --rm --platform linux/arm64 \
  -v "$PWD/fixtures:/review" \
  openapitools/openapi-generator-cli@sha256:a304ddf1e2e5f24f68fa3153568d6174cea4959d09aa8e3db6d526fd0782326d \
  generate -i /review/gen02-collision.json -g rust -o /review/out \
  --skip-validate-spec \
  --additional-properties=packageName=review,library=reqwest,supportAsync=true,supportMiddleware=true
```

Expected result: process completes; the wrapper reports `FILEPATH_COLLISION`;
generated inventory contains the tagged path and webhook, and not the untagged
normal path. This is a minimized diagnostic, not the full upstream generation.

## GEN03 — Langfuse Progenitor

Both raw and composed OpenAPI 3.0.1 inputs parse, but full generation fails on
enum variants `[=,>,<,>=,<=]` with `Failed to make unique variant names`. No
full generated client or full-client build exists. The raw inventory has 112
operations; the compatibility inventory records 17 removed or renamed
operations/models; the composition has 127 operation identities (15 net more
than raw). The compatibility source is
[PR 238](https://github.com/genai-rs/langfuse-client-base/pull/238), merged at
`bb3289ba6e2790c40fee737f11395b21d641184a`.

Three selected operation mocks passed: ingestion request/header behavior,
successful prompt retrieval, and successful observation query deserialization.
All 127 composed operations and all 29 OpenAI-shaped GEN01 synthetic cases were
not tested. GEN06 replayed only the selected ingestion mock:

Exact test target: `cargo test --locked --manifest-path selected/ingestion/Cargo.toml --test selected_wire`, with `CARGO_BUILD_JOBS=2`. The accepted evaluation's selected harness is required for this target; its temporary generated source is not part of this strategy PR.

Result: 1 passed, exit 0. This subset replay says nothing about full generation,
all-operation coverage, or migration effort.

## GEN04 — `openapi-to-rust`

The full OpenAI input generated and the candidate client checked successfully
under Rust 1.98.1. It emits all 360 normal path operation IDs and 30 separate
webhook operations. The baseline has 347 public async function entry points;
the candidate has 432 methods, with no old `apis::<tag>::function` paths
preserved. Only one full-input Responses endpoint was wire-tested; the other
359 normal operations were untested. A source join and classification of 119
broad/untyped contexts remains open.

The shared model corpus passes **20/22** for each OpenAPI dialect. The combined
SSE-enabled corpus passes **26/29 = 20/22 model cases + 6/7 transport cases**.
Two model failures concern required nullable presence and optional non-null
null acceptance. The transport failure is a non-success SSE response whose
typed error becomes `serde_json::Value`. GEN06 replayed the model suite:

Exact test target: `cargo test --locked --manifest-path corpus-sse/Cargo.toml --test models -- --test-threads=1`, with `CARGO_BUILD_JOBS=2`. The accepted evaluation's candidate corpus harness is required for this target; its temporary generated source is not part of this strategy PR.

Result: 20 passed, two known assertions failed, exit 101. This expected failing
exit confirms the two reported gaps; it is not a clean suite pass. Full client
generation/build was only recorded at Rust 1.98.1; Rust 1.88 evidence covers
the synthetic corpus only.

## GEN05 — `async-openai` adapter

The candidate declares version 0.42.2. Against upstream inventory, two narrow
operations are supported, 23 are source-missing, and 335 are untested. Of 64
wrapper calls, 16 are missing, 47 untested and one streaming-only supported.
All 29 synthetic contract cases are untested. Middleware, nominal public types,
tool handling and stream hooks need adaptation; adoption was not authorized.

GEN06 replayed the adapter tests at the prepared candidate revision:

Exact test target: `cargo test --locked --manifest-path adapter/Cargo.toml`, with `CARGO_BUILD_JOBS=2`. The accepted evaluation's temporary adapter harness is required for this target; its source is not part of this strategy PR.

Result: 6 passed, exit 0. The six mocked tests cover only the two adapter
operations. They ran on stable and Rust 1.88; the candidate's declared Rust
1.75 minimum was not verified.

## Scope and limitations

The bounded GEN06 commands above replay selected evidence; they do not rerun
full generation or broaden the original coverage. The evaluations do not
measure engineering hours, patch-review time, recurring maintenance, complete
downstream conversion, or production traffic. API counts, patch counts, package
counts and mixed-cache timings are not substitutes for those measures. The
shared fixture contract is tracked in
[GEN01's checked-in evaluation tools](https://github.com/genai-rs/.github/tree/61a3729da2f8d0361c77e90485997861af997e61/tools/generator-evaluation).
