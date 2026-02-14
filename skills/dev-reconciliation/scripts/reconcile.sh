#!/usr/bin/env bash
set -euo pipefail

# Dev Reconciliation — Standalone launcher
# Usage: ./reconcile.sh [--since "24 hours ago"] [--agent codex|claude]
# 
# Gathers commit data and launches an AI agent to review it.
# Can be run independently of the skill system.

SINCE="midnight"
AGENT="codex"

while [[ $# -gt 0 ]]; do
  case $1 in
    --since) SINCE="$2"; shift 2 ;;
    --agent) AGENT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not inside a git repository."
  exit 1
fi

DATE=$(date +%Y-%m-%d)
DIARY_DIR="$REPO_ROOT/.dev/diary"
OUTPUT="$DIARY_DIR/reconciliation-$DATE.md"

# Gather data
COMMITS=$(git log --since="$SINCE" --oneline 2>/dev/null || echo "No commits found")
COMMIT_COUNT=$(echo "$COMMITS" | grep -c '.' || echo "0")

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "No commits since $SINCE. Nothing to reconcile."
  exit 0
fi

echo "🔍 Reconciling $COMMIT_COUNT commits since $SINCE"
echo ""

DIFFS=$(git log --since="$SINCE" -p --stat 2>/dev/null)
DIARY=$(cat "$DIARY_DIR/$DATE.md" 2>/dev/null || echo "No diary entries")

# Build prompt
PROMPT="You are a code reconciliation agent. Review the following work and produce a reconciliation report.

## Commits ($COMMIT_COUNT)
$COMMITS

## Detailed Diffs
$DIFFS

## Dev Diary
$DIARY

Produce a reconciliation report covering:
1. Commit atomicity: Flag any commits doing multiple unrelated things
2. Test gaps: Which behavioral changes lack test coverage?
3. Commit message quality: Do all follow conventional format with why: lines?
4. Doc staleness: Should any docs be updated?
5. Decisions: Were there architectural decisions that should be documented?
6. Diary summary: Write a coherent narrative of the work done

Output as markdown with the header: # Reconciliation Report — $DATE"

mkdir -p "$DIARY_DIR"

case $AGENT in
  codex)
    echo "Running reconciliation via Codex..."
    codex exec "$PROMPT" > "$OUTPUT"
    ;;
  claude)
    echo "Running reconciliation via Claude..."
    claude --print "$PROMPT" > "$OUTPUT"
    ;;
  *)
    echo "❌ Unknown agent: $AGENT (use codex or claude)"
    exit 1
    ;;
esac

echo ""
echo "✅ Reconciliation report saved to $OUTPUT"
echo "   Review it and address any findings."
