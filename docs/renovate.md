# Renovate preset

Extend [`renovate-default.json`](../renovate-default.json) from a repo's
`renovate.json5`:

```json5
{
  extends: ['github>genai-rs/.github:renovate-default'],
}
```

It sets the Monday maintenance window, `chore(deps):` commit prefix,
lockfile maintenance, patch/minor grouping with automerge, isolated pre-1.0
and major updates, and grouped GitHub Actions updates. Add repo-specific
`packageRules` or `customManagers` on top.
