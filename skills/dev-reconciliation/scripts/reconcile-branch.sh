#!/usr/bin/env bash
set -euo pipefail

# Dev Reconciliation — Branch merge gate
# Audits all commits on a branch relative to its merge target.
# Usage: ./reconcile-branch.sh [branch] [--base main] [--agent codex|claude] [--dry-run]

BRANCH=""
BASE=""
AGENT="codex"
DRY_RUN=false
MAX_DIFF_BYTES=51200
MAX_COMMIT_LINES=200
HARD_GATE_ERRORS=0

usage() {
  echo "Usage: ./reconcile-branch.sh [branch] [--base main] [--agent codex|claude] [--dry-run]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      if [[ $# -lt 2 ]]; then echo "❌ --base requires a value."; usage; exit 1; fi
      BASE="$2"; shift 2 ;;
    --agent)
      if [[ $# -lt 2 ]]; then echo "❌ --agent requires a value."; usage; exit 1; fi
      AGENT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -*)  echo "Unknown option: $1"; usage; exit 1 ;;
    *)   BRANCH="$1"; shift ;;
  esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not inside a git repository."
  exit 1
fi

# Default branch to current
if [ -z "$BRANCH" ]; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD")
fi

# Default base to main or master
if [ -z "$BASE" ]; then
  if git rev-parse --verify main >/dev/null 2>&1; then
    BASE="main"
  elif git rev-parse --verify master >/dev/null 2>&1; then
    BASE="master"
  else
    echo "❌ Could not detect base branch. Use --base to specify."
    exit 1
  fi
fi

# Get commits on branch but not on base
MERGE_BASE=$(git merge-base "$BASE" "$BRANCH" 2>/dev/null || true)
if [ -z "$MERGE_BASE" ]; then
  echo "❌ No common ancestor between $BASE and $BRANCH."
  exit 1
fi

DATE=$(date +%Y-%m-%d)
DIARY_DIR="$REPO_ROOT/.dev/diary"
OUTPUT="$DIARY_DIR/reconciliation-branch-$BRANCH-$DATE.md"

COMMITS=$(git log --oneline "$MERGE_BASE..$BRANCH" 2>/dev/null | head -n "$MAX_COMMIT_LINES" || true)
if [ -z "$COMMITS" ]; then
  COMMIT_COUNT=0
else
  COMMIT_COUNT=$(printf "%s\n" "$COMMITS" | grep -c '.')
fi

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "No commits on $BRANCH beyond $BASE. Nothing to reconcile."
  exit 0
fi

echo "🔍 Reconciling $COMMIT_COUNT commits on $BRANCH (base: $BASE)"

checkpoint_commits=$(git log --format='%h %s' "$MERGE_BASE..$BRANCH" | grep -E '^[0-9a-f]+ (fixup!|squash!) ' || true)
if [ -n "$checkpoint_commits" ]; then
  echo "❌ Hard gate failed: checkpoint commits are still present on $BRANCH."
  echo "   Squash/fixup these before merge:"
  echo "$checkpoint_commits" | sed 's/^/   - /'
  HARD_GATE_ERRORS=$((HARD_GATE_ERRORS + 1))
fi

missing_why_commits=""
while IFS= read -r sha; do
  [ -z "$sha" ] && continue
  subject=$(git show -s --format='%s' "$sha")
  if echo "$subject" | grep -qE '^(fixup!|squash!) '; then
    continue
  fi

  if ! git show -s --format='%B' "$sha" | grep -qE '^why: .+'; then
    missing_why_commits="${missing_why_commits}${sha} ${subject}"$'\n'
  fi
done < <(git rev-list --reverse "$MERGE_BASE..$BRANCH")

if [ -n "$missing_why_commits" ]; then
  echo "❌ Hard gate failed: commits missing a required 'why:' line."
  echo "$missing_why_commits" | sed '/^$/d' | sed 's/^/   - /'
  HARD_GATE_ERRORS=$((HARD_GATE_ERRORS + 1))
fi

if [ "$HARD_GATE_ERRORS" -gt 0 ]; then
  echo "⚠️  Merge gate blocked by deterministic checks. Fix the commits above and re-run."
  exit 1
fi

# Truncate diffs
DIFF_TMP=$(mktemp)
trap 'rm -f "$DIFF_TMP"' EXIT

git log "$MERGE_BASE..$BRANCH" -p --stat > "$DIFF_TMP" 2>/dev/null || true
DIFFS=$(head -c "$MAX_DIFF_BYTES" "$DIFF_TMP")
DIFF_FULL_SIZE=$(wc -c < "$DIFF_TMP" | tr -d ' ')
TRUNCATION_NOTE=""
if [ "$DIFF_FULL_SIZE" -gt "$MAX_DIFF_BYTES" ]; then
  TRUNCATION_NOTE="(truncated from ${DIFF_FULL_SIZE} bytes to ${MAX_DIFF_BYTES} bytes)"
fi

AGENT_TAG=""
if [ -n "${AGENT_ID:-}" ]; then
  AGENT_TAG="
Agent: $AGENT_ID"
fi

# Build prompt
PROMPT="You are a code reconciliation agent. Review the following branch work and produce a merge-readiness report.

## Branch: $BRANCH (base: $BASE)
## Commits ($COMMIT_COUNT)$AGENT_TAG
$COMMITS

## Detailed Diffs $TRUNCATION_NOTE
$DIFFS

Produce a merge-readiness report covering:
1. Commit atomicity: Flag any commits doing multiple unrelated things
2. Test gaps: Which behavioral changes lack test coverage?
3. Commit message quality: Do all follow conventional format with why: lines?
4. Doc staleness: Should any docs be updated?
5. Decisions: Were there architectural decisions that should be documented?
6. Overall verdict: READY TO MERGE or NEEDS WORK (with specific items to fix)

Output as markdown with the header: # Branch Reconciliation — $BRANCH ($DATE)"

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "=== DRY RUN — Prompt that would be sent ==="
  echo "$PROMPT"
  exit 0
fi

mkdir -p "$DIARY_DIR"

case $AGENT in
  codex)
    echo "Running branch reconciliation via Codex..."
    echo "$PROMPT" | codex exec --stdin > "$OUTPUT"
    ;;
  claude)
    echo "Running branch reconciliation via Claude..."
    echo "$PROMPT" | claude --print --stdin > "$OUTPUT"
    ;;
  *)
    echo "❌ Unknown agent: $AGENT (use codex or claude)"
    exit 1
    ;;
esac

echo ""
echo "✅ Branch reconciliation report saved to $OUTPUT"

# Check verdict
if grep -qi "NEEDS WORK" "$OUTPUT" 2>/dev/null; then
  echo "⚠️  Verdict: NEEDS WORK — review the report and fix findings before merging."
  exit 1
else
  echo "✅ Verdict: READY TO MERGE"
  exit 0
fi
