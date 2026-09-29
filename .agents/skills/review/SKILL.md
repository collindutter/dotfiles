---
name: review
description: Run a code review sub-agent
---
Review the current changes with the `subagent` tool and the `reviewer` agent:
$@

The builtin `reviewer` from `pi-subagents` runs in an isolated context and
streams progress into this session. It is general-purpose, so this skill hands
it the rubric:

    ~/.agents/skills/review/references/code-review-rubric.md

The rubric defines a good review here (problem framing, correctness, design,
LLMisms, yap, output format) and points the reviewer at the yap field guide, so
yap has one definition. The reviewer only reports yap; the `yap` skill cuts it.

The reviewer has `read`, `grep`, `find`, and `ls` but no shell, so it can't run
`git` or `gh`. Capture that output to a file and pass the path.

Steps:

1. Base branch: from the arguments, else the repo's default branch on `origin`
   (`origin/main` or `origin/master`).

2. Scope against the merge-base and list changed files:

       base=$(git merge-base HEAD origin/<base>)
       git diff --stat "$base"..HEAD

3. Write the context to a file outside the repo, redirecting straight to it so
   the diff stays out of this session:

       ctx=$(mktemp -d)/review-context.md
       {
         echo "# Diff under review"
         echo
         echo '```diff'
         git diff "$base"..HEAD
         echo '```'
       } > "$ctx"

   If the branch has a PR, append its description
   (`gh pr view --json number,url,title,body`) plus any issues and follow-up
   PRs it links (`gh issue view`, `gh pr view`).

4. Call `subagent` once with `agent: "reviewer"` and a `task` that:
   - Names the rubric by absolute path as the review rubric, to read first and
     follow for axes and output format:
     `/Users/collindutter/.agents/skills/review/references/code-review-rubric.md`
   - Gives the context file's absolute path, to read after the rubric.
   - Lists changed files by absolute path, for context around each hunk.
   - Limits the review to problems the diff causes or newly exposes.
   - When a PR exists, says its description and linked issues are in the
     context file, so findings account for stated intent.
   - Forwards extra focus areas from the arguments.

   Pass the rubric path rather than pasting it, so it stays in one place. The
   model is pinned in `subagents.agentOverrides.reviewer.model`
   (`~/.pi/agent/settings.json`).

Leave the grading to the reviewer. When it finishes, report its findings.
