#!/usr/bin/env bash
set -euo pipefail

# Dev Reconciliation — Standalone launcher
# Usage: ./reconcile.sh [--since "24 hours ago"] [--agent codex|claude] [--dry-run]

SINCE=""
AGENT="codex"
DRY_RUN=false
MAX_DIFF_BYTES=51200   # ~50KB
MAX_COMMIT_LINES=200

usage() {
  echo "Usage: ./reconcile.sh [--since \"24 hours ago\"] [--agent codex|claude] [--dry-run]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      if [[ $# -lt 2 ]]; then
        echo "❌ --since requires a value."
        usage
        exit 1
      fi
      SINCE="$2"
      shift 2
      ;;
    --agent)
      if [[ $# -lt 2 ]]; then
        echo "❌ --agent requires a value (codex|claude)."
        usage
        exit 1
      fi
      AGENT="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not inside a git repository."
  exit 1
fi

DATE=$(date +%Y-%m-%d)
DIARY_DIR="$REPO_ROOT/.dev/diary"
LAST_REC_FILE="$REPO_ROOT/.dev/.last-reconciliation"
OUTPUT="$DIARY_DIR/reconciliation-$DATE.md"

# Determine --since: explicit flag > last reconciliation timestamp > 24 hours ago
if [ -z "$SINCE" ]; then
  if [ -f "$LAST_REC_FILE" ]; then
    SINCE=$(cat "$LAST_REC_FILE")
    echo "📅 Using last reconciliation timestamp: $SINCE"
  else
    SINCE="24 hours ago"
    echo "📅 No previous reconciliation found, using: $SINCE"
  fi
fi

# Gather data with truncation
COMMITS=$(git log --since="$SINCE" --oneline 2>/dev/null | head -n "$MAX_COMMIT_LINES" || true)
if [ -z "$COMMITS" ]; then
  COMMIT_COUNT=0
else
  COMMIT_COUNT=$(printf "%s\n" "$COMMITS" | grep -c '.')
fi

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "No commits since $SINCE. Nothing to reconcile."
  exit 0
fi

echo "🔍 Reconciling $COMMIT_COUNT commits since $SINCE"

# Truncate diffs to MAX_DIFF_BYTES
DIFF_TMP=$(mktemp)
DIARY_AGG_TMP=$(mktemp)
trap 'rm -f "$DIFF_TMP" "$DIARY_AGG_TMP"' EXIT

git log --since="$SINCE" -p --stat > "$DIFF_TMP" 2>/dev/null || true
DIFFS=$(head -c "$MAX_DIFF_BYTES" "$DIFF_TMP")
DIFF_FULL_SIZE=$(wc -c < "$DIFF_TMP" | tr -d ' ')
TRUNCATION_NOTE=""
if [ "$DIFF_FULL_SIZE" -gt "$MAX_DIFF_BYTES" ]; then
  TRUNCATION_NOTE="(truncated from ${DIFF_FULL_SIZE} bytes to ${MAX_DIFF_BYTES} bytes — review individual commits for full diffs)"
fi

COMMIT_DATES=$(git log --since="$SINCE" --format=%cd --date=format:%Y-%m-%d 2>/dev/null | sort -u)
DIARY_HASHES=""
for day in $COMMIT_DATES; do
  DIARY_FILE="$DIARY_DIR/$day.md"
  if [ -f "$DIARY_FILE" ]; then
    printf "### %s\n" "$day" >> "$DIARY_AGG_TMP"
    cat "$DIARY_FILE" >> "$DIARY_AGG_TMP"
    printf "\n\n" >> "$DIARY_AGG_TMP"
    HASHES_FOR_DAY=$(grep -oE '`[a-f0-9]{7}`' "$DIARY_FILE" | tr -d '`' || true)
    if [ -n "$HASHES_FOR_DAY" ]; then
      DIARY_HASHES="${DIARY_HASHES}${HASHES_FOR_DAY}"$'\n'
    fi
  fi
done

if [ -s "$DIARY_AGG_TMP" ]; then
  DIARY=$(cat "$DIARY_AGG_TMP")
else
  DIARY="No diary entries"
fi

# Hook bypass detection: compare commit hashes vs diary entries
COMMIT_HASHES=$(git log --since="$SINCE" --format=%h 2>/dev/null)
BYPASS_COMMITS=""
for hash in $COMMIT_HASHES; do
  if ! printf "%s\n" "$DIARY_HASHES" | grep -qx "$hash"; then
    BYPASS_COMMITS="$BYPASS_COMMITS $hash"
  fi
done

BYPASS_SECTION=""
if [ -n "$BYPASS_COMMITS" ]; then
  BYPASS_SECTION="
## Possible Hook Bypasses
The following commits have no matching diary entry (may have used --no-verify):
$(echo "$BYPASS_COMMITS" | tr ' ' '\n' | sed '/^$/d' | sed 's/^/- /')"
fi

# Build prompt
PROMPT="You are a code reconciliation agent. Review the following work and produce a reconciliation report.

## Commits ($COMMIT_COUNT)
$COMMITS

## Detailed Diffs $TRUNCATION_NOTE
$DIFFS

## Dev Diary
$DIARY
$BYPASS_SECTION

Produce a reconciliation report covering:
1. Commit atomicity: Flag any commits doing multiple unrelated things
2. Test gaps: Which behavioral changes lack test coverage?
3. Commit message quality: Do all follow conventional format with why: lines?
4. Doc staleness: Should any docs be updated?
5. Decisions: Were there architectural decisions that should be documented?
6. Hook bypass detection: Flag any commits that appear to have bypassed hooks
7. Diary summary: Write a coherent narrative of the work done

Output as markdown with the header: # Reconciliation Report — $DATE"

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "=== DRY RUN — Prompt that would be sent ==="
  echo "$PROMPT"
  exit 0
fi

mkdir -p "$DIARY_DIR"

case $AGENT in
  codex)
    echo "Running reconciliation via Codex..."
    echo "$PROMPT" | codex exec --stdin > "$OUTPUT"
    ;;
  claude)
    echo "Running reconciliation via Claude..."
    echo "$PROMPT" | claude --print --stdin > "$OUTPUT"
    ;;
  *)
    echo "❌ Unknown agent: $AGENT (use codex or claude)"
    exit 1
    ;;
esac

# Record reconciliation timestamp
date -Iseconds > "$LAST_REC_FILE"

echo ""
echo "✅ Reconciliation report saved to $OUTPUT"
echo "   Review it and address any findings."
