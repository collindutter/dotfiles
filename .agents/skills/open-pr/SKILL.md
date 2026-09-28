---
name: open-pr
description: Commit, push, and open PR creation in the browser with an empty body for the human to fill in.
disable-model-invocation: true
allowed-tools: read bash
---

Commit, push, and open PR creation in the browser. The human writes the body,
so leave it empty.

## Gather context

1. Find the base branch (usually `main` or `master`).
2. Read commit subjects for the title: `git log <base>...HEAD --format="%s"`.

## Commit and push

1. `git status`. Commit uncommitted changes you made this session, and only
   those files.
2. Conventional-commit message (`feat:`, `fix:`, `refactor:`), lowercase,
   imperative.
3. `git push -u origin HEAD`.

## Open the PR

1. Title in conventional-commit format, max 72 characters, e.g.
   `fix: handle missing library metadata on proxy nodes`.
2. Open the browser form with the title set, so the human sees any repo
   template and fills in the body:

   ```bash
   gh pr create --web --title "<title>"
   ```
