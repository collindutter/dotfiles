# Yap field guide

Yap is the residue left behind by thinking out loud: words written for the
writer, not the reader. Term from https://mckayla.blog/posts/yap.html.

This guide covers every place yap lands in a change: code comments, docstrings,
repo prose, and commit or PR bodies.

## The keep test

For each comment, docstring, or paragraph in scope, ask in order:

1. Does it say anything the code does not already say?
2. Would a reader who never saw the prompt, the ticket, or the previous version
   of this file need it?
3. Is it next to the thing it explains?
4. Is it true today?

Any "no" means cut, move, or shorten.

## Patterns

Code comments:

- Restatement. `// increment the counter` above `count += 1`.
- Prompt paraphrase. Describes the task or the request instead of the code.
- Diff-relative aside. Only makes sense to someone who saw the previous version:
  "Also handle the empty case", "Single source of truth", "This is needed for
  the tests to pass".
- Change narration. "previously", "used to", "no longer", "this replaces",
  "refactored from". That belongs in the commit message.
- Misplaced clump. Long header above a function while the tricky lines inside it
  are bare. Split it, move each sentence to the line it explains, drop the rest.
- File-top essay. Architecture lecture nobody will maintain.
- Banners. `// ===== HELPERS =====`, `// --- Step 3 ---`.
- Hedging filler. "Note that", "It is worth noting", "Importantly",
  "This ensures that we".
- Self-praise. "robust", "comprehensive", "cleanly handles", "for clarity",
  "for maintainability".
- TODO essays. A paragraph of speculation where an issue link belongs, or a note
  addressed to developers rather than to readers of the code ("use this pattern
  going forward").
- Test narration. Arrange/Act/Assert labels, comments restating an assertion.

Docstrings:

- Args and Returns blocks that repeat the signature and the type annotations.
- "Returns: the result." "Initializes the class."
- Prose describing every branch of the body.

Repo prose (README, docs, changelog):

- Preamble before the first useful sentence.
- Bullets that repeat their heading.
- "In this section we will", "Let's dive in", "It's important to understand".
- Tone-setting adjectives standing in for facts.
- A table or diagram carrying one fact.

Commit and PR bodies:

- Hunk-by-hunk inventory of the diff.
- The motivation stated three times in three registers.
- "This PR introduces a comprehensive..."

## What survives

- Why, when why is not derivable from the code: constraint, invariant,
  workaround, upstream bug, with a link.
- Non-obvious cost, ordering, or concurrency requirement.
- Units, ranges, and lifetime rules the types do not carry.
- Links: issue, RFC, spec, vendor doc.
- The one sentence that stops the next reader from "fixing" correct code.

What stays gets the fewest words that still read well in a year. No em dashes.
No temporal references. Length is never the offense; emptiness is.

## Procedure

1. Judge only added and modified lines. Pre-existing comments are out of scope
   unless the change made them false.
2. Prefer deleting over rewriting, and moving over rewriting. Rewrite only when
   the content is worth keeping and badly placed or badly phrased.
3. Never change code, tests, or behavior. If a comment is wrong because the code
   is wrong, report it and leave both alone.
4. Leave anything genuinely ambiguous and report it as a judgment call.

## Output format

### Cut
- `file:line` - what went, few words

### Moved or rewritten
- `file:line` - before, after

### Left alone
- `file:line` - why, one line

### Report only, not edited
- Commit messages, PR body, suspected code bugs.

### Counts
N cut, M moved, K rewritten, X lines removed.
