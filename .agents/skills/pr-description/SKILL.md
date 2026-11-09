---
name: pr-description
description: Write or update a PR description in my voice. Use when asked to write, fill in, tighten, or update a PR body.
allowed-tools: read bash
---

Write the PR description for the current branch: $@

## Gather

Read the PR's title, body, base branch, diff, and any linked issues. Include
uncommitted work only if asked. Check for a repo PR template.

If no PR exists, use the repo's default branch as the base. Search for a
matching issue when useful; don't force a link to a loosely related issue.
Keep existing links unless the task calls for changing them. Use `Closes`
only when the PR fully addresses the issue; otherwise use `Refs`.

## Draft

Write the body from the verified facts, following the guidance below. Use a
repo template or user-provided wording when available.

Write like a teammate explaining why the change matters. Usually one or two
sentences is enough: what changes, and why. A bug fix can explain what was
broken; a feature or refactor doesn't need an invented failure story.

Use ordinary language and complete sentences. Keep the details a reviewer
needs to understand the intent, not a compressed tour of the implementation.
Use code names when they're clearer than prose, with backticks. Write in
third person, present tense, with the PR as the subject ("This PR adds...",
"It also makes..."). Don't use "I" or "we", and don't force a before/after
formula.

Mention limitations or follow-up work when omitting them would mislead the
reader. Don't claim tests passed or behavior is supported without evidence.
No em dashes, sales language, or boilerplate headings. Follow the user's
wording and length preferences over these defaults.

The opener is what a human reader is promised is worth their time, so keep it
short even when there is more to say. Put longer detail that would help a
reviewer, such as design decisions, alternatives considered, or verification
steps, in a collapsed block after the opener. Label it with the model and
reasoning level from `PI_MODEL` and `PI_REASONING_LEVEL`, so readers know an
agent wrote it:

    <details>
    <summary>claude-opus-5-5 medium</summary>

    Longer detail here, as Markdown.

    </details>

Keep the blank lines inside the block so GitHub renders the Markdown. Omit the
block when the opener already covers everything a reviewer needs.

Keep paragraphs unwrapped and issue links at the end, after any details block. For a repo template,
preserve its structure, fill the description section, and leave other sections
blank unless asked. Don't mark checkboxes without evidence.

## Apply

Check the draft against the facts. If the user asked only for a draft, return
it without posting. Otherwise write it to a temp file and update the PR with
`gh pr edit --body-file`. Create a draft PR only when requested. Leave an
existing PR's title unchanged unless asked.

Show the resulting body and PR URL without repeating a summary of the change.
