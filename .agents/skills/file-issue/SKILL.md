---
name: file-issue
description: Create a well-structured GitHub issue from a raw support thread or rough notes. Distills messy input into a clear issue with title, description, and repro steps, then files it and kicks off triage and solve.
argument-hint: "[paste support thread or rough notes]"
allowed-tools: Bash(gh *) Skill Read Grep Glob
disable-model-invocation: true
---

# File an Issue from Raw Context

Take the raw text provided in `$ARGUMENTS` (a support thread, Slack conversation, rough notes, etc.) and create a clean, well-structured GitHub issue from it.

The calling context should provide:
- The repo (`owner/repo`) to file the issue in
- Any additional context needed for triage/solve (issue type IDs, project board details, local paths)

## Steps

### 1. Analyze the raw input

Read through the provided text and extract:
- **The core problem or request** - What is actually going wrong or being asked for?
- **Reproduction steps** - If it's a bug, what steps lead to the problem?
- **Expected vs actual behavior** - What should happen vs what does happen?
- **Environment details** - Any versions, OS, browser, config mentioned
- **Relevant error messages or logs** - Exact error text, stack traces, screenshots mentioned
- **Who reported it** - Attribution if identifiable

Ignore noise like greetings, tangents, "me too" replies, and troubleshooting attempts that didn't lead anywhere (unless they narrow down the root cause).

### 2. Draft the issue

Compose a clear issue with:

**Title**: A concise, specific summary (not vague like "thing is broken"). Should describe the symptom or request.

**Body**: Structured markdown with the relevant sections below. Only include sections that are applicable:

```markdown
<description of the problem or request, written clearly and concisely>

## Steps to Reproduce
1. ...
2. ...

## Expected Behavior
...

## Actual Behavior
...

## Environment
- ...

## Additional Context
<any relevant logs, error messages, or screenshots mentioned in the thread>

---
*Filed from support thread*
```

### 3. Create the issue

```bash
gh issue create -R <repo> --title "<title>" --body "<body>"
```

Report the created issue number and URL.

### 4. Chain to triage and solve

Run `/triage <issue-number>` then `/solve <issue-number>`, passing along any repo-specific context provided by the caller.
