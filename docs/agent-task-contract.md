# Agent task delivery contract

Use this contract for a bounded task in one genai-rs repository. Each repository
keeps its own API, compatibility, Rust minimum (MSRV), and release policy.

## Opt in and establish instructions

A maintainer opts a repository in by adding a link to this contract in its local
`CONTRIBUTING.md` or `AGENTS.md`, naming any local exceptions and validation
commands. Pin the link to a reviewed commit if adoption should not track future
changes. Organization documentation is not automatically inherited as `AGENTS.md`.
Read the target repository's applicable `AGENTS.md` files, including instructions
in directories being edited, before work; follow those instructions and the
explicit task authorization. Surface conflicts for review rather than silently
choosing a different compatibility policy.

For Tim's managed environment, also read `/Users/tim/.codex/RTK.md`. Prefix every
shell command with `rtk`; use `rtk proxy <command>` when a command needs unfiltered
output or lacks a dedicated wrapper. The examples below use that convention.
If RTK is required but unavailable, report the environment blocker.

## Delivery steps

1. **Read and claim.** Read the current Kata body, comments, owner, and predecessor
   state. Confirm the task is ready and authorized. Claim an unowned task as your
   actor; never force another worker's claim. If already assigned to you, retain
   the claim. Record the worker chat ID and isolated checkout path in Kata.
2. **Refresh and reproduce.** Fetch the remote default branch and record its exact
   SHA. Inspect open PRs and the current source facts; continue an existing task PR
   instead of duplicating it. If the fix has landed, verify it and report that
   evidence. In a fresh clone or an isolated worktree, run the smallest relevant
   reproduction before editing. For documentation, record the missing or
   inaccurate statement and a concrete source or link check.
3. **Edit narrowly.** Fill in the template below before implementation. Stay
   within its named files and acceptance criteria. Fix generated behavior in
   generator inputs, templates, or maintained patches, then regenerate using the
   repository procedure. Do not hand-edit generated output as the lasting fix.
   Never invent or fabricate schemas. Retain or backfill an absent upstream
   schema only when the target repository has an explicit, reviewed
   provider-specific compatibility policy and sourced evidence for its published
   Rust API. Keep that compatibility input bounded, versioned, reproducible,
   separately identifiable from raw upstream data, and covered by regression
   fixtures. For example, [OpenAI's repository rules](https://github.com/genai-rs/openai-client-base/blob/main/AGENTS.md)
   require strict upstream mirroring and forbid backfills; Langfuse's bounded,
   evidenced v3 inventory is demonstrated by [merged PR 238](https://github.com/genai-rs/langfuse-client-base/pull/238)
   and distinguished in the [proposed provider policy](https://github.com/genai-rs/.github/pull/3).
   Follow the target repository's current policy; request review before
   adding or extending compatibility data. Do not silently change API/MSRV policy.
4. **Validate.** Run the exact focused commands from the template, recording the
   working directory, tool versions, exit status, and relevant result. Prefer
   offline tests, local fixtures, and mock servers; live service tests require
   separate credentials and execution authorization. Distinguish an uncached
   dependency or unavailable tool from a product failure. Do not weaken tests to
   make the change pass. Run repository-required checks too; record any unavailable
   checks as limitations, never as passing. In a parallel worker wave, limit Cargo
   to two jobs, for example `rtk proxy env CARGO_BUILD_JOBS=2 cargo test --offline
   --locked <focused-filter>` after replacing the filter with the actual target.
5. **Open one focused PR.** Review the diff for unintended generated changes,
   credentials, refactoring, or dependency upgrades. Push one branch and create
   one draft PR per implementation task, or update its existing PR. Link the Kata
   ID and record the exact head SHA, changed files, validation, and limitations.
6. **Hand off for independent review.** Add `needs-review` and evidence to Kata.
   Keep the implementation task open while the reviewer checks the acceptance
   criteria, diff, and tests. A PR alone is not completion. After acceptance, an
   authorized actor may merge; close only after the accepted change is merged and
   required checks pass, with substantive prose and typed Kata evidence. A
   review/design task may close on its specified accepted decision evidence
   without a production merge.

After two unsuccessful fix cycles (a proposed fix followed by validation), an
API/MSRV decision, or a required edit outside the named scope, stop implementation
and hand off. Record the reproduction, attempted changes, exact blocker, and
remaining work, then add `needs-review`. Do not start a third speculative fix or
claim another task to bypass the blocker.

Implementation authorization does not authorize merge, release, package
publication, real credential rotation, or repository settings changes. Follow
the separate authorization required for each action; supervised workers need
recorded authorization for the exact PR before merging.

## Session naming

For GitHub issue or PR work, if creating a tmux session, name it exactly:

```text
<owner>/<repository> - <issue|pr>-<number> - <short-kebab-case-slug>
```

Use the same name for the Codex conversation when supported, and verify both
names after setup. Use a real GitHub issue/PR number; a Kata ID is not one. If
only a Kata task exists, do not invent a GitHub number. Once a real PR exists,
name the conversation using its PR number and update any task tmux session to
match. No tmux session is required by this contract.

## Copyable task template

Replace every placeholder with a concrete value or an explicit `none` before
starting. Commands must be runnable from the stated directory, not just names
such as “CI” or “unit tests”. Acceptance criteria must be observable.

```text
Task: <Kata project#id and title>
Actor / worker chat ID: <actor> / <chat ID>
Repository: <owner/repository and URL>
Base branch / refreshed base SHA: <branch> / <full SHA>
Existing GitHub issue or PR: <URL or none>
Predecessor IDs and verified state: <project#id: closed + evidence, or none>
Instructions read: <applicable AGENTS.md paths, RTK.md, local policies>
Isolated checkout / working directory: <absolute path>
Problem and reproduction: <trigger, exact command, actual vs expected result>
Allowed files: <explicit paths; include regenerated outputs if required>
Generated-source boundary: <inputs/patches -> output paths, or none>
Compatibility policy and schema provenance: <local policy/source revision, or none>
Acceptance criteria:
- <observable result>
Exact tests and checks:
- <cwd; rtk command; prerequisites; expected result>
- <required CI job and how its result is verified>
Non-goals: <excluded APIs, files, refactors, upgrades, live tests>
Authority: <implementation owner, independent reviewer, merge/release authority>
Stop conditions: two unsuccessful fix cycles; API/MSRV decision; scope expansion
Handoff evidence:
- Branch / exact head SHA / refreshed base SHA:
- PR URL or durable review/design artifact:
- Changed files and acceptance criteria satisfied:
- Exact commands, working directories, versions, exit statuses, results:
- Reproduction before/after and CI links tied to the head SHA:
- Attempts, blockers, residual risks, unrun checks, and remaining work:
- Reviewer decision and merge/check evidence when available:
Kata state: open + needs-review until accepted completion evidence is present
```

## Kata command reference

These forms were checked against installed Kata v0.17.2 help. Replace the shell
variables with the task's actual qualified ID and actor. Run from the bound
workspace or use a qualified reference such as `genai-rs#d3ke`. Check installed
help again when upgrading Kata; do not assume another tracker has these flags.

```sh
rtk proxy kata --help
rtk proxy kata show "$TASK" --json
rtk proxy kata --as "$ACTOR" claim "$TASK" --if-unowned
rtk proxy kata --as "$ACTOR" meta set "$TASK" worker_thread_id "$CHAT_ID" --if-absent
rtk proxy kata --as "$ACTOR" comment "$TASK" --body-file handoff.md
rtk proxy kata --as "$ACTOR" label add "$TASK" needs-review
```

Read back the owner after a claim and resolve a mismatch before editing. An
existing different worker ID is also a coordination conflict, not permission to
overwrite it. `handoff.md` is a local evidence file, not an additional repository
change. Include typed evidence strings such as `commit:<full SHA>`, `pr:<URL>`,
`test:<exact command>`, and `reviewed-paths:<path>` in the handoff for later use.
Comments preserve the narrative; typed evidence is submitted through `close`.

The following is for the authorized accepting actor **only after** completion
has been verified, not for the worker creating a draft PR:

```sh
rtk proxy kata --as "$ACTOR" close "$TASK" --reason done \
  --message "<substantive scope, acceptance, merge and check results>" \
  --evidence "commit:<full SHA>" \
  --evidence "pr:<PR URL>" \
  --evidence "test:<exact successful command>" \
  --evidence "reviewed-paths:<path>" --dry-run
```

Inspect the dry-run result, then omit `--dry-run` only when authorized and all
completion criteria are met. For an accepted review/design artifact, replace
inapplicable PR/commit evidence with truthful supported evidence; never invent a
merge, test, or artifact. Review `rtk proxy kata close --help` for supported types.
