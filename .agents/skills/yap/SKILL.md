---
name: yap
description: Cut yap from the current changes, meaning comments that restate the code, padded docstrings, and bloated docs or PR prose. Use when the user says "yap", "cut the yap", "deyap", asks to tighten comments, or wants a diff cleaned of LLM commentary before review.
---
Cut the yap from the changes on this branch using the `subagent` tool with the
`yap-cutter` agent: $@

Yap is the residue left behind by thinking out loud: words written for the
writer, not the reader. The agent is a thin persona, so this skill supplies the
field guide:

    ~/.agents/skills/yap/references/yap-field-guide.md

That file is the standing definition of yap here, covering code comments,
docstrings, repo prose, and commit or PR bodies, plus what survives a cut. It is
independent of any agent or harness. This skill scopes the diff, hands over the
guide, and reports what got cut.

The agent edits files but has no shell. It cannot run `git diff` or `gh`, so
this skill captures that output to a file and gives it the path.

Steps:

1. Determine the base branch. Use it if given in the arguments above; otherwise
   default to the repository's default branch on `origin` (`origin/main`, or
   `origin/master` if that is what the repo uses).

2. Scope the pass against the base branch's merge-base and enumerate the changed
   files:

       base=$(git merge-base HEAD origin/<base>)
       git diff --stat "$base"..HEAD

   Include uncommitted work: diff against the working tree, not just `HEAD`.

3. Write the context to a file outside the repository so the agent can read it
   without you pulling the diff into this session:

       ctx=$(mktemp -d)/yap-context.md
       {
         echo "# Diff under review"
         echo
         echo '```diff'
         git diff "$base"
         echo '```'
         echo
         echo "# Commit messages"
         git log --format='%H%n%B' "$base"..HEAD
       } > "$ctx"

   If the branch has an associated PR, append its body:

       gh pr view --json number,url,title,body 2>/dev/null

   Do not read the diff into this session yourself; redirect straight to the
   file.

4. Call the `subagent` tool once with `agent: "yap-cutter"` and a `task` that:
   - Points at the field guide with its absolute path and states it is
     authoritative for what counts as yap and for the output format:
     `/Users/collindutter/.agents/skills/yap/references/yap-field-guide.md`
   - Gives the absolute path to the context file.
   - Lists the changed files with absolute paths.
   - Says the agent may edit comments, docstrings, and prose in those files, and
     must not touch code, tests, or behavior.
   - Says commit messages and the PR body are report-only, since the agent has
     no shell.
   - Forwards any extra focus areas from the arguments above.

   Do not paste the guide into the task. Pass the path so the guide stays in one
   place.

   The model is pinned in the `yap-cutter` frontmatter
   (`~/.pi/agent/agents/yap-cutter.md`), not per call. To change it, edit that.

5. The agent is the only writer while it runs. Do not edit files in the same
   tree until it finishes.

6. When it finishes, `git diff` the files it touched to confirm no code changed,
   then report the cuts. If it flagged yap in the PR body, offer the tightened
   text and apply it with `gh pr edit --body-file` only if the user asks. Commit
   messages are the user's call; never rewrite history for this.

Do not grade the comments yourself. Let the subagent do it. Keep your own report
free of yap.
