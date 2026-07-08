---
name: open-pr
description: Write a PR description using conversation context and open PR creation in browser.
disable-model-invocation: true
allowed-tools: read bash
---

Write a PR description from the conversation context and open PR creation in the browser.

## Gather context

1. Get the base branch (usually `main` or `master`).
2. Get the diff: `git diff <base>...HEAD`.
3. Get the commit messages: `git log <base>...HEAD --format="%s"`.
4. Read changed files as needed to understand the broader context.

## Commit and push

1. Run `git status`. If there are uncommitted changes you made in this session,
   commit them. Only commit files you changed; do not sweep in unrelated edits.
2. Use a conventional-commit message (e.g. `feat:`, `fix:`, `refactor:`),
   lowercase, imperative mood.
3. Push the branch: `git push -u origin HEAD`.

## Write the description

Write the body as **plain prose**. Do NOT use section headers like "Summary",
"Changes", or "Test Plan", and do NOT write a bullet-point changelog.

The description should convey what the diff cannot: the motivation, the problem
being solved, relevant background, and any tradeoffs considered. Do not narrate
what code changed; the diff already shows that. Before each sentence, ask whether
a careful reviewer could infer it from the diff alone, and if so, cut it. Justify
a default only when it is actually contested.

- Keep it concise.
- Use backticks when referencing code elements (functions, variables, files,
  commands).
- Do NOT use em dashes. Use commas, periods, or restructure the sentence.

## Create the PR

1. Write a short PR title in conventional-commit format (e.g.
   `fix: handle missing library metadata on proxy nodes`), max 72 characters.
2. Open PR creation in the browser (do NOT create it directly):
   ```bash
   gh pr create --web --title "<title>" --body "<body>"
   ```
