---
name: open-pr
description: Commit, push, and open PR creation in the browser with an empty body for the human to fill in.
disable-model-invocation: true
allowed-tools: read bash
---

Commit any work, push the branch, and open PR creation in the browser. Do NOT
write the PR body; leave it empty for the human to fill in.

## Gather context

1. Get the base branch (usually `main` or `master`).
2. Get the commit messages: `git log <base>...HEAD --format="%s"` (used only to
   craft a concise title).

## Commit and push

1. Run `git status`. If there are uncommitted changes you made in this session,
   commit them. Only commit files you changed; do not sweep in unrelated edits.
2. Use a conventional-commit message (e.g. `feat:`, `fix:`, `refactor:`),
   lowercase, imperative mood.
3. Push the branch: `git push -u origin HEAD`.

## Create the PR

1. Write a short PR title in conventional-commit format (e.g.
   `fix: handle missing library metadata on proxy nodes`), max 72 characters.
2. Open PR creation in the browser with the title set and the body left empty.
   Do NOT create it directly and do NOT write a description; let the browser
   form (and any repo PR template) show for the human to fill in:
   ```bash
   gh pr create --web --title "<title>"
   ```
