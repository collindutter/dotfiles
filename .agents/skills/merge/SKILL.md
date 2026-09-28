---
name: merge
description: Commit, rebase, and merge the current branch.
disable-model-invocation: true
allowed-tools: read bash
---

Finish the current branch: commit, rebase onto the base, `workmux merge`.

Flags from the user's message:

- `--keep`, `-k`: pass `--keep` (keep the worktree and tmux window)
- `--no-verify`, `-n`: pass `--no-verify`

## 1. Commit

If anything is staged, commit it: lowercase, imperative, no conventional-commit
prefix. Nothing staged: skip.

## 2. Rebase

Base branch:

```
git config --local --get "branch.$(git branch --show-current).workmux-base"
```

Default `main` when unset.

`workmux merge` merges into the local base branch, so rebase onto that local
branch (`git rebase main`). Skip `git fetch` and `origin/<branch>`.

Conflicts: keep both the base's changes and this branch's.

1. For each conflicting file, read what the base changed first:
   `git log -p -n 3 <base> -- <file>`.
2. Resolve, `git add <file>`, `git rebase --continue`.
3. If a conflict's intent is unclear from both histories, stop and ask before
   resolving it.

## 3. Merge

```
workmux merge --rebase --notification [--keep] [--no-verify]
```

Include each optional flag only when the user passed it. This merges into the
base and removes the worktree and tmux window unless `--keep`.
