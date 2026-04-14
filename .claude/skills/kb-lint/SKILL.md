---
name: kb-lint
description: Run health checks on the knowledge base wiki and fix issues.
allowed-tools: Read Write Edit Glob Grep Bash(uv run mdformat *) Bash(git *)
---

# Lint the Knowledge Base

Run health checks on the wiki and fix issues found.

## Context

- Knowledge base root: `~/knowledge-base`

## Your task

1. **Read the index**: Read `~/knowledge-base/index.md` to understand the current wiki state.

2. **Scan all wiki articles**: Glob `~/knowledge-base/wiki/**/*.md` and read each article.

3. **Check for issues**:
   - **Broken links**: Find `[[wiki links]]` that don't point to any existing article.
   - **Missing backlinks**: If article A links to article B, article B should mention article A in its Related section.
   - **Missing frontmatter**: Articles should have title, tags, created, updated, and sources fields.
   - **Stale sources**: Check that files referenced in `sources` frontmatter still exist in `raw/`.
   - **Orphaned articles**: Articles with no incoming links from other articles.
   - **Inconsistent tags**: Look for near-duplicate tags (e.g., "ml" vs "machine-learning").
   - **Missing connections**: Suggest links between articles that cover related topics but don't reference each other.

4. **Check TODOs**: Read `~/knowledge-base/wiki/personal/todos.md` and `~/knowledge-base/wiki/work/todos.md` if they exist. Check for:
   - **Stale TODOs**: Unchecked items older than 30 days.
   - **Broken references**: TODOs with `[[wiki links]]` pointing to deleted articles.
   - **Completed items**: Move checked items (`- [x]`) to a `## Done` section at the bottom of the file.

5. **Fix issues**: For each issue found, fix it directly. Create missing backlinks, fix broken links, add missing frontmatter fields, normalize tags.

6. **Suggest article candidates**: Based on patterns and connections, suggest concepts that could be their own articles but aren't yet.

7. **Regenerate the index**: Rewrite `~/knowledge-base/index.md` with the current state.

8. **Format**: Run `uv run mdformat` on any changed files.

9. **Commit**: Stage all changed files in `~/knowledge-base/` and create a commit using conventional commit format (e.g., `docs: lint wiki`). If no files were changed, skip this step.

10. **Report**: Summarize all issues found, fixes applied, stale TODOs flagged, and suggestions for further improvement.
