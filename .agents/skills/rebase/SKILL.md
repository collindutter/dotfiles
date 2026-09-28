---
name: rebase
description: Rebase the current branch with smart conflict resolution.
disable-model-invocation: true
allowed-tools: read bash
---

Rebase the current branch. Arguments come from the user's message.

## Target

- No arguments: the branch's workmux base
  (`git config --get branch.$(git branch --show-current).workmux-base`), else
  local `main`. No fetch.
- `origin`: `git fetch origin`, target `origin/main`.
- Contains `/` (`origin/develop`): fetch that remote, target that ref.
- Anything else: that local branch, no fetch. `main` forces local main.

Run `git rebase <target>` and continue until it completes.

## Conflicts

Keep both sides: the target's changes and this branch's.

1. For each conflicting file, read what the target changed first:
   `git log -p -n 3 <target> -- <file>`.
2. Resolve, `git add <file>`, `git rebase --continue`.
3. If a conflict's intent is unclear from both histories, stop and ask before
   resolving it.
