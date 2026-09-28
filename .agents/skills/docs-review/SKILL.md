---
name: docs-review
description: Run a documentation review sub-agent that checks docs for accuracy against the code and for human, non-LLM voice. Use when the user asks to review docs, a README, a guide, or documentation changes.
---
Review documentation with the `subagent` tool and the `docs-reviewer` agent:
$@

The agent is a thin persona, so this skill hands it the rubric:

    ~/.agents/skills/docs-review/references/docs-review-rubric.md

Two axes, in priority order: is it true (every command, flag, path, signature,
and config key checked against the source), and does it read like a human wrote
it.

The reviewer has `read`, `grep`, `find`, and `ls` but no shell, so it can't run
`git` or `gh`. Capture that output to a file and pass the path.

Steps:

1. Scope: explicit doc files or a diff, from the arguments. None given: docs
   changed on this branch.

2. Base branch when diffing: from the arguments, else the repo's default branch
   on `origin` (`origin/main` or `origin/master`).

3. List docs in scope, keeping prose files (`.md`, `.mdx`, `.rst`, `.txt`, docs
   directories, changelogs):

       base=$(git merge-base HEAD origin/<base>)
       git diff --stat "$base"..HEAD

4. For a diff, write the context to a file outside the repo, redirecting
   straight to it:

       ctx=$(mktemp -d)/docs-review-context.md
       {
         echo "# Documentation diff under review"
         echo
         echo '```diff'
         git diff "$base"..HEAD -- <doc paths>
         echo '```'
       } > "$ctx"

   If the branch has a PR, append its description
   (`gh pr view --json number,url,title,body`). For a file-set scope, skip the
   capture and pass the paths.

5. Call `subagent` once with `agent: "docs-reviewer"` and a `task` that:
   - Names the rubric by absolute path, to read first and follow for both axes
     and the output format:
     `/Users/collindutter/.agents/skills/docs-review/references/docs-review-rubric.md`
   - Gives the context file's absolute path, when there is a diff.
   - Lists the docs in scope by absolute path and limits the review to them.
   - Says the review is read-only: don't run commands the docs tell readers to
     run.
   - Forwards extra focus areas from the arguments.

   Pass the rubric path rather than pasting it. The model is pinned in
   `~/.pi/agent/agents/docs-reviewer.md`.

Leave the grading to the reviewer. When it finishes, report its findings.
