---
name: yap
description: Cut yap from the current changes, meaning comments that restate the code, padded docstrings, and bloated docs or PR prose. Use when the user says "yap", "cut the yap", "deyap", asks to tighten comments, or wants a diff cleaned of LLM commentary before review.
---
Cut yap from this branch's changes: $@

Yap is words written for the writer, not the reader. Read the field guide
first. It defines what counts as yap, what survives, the procedure, and the
report format:

    ~/.agents/skills/yap/references/yap-field-guide.md

Steps:

1. Base branch: from the arguments, else the repo's default branch on `origin`
   (`origin/main` or `origin/master`).

2. Scope against the merge-base, including uncommitted work:

       base=$(git merge-base HEAD origin/<base>)
       git diff "$base"
       git log --format='%H%n%B' "$base"..HEAD

   If the branch has a PR, read its body too
   (`gh pr view --json number,url,title,body`).

3. Read the diff as a stranger would. Comments you wrote in this session are
   the easiest to miss, because they still make sense to you. Apply the keep
   test to each added or modified comment, docstring, and paragraph.

4. Edit comments, docstrings, and prose in the changed files only. Leave code,
   tests, and behavior alone. Treat commit messages and the PR body as
   report-only.

5. `git diff` the touched files to confirm no code changed, then report in the
   guide's format. If the PR body has yap, offer tighter text and apply it
   (`gh pr edit --body-file`) only if the user asks. Leave commit messages to
   the user; don't rewrite history for this.

Keep the report free of yap.
