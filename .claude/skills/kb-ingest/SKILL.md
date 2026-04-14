---
name: kb-ingest
description: Process raw source documents in the knowledge base into wiki articles.
argument-hint: [personal|work]
allowed-tools: Read Write Edit Glob Grep Bash(uv run mdformat *) Bash(date *) Bash(git *)
---

# Ingest Raw Sources into Wiki

Process unprocessed source documents from `raw/` into wiki articles in `wiki/`.

## Context

- Knowledge base root: `~/knowledge-base`
- Processed manifest: `~/knowledge-base/raw/.processed.json`

## Your task

1. **Read the index**: Read `~/knowledge-base/index.md` to understand the current wiki state.

2. **Find unprocessed sources**: Glob `~/knowledge-base/raw/` for all files. Read `~/knowledge-base/raw/.processed.json` (create it as `{}` if missing). Any file not listed in the manifest is unprocessed.

3. **Determine target directory**: If `$ARGUMENTS` is "personal" or "work", use that. Otherwise, infer from the source path (files in `raw/personal/` go to `wiki/personal/`, files in `raw/work/` go to `wiki/work/`).

4. **Process each source**:
   - Read the source document
   - Extract key concepts. Each distinct concept becomes its own wiki article.
   - For each concept, either create a new article in `wiki/<target>/` or update an existing one if the concept is already covered.
   - Use the article format defined in `~/knowledge-base/CLAUDE.md`: YAML frontmatter with title, tags, created, updated, sources, then summary, content, and related sections.
   - Add `[[wiki links]]` to related existing articles.
   - Update the `sources` frontmatter field to reference the raw file.

5. **Extract TODOs**: If any source contains action items (things that read like tasks, follow-ups, or things to investigate), append them to `~/knowledge-base/wiki/personal/todos.md` or `~/knowledge-base/wiki/work/todos.md` matching the source's directory. Use markdown checkboxes with a date and a `[[wiki link]]` back to the related article. Create the todos file if it doesn't exist.

6. **Update the manifest**: Add each processed file to `~/knowledge-base/raw/.processed.json` with its path as key and the current date as value.

7. **Regenerate the index**: Scan all files in `wiki/` and rewrite `~/knowledge-base/index.md` with all pages grouped by directory, each with a one-line description.

8. **Format**: Run `uv run mdformat` on any new or changed markdown files.

9. **Commit**: Stage all changed files in `~/knowledge-base/` and create a commit using conventional commit format (e.g., `docs: ingest <summary of sources>`).

10. **Report**: Summarize what was ingested, how many articles were created or updated, TODOs extracted, and any connections found.
