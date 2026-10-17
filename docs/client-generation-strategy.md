# Client generation strategy by provider

**Decision proposed for maintainer review — 17 October 2026.** GEN02–GEN05 are
accepted bounded evaluations. Their reports establish specific failures and
small areas of successful behavior; they do not establish that an alternative
client is ready for production. Keep OpenAI and Langfuse on their separate
existing generation paths for now. Do not adopt a replacement or infer that the
two providers need the same strategy.

The compact, checked-in replay record and evidence ledger is in
[`client-generation-strategy-evidence.md`](client-generation-strategy-evidence.md).
It records the accepted GEN02–GEN05 results, exact source/input identifiers,
limitations and the bounded GEN06 reruns.

## How to read the scores

The decision score is a qualitative 0–5 rating for how well the cited evidence
supports the **near-term action** in each row. It is not a benchmark, probability,
percent, weighted total or claim that an implementation is defect-free. A score
of 5 requires complete input and wire/type coverage, an understood public API
migration, controlled reproducibility and measured maintenance cost. A 4 requires
broad, relevant evidence without a critical known gap. A 3 supports retaining an
owned path with a named repair or policy gate. A 2 has useful full-input evidence
but a production-blocking semantic or migration gap. A 1 has only selected probes
or cannot generate the full required input. A 0 means there is no measured need or
ownership case for the proposed new system. `N/E` means that provider/measure was
not evaluated. Scores are per provider and are not compared across unlike inputs.

Maintenance effort is `N/E` for every candidate: no report measured maintainer
hours or a controlled reduction in patch effort. Generator patch counts, elapsed
builds under mixed caches, repository age, stars, and commit concentration are
not substitutes for that measurement. No speedup or cost-saving claim supports
this decision.

## OpenAI

**Recommendation: retain the current OpenAPI Generator pipeline and upstream
mirroring contract, with the coverage repair in OA06 as the immediate gate.**
Do not take a version-only upgrade to 7.26.0 or replace the generated dependency
based on the present comparisons. Do not change Stainless/OpenAPI input to make
a candidate succeed. OpenAI's repository instructions require the generated
client to mirror upstream and forbid invented or backfilled schemas.

| Near-term option | Score | Evidence and measured gap |
| --- | ---: | --- |
| Retain the current owned pipeline; repair the operation collision through OA06 | **3/5** | The existing pipeline, patches, and consumer boundary are owned here. The collision is a real coverage defect and must be repaired before a coverage claim: both the 7.15.0 baseline and 7.26.0 candidate emit 317 of 360 normal operations. OA06 (`genai-rs-openai-client-base#vdm6`) owns the focused repair and fail-closed inventory gate. |
| Adopt `openapi-to-rust` for the generated base client | **2/5** | The pinned full-input candidate generates and compiles and emits all 360 normal path operation IDs; it also emits 30 separate webhook operations. The shared corpus passes 20/22 model cases in each OpenAPI dialect and 26/29 combined cases (20/22 model plus 6/7 transport, including SSE). It accepts a missing required nullable field and null for an optional non-null field; typed SSE error mapping is also lost to `serde_json::Value`. It reports 119 broad/untyped contexts; their source semantics have not been joined and classified. Its full-input generation is useful evidence, not semantic parity. |
| Adopt `async-openai` behind the current ergonomic wrapper | **1/5** | A two-operation local adapter passes six mocked tests. The inventory reports 2 narrowly supported upstream operations, 23 source-missing and 335 untested; for 64 wrapper calls it reports 16 missing, 47 untested and one streaming-only supported call. All 29 synthetic contract cases remain untested. |
| Start a new general-purpose generator | **0/5** | No measured blocker disqualifies the existing approaches as a class, and no maintenance owner or lower total effort has been demonstrated. |

The 7.26.0 generator upgrade does not fix the coverage defect. Independent
reproduction with the pinned generator image shows the untagged normal operation
and a webhook both writing `default_api.rs`; the later webhook write replaces the
untagged operation while the tagged normal endpoint remains in `probe_api.rs`.
Both baseline and candidate lose the same 43 normal method/path
pairs. The 7.26.0 full generation also produced 24 Rust build errors (23 missing
model references and one undeclared `chrono` use). The 7.15.0 baseline full run
was killed with exit 137 after about 607 seconds, so this is not a controlled
baseline-versus-candidate build-time comparison. OA06 separately owns the
collision and must preserve webhook semantics while accounting for all 360
normal operations. Do not count webhook methods toward normal-path coverage.

`openapi-to-rust` is the strongest measured full-input alternative, but it is
not ready to replace the current public dependency. Its 432 generated operation
methods compare with 347 current public async entry points; none of the old
`apis::<tag>::function` paths are preserved. This is the inventory surface, not
an estimate of engineering hours. `ClientWithMiddleware` would also become a
different client boundary. Only one full-input Responses endpoint was wire
tested; the other 359 normal operations remain untested. A full source join of
the 119 permissive/untyped contexts, broad model fidelity review, downstream
wrapper compilation and middleware parity remain open.

The `async-openai` prototype also replaces public generated types and the
`ClientWithMiddleware` boundary. Existing wrapper behavior includes asynchronous
request/response/error and stream hooks, state and telemetry, Langfuse integration,
and a typed tool registry. Those require an SDK-owned adaptation layer. Its
prototype establishes that native Responses and one streaming path can work with
mocks; it does not establish drop-in coverage. A switch would remove Assistants
and Threads calls present in the wrapper's current API. The accepted OA05
boundary authorizes preparation of a versioned OpenAI base 0.16 / wrapper 0.7
line, including code, tests and migration documentation; publication remains a
separate decision. That preparation can preserve the current generated-client
strategy while handling source and API breaks. It does not authorize adopting
`async-openai`. Do not widen the existing `^0.15.0` consumer range as part of a
generator comparison. OA07 separately prepares the base model/version contract;
OA08 prepares the wrapper adaptation after OA07 and the OE04 streaming repair are
accepted. Preserve published base 0.15.0 / wrapper 0.6.0 as the existing pair.
This versioned preparation is distinct from selecting a new generator and does
not by itself approve a production migration or release.

## Langfuse

**Recommendation: retain the current OpenAPI Generator pipeline and the reviewed
v3 compatibility composition.** Keep the raw downloaded `openapi.yml` separate
from its normalized and composed generator input. The accepted compatibility
inventory preserves 17 removed or renamed operations and their model definitions,
alongside current upstream operations. This boundary is specific to Langfuse and
does not authorize overlays for OpenAI.

| Near-term option | Score | Evidence and measured gap |
| --- | ---: | --- |
| Retain the current owned generator plus the accepted v3 composition | **3/5** | The existing client and compatibility contract are maintained, and the raw/composed inputs are reproducible. Current generation maintenance effort was not measured in this comparison, and the strategy still requires regression tests for retained and current operations. |
| Adopt the evaluated Progenitor snapshot | **1/5** | Full raw and composed inputs parse as OpenAPI 3.0.1, but both fail during generation on the comparison enum values `[=,>,<,>=,<=]`; no full output or client build exists. Three selected generated operation mocks pass, while all 127 composed operation identities and all 29 synthetic GEN01 cases remain `not_tested`. |
| Adopt `openapi-to-rust` or `async-openai` for Langfuse | **N/E** | Neither was evaluated against the full Langfuse input and public API. The OpenAI-specific async client is not evidence for a Langfuse replacement. |
| Start a new general-purpose generator | **0/5** | No measured case establishes a need for new generator ownership. |

Progenitor's three passing subset probes cover ingestion request encoding and
header behavior, successful prompt retrieval, and successful observation query
deserialization. They are local mocks over original source-derived operation
definitions and transitive references; they do not expand into full-client
coverage. The GEN01 OpenAI-shaped model corpus was not run against Progenitor and
stays `not_tested`.

The selected Progenitor builder calls and `reqwest::Client` also differ from the
current generated surface and `ClientWithMiddleware` boundary. Total Rust symbol
changes, wrapper compilation and migration effort are `not_tested`; do not present
the three subset APIs as a migration estimate. Any later Progenitor evaluation
must preserve both the raw upstream input and the separately composed v3 input,
retain the versioned compatibility inventory, and report the full 127-operation
composition. It must not locally alter schemas to get past enum-name generation.

## Scorecard limits and measured migration surface

The scores support a near-term strategy; they do not hide unknowns. The following
measures are intentionally kept distinct:

| Provider / candidate | Full input and operation evidence | Semantic evidence | API migration evidence | Maintenance cost |
| --- | --- | --- | --- | --- |
| OpenAI / current pipeline | Baseline and 7.26.0 candidate each emit 317/360 normal operations in the reproduced generation inventory; 43 missing due to the webhook/file collision | Baseline full run interrupted; candidate has 24 compile errors; collision reproduced on a minimal pinned input | Existing API remains the reference; OA06 must restore all normal paths and retain webhook meaning | `N/E` |
| OpenAI / `openapi-to-rust` | All 360 normal path operation IDs emitted; 30 separate webhook operations are also emitted. These are identities, not 360 successful calls. | Full generated client checks; 20/22 shared model cases per dialect; 26/29 combined cases = 20/22 model plus 6/7 transport (including SSE); only one full-input endpoint wire tested | 347 existing entry points vs 432 candidate methods; old paths not retained; downstream/middleware adaptation not measured | `N/E` |
| OpenAI / `async-openai` | 2 narrow operations supported; 23 missing, 335 untested; wrapper inventory: 16 missing, 47 untested, one streaming-only | Six local mock tests pass for two adapter operations; 29 corpus cases untested | 64 wrapper calls inventoried; nominal types, borrowed returns, middleware and stream hooks require adaptation; no downstream conversion compile | `N/E` |
| Langfuse / current pipeline | 112 raw upstream operations; the compatibility inventory names 17 removed or renamed operations/models; composition produces 127 operation identities (15 net additional) | Current strategy retains the accepted compatibility boundary; no new whole-client comparative wire run was performed here | Existing generated public API is the reference; no total candidate symbol diff measured | `N/E` |
| Langfuse / Progenitor | Raw 112 and composed 127 operation inventories preserved; full generation fails before output | Three selected mocks pass; full generation fails on enum variants; 29 synthetic cases untested | Builder and transport surface differs; full symbol migration is `not_tested` | `N/E` |

Candidate versions refer to exact source snapshots, not registry-tag equivalence:
Progenitor source `23accc9f63cf3a56ac697ba92ac3d176c940dbdb` declares version
0.15.1 but is three commits after the peeled 0.15.1 release commit;
`openapi-to-rust` source is `2a226e4f6574451d5d88eb004ebbb99897be2467`;
`async-openai` source is `c2deb8880566c3db35979654ea9dd45dc3deffd9` and declares
0.42.2. OpenAPI Generator inputs used 7.15.0 for the OpenAI baseline,
7.26.0 for its candidate and 7.25.0 for the Langfuse pipeline.

For runtime boundaries, OpenAI baseline and wrapper declare Rust 1.88. Full
`openapi-to-rust` client build evidence used Rust 1.98.1; the accepted 1.88 run
covered only its synthetic corpus. The async adapter tests passed at 1.98.1 and
1.88, but the candidate's declared 1.75 minimum was not verified. Progenitor
subset tests used 1.98.1 and the generated manifest declares edition 2024 without
a Rust minimum. None of these facts establishes a lower supported MSRV or parity
for full-provider features.

The evaluations found no controlled before/after measurement of engineering
time, patch-review hours or total recurring maintenance. OpenAI's many named
repair scripts and Langfuse's normalization/composition steps are visible work,
but counts do not establish which are necessary or how much they cost. GEN02's
patch audit classified 26 steps: 1 required, 4 unsafe and 21 untested. This does
not establish maintenance savings, and deleting or revising patches is not
approved. Do not use mixed-cache generation/build timings or package counts from
unequal API coverage to claim lower cost.

## Pilot, rollback and follow-up

For OpenAI, OA06 is the first pilot: one focused PR owns the minimal collision
fixture, deterministic correction, fail-closed complete-operation inventory and
restored-endpoint mock. It must account for all 360 normal methods/paths, keep
webhooks separate and preserve unchanged upstream bytes. Do not combine that fix
with a new generator, wrapper migration or workflow change. After independent
acceptance of OA06, a **separate** one-PR candidate pilot may compare
`openapi-to-rust` against the repaired baseline on the complete upstream input
and shared fixtures. It must include the full generated-source diff, typed model
and endpoint fidelity inventory, downstream wrapper compile, middleware evidence,
MSRV and two clean deterministic runs. A failed gate closes the pilot without
changing the production generator or release; rollback is to the accepted
generator input/scripts and generated revision. Async-openai remains outside this
pilot until the separate human decision on its public API/release boundary.

For Langfuse, defer a production migration pilot. A future isolated, one-PR
Progenitor feasibility pilot can start only after the pinned upstream tool handles
the enum-name case without changing either upstream snapshot or the accepted v3
data. It must produce the complete composed 127-operation client before compiling
or comparing public API and wire behavior. If it does not, retain the current
pipeline and compatibility input. Rollback leaves raw upstream bytes, v3
composition, generated client and release contract unchanged.

After this decision is accepted, register any new generator implementation or
migration as its own Kata task with repository, exact source/input hashes,
acceptance tests, downstream surface and rollback. OA06 collision repair and the
OA07/OA08 versioned API preparation are already separately registered; this
document does not duplicate or take ownership of those changes. No package
publication, repository setting, Rust minimum or release version changes here.

## Evidence and sources

The decision uses accepted bounded reports, not unreviewed summaries:

- GEN02 OpenAI generator comparison: baseline source
  [`806bd829`](https://github.com/genai-rs/openai-client-base/tree/806bd82935d1455f1dde6551d37e26291b35f2f4),
  full OpenAI input SHA-256
  `2fa40050a4a4a85c3bf16bb20f3083fd32674cab360cb0aa98d05d2693f96025`,
  and the separately assigned OA06 collision-repair task (`genai-rs-openai-client-base#vdm6`).
- GEN03 Langfuse Progenitor comparison: evaluated source
  [`23accc9`](https://github.com/oxidecomputer/progenitor/tree/23accc9f63cf3a56ac697ba92ac3d176c940dbdb);
  raw Langfuse snapshot SHA-256
  `301fc5d38a5d4bc2dc97f517e205ea2b0c145a993eec93f490e3a958408de6f6`;
  composed input SHA-256
  `0c893866b052fb257659a4fc091a9a98c984b8d0ce570b2b4facdbfb46c7b004`.
- GEN04 OpenAI alternative generator: evaluated source
  [`2a226e4`](https://github.com/gpu-cli/openapi-to-rust/tree/2a226e4f6574451d5d88eb004ebbb99897be2467);
- GEN05 async-openai adapter: evaluated source
  [`c2deb88`](https://github.com/64bit/async-openai/tree/c2deb8880566c3db35979654ea9dd45dc3deffd9);
  wrapper baseline
  [`8717a62`](https://github.com/genai-rs/openai-ergonomic/tree/8717a622373d565d3d9511ba7150dca245b4fcfa).
- Shared synthetic contract and sampled baseline:
  [GEN01 result and fixture contract](https://github.com/genai-rs/.github/tree/61a3729da2f8d0361c77e90485997861af997e61/tools/generator-evaluation).
- Provider boundary and release requirements:
  [accepted compatibility policy](client-compatibility-policy.md),
  [OpenAI upstream-mirroring instruction](https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/AGENTS.md),
  [Langfuse compatibility PR 238](https://github.com/genai-rs/langfuse-client-base/pull/238),
  and its [versioned compatibility input](https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/scripts/legacy_v3_compatibility.json).

The checked-in ledger linked above carries the replayable evidence needed to
review these claims, including exact bounded commands and outcomes. The public
upstream OpenAPI URLs are mutable; observed content hashes are recorded in the
ledger. Bounded reruns do not extend any candidate's full-input coverage.
