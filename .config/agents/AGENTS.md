# Writing code

- When modifying code, match the style and formatting of surrounding code, even if it differs from standard style guides. Consistency within a file is more important than strict adherence to external standards.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.
- When adding or modifying code, write unit tests if there is an established pattern of doing so in the project (e.g., an existing test suite, test directory, or tests alongside similar code). Match the existing testing style and framework.
- NEVER give time estimates for implementations (e.g., "this will take 2 hours", "phase 1: 1 day"). You have no reliable basis for estimating how long work will take in human time. Describe scope, complexity, or ordering instead if needed.
- Do not preserve backward compatibility unless the user explicitly asks for it.
- No `any` types unless absolutely necessary.

# Delegating coding work to subagents

For coding tasks, use your judgement to delegate implementation to a
lower-power model via the `subagent` tool instead of doing it in the main
loop:

- `coder` (Sonnet): substantive implementation work with a clear spec.
- `mechanic` (Haiku): trivial/mechanical edits (renames, copy changes, small
  fixes, config tweaks).

Give the subagent a self-contained prompt: the files involved, the exact
change wanted, and any conventions to follow. Review the resulting diff in the
main loop before considering the task done.

Keep in the main loop: design decisions, debugging that requires judgement,
code review, synthesis, and anything where the spec is still fuzzy. When in
doubt, or when a delegated task comes back wrong twice, just do it yourself.

# Tooling

- Prefer `rg` over `grep` and `fd` over `find` for file searches. They are faster and respect `.gitignore` by default.
- Fall back to `grep`/`find` only when `rg`/`fd` are unavailable or when a flag you need isn't supported.

# Committing Code / Pull Requests

- Use conventional commits for commits and pr titles.
- Do NOT write PR descriptions. Leave the PR body empty; the human fills it in.
- The only thing that may go in a PR body is functional linking metadata, such as `Closes #123` when the issue number is known. Never write prose, summaries, headers, or a changelog.
- Do not use em dashes (--) in any written output. Use commas, periods, or restructure the sentence instead.
- ONLY commit files YOU changed in THIS session.

# Getting help

- ALWAYS ask for clarification rather than making assumptions.
- If you're having trouble with something, it's ok to stop and ask for help. Especially if it's something your human might be better at.

# Knowledge Base

A personal knowledge base exists at `~/knowledge-base/`. It contains a wiki of markdown articles managed by an Agent, with source material in `raw/` and compiled articles in `wiki/`. Use `/kb-ingest` to process raw sources and `/kb-lint` to run health checks.

# Alerts

- Finish-of-task notifications are automatic. The `alerter` extension (`~/.pi/agent/extensions/alerter.ts`) fires a macOS notification when the agent finishes a prompt, suppressed while the terminal is focused. Do not run `alerter` by hand for this.
