#!/usr/bin/env bash
set -euo pipefail

# One-shot local quality loop.
#
# Usage:
#   health-check.sh
#   health-check.sh --since "48 hours ago"
#   health-check.sh --skip-reconcile
#   health-check.sh --agent codex

SINCE="24 hours ago"
SKIP_RECONCILE=false
AGENT="codex"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      if [[ $# -lt 2 ]]; then
        echo "❌ --since requires a value."
        exit 1
      fi
      SINCE="$2"
      shift 2
      ;;
    --skip-reconcile)
      SKIP_RECONCILE=true
      shift
      ;;
    --agent)
      if [[ $# -lt 2 ]]; then
        echo "❌ --agent requires a value."
        exit 1
      fi
      AGENT="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "${REPO_ROOT:-}" ]; then
  echo "Not inside a git repository."
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

find_tool() {
  local rel="$1"
  for candidate in \
    "$REPO_ROOT/$rel" \
    "$REPO_ROOT/.agents/$rel" \
    "$HOME/.agents/$rel"; do
    if [ -x "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

DOCS_LIST=$(find_tool "skills/dev-discipline/scripts/docs-list.sh")
SYNC_PLAN=$(find_tool "skills/dev-discipline/scripts/sync-plan-template.sh")
DOC_GARDENER=$(find_tool "skills/dev-discipline/scripts/doc-gardener.sh")
PLANNER_VALIDATE=$(find_tool "skills/planner/scripts/validate-plan.sh")
ARCHITECTURE_VALIDATE=$(find_tool "skills/planner/scripts/validate-architecture.sh")
RECONCILE=$(find_tool "skills/dev-reconciliation/scripts/reconcile.sh")

echo "Running health check in $REPO_ROOT"

echo ""
echo "1) docs-list"
"$DOCS_LIST"

echo ""
echo "2) sync plan template (--check)"
"$SYNC_PLAN" --check

echo ""
echo "3) planner validate (all active plans)"
"$PLANNER_VALIDATE"

echo ""
echo "4) architecture validate"
"$ARCHITECTURE_VALIDATE"

echo ""
echo "5) doc gardener"
"$DOC_GARDENER" --since "$SINCE"

if [ "$SKIP_RECONCILE" = true ]; then
  echo ""
  echo "6) reconcile skipped (--skip-reconcile)"
  exit 0
fi

echo ""
echo "6) reconcile"
if [ "$AGENT" = "codex" ] && ! command -v codex >/dev/null 2>&1; then
  echo "⚠️  codex CLI not found; skipping reconcile."
  exit 0
fi
if [ "$AGENT" = "claude" ] && ! command -v claude >/dev/null 2>&1; then
  echo "⚠️  claude CLI not found; skipping reconcile."
  exit 0
fi

"$RECONCILE" --since "$SINCE" --agent "$AGENT"

echo ""
echo "Health check complete."
