---
name: griptape-ops-infra
description: Use the griptape-ops-slack-handler repo's env and skills for read-only access to Griptape's Datadog and Azure infrastructure when troubleshooting live infra. Use when the user asks about live Griptape Cloud infra state, recent deploys, prod logs, errors, traces, monitors, alerts, AKS / Container Apps / Functions / VMs, activity log, or anything else that requires authenticated read access to Datadog or Azure.
allowed-tools: Bash, Read
---

# Griptape Ops Infra (Datadog + Azure)

The repo at `~/Projects/griptape/griptape-ops-slack-handler` is the Griptape ops bot. It ships with:

- A `.env` containing read-only credentials for **Datadog** (`DD_API_KEY`, `DD_APP_KEY`, `DD_SITE`) and **Azure** (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`).
- Two skills under `.agents/skills/` that document the exact API calls and `az` invocations the bot uses: `.agents/skills/datadog/SKILL.md` and `.agents/skills/azure/SKILL.md`.

Use this repo as a local toolbox when the user asks you to troubleshoot live Griptape infra from outside the bot itself. **You are not the bot** — you do not post to Slack or GitHub. You're using the same credentials and recipes to answer the user directly.

## When to use

- "Check Datadog for ..." / "are there errors in prod right now"
- "What's the state of \<cluster|container app|function\>"
- "What changed in Azure around \<time\>" / activity log questions
- "Pull the monitor behind PD incident X"
- Any live-infra question where `WebFetch` won't work because the data is behind auth.

Do **not** use this for application data questions (Postgres) or GitHub work — those need different credentials and aren't in scope here.

## Setup (do this once per session)

```bash
cd ~/Projects/griptape/griptape-ops-slack-handler

# Load the env into the current shell. set -a exports every assignment.
set -a; source .env; set +a

# For Azure, log in with the service principal from the env.
az login --service-principal \
  -u "$AZURE_CLIENT_ID" \
  -p "$AZURE_CLIENT_SECRET" \
  --tenant "$AZURE_TENANT_ID" >/dev/null
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
```

Datadog needs no separate login — the curl examples below use `DD_API_KEY` / `DD_APP_KEY` directly.

## How to actually run things

The two embedded skill files are the source of truth for query shapes. Read them when you need a recipe:

- Datadog (logs, spans, monitors, PD-incident → monitor pivot):
  `~/Projects/griptape/griptape-ops-slack-handler/.agents/skills/datadog/SKILL.md`
- Azure (resource inventory, AKS, Container Apps, Functions, VMs, activity log, Log Analytics, App Insights, metrics):
  `~/Projects/griptape/griptape-ops-slack-handler/.agents/skills/azure/SKILL.md`

Quick smoke tests to confirm the env is wired up:

```bash
# Datadog: list the first few monitors
curl -s "https://api.${DD_SITE:-datadoghq.com}/api/v1/monitor?page_size=3" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DD_APP_KEY" | jq '.[].name'

# Azure: confirm the active subscription
az account show --query "{name:name, id:id, tenant:tenantId}" -o table
```

## Read-only discipline

Both surfaces are read-only and must stay that way:

- **Azure** — the service principal is scoped to `Reader` + `Monitoring Reader` + `Log Analytics Reader`. Never run `az` subcommands whose verb is `create`, `delete`, `update`, `set`, `restart`, `start`, `stop`, `scale`, `restore`, `purge`, `regenerate`, `reset`, `assign`, or `revoke`. Never run `az ad`, `az role`, or `az policy`. Never pass `--admin` to `az aks get-credentials`. If the user asks for a mutation, decline and tell them to do it themselves with their own credentials.
- **Datadog** — only use `GET` endpoints and the `POST` search endpoints documented in the skill (`/logs/events/search`, `/spans/events/search`). Don't call mutation endpoints (monitor create/update, dashboard edits, downtimes, etc.).

## Discipline for live queries

- Always bound time ranges. ISO 8601 UTC. If the user says "last hour", compute `now - 1h` → `now` and state the window in your answer.
- Never run tail-style commands (`kubectl logs --follow`, `az containerapp logs show --follow`). Use `--tail`, `--since`, or explicit `--start-time` / `--end-time`.
- On HTTP 429 or Log Analytics throttling, stop and report partial results — don't retry in a loop.
- Don't dump giant JSON blobs into the response. Filter at the source with `--query` (Azure) or by summarizing log counts (Datadog).

## What this skill is *not*

- It is not a way to post to Slack or comment on GitHub as the bot. Don't try to invoke `main.py` or simulate a Slack/GitHub event.
- It is not a substitute for the `griptapeops` GitHub App's permissions — your local `gh` is your own identity. Use a separate flow for GitHub work.
- It does not give you Postgres access. The DB credentials in `.env` are the bot's; do not connect to prod Postgres from this skill.
