#!/usr/bin/env bash
# List Slack threads with activity since the last run, read or not, that are
# not tracked in aven. Read-only.
# Usage: slack-gather.sh [since]   (Slack ts, Unix time, or YYYY-MM-DD)
#
# since defaults to the last-run file, else 3 days ago. Drops bot messages,
# channels in skip-channels.txt (one name per line, # comments allowed),
# messages in the ignore list, threads with a tracked message, and threads
# where only you posted.
#
# Output: {as_of, threads: [{url, channel, kind, mentions_me, unread,
# last_from_me, messages: [{ts, user, from_me, text, url}]}]}.
# Write as_of to the last-run file after applying.
set -euo pipefail
here=$(dirname "$0")
state=${AVEN_TRIAGE_STATE:-$HOME/.local/state/aven-triage}
ignore=${AVEN_TRIAGE_IGNORE:-$state/ignored.txt}
skip=$state/skip-channels.txt
since=${1:-$(cat "$state/last-run" 2>/dev/null || date -v-3d +%F)}

# Permalinks become channel:digits keys. A reply permalink also yields its
# thread's key, so tracking any reply covers the whole thread.
keys=$(mktemp)
trap 'rm -f "$keys"' EXIT
{
  "$here/tracked.sh" | cut -f4 | sed 's/^/tracked /'
  if [ -f "$ignore" ]; then cut -d" " -f1 "$ignore" | sed 's/^/ignored /'; fi
} | jq -R 'capture("^(?<list>\\S+) .*/archives/(?<c>[A-Z0-9]+)/p(?<p>\\d+)(\\?.*thread_ts=(?<t>[\\d.]+))?")
    | {list, msg: "\(.c):\(.p)", thread: (if .t then "\(.c):\(.t | sub("\\."; ""))" else null end)}' |
  jq -s '{tracked: [.[] | select(.list == "tracked") | .msg, .thread | values],
          ignored: [.[] | select(.list == "ignored") | .msg]}' >"$keys"

skipped=$(grep -v '^\s*\(#\|$\)' "$skip" 2>/dev/null | awk '{print $1}' | jq -R . | jq -s . || echo '[]')

slacker activity --since "$since" --format json |
  jq --slurpfile k "$keys" --argjson skip "$skipped" '
    def key($c; $ts): "\($c):\($ts | sub("\\."; ""))";
    $k[0] as $k
    | .as_of as $as_of
    | [.messages[]
       | select((.bot | not) and ((.channel_name // "") as $n | $skip | index($n) | not))
       | select(key(.channel; .ts) as $m | $k.ignored | index($m) | not)]
    | group_by(.channel + ":" + (.thread_ts // .ts))
    | map(select(any(.[]; .from_me | not)))
    | map(select(
        (key(.[0].channel; .[0].thread_ts // .[0].ts) as $t | $k.tracked | index($t) | not)
        and all(.[]; key(.channel; .ts) as $m | $k.tracked | index($m) | not)))
    | map({
        url: (.[0].url | sub("p[0-9]+\\?thread_ts=(?<t>[0-9.]+)$"; "p\(.t | sub("\\."; ""))")),
        channel: .[0].channel_name,
        kind: .[0].kind,
        mentions_me: any(.[]; .mentions_me),
        unread: any(.[]; .read | not),
        last_from_me: .[-1].from_me,
        messages: map({ts, user: .user_name, from_me, text: .text[:1500], url})
      })
    | {as_of: $as_of, threads: .}'
