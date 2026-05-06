---
name: triage
description: Triage a single GitHub issue. Read the issue, classify its type, add relevant labels, route to the correct repo if needed, and update project board status.
argument-hint: "[issue-number]"
allowed-tools: Bash(gh *) Read Grep Glob
disable-model-invocation: true
---

# Triage a GitHub Issue

Triage the issue specified by `$ARGUMENTS`. The calling context provides repo-specific details including the repo, issue type IDs, project board IDs, local repo paths, and routing rules.

## Steps

### 1. Read the issue

```bash
gh issue view $ARGUMENTS -R <repo> --json id,number,title,body,comments,labels,assignees,url
```

### 2. Explore the codebase

Use the local repo paths provided by the calling context to search for relevant code. Read files, grep for keywords mentioned in the issue, and understand the area of the codebase involved.

### 3. Classify issue type

Based on the issue content and codebase exploration, classify as one of the provided issue types (e.g. Bug, Feature, Task, Epic).

Guidelines:
- **Bug**: Something is broken or behaving unexpectedly
- **Feature**: A request for new functionality or capability
- **Task**: A specific piece of work that needs doing (refactor, update, config change)
- **Epic**: A large body of work that should be broken into smaller issues

### 4. Set issue type

Use the GraphQL `updateIssue` mutation with the issue's node ID and the appropriate type ID from the calling context:

```bash
gh api graphql -f query='mutation { updateIssue(input: {id: "<issue_node_id>", issueTypeId: "<type_id>"}) { issue { issueType { name } } } }'
```

### 5. Add relevant labels

Add labels that provide information beyond the issue type. Do NOT add labels that are redundant with the issue type (e.g. don't add a "bug" label if the issue type is Bug).

### 6. Route to correct repo

If routing rules are provided and the issue belongs in a different repo, transfer it:

```bash
gh issue transfer <issue-number> <destination-owner/repo> -R <source-owner/repo>
```

### 7. Update project status

If project board details are provided, move the issue from "To triage" to "Backlog":

1. Get the issue's project item ID:
```bash
gh api graphql -f query='query { node(id: "<issue_node_id>") { ... on Issue { projectItems(first: 10) { nodes { id project { id } } } } } }'
```

2. Update the status field:
```bash
gh api graphql -f query='mutation { updateProjectV2ItemFieldValue(input: {projectId: "<project_id>", itemId: "<item_id>", fieldId: "<status_field_id>", value: {singleSelectOptionId: "<backlog_option_id>"}}) { projectV2Item { id } } }'
```

### 8. Post triage comment

Comment on the issue with a brief summary of the triage:
- What issue type was assigned and why
- Any labels added
- Whether the issue was transferred to another repo (and which one)

```bash
gh issue comment <issue-number> -R <repo> --body "<triage summary>"
```
