#!/usr/bin/env bash
# Record URLs that triage should stop proposing.
# Usage: ignore.sh <url> [reason]
set -euo pipefail
ignore=${AVEN_TRIAGE_IGNORE:-$HOME/.local/state/aven-triage/ignored.txt}
mkdir -p "$(dirname "$ignore")"
url=$1; shift
grep -qF "$url " "$ignore" 2>/dev/null || printf '%s %s\n' "$url" "${*:-}" >>"$ignore"
