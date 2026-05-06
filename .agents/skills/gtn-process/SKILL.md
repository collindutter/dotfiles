---
name: gtn-process
description: Find griptape-nodes issues created in the last 8 hours and propose a triage plan for each one without applying changes.
allowed-tools: Bash(gh *) Skill Read Grep Glob
disable-model-invocation: true
---

# Process Recent Griptape-Nodes Issues

Find untriaged issues created in the last 8 hours in `griptape-ai/griptape-nodes` and propose a triage plan for each. Do NOT set issue types, add labels, transfer repos, update project status, or post comments. Output is a plan the user can review before any action is taken.

## Griptape Context

All of the following context is used to inform the proposed triage plan. Do not invoke `/triage` or any mutation step.

### Repo
`griptape-ai/griptape-nodes`

### Issue Type IDs
- Task: `IT_kwDOB1fDcM4BG0lm`
- Bug: `IT_kwDOB1fDcM4BG0lp`
- Feature: `IT_kwDOB1fDcM4BG0lt`
- Epic: `IT_kwDOB1fDcM4Bk95C`

### Local Repo Paths and Tmux Sessions
- `griptape-ai/griptape-nodes` -> path: `/Users/collindutter/Projects/griptape/griptape-nodes`, session: `griptape-nodes`
- `griptape-ai/griptape-nodes-library-standard` -> path: `/Users/collindutter/Projects/griptape/griptape-nodes-libraries/griptape-nodes-library-standard`, session: `griptape-nodes-libraries`
- `griptape-ai/griptape-vsl-gui` -> path: `/Users/collindutter/Projects/griptape/griptape-vsl-gui`, session: `griptape-nodes-ui`

### Repo Routing
Issues filed in `griptape-nodes` may actually belong in:
- `griptape-ai/griptape-nodes-library-standard` - if the issue is about library/node code
- `griptape-ai/griptape-vsl-gui` - if the issue is about the UI/frontend

### GitHub Project Board
- Project ID: `PVT_kwDOB1fDcM4AO0Q1`
- Status Field ID: `PVTSSF_lADOB1fDcM4AO0Q1zgJdTQo`
- Status Options:
  - To triage: `da2dffc2`
  - Backlog: `c625926a`
  - In Progress: `ab014513`
  - In review: `b6146984`
  - Done: `98236657`
  - Blocked: `53987995`

## Steps

### 1. Compute the 8-hour cutoff

Calculate the ISO 8601 timestamp for 8 hours ago:
```bash
date -u -v-8H '+%Y-%m-%dT%H:%M:%S'
```

### 2. Fetch recent untriaged issues

Use GraphQL to get open issues from the last 8 hours that have no issue type set:

```bash
gh api graphql -f query='query {
  search(query: "repo:griptape-ai/griptape-nodes is:issue is:open created:>YYYY-MM-DDTHH:MM:SS", type: ISSUE, first: 50) {
    nodes {
      ... on Issue {
        id
        number
        title
        issueType { name }
      }
    }
  }
}'
```

Filter the results to only issues where `issueType` is null.

### 3. Analyze each issue (read-only)

For each untriaged issue, in sequence, read the issue and explore the relevant local repo paths to understand it. Do NOT run `/triage`, do NOT call any mutating `gh` command (no label adds, no type sets, no transfers, no project status updates, no comments).

### 4. Output a triage plan

For each issue, print a proposed plan that the user can review before any action is taken:
- Issue number, title, and URL
- Proposed issue type and a brief reason
- Proposed labels (if any) and reason
- Proposed target repo if routing applies, and reason
- Proposed project status change (e.g. To triage → Backlog)
- Any open questions or ambiguity the user should resolve

End with a note that no changes have been made and the user should confirm before applying.
