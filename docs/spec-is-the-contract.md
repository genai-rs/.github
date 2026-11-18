# The specification is the contract

What a client and a server of the same API share is its **OpenAPI
specification**, not a crate.

- **Each repository generates its own types** from the specification, with
  [timvw-rust](https://github.com/timvw/openapi-generator-timvw-rust). There are
  no shared model crates.
- **A server does not depend on the client**, and a client does not depend on a
  server. They meet over HTTP, as they do in production.
- **A client and a server live in separate repositories**:
  [openai-client-base](https://github.com/genai-rs/openai-client-base) is the
  client, [openai-mock-server](https://github.com/genai-rs/openai-mock-server)
  the mock. A proxy or a gateway would be a third, generating its own server.
- **Each repository records the specification it was generated from**: the
  checked-in copy, and for the mock the upstream revision (`openapi.revision`).
  A regeneration is a pull request in that repository.

## Why

A shared model crate, or a server that takes its models from the client crate,
ties the releases together: a change to one forces a release of the other, and
the server inherits the client's manifest, features and version. It also hides
drift that is real. A client and a server run on different revisions of an API
all the time; two repositories on two revisions show that in a test instead of
in production.

## What it costs

- A crate that tests a client against the mock compiles two sets of models.
  The mock keeps that short: its default Cargo features are only the API groups
  it scripts.
- Nothing proves at compile time that the two agree. The mock's tests run the
  published client against it, which finds a disagreement where it matters, on
  the wire.

This was decided when the mock was built, after a first version that shared the
client's models: see
[what was built](https://github.com/timvw/openapi-generator-timvw-rust/blob/main/docs/design/openai-mock-server.md#what-was-built).
The generator's `modelsCrate` option still exists for an API where one models
crate is wanted; genai-rs does not use it.
