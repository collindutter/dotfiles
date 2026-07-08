---
name: workmux-prune
description: Scan all workmux worktrees across repos, check the GitHub PR
  state of each branch, and remove worktrees whose PRs are merged (or closed
  without merging). Use when the user asks to "prune worktrees", "clean up
  merged worktrees", or wants to know which workmux worktrees can be removed.
---

# Prune Merged Workmux Worktrees

Find workmux worktrees whose work has landed (PR merged) or been abandoned
(PR closed without merging) and remove them with `workmux rm`.

The bash tool may not support loops or `cd` chains directly; wrap multi-step
shell in `bash -c '...'`.

## 1. Discover worktrees

Worktree directories live in `<project>__worktrees/` as siblings of each
project root. Find them all:

```bash
fd -d 1 -t d '__worktrees$' ~/Projects/griptape
```

(Adjust the root if the user is working elsewhere.)

For each worktree, collect the repo, handle, and branch:

```bash
bash -c 'for d in ~/Projects/griptape/*__worktrees/*/; do
  repo=$(basename $(dirname "$d")); repo=${repo%__worktrees}
  branch=$(git -C "$d" branch --show-current 2>/dev/null)
  echo "$repo|$(basename $d)|$branch"
done'
```

## 2. Check PR state per branch

In each worktree, look up the PR for its branch:

```bash
cd <worktree> && gh pr view <branch> --json state,number,title \
  --jq '"\(.state) #\(.number) \(.title)"'
```

Run these in a batch (one `bash -c` loop) rather than one call per worktree.

## 3. Handle "no PR found" branches

A branch with no PR is NOT automatically safe to keep or remove. Two common
cases:

- **Contributor PR checkout**: the local branch name differs from the PR's
  head ref (e.g. `someuser-feature/foo` checked out from a fork). Look up
  PRs associated with the HEAD commit:

  ```bash
  gh api "repos/<owner>/<repo>/commits/$(git rev-parse HEAD)/pulls" \
    --jq '.[] | "#\(.number) \(.state) merged=\(.merged_at) \(.title)"'
  ```

  If that returns nothing, search by branch/issue keywords:

  ```bash
  gh pr list --state all --search "<keywords> in:title,body" \
    --json number,state,title,headRefName
  ```

- **Local-only work**: check unmerged commits and dirty state before
  classifying:

  ```bash
  git fetch -q origin main
  git rev-list --count origin/main..HEAD   # unmerged commits
  git status --porcelain | wc -l           # uncommitted changes
  ```

  If the HEAD commit belongs to an open PR on another branch, keep it.

## 4. Classify and confirm

| PR state | Action |
|---|---|
| MERGED | Prunable |
| CLOSED (not merged) | Candidate; likely abandoned/superseded, confirm |
| OPEN | Keep |
| No PR, has unmerged/dirty work | Keep |

Present the full table to the user and ask which to remove (merged only,
merged + closed, or none) with `ask_user_question` before deleting anything.

## 5. Remove

`workmux remove` must run from within the repo the worktree belongs to:

```bash
bash -c 'cd ~/Projects/griptape/<repo> && workmux remove -f <handle> [<handle>...]'
```

This removes the worktree, tmux window, and local branch.

## 6. Report

Summarize what was removed (repo, handle, PR reference) and what was kept
and why.

## Notes

- `workmux rm --gone` (per repo) is a faster path that removes worktrees
  whose upstream branch was deleted after merge, but it misses
  contributor-branch checkouts and closed-unmerged PRs, and it won't catch
  branches that were never pushed.
- `workmux list --pr` shows PR status for the current repo's worktrees and
  can substitute for step 2 when operating in a single repo.
