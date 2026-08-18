---
name: docs-review
description: Run a documentation review sub-agent that checks docs for accuracy against the code and for human, non-LLM voice. Use when the user asks to review docs, a README, a guide, or documentation changes.
---
Run a documentation review using the `subagent` tool with the builtin `reviewer`
agent: $@

The reviewer is a general-purpose review agent, so this skill supplies the
rubric:

    ~/.agents/skills/docs-review/references/docs-review-rubric.md

That file is the standing definition of a good docs review here. It has two
axes in priority order: is it TRUE (every command, flag, path, signature, and
config key verified against the source), and does it read like a human wrote it
(the banned constructions and structural tells). It is deliberately independent
of any agent or harness. This skill scopes the docs, hands over the rubric, and
reports the result.

The reviewer has `read`, `grep`, `find`, and `ls` but **no shell**. It cannot run
`git diff` or `gh` itself, so this skill captures that output to a file and gives
the reviewer the path.

Steps:

1. Determine the scope. Use whatever the arguments above specify: explicit doc
   files, or a diff. If nothing is specified, review the documentation changed on
   this branch.

2. Determine the base branch when diffing. Use it if given; otherwise default to
   the repository's default branch on `origin` (`origin/main`, or `origin/master`
   if that is what the repo uses).

3. Enumerate the docs in scope and filter to prose files (`.md`, `.mdx`, `.rst`,
   `.txt`, docs directories, changelogs):

       base=$(git merge-base HEAD origin/<base>)
       git diff --stat "$base"..HEAD

4. Write the review context to a file outside the repository so the reviewer can
   read it without you pulling the diff into this session's context:

       ctx=$(mktemp -d)/docs-review-context.md
       {
         echo "# Documentation diff under review"
         echo
         echo '```diff'
         git diff "$base"..HEAD -- <doc paths>
         echo '```'
       } > "$ctx"

   If the branch has an associated PR, append its description so the reviewer can
   read the intent behind the change:

       gh pr view --json number,url,title,body 2>/dev/null

   When the scope is a set of files rather than a diff, skip the diff capture and
   just pass the file paths.

5. Call the `subagent` tool once with `agent: "reviewer"` and a `task` that:
   - Points at the rubric with its absolute path and states that it is the review
     rubric, to be read first and followed for both axes and the output format:
     `/Users/collindutter/.agents/skills/docs-review/references/docs-review-rubric.md`
   - Gives the absolute path to the review context file, when there is a diff.
   - Lists the doc files in scope with absolute paths, and instructs the reviewer
     to review only those.
   - Tells the reviewer to verify every concrete claim against the source in the
     repository rather than trusting the prose, and to mark anything it cannot
     confirm as an unverifiable claim.
   - Reminds the reviewer that the review is read-only and it must NOT execute
     any command a doc tells the reader to run.
   - Forwards any extra focus areas from the arguments above.

   Do not paste the rubric into the task. Pass the path and let the reviewer read
   it, so the rubric stays in one place.

   The review model is pinned in `subagents.agentOverrides.reviewer.model`
   (`~/.pi/agent/settings.json`), not per call. To change it, edit that.

Do not read or grade the docs yourself. Let the reviewer subagent do that. When
it finishes, report its findings.
