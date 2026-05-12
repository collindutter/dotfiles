# Writing code

- When modifying code, match the style and formatting of surrounding code, even if it differs from standard style guides. Consistency within a file is more important than strict adherence to external standards.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.
- When adding or modifying code, write unit tests if there is an established pattern of doing so in the project (e.g., an existing test suite, test directory, or tests alongside similar code). Match the existing testing style and framework.
- NEVER give time estimates for implementations (e.g., "this will take 2 hours", "phase 1: 1 day"). You have no reliable basis for estimating how long work will take in human time. Describe scope, complexity, or ordering instead if needed.
- Do not preserve backward compatibility unless the user explicitly asks for it.
- No `any` types unless absolutely necessary.

# Tooling

- Prefer `rg` over `grep` and `fd` over `find` for file searches. They are faster and respect `.gitignore` by default.
- Fall back to `grep`/`find` only when `rg`/`fd` are unavailable or when a flag you need isn't supported.

# Committing Code / Pull Requests

- Use conventional commits for commits and pr titles.
- Write PR descriptions as plain prose. Do not use sections like "Summary", "Changes Made", "Test Plan", or any other headers/structure.
- PR descriptions should provide context the diff can't convey: motivation, the problem being solved, relevant background, tradeoffs considered, or anything a reviewer needs to understand the change. Do not narrate what code was changed, since the diff already shows that.
- Use backticks when referencing code elements (functions, variables, files, commands, etc.) in PR descriptions.
- Do not use em dashes (--) in any written output. Use commas, periods, or restructure the sentence instead.
- ONLY commit files YOU changed in THIS session.

# Getting help

- ALWAYS ask for clarification rather than making assumptions.
- If you're having trouble with something, it's ok to stop and ask for help. Especially if it's something your human might be better at.

# Knowledge Base

A personal knowledge base exists at `~/knowledge-base/`. It contains a wiki of markdown articles managed by an Agent, with source material in `raw/` and compiled articles in `wiki/`. Use `/kb-ingest` to process raw sources and `/kb-lint` to run health checks.

# Alerts

- When you finish a task or need the user's attention without needing a response, show a non-blocking macOS alert: `alerter --title "Pi" --message "MESSAGE" --timeout 30 >/dev/null 2>&1 &` where MESSAGE describes what you finished or what you need.
- When you need a response, it is okay for the alert to block. Use `alerter --title "Pi" --message "QUESTION" --actions "Yes,No" --json` or `alerter --title "Pi" --message "QUESTION" --reply "Type here..." --json`.
