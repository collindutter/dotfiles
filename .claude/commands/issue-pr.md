---
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git stash:*), Bash(git checkout:*), Bash(git push:*), Bash(gh issue list:*), Bash(gh issue create:*), Bash(gh pr create:*)
description: Create a GitHub issue describing the root problem behind current changes, then open a PR that references it
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Changes vs main: !`git diff main...HEAD`
- Staged changes (if on main): !`git diff --cached`

## Your task

1. **Analyze the changes** to identify the root problem that motivated them. Focus on what was broken or missing — not what was done to fix it.

2. **Find or create a GitHub issue**:
   - First, search existing open issues with `gh issue list --search "<keywords>"` using a few relevant keywords from the root problem
   - If a matching issue exists, use it and note its number
   - If no relevant issue exists, create one with `gh issue create`:
     - A concise title describing the root problem
     - A body explaining the problem, its impact, and any relevant context. Do NOT describe the solution.

3. **Create a branch** (if on main) using `git checkout -b` with a short descriptive name.

4. **Commit** all changes using `git add` and `git commit` with a conventional commit message.

5. **Push** the branch to origin with `git push -u origin <branch>`.

6. **Create a PR** using `gh pr create` that:
   - Has a title summarizing what was done
   - References the issue in the body with `Closes #<issue-number>`
   - Summarizes the approach taken

Do steps 3-6 in a single message after creating the issue.
