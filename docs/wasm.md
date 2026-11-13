# The `wasm` job

The opt-in `wasm` job of [`rust-ci.yml`](../.github/workflows/rust-ci.yml)
(check `ci / wasm`) runs when `wasm-clippy-args` or `wasm-test-args` is set
([inputs](rust-ci.md#inputs)). It installs the `wasm32-unknown-unknown` target,
`wasm-bindgen-cli` at the `wasm-bindgen` version in the caller's `Cargo.lock`
and Node.js, then runs each non-empty line of each input:

- `wasm-clippy-args`: `cargo clippy --target wasm32-unknown-unknown <line> -- -D warnings`;
- `wasm-test-args`: `cargo test --target wasm32-unknown-unknown <line>`, with
  `wasm-bindgen-test-runner` as the runner (tests run in Node.js).

```yaml
    with:
      msrv: "1.88"
      wasm-clippy-args: |
        --no-default-features --lib --test wasm
      wasm-test-args: |
        --no-default-features --test wasm
```

It is a heavy job (skipped at step level under `local-ci`/`release`, see
[the gate](gate.md)); it is not meant to be a required check.
[local-ci](local-ci.md) runs the same commands when the host has the target,
`node` and a matching `wasm-bindgen-test-runner`, and otherwise skips them and
says `wasm-SKIPPED` in the status.
