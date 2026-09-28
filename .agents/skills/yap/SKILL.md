---
name: yap
description: Cut yap from the current changes, meaning comments that restate the code, padded docstrings, and bloated docs or PR prose. Use when the user says "yap", "cut the yap", "deyap", asks to tighten comments, or wants a diff cleaned of LLM commentary before review.
---
Cut yap from this branch's changes with the `subagent` tool and the
`yap-cutter` agent: $@

Yap is words written for the writer, not the reader. The agent is a thin
persona, so this skill hands it the field guide:

    ~/.agents/skills/yap/references/yap-field-guide.md

The guide covers comments, docstrings, repo prose, and commit or PR bodies, and
what survives a cut.

The agent edits files but has no shell, so it can't run `git` or `gh`. Capture
that output to a file and pass the path.

Steps:

1. Base branch: from the arguments, else the repo's default branch on `origin`
   (`origin/main` or `origin/master`).

2. Scope against the merge-base, including uncommitted work, and list changed
   files:

       base=$(git merge-base HEAD origin/<base>)
       git diff --stat "$base"

3. Write the context to a file outside the repo, redirecting straight to it:

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

   If the branch has a PR, append its body
   (`gh pr view --json number,url,title,body`).

4. Call `subagent` once with `agent: "yap-cutter"` and a `task` that:
   - Names the field guide by absolute path as authoritative for what counts
     as yap and the output format:
     `/Users/collindutter/.agents/skills/yap/references/yap-field-guide.md`
   - Gives the context file's absolute path.
   - Lists changed files by absolute path.
   - Allows edits to comments, docstrings, and prose in those files only, not
     code, tests, or behavior.
   - Marks commit messages and the PR body report-only.
   - Forwards extra focus areas from the arguments.

   Pass the guide path rather than pasting it. The model is pinned in
   `~/.pi/agent/agents/yap-cutter.md`.

5. Don't edit the tree while the agent runs.

6. When it finishes, `git diff` the files it touched to confirm it changed no
   code, then report the cuts. If it flagged yap in the PR body, offer tighter
   text and apply it (`gh pr edit --body-file`) only if the user asks. Leave
   commit messages to the user; don't rewrite history for this.

Leave the grading to the agent, and keep your own report free of yap.
