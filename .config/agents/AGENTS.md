# Writing Comments

- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.

# Delegating coding work to subagents

Delegation runs through the `subagent` tool from `pi-subagents`. For coding
tasks, use your judgement to delegate to a cheaper agent instead of doing the
work in the main loop:

- `scout` (Haiku): fast read-only codebase recon that returns compressed
  findings for handoff. Use it to gather context before designing or
  delegating, instead of reading everything in the main loop.
- `researcher` (Sonnet): web and docs research that returns a sourced brief.
  Use it before trusting external facts.
- `worker` (Sonnet): substantive implementation work with a clear spec. It
  escalates unapproved decisions instead of guessing.
- `delegate` (Haiku): trivial/mechanical edits (renames, copy changes, small
  fixes, config tweaks) and anything that just needs a cheap second pair of
  hands close to the parent session.
- `reviewer` (Sonnet): read-only review of a diff, plan, or proposed solution.
  Use it to check work before committing or opening a PR. It has no shell, so
  give it file paths or a diff written to a file rather than a git command.
- `oracle` (Opus): a second opinion before acting. Use it when the decision
  itself is risky, not when the work is merely large.

The builtin `reviewer` is general purpose and carries no rubric of its own. When
delegating a review, pass the absolute path of the relevant rubric in the task
and tell it to read that first:

- Code and diffs: `~/.agents/skills/review/references/code-review-rubric.md`
- Documentation: `~/.agents/skills/docs-review/references/docs-review-rubric.md`

Pass the path, never the file contents, so the rubric stays in one place. The
`review` and `docs-review` skills already do this; the rule is for ad-hoc review
delegation that does not go through them. Those rubrics are plain documents with
no dependency on any agent harness, so they are equally usable for a review you
do yourself in the main loop.

Models are pinned per role in `subagents.agentOverrides`
(`~/.pi/agent/settings.json`), not per call, so do not try to pass a model.

Give the subagent a self-contained prompt: the files involved, the exact
change wanted, and any conventions to follow. Review the resulting diff in the
main loop before considering the task done.

Multi-step delegation is code-driven. Use `workflowScript` with
`await runs.run(key, {...})` for sequential steps and `await runs.all([...])`
for parallel fanout. There are no top-level `chain`, `tasks`, or `parallel`
parameters.

Keep in the main loop: design decisions, debugging that requires judgement,
code review, synthesis, and anything where the spec is still fuzzy. When in
doubt, or when a delegated task comes back wrong twice, just do it yourself.

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

# Getting help

- ALWAYS ask for clarification rather than making assumptions.
- When using the `ask_user_question` tool, ALWAYS preserve a way for me to type a custom answer. The auto-appended "Type something." row is suppressed on multi-select questions and on any single-select question where an option carries a `preview`. So avoid `multiSelect` and option `preview`s unless they are truly necessary; if I need to type a custom answer, keep questions single-select with no previews.
- If you're having trouble with something, it's ok to stop and ask for help. Especially if it's something your human might be better at.

# Knowledge Base

A personal knowledge base exists at `~/knowledge-base/`. It contains a wiki of markdown articles managed by an Agent, with source material in `raw/` and compiled articles in `wiki/`. Use `/kb-ingest` to process raw sources and `/kb-lint` to run health checks.

# Alerts

- Finish-of-task notifications are automatic. The `alerter` extension (`~/.pi/agent/extensions/alerter.ts`) fires a macOS notification when the agent finishes a prompt, suppressed while the terminal is focused. Do not run `alerter` by hand for this.
