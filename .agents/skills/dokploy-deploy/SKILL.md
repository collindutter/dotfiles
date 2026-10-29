---
name: dokploy-deploy
description: Deploy a personal app from scratch to Collin's Dokploy setup using GitHub Actions, GHCR, Tailscale, shared PostgreSQL, Cloudflare DNS/R2, Google Sign-In, Mailgun, and backups. Use when asked to deploy a project, set up its hosting, or wire up this stack.
---

# Dokploy deployment

Provision a new application on existing infrastructure, not another Dokploy installation. Adapt runtime steps to the repository; Django examples are not requirements for other stacks. Optional integrations apply only when the app needs them.

## 1. Choose the identity and target

Agree on the app name, repository slug, owner email, and hostname before creating resources. Offer a subdomain of an owned zone. Explain any temporary `sslip.io` hostname before using one; it resolves an embedded IP without buying a domain.

Inspect repo instructions, Git status/remotes, dependencies, startup command, tests, migrations, authentication, static/media handling, and deployment files. Preserve unrelated changes. New repositories and images stay private unless the user requests otherwise; do not invent a license.

These are discovery hints, not permission to trust stale addresses:

| Resource | Expected target |
|---|---|
| Dokploy API | `http://dokploy:3000`, Tailscale IP `100.114.107.61` |
| Deployment server | **Side Projects**, Tailscale `100.121.184.24`, public `5.78.77.159` |
| Side Projects server ID | `wc0xPdanigJqDRFQdhcMw` |
| Shared PostgreSQL | `shared-infrastructure-postgres-dplt29`, internal port `5432` |
| Shared PostgreSQL ID | `dCkBBr4WkaJOlLlpbVRRO` |
| TablePlus endpoint | Side Projects' Tailscale address, port `5435` |

Verify with Tailscale, SSH hostname, Dokploy metadata, and Docker service inspection. **Do not deploy to Page Goblin's servers or use its databases, buckets, or backup destinations.** Leave shared admin credentials, published ports, firewall rules, and other applications unchanged.

References, inspect rather than copy blindly:

- `~/Projects/personal/artiflect`: Dockerfile, `.github/workflows/`, deployment guard script, private R2 storage, Mailgun configuration.
- `~/Projects/personal/spider-league/.github/workflows/`: the existing checks → GHCR → Tailscale → Dokploy pattern.
- `~/Projects/personal/page-goblin`: Django storage/email examples only. Its public-media configuration is unsuitable for private artifacts.

## 2. Authenticate without leaking credentials

Check `gh auth status`, `tailscale status`, `op account list`, and `op vault list`. For 1Password, the user enables **Settings → Developer → Integrate with 1Password CLI**, unlocks the app, and approves prompts.

Relevant 1Password items:

- `Dokploy Github Actions Api Key`
- `Dokploy GHCR Personal Access Token`
- `Tailscale Github OAuth`

Inspect item titles and field names first. Notes may contain `KEY=value` lines rather than a raw token. Parse values inside a process; pass secrets through stdin or request bodies, not printed shell commands. Use `gh secret set` with stdin. Store scratch credentials in an owner-only directory/files (`0700`/`0600`) and remove them after verification.

Validate credentials against their intended service. On denial or expired credentials, request the missing access. Do not manufacture Dokploy sessions/API keys through its database, expose images to avoid registry authentication, or widen permissions silently.

### Cloudflare

Prefer its official MCP server with browser OAuth:

```sh
pi mcp add cloudflare --url https://mcp.cloudflare.com/mcp
pi mcp login cloudflare
```

Check existing configuration before adding/replacing it. Read the `agent-browser` skill before browser automation. Inspect Cloudflare's API schemas with its MCP `search` tool before mutations. OAuth permission to create buckets does not imply permission to create API tokens.

### Google Cloud

Check `gcloud auth list`; use `gcloud auth login` for browser approval. If installation is authorized, add `cask "gcloud-cli"` to `~/.config/homebrew/Brewfile` and run `fish -lc brew-sync`. This upgrades and cleans the whole Brewfile. Report unrelated package conflicts rather than removing apps without approval.

CLI authentication does not sign the user into a browser session. Never ask for a Google password or bypass Google's automated-browser checks.

## 3. Prepare the application

- Build a production Docker image using locked dependencies, a nonroot user, and an allowlisted context. Exclude `.env`, keys, databases, credentials, VCS history, and development artifacts.
- Derive environment names from the app. For Django, set `DEBUG=false`, `SECRET_KEY`, `ALLOWED_HOSTS`, `DATABASE_URL`, the canonical URL, and any required OAuth signing key.
- Generate fresh application/signing secrets. Persist them across deployments; never ship development keys or seed demo users in production.
- Support PostgreSQL through `DATABASE_URL`; keep local development independent of cloud services. Add/test the driver and migrations rather than passing SQLite options to PostgreSQL.
- For Django, serve collected static files in production. Run migrations before serving. For MCP, use the ASGI entry point with lifespan enabled, not WSGI or a development server.
- Start with one worker/replica if OAuth codes or rate limits use local-memory cache. Configure shared cache before scaling. Keep deployments/migrations serialized.
- Use bounded resources suited to host headroom, a startup grace period, and a health probe. Dokploy's resource API uses **bytes** for memory and **NanoCPUs** for CPU; verify the schema.
- Create the initial app admin with an explicit owner email and random password. Save the login in 1Password immediately. App admin, database login, and server root are different accounts.

Run repository checks, migration drift checks, and a container build. Keep the README product-focused; do not generate an operations manual unless requested.

## 4. Provision data and integrations

### PostgreSQL

Create a dedicated database and login role on the verified shared instance. Use the app's final name, properly quoted SQL identifiers, and a generated password. The role owns its database/schema but has no superuser, role-creation, or database-creation privileges. Scope any `REVOKE ... FROM PUBLIC` to the new database only.

Use the internal service name and port `5432` in `DATABASE_URL`. Save a separate TablePlus-ready URI in 1Password using the Tailscale address and published port. Test an authenticated connection, not just an open TCP socket. Do not open the public firewall when the public IP times out but Tailscale works.

### Private R2 storage

Create an app-specific bucket. Keep `r2.dev`, public custom domains, and browser CORS disabled unless public assets are explicitly required.

The deployed app needs bucket-scoped **Object Read & Write** S3 credentials even when MCP uses OAuth. If token creation is not permitted, have the user create the scoped R2 token and save its access key ID and secret in 1Password. Do not borrow another app's bucket credentials.

When deriving credentials from a Cloudflare API token, the access key ID is the token ID; the secret is SHA-256 of its exact token value. Verify against Cloudflare's [R2 authentication docs](https://developers.cloudflare.com/r2/api/tokens/). Validate copied/wrapped values without printing them. Test put/get/delete of a unique probe and confirm isolation from other buckets without reading their contents.

For Django, use `django-storages[s3]` with a separate storage alias, account-specific HTTPS endpoint, region `auto`, and all four settings:

```text
R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_BUCKET_NAME
```

Partial configuration must fail clearly. For artifact HTML:

- Store private immutable objects under unique keys; never overwrite versions.
- Keep pointers, hashes, sizes, permissions, and version metadata in PostgreSQL.
- Authorize before fetching content. Serve through the application/sandbox, not public or presigned raw-HTML URLs.
- Keep synchronous S3 calls off the ASGI event loop. Test upload failure, transaction rollback, conflicts, missing/corrupt objects, history, restore, and export.
- Never delete a possibly committed object after an ambiguous transaction failure. Audit orphan objects separately; do not install blanket lifecycle deletion.

### Google Sign-In

Create a dedicated project with `gcloud projects create <project-id> --name=<app>`. Do not enable billing or unrelated paid services merely to configure sign-in.

Standard web OAuth clients use **Google Auth Platform** in the Console. `gcloud iam oauth-clients` is for Workforce Identity Federation, not ordinary Google Sign-In; IAP clients are not a substitute. Follow [Google's client setup](https://support.google.com/cloud/answer/15549257).

Use a normal browser when Google rejects automation. Have the user configure app branding, audience, support/contact email, and a **Web application** client. Request only needed sign-in scopes, usually `openid email profile`. Add the exact HTTPS callback exposed by the app. For Django allauth:

```text
https://<hostname>/accounts/google/login/callback/
```

Ask for the downloaded client JSON's local path, not a pasted secret. Validate its project ID, `web` client type, and redirect URI. Save credentials in 1Password and configure the application's client ID/secret.

Matching emails do not safely imply linked accounts. Existing password users should sign in and connect Google through `/accounts/3rdparty/`. Preserve the app's email-verification and account-linking policies. A provider confirmation page is not an OAuth failure. Check test-user/publishing restrictions if other Google accounts cannot sign in.

### Email

Prefer a verified sender domain and app-scoped credentials. `mg.coolin.me` is an existing Mailgun sender to inspect. Reuse shared sending credentials only deliberately; record every consumer for rotation. Never modify another application's credentials while configuring this app.

For Django 6.1+, Anymail's Mailgun backend uses `MAILERS["default"]` with `api_key`, `sender_domain`, and a bounded timeout. Follow the installed Django/Anymail versions, not obsolete `EMAIL_BACKEND` examples. Use `MAILGUN_API_KEY`, `MAILGUN_SENDER_DOMAIN`, and a real `DEFAULT_FROM_EMAIL` where supported. Development stays on console email. Partial production configuration fails; delivery errors must not be swallowed.

## 5. Provision Dokploy and continuous deployment

Use [the API recipes](references/dokploy-api.md). Read the running instance's authenticated OpenAPI document before constructing requests; tRPC and REST envelopes differ. Reconcile resource state after timeouts before retrying creation.

Create an app project/environment and a Docker-provider application on **Side Projects**. Record its returned IDs and generated service name. Configure private GHCR pull credentials in Dokploy, runtime secrets, one replica, limits, health checks, and proxy settings. Keep secrets out of build arguments and images.

Mirror the reference pipeline with these safeguards:

1. Checks run on main pushes and PRs, with read-only repository permissions.
2. Only a successful **main push** check from the same repository triggers deployment. Never deploy PR/fork completion events.
3. Check out the exact checked `head_sha`; reject superseded main runs before publishing. Serialize production jobs without canceling a rollout mid-flight.
4. Build the target server's architecture and push a private GHCR image using `GITHUB_TOKEN` with `packages: write`.
5. Join Tailscale using `tag:ci`.
6. Verify the exact app ID, server ID, and Docker source before any mutation. Use this app's IDs, never copied Artiflect/Spider League IDs.
7. Update only the image to the build's immutable digest, preserving registry credentials and environment. Trigger deployment; fail on HTTP errors and tRPC error envelopes.

Repository variables: `DOKPLOY_URL`, `DOKPLOY_APP_ID`, `TS_OAUTH_CLIENT_ID`.
Repository secrets: `DOKPLOY_API_KEY`, `TS_OAUTH_SECRET`.

Configure these before the first deploying push. A green Action means Dokploy accepted the request, not that the app became healthy. Inspect deployment status, actual service image, replica count, and public behavior afterward. Do not treat a source-upload bootstrap as completed CI/CD.

## 6. DNS, TLS, and proxy trust

Create only the chosen hostname's DNS record, targeting the verified deployment server, not the Dokploy manager. DNS-only is a useful default for direct MCP traffic; if proxying through Cloudflare, verify TLS mode, caching, challenges, and forwarded client IP behavior. Do not change zone-wide settings for one app.

Add the hostname in Dokploy with the container's internal port and Let's Encrypt HTTPS. Set the app's canonical public URL, allowed hosts, secure cookies, and HTTPS detection. Do not publish the application port directly.

For Uvicorn behind Swarm, use `endpointSpecSwarm.Mode=dnsrr` to preserve the proxy peer address. Default VIP routing can hide it behind source NAT. Discover Traefik's actual connecting address and set `FORWARDED_ALLOW_IPS` narrowly. On the reference network it is `10.0.1.13`, but inspect it rather than trusting that value forever. Do not use `*` or bypass peer validation with unconditional forwarded-header trust.

Verify HTTP → HTTPS, certificate validity, assets, POST/CSRF, and spoofed forwarded headers. If a temporary hostname exists, redirect only that hostname to the canonical URL, preserving path/query. OAuth clients may need reauthorization after an issuer change.

If public DNS resolves but the Mac reports `ENOTFOUND`, compare authoritative/public/Tailscale DNS with the OS lookup. Request administrator approval before flushing caches:

```sh
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Do not disable Tailscale DNS or rewrite resolver settings as a shortcut.

## 7. Backups and live acceptance

Create a dedicated Dokploy destination for the app. A private app bucket with a separate `backups/<app>/` prefix is acceptable for off-host database backups; it is not independent credential isolation or replication of the artifact objects. Use a separate bucket/token when stronger isolation is required. Never reuse Page Goblin's destination.

Schedule only the app database. A reasonable default is **03:00 UTC, 14 latest copies**; verify the scheduler's timezone. Inspect retention scope before enabling deletion. Dokploy prepends the managed database service name to the configured prefix. Retention must never reach artifact objects or another database's backups.

Run a backup immediately. Download/decompress it privately, restore into a uniquely named temporary database, verify schema/data and any referenced R2 hashes/sizes, then remove the temporary database/files. Never test restore over production. Preserve signing keys in 1Password separately; database backups do not contain environment secrets. Keep immutable R2 objects referenced by retained snapshots.

Acceptance requires evidence, not configuration alone:

- Exact image healthy on the correct server; HTTPS pages, assets, login, secure cookies, and database connectivity work.
- Private upload/read/update/history/export work; unauthorized requests cannot fetch content. For R2, verify objects and database pointers, not just bucket existence.
- Google authorization uses the intended client/callback. Distinguish this from a completed user sign-in/linking test.
- Send one clearly labeled email to the operator; confirm the provider's **delivered** event, not merely queued acceptance.
- Backup uploaded and restored; scheduled retention targets only its prefix.

### MCP acceptance

Inspect both global and project `.pi/mcp.json`: project settings can override the deployed URL with localhost. Point the intended entry at `https://<hostname>/mcp` and run `pi mcp list`.

For clients requiring dynamic registration, explicitly enable the app's rate-limited DCR support, or pre-register a public PKCE client and configure its client ID. An MCP endpoint alone does not advertise registration. Check protected-resource metadata and the authorization server's OAuth/OIDC metadata, including `registration_endpoint` and exact issuer/resource identities.

Test registration → browser login/consent → PKCE exchange → refresh → initialization/tool listing → authorized read/write → conflict and unauthorized denial. Remove only the probe's clients, tokens, records, and objects. Do not expose access tokens in logs.

Then run `pi mcp login <app>` in the actual project directory. Keep the callback listener alive while the user approves in their normal browser. Confirm connected state and expected tools; ask for `/reload` to expose changed tools in the active session.

## Finish

Save app admin, database URI, R2, Google, email, and signing credentials in clearly named 1Password items. Delete temporary secret copies, not the user's only copy. Leave no probe data or restore databases. Preserve unrelated Git changes.

Report the live URL, repository/commit, verified checks, backup schedule, credential item names, and any remaining manual steps. Do not claim Google linking, email delivery, scheduled execution, or independent object backups were tested when only setup succeeded.
