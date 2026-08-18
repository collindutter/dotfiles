---
name: review
description: Run a code review sub-agent
---
Run a code review of the current changes using the `subagent` tool with the
`reviewer` agent: $@

The builtin `reviewer` agent from `pi-subagents` runs in an isolated context as
a separate `pi` process and streams its tool calls and progress live into this
session. It is a general-purpose reviewer, so this skill supplies the rubric:

    ~/.agents/skills/review/references/code-review-rubric.md

That file is the standing definition of what a good review looks like here
(problem framing, correctness, design and structure, LLMisms, output format). It
is deliberately independent of any agent or harness. This skill scopes the diff,
hands over the rubric, and reports the result.

The reviewer has `read`, `grep`, `find`, and `ls` but **no shell**. It cannot
run `git diff` or `gh` itself, so this skill captures that output to a file and
gives the reviewer the path.

Steps:

1. Determine the base branch. Use it if given in the arguments above; otherwise
   default to the repository's default branch on `origin` (`origin/main`, or
   `origin/master` if that is what the repo uses).

2. Compute the review scope against the base branch's merge-base and enumerate
   the changed files:

       base=$(git merge-base HEAD origin/<base>)
       git diff --stat "$base"..HEAD

3. Write the review context to a file outside the repository so the reviewer can
   read it without you pulling the diff into this session's context:

       ctx=$(mktemp -d)/review-context.md
       {
         echo "# Diff under review"
         echo
         echo '```diff'
         git diff "$base"..HEAD
         echo '```'
       } > "$ctx"

   If the branch has an associated PR, append its description and any linked
   issues to the same file so the reviewer can read the intent behind the
   change:

       gh pr view --json number,url,title,body 2>/dev/null

   Append linked issues and follow-up PRs referenced in that body with
   `gh issue view` / `gh pr view` as well. Do not read the diff or the PR body
   into this session yourself; redirect straight to the file.

4. Call the `subagent` tool once with `agent: "reviewer"` and a `task` that:
   - Points at the rubric with its absolute path and states that it is the
     review rubric, to be read first and followed for both the axes to evaluate
     and the output format:
     `/Users/collindutter/.agents/skills/review/references/code-review-rubric.md`
   - Gives the absolute path to the review context file and tells the reviewer
     to read it after the rubric.
   - Lists the changed files with absolute paths so the reviewer can read them
     for context around each hunk.
   - Instructs the reviewer to review only those changes, ignoring pre-existing
     issues in unchanged code, and only report problems the diff causes or newly
     exposes.
   - When a PR exists, notes that its description and linked issues are in the
     context file, so findings account for stated intent and deliberate
     deviations.
   - Forwards any extra focus areas from the arguments above.

   Do not paste the rubric into the task. Pass the path and let the reviewer
   read it, so the rubric stays in one place.

   The review model is pinned in `subagents.agentOverrides.reviewer.model`
   (`~/.pi/agent/settings.json`), not per call. To change it, edit that.

Do not read the code or grade the diff yourself. Let the reviewer subagent do
that. When it finishes, report its findings.
