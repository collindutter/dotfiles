# Writing

- When writing something intended for human consumption, (comment, commit message, reply to prompt) use as few words as possible. Pick every word meticulously to reduce the volume to a strict minimum. Be down to the point. Less is more.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.

# Subagents

Delegation runs through the `subagent` tool from `pi-subagents`. For coding tasks, use your judgement to delegate to a cheaper agent instead of doing the work in the main loop

# Tooling

- Prefer `rg` over `grep` and `fd` over `find` for file searches. They are faster and respect `.gitignore` by default.
- Fall back to `grep`/`find` only when `rg`/`fd` are unavailable or when a flag you need isn't supported.

# Committing Code / Pull Requests

- Use conventional commits for commits and pr titles.
- By default, do NOT write PR descriptions. Leave the PR body empty; the human fills it in.
- If the human explicitly asks you to write the description, write it.
- Default behavior when the repo has a PR template (e.g., `.github/PULL_REQUEST_TEMPLATE.md` or `.github/PULL_REQUEST_TEMPLATE/`): use the template's structure as the PR body but leave the sections blank for the human to fill in. Do not write any content into the sections unless asked to.
- Otherwise, the only thing that may go in a PR body is functional linking metadata, such as `Closes #123` when the issue number is known. Do not write prose, summaries, headers, or a changelog unless asked to.
- Do not use em dashes (--) in any written output. Use commas, periods, or restructure the sentence instead.
- ONLY commit files YOU changed in THIS session.

# Knowledge Base

A personal knowledge base exists at `~/knowledge-base/`. It contains a wiki of markdown articles managed by an Agent, with source material in `raw/` and compiled articles in `wiki/`. Use `/kb-ingest` to process raw sources and `/kb-lint` to run health checks.
