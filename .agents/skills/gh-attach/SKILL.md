---
name: gh-attach
description: Upload images or videos (screenshots, pi-clipboard PNGs) to GitHub issues, PRs, and comments from the CLI. Use when asked to upload, attach, or embed a screenshot or media in a PR, issue, or comment.
---
`gh` (v2.99+) uploads media with `--attach`. No browser, no repo commits.
Works on `gh issue create|comment`, `gh pr create|comment|edit`.

```sh
# Append to the existing body
gh pr edit 123 --attach './shot.png#Alt text'

# Place it in the body: reference the same relative path, gh rewrites it
# to a github.com/user-attachments URL
echo '![Alt text](./shot.png)' >> body.md
gh pr edit 123 --body-file body.md --attach ./shot.png
```

Write body files with `mktemp`, never a fixed `/tmp` name: parallel sessions
clobber each other. Copy pi-clipboard files to a short name first. Repeat `--attach` for
multiple files. Needs push access to the repo.
