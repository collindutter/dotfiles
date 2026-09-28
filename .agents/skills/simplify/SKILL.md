---
name: simplify
description: Simplify recent code changes without changing behavior. Use when the user says "simplify", asks to clean up working code, or wants a clarity pass on a diff.
---

Simplify the current changes: $@

1. Scope: the requested files or diff, else uncommitted changes, else the last
   commit. Leave unrelated code alone.
2. Read the project instructions, changed code, nearby code, and relevant tests
   before editing.
3. Remove needless nesting, duplication, wrappers, state, defensive checks, and
   comments that restate the code. Fix unclear names and control flow.
4. Prefer clear, explicit code over fewer lines or clever abstractions. Follow
   existing repo patterns.
5. Preserve inputs, outputs, errors, side effects, ordering, and public
   contracts. If you can't tell whether a change preserves them, skip it.
6. Keep only changes that are clearly simpler.
7. Run the smallest relevant tests, lint, type checks, or build. Report changes
   and results briefly.

No cleanup needed is a valid result.
