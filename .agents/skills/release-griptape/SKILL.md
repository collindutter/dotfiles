---
name: release-griptape
description: Release griptape-nodes-app or griptape-nodes-desktop by syncing upstream pins, bumping the version, and cutting a tag. Use when the user says "release the app", "release desktop", "cut a griptape-nodes-app release", "sync the engine into desktop", or any variation that implies publishing a new app or desktop version.
allowed-tools: Bash(git *) Bash(gh *) Bash(uv *) Bash(npm *) Bash(curl *) Bash(jq *) Bash(mise run *) Bash(rg *) Read Edit
---

# Release griptape-nodes app or desktop

You drive the release chore for two repos in the griptape-nodes release chain. Order: engine ships first (out of scope, released by hand from `griptape-nodes`), then app (which pins the engine), then desktop (which pins the app and the editor). The editor (`griptape-vsl-gui`) is also released by hand and is an independent upstream of desktop.

- **app**: `~/Projects/griptape/griptape-nodes-app`
  - Engine pin: `griptape-nodes-engine` in `pyproject.toml` (range like `>=X.Y.0,<X.(Y+1)`).
  - Own version: `version =` in `pyproject.toml`. Published to PyPI as `griptape-nodes`. Note the naming: the **app** is `griptape-nodes` on PyPI, the **engine** is `griptape-nodes-engine` on PyPI.
  - Release: `mise run version:publish` (tags `vX.Y.Z`, force-moves `stable`, pushes tags and a `release/vX.Y` branch).

- **desktop**: `~/Projects/griptape/griptape-nodes-desktop`
  - App pin: `GRIPTAPE_NODES_APP_VERSION = 'X.Y.Z'` in `src/common/config/versions.ts` (exact). `scripts/sync-engine-bundle.ts` reads this and runs `uv pip install griptape-nodes==<VERSION>` into the bundled Python interpreter. The engine arrives transitively via the app's own pin; desktop never pins the engine directly.
  - Editor pin: `@griptape-ai/nodes-editor-dist` in `package.json` (caret range; `package-lock.json` is the source of truth).
  - Own version: `"version"` in `package.json`.
  - Release: bump version, push to main, tag `vX.Y.Z`, push the tag, then **manually trigger** `release.yml` via `gh workflow run`. The workflow creates the GH release at the end. Tag-push alone does not start a build.

## Procedure

1. **Identify the target repo.** "the app" → griptape-nodes-app, "desktop" → griptape-nodes-desktop. If ambiguous, ask.

2. **Read current state of the target repo:**
   - **app:** engine pin via `rg "griptape-nodes-engine" pyproject.toml`; own version via `uv version`.
   - **desktop:** `GRIPTAPE_NODES_APP_VERSION` in `src/common/config/versions.ts`; `@griptape-ai/nodes-editor-dist` in `package.json` and `package-lock.json`; `"version"` in `package.json`.
   - Always also: `git status`, `git branch --show-current`, latest `vX.Y.Z` tag.

3. **Look up the latest live upstream versions** ("live" = present on the registry that `uv` / `npm install` will hit, not just tagged in the source repo). Which upstreams matter depends on the target:
   - **Releasing app** → engine on PyPI:
     `curl -s https://pypi.org/pypi/griptape-nodes-engine/json | jq -r '.info.version'`
   - **Releasing desktop** → app on PyPI **and** editor on GH Packages:
     - App (PyPI, package name is `griptape-nodes`):
       `curl -s https://pypi.org/pypi/griptape-nodes/json | jq -r '.info.version'`
     - Editor (GitHub Packages npm registry, scope `@griptape-ai`):
       `gh api '/orgs/griptape-ai/packages/npm/nodes-editor-dist/versions?per_page=20' --jq '[.[].name | select(test("nightly") | not)] | .[0]'`
       The `select(test("nightly") | not)` filter is required — nightly builds publish as `0.0.0-nightly.<date>` and would otherwise sort to the top.
       Do **not** use `gh release view` for the editor; the editor repo tags releases as `parent-vMAJ.MIN` (e.g. `parent-v112.1`), which is not a valid npm version string. Always go through the registry.

4. **Stop and ask the user.** Always:
   - **app:** "Engine X.Y.Z is latest on PyPI; you pin `>=A.B.0,<A.(B+1)` (resolved A.B.C). Bump engine? What app version should I tag?"
   - **desktop:** "App: X.Y.Z latest on PyPI (currently pinned A.B.C). Editor: M.N.O latest on GH Packages (currently P.Q.R). Bump which? What desktop version should I tag?"
   - Never compute the target repo's own version yourself. App version and engine version are independent (current main is app 0.85.3 / engine 0.85.2). Desktop's own version is independent of the app and editor versions it pins.

5. **If the user named a specific upstream version, verify it is live before bumping.** Engine and editor both have CI pipelines that take many minutes to publish to their respective registries; the source repo can be tagged well before the artifact is installable.
   - **Engine** (when releasing app): `curl -s https://pypi.org/pypi/griptape-nodes-engine/<VERSION>/json` (HTTP 200 = live, 404 = not yet).
   - **App** (when releasing desktop): `curl -s https://pypi.org/pypi/griptape-nodes/<VERSION>/json` (HTTP 200 = live, 404 = not yet). PyPI's index can lag the publish workflow's success by a minute or two even after CI reports green.
   - **Editor** (when releasing desktop): the registry-version query in step 3 must return `<VERSION>` (or higher).
   - If the requested version is not yet live, **poll**: every 30s for up to 30 minutes. Tell the user you're waiting and which artifact you're waiting on. After the timeout, stop and ask.
   - If the user said "use the latest", whatever step 3 returned is by definition live; skip this step.

6. **Refuse to proceed** if any of:
   - Working tree is dirty.
   - Current branch is not `main`, with one exception: a **desktop** stable patch may be cut from a `release/vX.Y` maintenance branch (used to ship a cherry-picked fix without dragging along everything on `main`). Any other non-`main` branch still requires the user to explicitly say otherwise.
   - The tag the user supplied already exists locally or on origin.
   - The target repo's own version would go backwards.
   - A user-supplied upstream version still isn't live after the poll timeout.

7. **Show the plan** before any mutating command: repo, files to edit, version transitions, commit message, tag(s), and the exact `git push` / `gh workflow run` commands. Wait for explicit confirmation. Silence is not consent.

8. **Apply the bumps:**
   - **app** (engine sync):
     ```
     uv add "griptape-nodes-engine>=<NEW_MAJMIN>.0,<<NEXT_MAJMIN>"
     uv version <APP_VERSION>
     uv lock
     git add pyproject.toml uv.lock
     git commit -m "chore: bump v<APP_VERSION>"
     ```
     For an app-only patch with no engine bump, skip `uv add` and just `uv version` + `uv lock`.
   - **desktop:**
     - If app bumped: edit `src/common/config/versions.ts`, set `GRIPTAPE_NODES_APP_VERSION = '<NEW_APP>'`.
     - If editor bumped: `npm install --save @griptape-ai/nodes-editor-dist@<NEW_EDITOR>`. This rewrites the caret floor in `package.json` and updates `package-lock.json`. Intentional — the lockfile is what ships.
     - Always: `npm version <DESKTOP_VERSION> --no-git-tag-version` (the flag matters; don't let npm tag/commit).
     - `git add -A` then `git commit -m "chore: bump v<DESKTOP_VERSION>"`. Mention which upstreams moved in the body.

9. **Tag and push (and trigger the build for desktop).** Confirm again before pushing.
   - **app:** `mise run version:publish`. This handles the `vX.Y.Z` tag, the `stable` force-move, and the `release/vX.Y` branch push. CI takes over from there.
   - **desktop (from `main`, normal release):**
     ```
     git push origin main
     git tag v<DESKTOP_VERSION>
     git push origin v<DESKTOP_VERSION>
     gh workflow run release.yml --ref main --repo griptape-ai/griptape-nodes-desktop
     ```
     Push the tag by name. Never `git push --tags`. The tag-push alone does not start a build; `release.yml` only runs on `workflow_dispatch` and the nightly cron. The workflow defaults the channel to `stable` when run from `main`, which is what you want for a real release.
   - **desktop (stable patch from a `release/vX.Y` branch):** same as above but push the branch and tag, then pass `channel=stable` explicitly (release branches default to a branch-named test build, so you must opt in):
     ```
     git push origin release/vX.Y
     git tag v<DESKTOP_VERSION>
     git push origin v<DESKTOP_VERSION>
     gh workflow run release.yml --ref release/vX.Y -f channel=stable --repo griptape-ai/griptape-nodes-desktop
     ```
     Velopack serves the highest version in the `stable` channel, so only patch the currently-latest stable line; do not ship a lower version after a higher one is already live on stable.

10. **Verify** (the build is long-running for desktop; tens of minutes is normal):
    - **app:** `gh run watch` on the latest `publish.yml` run. Then poll PyPI until visible: `curl -s https://pypi.org/pypi/griptape-nodes/json | jq -r '.info.version'`. The index can lag the publish call by a minute or two.
    - **desktop:** find the run you just dispatched (`gh run list --workflow=release.yml --limit=1 --repo griptape-ai/griptape-nodes-desktop`) and `gh run watch <run-id> --repo griptape-ai/griptape-nodes-desktop`. The unified GH release is created by the final `create-github-release` job, not by tag push, so confirm with `gh release view v<DESKTOP_VERSION> --repo griptape-ai/griptape-nodes-desktop` after the run finishes.

11. **Report back** with the GH release URL, PyPI link (app only), and (when releasing app) a note on whether desktop is now out of date with the app you just shipped.

## Safety rules that override anything above

- Never `git push --tags` or `git push -f --tags`. Push specific tags by name.
- The only tag that may be force-moved is `stable`, only via `mise run version:publish` for the app.
- Never push to `main` without showing the plan and getting explicit confirmation.
- If anything looks off (unrelated commits on main, a tag already exists, a dirty tree, an upstream version that went backwards, an app pin that doesn't resolve on PyPI), stop and ask. Don't improvise.
- If the user says "go" but the plan touches more than one repo, confirm again per repo. Never chain a desktop release off an app release.

## Ambiguous intent

- "release griptape-nodes" with no qualifier → ask which repo (the engine repo is also `griptape-nodes`).
- "release everything" → run the procedure for app, then for desktop, confirming each independently.
- "what's out of date?" → report current pins vs latest upstreams for both repos (app: engine; desktop: app + editor). No mutations.
- "is desktop ready to release?" → list app + editor staleness; don't propose a plan unless asked.

## Conventions you must not override

- App's engine pin is a range (`>=X.Y.0,<X.(Y+1)`). Desktop's app pin is exact (the constant `GRIPTAPE_NODES_APP_VERSION` in `versions.ts`).
- Desktop pins the app, not the engine. The engine arrives transitively through the app's own pin. Don't try to bump the engine directly from the desktop repo.
- Desktop's editor pin in `package.json` is a caret range; in `package-lock.json` it's exact. Always bump both via `npm install --save`.
- App version and engine version are independent. Desktop's own version is independent of the app and editor versions it pins.
- The editor repo's release tags are `parent-vMAJ.MIN` (e.g. `parent-v112.1`), which is **not** the npm version. Always look up the editor's installable version through the GH Packages registry, not GH releases.
- Desktop's `release.yml` only runs on `workflow_dispatch` (manual) or the nightly cron. Pushing a `vX.Y.Z` tag does not trigger a build.
- The desktop repo still has files and folders named "engine bundle" (`scripts/sync-engine-bundle.ts`, `resources/engine-bundle/`) for historical reasons. The bundle actually installs the *app* package (`griptape-nodes`), which transitively installs the engine. Don't be misled by the naming.
