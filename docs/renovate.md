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
updates of dependencies at 1.0 or later, a separate group without automerge
for 0.x dependencies, major updates labelled `breaking` for manual review,
grouped and automerged GitHub Actions updates, and automerged security and
dev-dependency updates. Add repo-specific `packageRules` or `customManagers`
on top.
