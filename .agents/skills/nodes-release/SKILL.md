---
name: nodes-release
description: Release Griptape Nodes from local checkouts, from the engine (griptape-nodes-engine) and the editor (griptape-vsl-gui) through the app (griptape-nodes-app) to the desktop app (griptape-nodes-desktop). Use when asked to cut, publish, or ship a Griptape Nodes engine, editor, app, or desktop release, or a patch release of one.
---

# Griptape Nodes releases

A release goes through four repos. Each later layer installs the earlier ones
by an exact version pin:

| Stage | Repo | Local checkout | Publishes | Pinned by |
| --- | --- | --- | --- | --- |
| 1 | `griptape-nodes-engine` | `~/Projects/griptape/griptape-nodes` | `griptape-nodes-engine` on PyPI, Docker images | the app's `pyproject.toml` |
| 1 | `griptape-vsl-gui` (editor) | `~/Projects/griptape/griptape-vsl-gui` | the hosted editor and parent app, `griptape-nodes-editor-dist` on PyPI, `@griptape-ai/nodes-editor-dist` and `@griptape-ai/nodes-manage-ui` on GitHub Packages | the app's `editor` extra, the desktop's `package.json` |
| 2 | `griptape-nodes-app` (private) | `~/Projects/griptape/griptape-nodes-app` | `griptape-nodes` wheels on PyPI | the desktop's `src/common/config/versions.ts` |
| 3 | `griptape-nodes-desktop` | `~/Projects/griptape/griptape-nodes-desktop` | installers and the Velopack auto-update feed in S3 | nothing |

The engine and the editor don't depend on each other, so either can go first.
Don't start a later stage until what it pins is published. A pin to a version
PyPI doesn't have yet fails `uv lock`, and a desktop build against a missing
package fails to bundle.

Release only the stages the user asks for. An editor-only release, for example,
needs nothing from the other repos.

The engine, editor, and app release scripts refuse to run with no changelog
entries. Pass their allow-empty flag only if the user says to.

## Confirm before every release step

A release is public and can't be taken back. Before each command that tags,
publishes, or dispatches a release workflow, show the repo, the version, the
branch and HEAD SHA it runs from, and the exact command. Then ask with
`ask_user_question` and run it only on an explicit yes. One yes covers one
command. Pushing a branch needs no yes.

## Start each repo clean

Each stage works in the local checkout. Before touching one, fetch and switch
to the branch you'll release from, `main` or the release branch for a patch:

```bash
cd ~/Projects/griptape/<checkout>
git status --short
git fetch --tags origin
git switch <branch> && git pull --ff-only
```

If the tree is dirty, or the branch doesn't fast-forward, stop and ask. The
release scripts commit and tag what's checked out, so stray local work would
ship.

## Pull requests

PRs follow the usual rules: conventional-commit title, `gh pr create --draft`,
empty body. Each PR needs an approval before it merges.

## Wait on CI, then check what it published

Each stage ends in CI that takes minutes. Find the run with
`gh run list -R griptape-ai/<repo> --limit 5`, then watch it with
`gh run watch <id> -R griptape-ai/<repo> --exit-status`. Before starting the
next stage, check that the exact version is published:

```bash
curl -s https://pypi.org/pypi/<package>/<version>/json | jq -r .info.version
```

Don't check `/pypi/<package>/json`. Its `.info.version` is the highest version
on PyPI, which for a patch on an older line isn't the one you released.

The desktop installs the editor from GitHub Packages, which the editor
publishes after PyPI. Check both packages from the desktop checkout, whose
`.npmrc` authenticates:

```bash
cd ~/Projects/griptape/griptape-nodes-desktop
npm view @griptape-ai/nodes-editor-dist@<version> version
npm view @griptape-ai/nodes-manage-ui@<version> version
```

If `uv lock` rejects a just-published pin, its index cache is stale. Run
`uv lock --refresh`.

## Stage 1: engine

```bash
cd ~/Projects/griptape/griptape-nodes
make version/get
git tag -l 'v*' --sort=-version:refname | head -1
make changelog
```

1. Check that `make version/get` is ahead of the latest tag. If it isn't, the
   `chore: bump` PR from the last release hasn't merged. Say so and stop.
1. Show the `make changelog` output. Those are the release notes. To fix
   wording, edit `changelog.d/` through a PR to `main`, then pull.
   `make version/publish` refuses uncommitted changes there, and it deletes
   those files.
1. After the yes, run `make version/publish`. It rolls the changelog on a
   detached commit, pushes the `vX.Y.Z` and `stable` tags and the
   `release/vX.Y` branch, then returns to the branch you started on. The roll
   commit is only on the remote `release/vX.Y`, so pull before reusing that
   branch locally.
1. CI creates the GitHub release (`stable-release.yml`), publishes to PyPI and
   Docker (`publish.yml`), and for an `X.Y.0` tag opens an auto-merging
   `chore: bump` PR on `main`. That PR needs an approval, and other PRs can't
   merge into `main` until it lands. Remind the user.

## Stage 1: editor

The editor's versions are whole numbers (`v127`), and patches add one part
(`v127.1`). Packages publish them as `0.127.0` and `0.127.1`.

1. On a branch off `main`, run `npm run bump-version`. It runs `npm install`,
   folds `changelog.d/` into a `CHANGELOG.md` section, and commits
   `chore: bump to version v<N>`. Pass `-- --allow-empty` to release with no
   entries. Show the section it wrote as the release notes, then push the
   branch and open the PR with that commit's message as the title.
1. Once it's merged, `git switch main && git pull --ff-only`, and check that
   the top commit is the merged bump. The release script runs only on `main`
   or, for a patch, `release/v<N>`.
1. After the yes, run `npm run release`. It pushes the `v<N>` and `parent-v<N>`
   tags, then force-moves `stable`. It refuses if a PR merged after the bump
   added changelog entries. Report that and stop.
1. CI creates the releases (`prod-release.yml`), and each one triggers
   `deploy.yml`. **These go to prod right away.** `v<N>` deploys the editor,
   `parent-v<N>` deploys the parent app, and `stable` redeploys the editor's
   `stable` prefix. `v<N>` also publishes to PyPI, then to npm on GitHub
   Packages. If npm fails after PyPI succeeded, re-running the deploy job is
   safe, because it skips a version PyPI already has.

## Stage 2: app

1. On a branch off `main`, pin what stage 1 released. In `pyproject.toml`, set
   `"griptape-nodes-engine==<version>"`, or the `editor` extra's
   `"griptape-nodes-editor-dist==0.<N>.<P>"`, or both. `<P>` is 0 for `v<N>`
   and 1 for `v<N>.1`. Run `uv lock` and add a `CHANGELOG.md` entry under
   `[Unreleased]`. Title the PR `deps(engine): pin engine to <version>`, or
   use a `deps(editor):` or `deps:` title to match.
1. Once it's merged, pull `main` and check that the `pyproject.toml` version is
   ahead of the latest tag. If it isn't, the `chore: bump` PR from the last
   `X.Y.0` release hasn't merged. Say so and stop.
1. Show the `[Unreleased]` section of `CHANGELOG.md` as the release notes.
1. After the yes, run `mise run version:publish`. It rolls the changelog, tags
   `vX.Y.Z` and `stable`, and pushes the `release/vX.Y` branch. Pass
   `--allow-empty` to release with no entries.
1. CI builds wheels for five platforms, smoke-tests them, and publishes to
   PyPI. For an `X.Y.0` tag it opens a `chore: bump` PR on `main`, as the
   engine does. If publishing fails after the tag exists, re-run it with
   `gh workflow run publish.yml -R griptape-ai/griptape-nodes-app -f tag=v<version>`
   after another yes. Don't retag.

## Stage 3: desktop

The desktop's version isn't automated. Use the next minor after the latest
`v*` tag, or the next patch for a patch release, and confirm it with the user.

1. On a branch off `main`, make the bump PR, titled like
   `chore: bump v<desktop>, app to <app>, editor to <editor>`:
   - add `[Unreleased]` entries to `CHANGELOG.md` if it has none. They show in
     the app's release notes window, so write them for end users: the bundled
     app version, then the changes they'll notice from every stage;
   - run `npm version --no-git-tag-version <desktop>`, which also rolls
     `[Unreleased]` into the version. It refuses an empty section, but only
     after it has already bumped `package.json`;
   - set `GRIPTAPE_NODES_APP_VERSION` in `src/common/config/versions.ts`;
   - if the editor was released, set `@griptape-ai/nodes-editor-dist` and
     `@griptape-ai/nodes-manage-ui` to `^0.<N>.<P>` in `package.json`, then
     run `npm install`.
1. Once it's merged, and after the yes, start the build:
   `gh workflow run release.yml -R griptape-ai/griptape-nodes-desktop --ref main`.
   On `main` the channel defaults to `stable`, which uploads to the
   auto-update feed, so existing users get the update.
1. Watch the run. A platform whose `v<version>-<os>-<arch>` tag already exists
   is skipped, so re-running after a failure rebuilds only the failed
   platforms.

## Patch releases

Patches ship from release branches. Every change on a release branch except
the version bump comes from `main`: merge it there through the usual PR, then
cherry-pick it with `git cherry-pick -x`. That covers fixes, the app's
dependency pins, and the desktop's pins and changelog entries. Only the commit
that bumps the version is made on the release branch.

### Before starting

- **Release branches:** the engine and app push `release/vX.Y` when they
  publish `X.Y.0`. Create the editor's and desktop's by hand if they don't
  exist yet: `git switch -c release/v<N> v<N>` for the editor and
  `git switch -c release/vX.Y vX.Y.0` for the desktop.
- **Version check:** "ahead of the latest tag" doesn't apply, because the
  latest tag can be on a newer line. Check instead that `git tag -l v<version>`
  prints nothing.
- **`stable`:** every release script force-moves `stable`. A patch to any line
  but the newest moves it backward, and for the editor that redeploys the
  `stable` prefix. Warn the user before the confirm step.
- **Candidate fixes:** run `git cherry -v release/<x> origin/main` in each repo.
  Lines starting with `+` aren't on the release branch yet, and that list
  includes everything `main` gained since the branch forked. Commits with a
  `fixed-*` entry in `changelog.d/` are the usual picks. Ask about the rest
  (perf, dev-only build fixes, features) before cherry-picking.
- **Pins on `main`:** if `main` already pins a newer version than the patch,
  a pin PR there would downgrade it. Tell the user before opening it.
- **Conflicts:** on a cherry-pick conflict in `uv.lock` or `package-lock.json`,
  keep the release branch's file, then rerun `uv lock` or `npm install`. Stop
  and ask on any other conflict.

### Per repo

- **Engine:** on `release/vX.Y`, cherry-pick the fixes and run
  `make version/patch`. Push the branch, confirm, then run
  `make version/publish`.
- **Editor:** on `release/v<N>`, cherry-pick the fixes and run
  `npm run bump-patch`. Push the branch, confirm, then run `npm run release`.
- **App:** if stage 1 patched the engine or the editor, open the pin PR on
  `main` as in stage 2. Once it and any app fixes are merged, cherry-pick them
  onto `release/vX.Y`. The app's `CHANGELOG.md` is edited by hand, and a
  cherry-pick can auto-merge an entry into an older release's section without
  a conflict. After each one, check that the entry sits under `[Unreleased]`.
  If the original on `main` is misplaced too, fix it there. Then run
  `uv version --frozen --bump patch` (which skips building the Rust extension)
  and `uv lock`, and commit `chore: bump vX.Y.Z`. Push the branch, confirm,
  then run `mise run version:publish`.
- **Desktop:** open a PR on `main` titled like
  `chore: bump app to <app>, editor to <editor>` that sets the pins and adds
  the `[Unreleased]` entries as in stage 3. Once it's merged, cherry-pick it
  onto `release/vX.Y`. As in the app, check that its entries sit under
  `[Unreleased]` and not in the last release's section. Then run
  `npm version --no-git-tag-version <desktop>`, and
  commit `chore: bump v<desktop>`. Push the branch, confirm, then run
  `gh workflow run release.yml -R griptape-ai/griptape-nodes-desktop --ref release/vX.Y -f channel=stable`.
  Without `-f channel=stable` it builds a branch-named test channel and skips
  S3.

### Record the patch on `main`

Once a patch is published, open a PR on `main` titled like
`docs(changelog): record vX.Y.Z` that writes it into `main`'s changelog. This
is a separate commit on trunk. Don't merge the release branch into `main`.

- Copy the `## [X.Y.Z]` section from the release branch's `CHANGELOG.md` and
  put it above the newest version section on `main`.
- Copy its link definition too, and point `[Unreleased]:` at the patch tag.
  The engine's and app's checks require `[Unreleased]` to compare the latest
  tag to `HEAD`.
- Remove what shipped from `main`. In the engine and editor, `git rm` the
  `changelog.d/` files the release commit deleted. In the app and desktop,
  delete the matching entries from `[Unreleased]`.
- Run the repo's changelog check: `make check/changelog`,
  `npm run changelog:check`, or `mise run check:changelog`.

Without this, `main`'s changelog skips the patch, and the next minor's notes
repeat fixes users already have.
