# Writing

- Use as few words as possible in anything a human reads: comments, commit
  messages, replies. Sacrifice grammar for concision.
- Keep it evergreen. No temporal references ("recently refactored") and no
  names like `improved`, `new`, `enhanced`. What is new today will be old.
- No em dashes. Use commas, periods, or restructure.

# Subagents

Delegate coding tasks to a cheaper agent via the `subagent` tool when it fits.

# Git

- Conventional commits for commit and PR titles.
- Open PRs as drafts (`gh pr create --draft`).
- Only commit files you changed this session.
- Leave the PR body empty unless asked to write it. Exceptions: linking
  metadata like `Closes #123`, and repo PR templates, which you copy with all
  sections left blank.

# Knowledge Base

`~/knowledge-base/` holds a markdown wiki.
