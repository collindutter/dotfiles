#!/usr/bin/env bash
# Print every aven task with url metadata, including done and canceled ones.
# Output: TSV of ref, status, labels, url.
set -euo pipefail
WS=${AVEN_TRIAGE_WORKSPACE:-work}

# --all leaves out deferred tasks, so add --upcoming.
{
  aven --workspace "$WS" list -A --all --has-metadata url --json
  aven --workspace "$WS" list -A --upcoming --has-metadata url --json
} | jq -rs 'add | unique_by(.ref) | .[] | [.ref, .status, (.labels | join(","))] | @tsv' |
  while IFS=$'\t' read -r ref status labels; do
    url=$(aven --workspace "$WS" context "$ref" --json | jq -r '.metadata.url // empty')
    printf '%s\t%s\t%s\t%s\n' "$ref" "$status" "$labels" "$url"
  done
