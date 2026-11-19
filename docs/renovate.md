# Renovate preset

Extend [`renovate-default.json`](../renovate-default.json) from a repo's
`renovate.json5`:

```json5
{
  extends: ['github>genai-rs/.github:renovate-default'],
}
```

It sets the Monday maintenance window, `chore(deps):` commit prefix,
lockfile maintenance (not automerged), grouped and automerged patch/minor
updates of dependencies at 1.0 or later, a grouped and automerged
`pre-1.0 Rust updates` PR for compatible 0.x updates (0.x.y to 0.x.z), one PR
per crate labelled `breaking` for 0.x minor updates (0.x to 0.y, breaking in
Cargo) and for major updates, grouped and automerged GitHub Actions updates,
and automerged security and dev-dependency updates. Add repo-specific
`packageRules` or `customManagers` on top.

It turns off `config:recommended`'s limit of two new PRs per hour
(`prHourlyLimit: 0`): with a weekly window that limit let only a couple of
PRs through each Monday, so updates queued up as "Awaiting Schedule" on the
Dependency Dashboard instead of becoming PRs. `:prConcurrentLimit10` still
bounds the number of open PRs. Breaking 0.x updates get their own PR rather
than sharing one with compatible updates, so one update that needs code
changes no longer holds back the others.
