#!/usr/bin/env bash
# Splice a suggestion block's replacement lines into a copy of a file at the anchored
# range, so the project's formatter / typechecker / tests can run on the result BEFORE
# you post a comment the author can apply with one click.
#
# Usage: check-suggestion.sh <path> <start_line> <end_line> <suggestion_file>
#
#   path            : the file as it exists at the PR head SHA (your checkout must match).
#   start_line      : first line of the comment's anchor, inclusive.
#   end_line        : last line of the comment's anchor, inclusive. For a single-line
#                     anchor pass the same number twice. GitHub replaces exactly this
#                     range with the suggestion, so this is what gets spliced out.
#   suggestion_file : the replacement lines ONLY, with no ```suggestion fence and with
#                     their real indentation. An empty file means the suggestion deletes
#                     the range.
#
# Prints the spliced file's path and a unified diff against the original. Nothing in the
# GitHub API validates that a suggestion applies cleanly, or even parses, so this is the
# only check available.
set -euo pipefail

path="${1:?usage: check-suggestion.sh <path> <start_line> <end_line> <suggestion_file>}"
start="${2:?need a start line}"
end="${3:?need an end line (same as start for a single-line anchor)}"
suggestion="${4:?need a file holding the replacement lines, unfenced}"

[[ -f "$path" ]] || { echo "no such file: $path" >&2; exit 1; }
[[ -f "$suggestion" ]] || { echo "no such file: $suggestion" >&2; exit 1; }
[[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]] || { echo "line numbers must be integers" >&2; exit 1; }
(( start >= 1 )) || { echo "start_line must be >= 1" >&2; exit 1; }
(( end >= start )) || { echo "end_line ($end) is before start_line ($start)" >&2; exit 1; }

total=$(grep -c '' "$path")
(( end <= total )) || { echo "end_line ($end) is past the end of $path ($total lines)" >&2; exit 1; }

if grep -q '^```' "$suggestion"; then
  echo "WARNING: $suggestion contains a fence line. Pass the replacement lines only." >&2
fi

# Indentation is applied verbatim, and a mismatched indent is the most common way a
# suggestion lands as broken code rather than as an error.
describe_indent() {
  local ws="$1" tabs spaces
  if [[ -z "$ws" ]]; then
    echo "none"
    return
  fi
  tabs=${ws//[^$'\t']/}
  spaces=${ws//[^ ]/}
  echo "${#spaces} space(s), ${#tabs} tab(s)"
}

orig_indent=$(sed -n "${start}p" "$path" | sed -n 's/^\([[:space:]]*\).*/\1/p')
new_indent=$(sed -n '1p' "$suggestion" | sed -n 's/^\([[:space:]]*\).*/\1/p')
if [[ -s "$suggestion" && "$orig_indent" != "$new_indent" ]]; then
  echo "WARNING: leading whitespace on the first line differs from $path:$start." >&2
  echo "         original: $(describe_indent "$orig_indent")" >&2
  echo "         suggested: $(describe_indent "$new_indent")" >&2
fi

out="$(mktemp -d)/$(basename "$path")"
{
  if (( start > 1 )); then
    sed -n "1,$((start - 1))p" "$path"
  fi
  cat "$suggestion"
  if (( end < total )); then
    sed -n "$((end + 1)),\$p" "$path"
  fi
} > "$out"

echo "spliced: $out"
echo
diff -u "$path" "$out" || true
echo
echo "Now run the project's formatter / typechecker / tests against $out."
