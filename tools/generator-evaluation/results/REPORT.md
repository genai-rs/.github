# GEN01 bounded baseline report

Status: ready for independent review; no generator or client adopted.

The corpus defines 29 cases for both OpenAPI 3.0.1 and 3.1.0. Validation checks
both complete synthetic documents with openapi-spec-validator and checks all 22
model case expectations in each dialect with JSON Schema validation. Seven HTTP
and SDK transport cases have explicit mock wire contracts but are not executed.

The OpenAI baseline is commit `806bd82935d1455f1dde6551d37e26291b35f2f4`.
The entire checked-in `realtime_beta_server_event_response_mcp_call_completed.rs`
module was compiled unchanged in the isolated probe. It produced three passing
Rust tests: dotted enum serialization, rejection of an unknown closed enum value,
and whole-model deserialize/serialize equality. This samples two corpus cases;
it does not generate the synthetic corpus or establish full-client coverage.

The negative control changes only the assertion expectation to
`response_mcp_call_completed`. Cargo reports one failed assertion, showing actual
`response.mcp_call.completed`, and exits 101. The driver verifies both that exit
code and a failed test count. This deliberate failure is evidence of harness
sensitivity, not a baseline defect. See baseline-positive.log and
baseline-negative.log; baseline-probe.Cargo.lock fixes probe dependencies.

All 27 unsampled cases are explicitly `not_tested`. No candidate capability is
classified unsupported without evidence. Build time measures only the disposable
sample probe (including Cargo work); peak memory, MSRV, output determinism, manual
patch accounting, middleware compatibility and migration cost remain not tested.
There was no full generator, full client build, live API call or production edit.

## Full upstream evidence

The runner parsed the full byte-preserved upstream YAML files. Their immutable
hashes and complete operation inventories are in baseline.json. Both snapshots
had zero unresolved local references; this does not assert full OpenAPI validity.

| Provider | OpenAPI | Bytes | Operations | SHA-256 |
| --- | --- | ---: | ---: | --- |
| OpenAI | 3.1.0 | 4118855 | 360 | `2fa40050a4a4a85c3bf16bb20f3083fd32674cab360cb0aa98d05d2693f96025` |
| Langfuse | 3.0.1 | 425043 | 112 | `301fc5d38a5d4bc2dc97f517e205ea2b0c145a993eec93f490e3a958408de6f6` |

The handoff artifact `gen01-evidence.tar.gz` preserves the complete upstream
snapshots, original/current generation scripts, probe source and dependency lock,
corpus, runner and result logs. These evidence snapshots are not installed in any
production repository. Upstream URLs are mutable: a rerun with changed bytes is
a new evaluation, and must report its new hash rather than silently reusing this
report's outcome.

## Validation commands

Run from the worker workspace (repository-local replay commands are in README):

```sh
rtk proxy uv run work/github/tools/generator-evaluation/evaluate.py validate
rtk proxy uv run work/github/tools/generator-evaluation/evaluate.py baseline --baseline work/openai-baseline --snapshots work/upstream --work work/probe-locked --output work/github/tools/generator-evaluation/results
rtk proxy uv run work/github/tools/generator-evaluation/evaluate.py validate-result work/github/tools/generator-evaluation/results/baseline.json
rtk git -C work/github diff --check
```

The first run established the lockfile; the recorded rerun uses `--locked` and a
fresh probe target directory. The driver sets CARGO_BUILD_JOBS=2. The result JSON
contains the exact Cargo commands, compiler, platform, measured elapsed time,
source/corpus hashes and per-case statuses. An expected failed control does not
cause the overall driver to fail; an unexpected pass or build failure does.

## Review boundary

GEN02–GEN05 must supply candidate-specific typed adapters and full input/output
inventories. The contract permits honest failures and unsupported dialects; it
does not permit schema backfilling, erased operations or broad Value fallbacks to
be counted as typed success. Streaming parsing/cancellation are SDK transport
measurements. Independent supervisor acceptance is required before closing GEN01.
