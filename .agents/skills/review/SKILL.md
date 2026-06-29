---
name: review
description: Run a code review sub-agent
---
Run a code review of the current changes using the `subagent` tool with the
`reviewer` agent: $@

The `reviewer` agent (`~/.pi/agent/agents/reviewer.md`) runs in an isolated
context as a separate `pi` process and streams its tool calls and progress live
into this session, so its work is visible as it happens. The review rubric and
output format live in that agent's prompt; this skill only scopes the diff and
hands it off.

Steps:

1. Determine the base branch. Use it if given in the arguments above; otherwise
   default to the repository's default branch on `origin` (`origin/main`, or
   `origin/master` if that is what the repo uses).

2. Compute the review scope against the base branch's merge-base and enumerate
   the changed files:

       git merge-base HEAD origin/<base>
       git diff --stat "$(git merge-base HEAD origin/<base>)"..HEAD

3. Call the `subagent` tool once with `agent: "reviewer"` and a `task` that:
   - States the exact diff command to review:
     `git diff "$(git merge-base HEAD origin/<base>)"..HEAD`
   - Lists the changed files and instructs the reviewer to review only those,
     ignoring pre-existing issues in unchanged code, and only report problems
     the diff causes or newly exposes.
   - Forwards any extra focus areas from the arguments above.

   The `subagent` tool has no per-call model override; the review model is set
   in the `reviewer` agent's frontmatter. To change it, edit that file.

Do not read the code or run the diff yourself. Let the reviewer subagent do
that. When it finishes, report its findings.
