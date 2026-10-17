# GenAI-RS

Rust libraries for OpenAI integration, Langfuse observability, and experimental LangGraph workflow tooling.

## Choose a starting point

- **Call OpenAI:** start with [openai-ergonomic](https://github.com/genai-rs/openai-ergonomic) for builders, streaming helpers, and interceptors. It is under construction; check its API coverage before adopting it. Use [openai-client-base](https://github.com/genai-rs/openai-client-base) when you need the generated API surface directly or are building your own abstraction.
- **Use the Langfuse API:** choose [langfuse-ergonomic](https://github.com/genai-rs/langfuse-ergonomic) for builders, batching, and operations such as prompts, datasets, and scores. Use [langfuse-client-base](https://github.com/genai-rs/langfuse-client-base) for direct generated bindings.
- **Export OpenTelemetry spans to Langfuse:** choose [opentelemetry-langfuse](https://github.com/genai-rs/opentelemetry-langfuse). It configures the OTLP exporter and Langfuse context; it does not require a Langfuse API client at runtime. Match your application's OpenTelemetry dependency versions to the exporter.
- **Explore Python LangGraph conversion:** see [langgraph-rs](https://github.com/genai-rs/langgraph-rs). Treat it as experimental: conversion and validation paths still contain placeholders at the reviewed commit.

## Public repository catalog

Reviewed on **17 October 2026**. Versions below are package/workspace versions on the reviewed default-branch commits, not a claim that those versions are published on crates.io. Each version links to its exact manifest. Rust minimums are the manifest's declared `rust-version`, not independently verified build results. “Not declared” is not a compatibility promise.

All Rust projects below are pre-1.0. “Active” means the repository is not archived; it does not imply production readiness or a support guarantee.

| Repository | Purpose | Maturity | Manifest version | Declared Rust minimum |
| --- | --- | --- | --- | --- |
| [openai-client-base](https://github.com/genai-rs/openai-client-base) | Low-level OpenAI API bindings | Active, pre-1.0 | [0.15.0](https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/Cargo.toml) | 1.88 |
| [openai-ergonomic](https://github.com/genai-rs/openai-ergonomic) | OpenAI builders, streaming, and interceptors | Experimental / under construction | [0.6.0](https://github.com/genai-rs/openai-ergonomic/blob/8717a622373d565d3d9511ba7150dca245b4fcfa/Cargo.toml) | 1.88 |
| [langfuse-client-base](https://github.com/genai-rs/langfuse-client-base) | Low-level Langfuse API bindings | Active, pre-1.0 | [0.15.0](https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/Cargo.toml) | 1.88 |
| [langfuse-ergonomic](https://github.com/genai-rs/langfuse-ergonomic) | Langfuse API builders and batching | Active, pre-1.0 | [0.7.0](https://github.com/genai-rs/langfuse-ergonomic/blob/e314906103419ef15807eb7b8061e8e35937d3e1/Cargo.toml) | 1.88 |
| [opentelemetry-langfuse](https://github.com/genai-rs/opentelemetry-langfuse) | Langfuse OTLP export and context utilities | Active, pre-1.0 | [0.7.0](https://github.com/genai-rs/opentelemetry-langfuse/blob/9a13be1ead6f9274eacef1b2c023b863b4dd2360/Cargo.toml) | 1.93.1 |
| [langgraph-rs](https://github.com/genai-rs/langgraph-rs) | Inspector, generator, runtime, and CLI for LangGraph workflows | Experimental | [0.1.2](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/Cargo.toml) (workspace) | Not declared in workspace or member manifests |
| [.github](https://github.com/genai-rs/.github) | Organization profile and community documentation | Active documentation | Not a Rust package | Not applicable |

## Source boundaries and dependencies

- **Generated base clients:** `openai-client-base` and `langfuse-client-base` contain generated API/model code plus maintained generation scripts and patches. Fix generated behavior through the generation pipeline. The [OpenAI repository guidance](https://github.com/genai-rs/openai-client-base/blob/806bd82935d1455f1dde6551d37e26291b35f2f4/AGENTS.md) requires fidelity to the upstream OpenAI/Stainless specification; the [Langfuse generation pipeline](https://github.com/genai-rs/langfuse-client-base/blob/bb3289ba6e2790c40fee737f11395b21d641184a/README.md#generation) also applies its documented legacy v3 compatibility data. These are distinct generation contracts.
- **Handwritten wrappers:** `openai-ergonomic` depends on [openai-client-base](https://github.com/genai-rs/openai-client-base) `^0.15.0`; `langfuse-ergonomic` depends on [langfuse-client-base](https://github.com/genai-rs/langfuse-client-base) `^0.15.0`. Their builders and orchestration are handwritten, while underlying API models come from the generated clients. See the pinned manifests above for the complete dependency ranges.
- **Handwritten OTLP integration:** `opentelemetry-langfuse` builds on [OpenTelemetry Rust](https://github.com/open-telemetry/opentelemetry-rust): `opentelemetry`, `opentelemetry_sdk`, and `opentelemetry-otlp` are all `^0.33.1`. [langfuse-ergonomic](https://github.com/genai-rs/langfuse-ergonomic) `^0.7.0` is a development dependency only. `openai-ergonomic` currently uses the OpenTelemetry 0.32 family, so its SDK types and the exporter's 0.33 types are not interchangeable.
- **Handwritten workflow tooling, generated output:** `langgraph-rs` contains [inspector](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/langgraph-inspector/Cargo.toml), [generator](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/langgraph-generator/Cargo.toml), [runtime](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/langgraph-runtime/Cargo.toml), and [CLI](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/langgraph-cli/Cargo.toml). The CLI depends on the other three workspace crates; the generator depends on the inspector's metadata types. The inspector's optional Python integration uses [PyO3](https://github.com/PyO3/pyo3) `^0.29.3`. Generated workflow code still needs review and implementation of missing node/routing logic; see the [generator source](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/langgraph-generator/src/lib.rs) and [CLI source](https://github.com/genai-rs/langgraph-rs/blob/a5f7b261f76ed0b36d377db6057f92761fa51f7e/langgraph-cli/src/main.rs).
- **Documentation:** `.github` contains the handwritten organization profile and community files; it has no Rust dependency graph.

## Historical example

[rmcp-demo](https://github.com/genai-rs/rmcp-demo) is **archived**. It is a handwritten Rust MCP server and Python client demonstration with tracing, retained as historical reference. Its [0.1.0 manifest](https://github.com/genai-rs/rmcp-demo/blob/58eaf2d7de9f4fbcf80a0145e49905a7b3ce9aba/Cargo.toml) declares `opentelemetry-langfuse = "^0.5"` and OpenTelemetry 0.31; it does not declare a Rust minimum. Do not use it as a compatibility example for the current exporter.

## Contributing

Report bugs, suggest improvements, or submit focused documentation and code changes in the relevant repository. Read that repository's contribution guidance and `AGENTS.md` when present, and preserve its generated-source boundaries.
