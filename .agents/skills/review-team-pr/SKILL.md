---
name: review-team-pr
description: Check out a teammate's PR into a new workmux worktree and kick off a code review there. Use when the user provides a PR link or number and asks to "review this PR", "review team PR", or wants a PR checked out and reviewed in its own worktree/session.
---
Check out a pull request into a fresh workmux worktree and start the `review`
skill in that worktree's agent session: $@

Steps:

1. Extract the PR number from the arguments above. Accept either:
   - A bare number (e.g., `123` or `#123`)
   - A GitHub PR URL (e.g., `https://github.com/org/repo/pull/123`), take the
     number after `/pull/`

   If no PR number can be determined, ask the user for one.

2. Determine the PR's base branch so the review diffs against the right thing:

       gh pr view <number> --json baseRefName --jq .baseRefName

   If `gh` fails (not installed, not authenticated), fall back to omitting the
   base and let the review skill use the repo's default branch.

3. Create the worktree and inject the review prompt so the agent in the new
   session starts the review immediately:

       workmux add --pr <number> -p "Use the review skill to review this PR's changes against origin/<base>."

   Notes:
   - Run this from inside the repository the PR belongs to.
   - Do not pass `-b`; let workmux switch to the new window so the user lands
     in the review session.
   - If the user included extra focus areas in the arguments, append them to
     the prompt so the review skill forwards them to the reviewer.

4. Report the worktree/branch that was created and that the review is running
   in its tmux window. Do not run the review yourself in this session; the
   injected prompt drives it in the new worktree's agent.
