---
name: review
description: Run an adversarial code review sub-agent that tries to break the current changes and returns a ship/iterate/rethink verdict
---
Adversarially review the current changes with the `subagent` tool and the
`reviewer` agent:
$@

The builtin `reviewer` from `pi-subagents` runs in an isolated context and
streams progress into this session. It is general-purpose, so this skill hands
it the rubric:

    ~/.agents/skills/review/references/code-review-rubric.md

The rubric sets the adversarial stance, attack surface, finding bar, and
output format. The reviewer's value comes from independence. It must judge the
diff without your reasoning about it, so don't explain or defend the change in
the task.

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

   Append the repo's rules from the base branch: `REVIEW.md`, `AGENTS.md`, and
   `CLAUDE.md` at the root or in a directory above a changed file, skipping
   symlinks. Also append any file a root `REVIEW.md` includes with an
   `@<file>` line.

       changed=$(git diff --name-only "$base"..HEAD)
       git ls-tree -r origin/<base> \
         | awk '$1 != "120000" && $4 ~ /(^|\/)(REVIEW|AGENTS|CLAUDE)\.md$/ {print $4}' \
         | while read -r f; do
             d=$(dirname "$f")
             if [ "$d" = . ] || grep -q "^$d/" <<<"$changed"; then
               printf '\n# Repo rules: %s\n\n' "$f"
               git show "origin/<base>:$f"
             fi
           done >> "$ctx"

   If the branch has a PR, append its description
   (`gh pr view --json number,url,title,body`) plus any issues and follow-up
   PRs it links (`gh issue view`, `gh pr view`).

4. Call `subagent` once with `agent: "reviewer"` and a `task` that:
   - Frames the job as adversarial: find the strongest reasons this diff
     should not ship, and return `SHIP` with no findings if none hold up.
   - Names the rubric by absolute path, to read first and follow for method
     and output format:
     `/Users/collindutter/.agents/skills/review/references/code-review-rubric.md`
   - Gives the context file's absolute path, to read after the rubric. Says
     any repo rules in it calibrate the rubric as its "Repository rules"
     section describes.
   - Lists changed files by absolute path, for context around each hunk.
   - Limits the review to problems the diff causes or newly exposes.
   - When a PR exists, says its description and linked issues are in the
     context file, as the claims to attack.
   - Forwards extra focus areas from the arguments, to weight heavily without
     ignoring other material issues.
   - Contains no summary of the change, its rationale, or your confidence in
     it.

   Pass the rubric path rather than pasting it, so it stays in one place. The
   model is pinned in `subagents.agentOverrides.reviewer.model`
   (`~/.pi/agent/settings.json`).

5. Spot-check findings before reporting them. Reviewers can sound certain
   about problems that aren't there. For each `high` or `medium` finding,
   read the cited lines and confirm the scenario is reachable. Report what
   you couldn't confirm as disputed, with the evidence, rather than dropping
   it silently. The review itself changes no code.

Report the verdict first, then confirmed findings by severity, then disputed
ones, then the reviewer's coverage gaps.
