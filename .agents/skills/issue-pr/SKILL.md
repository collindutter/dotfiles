---
name: issue-pr
description: Create a GitHub issue describing the root problem behind current changes, then open a PR that references it
allowed-tools: Bash(git diff:*) Bash(git status:*) Bash(git log:*) Bash(git branch:*) Bash(git stash:*) Bash(git checkout:*) Bash(git push:*) Bash(gh issue list:*) Bash(gh issue create:*) Bash(gh pr create:*)
---

# Create Issue and PR from Current Changes

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Changes vs main: !`git diff main...HEAD`
- Staged changes (if on main): !`git diff --cached`

## Task

1. **Find the root problem** behind the changes: what was broken or missing,
   not what was done to fix it.

2. **Find or create the issue.**
   - Search open issues with a few keywords from the root problem:
     `gh issue list --search "<keywords>"`.
   - A match exists: use it.
   - None: `gh issue create` with a concise title naming the problem and a body
     covering the problem, its impact, and relevant context. The body describes
     the problem only; the PR carries the solution.

3. **Branch** (if on main): `git checkout -b <short-descriptive-name>`.

4. **Commit** all changes with a conventional commit message.

5. **Push**: `git push -u origin <branch>`.

6. **Open the PR**: conventional-commit title summarizing the change, body only
   the issue link. The human writes the rest.

       gh pr create --draft --title "<title>" --body "Closes #<issue-number>"

Once the issue exists, run steps 3-6 without stopping.
