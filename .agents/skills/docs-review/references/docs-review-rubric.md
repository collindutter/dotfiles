# Documentation review rubric

A standing definition of what a good documentation review looks like. It is
independent of any agent harness, delegation mechanism, or tool: apply it as a
reviewing agent, hand it to a delegated reviewer, or work through it by hand.

You review documentation: READMEs, guides, references, tutorials, changelogs,
doc comments, and similar prose. You review only the docs you were pointed at
(a diff or a set of files), not the whole repository. Report only problems in
that scope.

The review is read-only. Do not modify files, stage changes, run builds, or
execute any command a doc tells the reader to run; those may mutate state, hit
networks, or cost money. Verify claims by reading the source, not by running
it.

Your job has two axes, in priority order: is it TRUE, and does it read like a
human wrote it. A beautifully written doc that lies is worse than a plain one
that is correct.

## Strategy

1. Read the docs in scope end to end first, so you understand what they claim.
2. For every concrete claim, find the ground truth in the repository and
   confirm it. Do not trust the prose; open the code.
3. Evaluate voice and structure against the anti-slop rules below.
4. Report findings grounded in specific `file:line` locations.

## Axis 1: Grounded in reality (highest priority)

Treat every factual assertion as a claim to verify against the actual code,
config, and project layout. Flag anything you cannot confirm.

- Commands, flags, and subcommands: does the CLI/script actually accept them?
  Check the arg parser, `package.json` scripts, `Makefile`, `pyproject.toml`,
  etc. A flag that does not exist is a bug, not a nitpick.
- File paths, module names, and imports: do the referenced files, packages,
  and symbols exist at the stated paths?
- API surface: do the documented function/method names, signatures, arguments,
  return types, and defaults match the source?
- Config keys, env vars, and settings: do they exist and mean what the doc says?
- Code samples: would they run against the current code? Check imports, names,
  argument order, and obvious type mismatches.
- Version and compatibility claims: are stated versions consistent with the
  lockfiles/manifests in the repo?
- Outputs and behavior: does described behavior match what the code does? Flag
  invented output, screenshots-in-words, or aspirational behavior.
- Links and cross-references: do internal links point at files/anchors that
  exist? Flag obvious dead or renamed targets.
- Unverifiable claims: if a statement cannot be checked against anything in the
  repo, say so explicitly and mark it as needing a human or a source.

For each grounding finding, say what the doc claims, what the source actually
shows (`file:line`), and the correction.

## Axis 2: Human voice, not LLM slop

Docs should read like a competent engineer wrote them for a specific reader.
Flag the tells below. For each, quote the offending text and give a concrete
rewrite, not just a label.

Banned constructions (flag on sight):
- Em-dash parenthetical asides. Use a period, semicolon, or comma.
- "It's not X, it's Y." Use the affirmative: "Y, not X" or just "Y."
- "Delve," "dive in," "let's dive in." Use "read," "look at," "open," or just start.
- "Navigate the landscape of," "unlock the power of," "harness." State what it does.
- "In today's fast-paced world," "in an era where." Delete.
- "Boasts" for "has." "Leverage" (verb) for "use."
- Empty adjectives: "robust," "comprehensive," "seamless," "powerful,"
  "cutting-edge." If you cannot say what makes it robust, cut the word.
- Three-item filler lists ("fast, reliable, and scalable") where one true item
  would do. Glued adjective pairs ("simple and effective," "robust and scalable").

Banned narrator intrusions (the writer commenting on the doc instead of writing it):
- Editorial ranking of the content: "X is the big one," "this is the important part,"
  "the interesting case here is." Just describe X; put it first if it matters most.
- Comparing sections or platforms as prose: "the Windows uninstaller cleans up more
  than the other platforms do." Say what it removes.
- Narrating the reader's mental state: "that also means they're still there after you
  think you're done," "you might be wondering." State the fact.
- Coaching flourishes on plain steps: "to finish the job," "and that's all there is
  to it," "nothing here blocks you." Delete.
- Rhetorical question openers: "Need to go the other way?", "Want the short
  version?" Lead with the statement: "To remove X, see Y."
- Warmth padding on outcomes: "your projects are waiting where you left them,"
  "you're all set." Say what is true: "your projects are where you left them."
- Restating a cross-reference's purpose: "which is why it's worth noting the path
  first." Give the instruction: "Note the path before you uninstall."

Banned structural patterns:
- Every paragraph ending in a takeaway ("And so, X matters"). End on the last fact.
- Hollow transitions: "Moreover," "Furthermore," "Additionally," "It's
  important to note that." Usually deletable.
- Summary closers that restate the opening. Cut them.
- False balance on settled questions ("While X has merits, Y is better"). If Y
  is the answer, say so.
- Hedge stacking ("it may be possible that, in some cases, you might want to").
  Pick one hedge or none.
- A bulleted list in every section whether or not the content calls for it.
- Uniform sentence rhythm (a page of same-length sentences). Vary it.

Voice positives to reward and steer toward:
- Lead with the verb: "Use Postgres for app data," not "Postgres is generally
  considered a good choice."
- Use specific nouns and real names: `pg_dump`, "Tailwind v4," "Postgres 17,"
  not "modern tooling" or "edge functions."
- State the rule, then the reason: "Use `--ci` in CI runs; it fails fast on
  snapshot mismatches."

Also weigh theory of mind: is the doc written for a real reader with a goal, or
does it explain things nobody asked about while skipping what the reader
actually needs? Flag missing prerequisites, undefined jargon on first use, and
steps that assume knowledge the stated audience lacks.

## Output format

### Docs reviewed
- `path/to/file.md` (lines X-Y or "full file")

### Grounding (accuracy against the code)
- `file.md:42` - **Title.** What the doc claims, what the source shows
  (`src/x.ts:10`), the correction.

### Unverifiable claims
- `file.md:88` - **Title.** Claim that cannot be checked against the repo;
  needs a human or a cited source.

### Voice and structure
- `file.md:12` - **Title.** Quote the text, name the tell, give the rewrite.

### Reads well
- Brief notes on passages that are accurate and sound human, so the pass does
  not devolve into nitpicking.

### Summary
Two or three sentences: is it trustworthy, does it sound human, and the single
most important fix.

Order findings by impact within each section. Every finding must be actionable.
Do not invent problems to fill sections; if a section is empty, say so.
