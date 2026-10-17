# Shared generator evaluation contract

GEN01 defines comparable wire semantics for later generator and SDK experiments.
It does not select a generator or authorize a production migration. All files in
`fixtures/` are **synthetic evaluation inputs only**. Never copy them into a
production generation pipeline, fill missing upstream definitions with them, or
trim a real upstream specification until a candidate passes.

## Corpus and ownership

`fixtures/cases.json` is the case inventory: every case includes wire input,
expected output (or rejection), an operation ID, layer, and pass criterion.
`openapi-3.0.1.json` and `openapi-3.1.0.json` express the same synthetic contract;
only the nullable representation differs. JSON is also valid YAML, but the files
are intentionally `.json` to avoid YAML parser size and scalar coercion issues.

| Cases | Required behavior | Owner measured |
| --- | --- | --- |
| `enum.*` | Dotted wire name unchanged; closed enum rejects unknown; open known-or-other union preserves unknown string | Generated model |
| `tagged.*` | Both variants retain discriminator and fields; wrong payload rejected | Generated model |
| `untagged.*` | String/integer variants preserve type; object rejected | Generated model |
| `allof.*` | Both base and extension required fields present; either missing fails | Generated model |
| `presence.*` | Required vs omitted, optional vs null, required nullable vs absent all remain distinct | Generated model |
| `recursive.*` | Nested typed children roundtrip; invalid child rejected | Generated model |
| `error.typed-body` | Typed code and message roundtrip | Generated model |
| `stream.event-model` | Typed event payload roundtrips | Generated model |
| `multipart.bytes` | Binary multipart part and metadata reach local mock unchanged | Generated HTTP client |
| `error.http-status`, `error.unknown-body` | Non-success status, typed or raw error body retained | Generated HTTP client |
| `stream.chunked-sse`, `stream.bad-event`, `stream.cancel`, `stream.non-success` | SSE chunk/UTF-8 boundaries, decode errors, cancellation, HTTP errors | Handwritten SDK transport |

The SSE endpoint is deliberately a byte stream in OpenAPI. OpenAPI alone does
not specify its framing, `[DONE]` sentinel, cancellation, or backpressure. Do not
credit a generator for behavior supplied by a handwritten adapter. If a generator
supplies equivalent transport, record its exact implementation and revision.

For each generated candidate, write a small adapter using its **public typed
models and operations**, feeding these exact wire cases. Valid model cases must
deserialize and serialize to equal JSON values; key order is immaterial, omitted
keys, explicit null, numeric/string distinctions and array order are not. Invalid
cases must fail at the boundary stated in the criterion. If validation requires
handwritten code, record that code as a manual patch/adapter rather than claiming
native generator support. Transport cases use a local mock, never credentials or
live API calls. Multipart boundaries may vary; part bytes may not.

One case result is `pass`, `fail`, `unsupported`, or `not_tested`, always with
evidence. `unsupported` requires an observed rejection or a source-linked
capability limitation; failure to run a test is `not_tested`. A successful Cargo
build is not semantic success. An absent operation goes in `missing_operations`;
a schema replaced by `serde_json::Value`, an empty struct or another broad fallback
goes in `type_fidelity_losses` with location, expected type, actual type and impact.
Even a wire roundtrip through `Value` cannot establish typed coverage. Do not
average these losses away in a single score. Unknown raw HTTP error bodies are
intentionally permitted and are not schema fallbacks.

## Reproduce the bounded baseline

Requires Python 3.11+, uv, Rust/Cargo, git, curl and RTK. `evaluate.py` pins its
Python dependencies. Run these commands from the repository root. Choose a fresh
disposable directory for each run; the probe refuses to overwrite an old crate.
No upstream checkout is modified.

```sh
rtk proxy mkdir -p work/gen01/upstream
rtk git clone https://github.com/genai-rs/openai-client-base.git work/gen01/openai
rtk git -C work/gen01/openai checkout 806bd82935d1455f1dde6551d37e26291b35f2f4
rtk proxy curl --fail --location --retry 2 https://raw.githubusercontent.com/openai/openai-openapi/main/openapi.yaml --output work/gen01/upstream/openai.yaml
rtk proxy curl --fail --location --retry 2 https://cloud.langfuse.com/generated/api/openapi.yml --output work/gen01/upstream/langfuse.yaml
rtk proxy uv run tools/generator-evaluation/evaluate.py validate
rtk proxy uv run tools/generator-evaluation/evaluate.py snapshots work/gen01/upstream work/gen01/upstream-manifest.json
rtk proxy uv run tools/generator-evaluation/evaluate.py baseline --baseline work/gen01/openai --snapshots work/gen01/upstream --work work/gen01/run-1 --output work/gen01/results
rtk proxy uv run tools/generator-evaluation/evaluate.py validate-result work/gen01/results/baseline.json
```

The pinned checkout reproduces the sampled module; refresh remote HEAD and record
its SHA for a new evaluation. The upstream URLs are mutable: compare hashes with
the recorded manifest and report a new input revision if they differ. Preserve
the exact original snapshot bytes alongside each evaluation artifact; hashes
alone cannot retrieve old content. The GEN01 handoff includes those full bytes in
its artifact archive. These are evaluation evidence, never production inputs.

The runner reads the complete source module from `git show HEAD:path`, without
patching it, and compiles it in a disposable crate with its declared Serde/bon
dependencies. `crate::models` is an empty namespace satisfying an unused import;
no field types are stubbed. The committed probe Cargo.lock fixes the resolved
dependencies on later runs. This is a model sample, **not a full client build or
a synthetic generation run**. Three positive Rust tests exercise dotted enum
serialization, unknown closed-enum rejection and whole-model roundtrip. A second
run deliberately expects an underscore spelling and must fail exactly one test
with exit 101. The driver succeeds only when it detects that failure. This
negative control is not a product bug or a candidate failure.

## Compare candidates

Refresh provider repositories, default branches and relevant open PRs first.
Record candidate repository, commit SHA, version, generator commit/image digest,
flags, template revisions, adapter revisions, Rust toolchain, target triple,
feature flags, lockfiles and commands. A version tag alone is not an immutable
container identity. Capture Docker `RepoDigests` and the platform used. Keep raw
generation, repository-patched generation and SDK-adapter results separate.

For example, this runs the two current generator versions on the same fixture
in fresh directories. It is a comparison recipe, not a claim these runs passed:

```sh
rtk proxy mkdir -p work/gen01/7.15.0 work/gen01/7.25.0
rtk proxy docker pull openapitools/openapi-generator-cli:v7.15.0
rtk proxy docker pull openapitools/openapi-generator-cli:v7.25.0
rtk proxy docker image inspect openapitools/openapi-generator-cli:v7.15.0 --format '{{json .RepoDigests}}'
rtk proxy docker image inspect openapitools/openapi-generator-cli:v7.25.0 --format '{{json .RepoDigests}}'
rtk proxy docker run --rm -v "$PWD:/local" openapitools/openapi-generator-cli:v7.15.0 generate -i /local/tools/generator-evaluation/fixtures/openapi-3.1.0.json -g rust -o /local/work/gen01/7.15.0 --additional-properties=packageName=gen01,library=reqwest,supportAsync=true,supportMiddleware=true,preferUnsignedInt=false,useSingleRequestParameter=false
rtk proxy docker run --rm -v "$PWD:/local" openapitools/openapi-generator-cli:v7.25.0 generate -i /local/tools/generator-evaluation/fixtures/openapi-3.1.0.json -g rust -o /local/work/gen01/7.25.0 --additional-properties=packageName=gen01,library=reqwest,supportAsync=true,supportMiddleware=true,preferUnsignedInt=false,useSingleRequestParameter=false
rtk proxy env CARGO_BUILD_JOBS=2 cargo check --manifest-path work/gen01/7.15.0/Cargo.toml
rtk proxy env CARGO_BUILD_JOBS=2 cargo check --manifest-path work/gen01/7.25.0/Cargo.toml
```

Repeat with 3.0.1 in new output directories. Then run each candidate-specific
typed adapter against all `cases.json` entries and save its exact Cargo commands,
source and logs. The shared runner does not yet implement those adapters. Run
real upstream snapshots separately by replacing `-i` with the original hashed
file in `work/gen01/upstream/`; do not preprocess it silently or use a synthetic
subset as a full-spec result. A candidate that cannot parse a dialect is explicitly
unsupported for that input. Missing references remain reported upstream errors.
An existing repository normalization/compatibility pipeline is a distinct,
labeled candidate with a full transformation manifest; it cannot overwrite the
raw upstream artifact or be presented as unmodified upstream fidelity.

## Results and measurements

`results.schema.json` is the common machine-readable format. Start from
`results/baseline.json`, replace identity/evidence, and reset unrun fields to
`not_tested`; never copy its passes into another candidate. Validate with
`validate-result`. Include every case exactly once and partition the operation
inventory into supported, missing and untested. For full-upstream reports use
the snapshot's complete operation inventory, plus a separate synthetic run.
Model-only samples cannot establish endpoint coverage. The validator checks
structure and inventories; reviewers still must verify evidence and fidelity.

| Metric | Measurement contract |
| --- | --- |
| Coverage/type fidelity | Compare all operation IDs and reachable public schemas with input inventory; list missing operations and every generic fallback; attach raw and generated inventories. A pass needs a typed assertion. |
| Manual patches | List source/input/output hashes, scripts, touched files/lines, rationale and elapsed human effort. Count transformations separately from generic generation flags. Zero requires auditing the entire pipeline. |
| Build time | Separate generation, cold build and warm build; record hardware, jobs, toolchain, cache and network state. Report repeats/range. Never compare this sample probe time to whole-client generation/build. |
| Peak memory | Measure whole process tree or container/cgroup peak during generation and build separately, in bytes, with platform/tool/version. Single-process RSS is explicitly a lower bound. |
| MSRV | Record declared minimum separately from lowest successfully tested compiler. Run locked check/tests at that compiler with exact features/target. A new MSRV is a review decision, not an automatic upgrade. |
| Output determinism | Generate twice into clean directories from identical input and pinned tool versions. Hash sorted relative paths and file bytes. Report raw differences; list timestamp normalization rules separately. |
| Middleware compatibility | Mock a hook that adds a header, observes status, and counts attempts; check async/error/retry behavior and reqwest-middleware/Tower boundaries. Record adapter code and changed public signatures. |
| Public API migration cost | Diff exported models, fields, enum variants, constructors, operations and error signatures; compile representative downstream calls. Count breaking symbols and adapter lines with a source-linked inventory. No estimate is a measured zero. |

Each metric is either `{status: "measured", value, unit, method}` or
`{status: "not_tested", reason}`. Values may be structured inventories, not only
numbers. Store logs and adapter sources with the result; unsupported semantics,
failed generation and deliberate controls must remain visible. No combined
ranking, adoption decision, package release or production schema changes belong
to this contract task.

## Source refresh

Reviewed on 17 October 2026:

- OpenAI current [generation script](https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/scripts/generate.sh) still defaults to 7.15.0 and has input plus post-generation repair passes; it matches the task's [original script](https://github.com/genai-rs/openai-client-base/blob/1a4259e2b4cc0f0848ea86feb982fa7181840b1f/scripts/generate.sh) byte-for-byte. Its [AGENTS.md](https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/AGENTS.md) prohibits fabricating missing upstream schemas.
- Langfuse current [generation script](https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/scripts/generate-openapi-client.sh) defaults to 7.25.0, normalizes input, builds a separate compatibility input and patches output. The task's [original script](https://github.com/genai-rs/langfuse-client-base/blob/28f072145f3e340274a18e0d477a186a3977edfc/scripts/generate-openapi-client.sh) is retained as a reference, not assumed current.

Full snapshot hashes, sizes, operation IDs and unresolved local references are
recorded in `results/baseline.json`. Snapshot parsing/inventory is not full
OpenAPI validity or generation success. See `results/REPORT.md` for the measured
smoke outcome and explicit remaining work.
