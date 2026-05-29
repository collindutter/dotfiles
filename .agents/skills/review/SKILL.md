---
name: review
description: Run a code review sub-agent
---
Spawn yourself as a sub-agent via bash to do a code review: $@

Use `pi --print` with appropriate arguments. If the user specifies a model,
use `--provider` and `--model` accordingly.

Pass a prompt to the sub-agent asking it to review only the changes introduced
by this PR (e.g. the diff against the base branch), not pre-existing code. Focus
exclusively on bugs introduced by these changes:
- Bugs and logic errors introduced by the diff
- Security issues introduced by the diff
- Error handling gaps introduced by the diff

Instruct the sub-agent to ignore pre-existing issues in unchanged code. Only
report problems that the changes in this PR cause or newly expose.

Do not read the code yourself. Let the sub-agent do that.

Report the sub-agent's findings.
