---
name: slacker
description: Fetch Slack threads, download attached files, and search messages for the user so they don't have to copy-paste conversations into chat. Use when the user shares a Slack permalink, asks to pull a thread, asks for a file or screenshot posted in Slack, or references a Slack search.
allowed-tools: Bash(slacker *)
---

# Slack for the user

Use the `slacker` CLI to read Slack threads, download attachments, and search
messages directly, instead of asking the user to paste content.

## When to use

- The user shares a Slack permalink (`https://*.slack.com/archives/...`).
- The user asks you to read, summarize, or act on a Slack thread or search.
- The user references a Slack conversation you haven't been shown.
- The user references a file, image, video, or log posted in Slack.

## Commands

- Fetch a thread by permalink: `slacker read-thread --url <permalink> --format text`
- Fetch a thread by IDs: `slacker read-thread --channel <C...> --ts <1700000000.000100> --format text`
- Search: `slacker search-messages --format text -- <query>`
- Download files: `slacker download-file <target>... --dir <path>`
- Verify auth: `slacker auth test`

Use `--format json` when you need structured output to parse.
Pass `--limit` on `read-thread` to cap replies.

## Downloading files

`read-thread` lists each attachment's file ID. Pass those IDs, a file
permalink (`https://*.slack.com/files/...`), or a `files.slack.com` URL to
`download-file`. Downloads land in the current directory unless you pass
`--dir`; use `--name` to rename a single download and `--force` to overwrite.
Download into a temp directory when the user only wants you to inspect a file.

## If auth is missing

If a command fails with "No config" or "not_authed", tell the user to run
`slacker auth parse-curl` after copying a `*.slack.com/api/...` request from
browser DevTools as cURL. Do not attempt to capture credentials yourself.
