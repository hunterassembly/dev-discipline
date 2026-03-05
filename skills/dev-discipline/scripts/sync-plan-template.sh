#!/usr/bin/env bash
set -euo pipefail

# Keep docs/plans/active/plan-template.md synced with canonical planner template.
#
# Usage:
#   sync-plan-template.sh
#   sync-plan-template.sh --check

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=true
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "${REPO_ROOT:-}" ]; then
  echo "Not inside a git repository."
  exit 1
fi

TARGET="$REPO_ROOT/docs/plans/active/plan-template.md"
SOURCE=""
for candidate in \
  "$REPO_ROOT/skills/planner/templates/exec-plan.md" \
  "$REPO_ROOT/.agents/skills/planner/templates/exec-plan.md" \
  "$HOME/.agents/skills/planner/templates/exec-plan.md"; do
  if [ -f "$candidate" ]; then
    SOURCE="$candidate"
    break
  fi
done

if [ -z "$SOURCE" ]; then
  echo "Could not find canonical planner template."
  echo "Expected one of:"
  echo "  skills/planner/templates/exec-plan.md"
  echo "  .agents/skills/planner/templates/exec-plan.md"
  echo "  ~/.agents/skills/planner/templates/exec-plan.md"
  exit 1
fi

if [ ! -f "$TARGET" ]; then
  if [ "$CHECK_ONLY" = true ]; then
    echo "Plan template missing: $TARGET"
    exit 1
  fi
  mkdir -p "$(dirname "$TARGET")"
  cp "$SOURCE" "$TARGET"
  echo "Created plan template from canonical source."
  exit 0
fi

if cmp -s "$SOURCE" "$TARGET"; then
  echo "Plan template already in sync."
  exit 0
fi

if [ "$CHECK_ONLY" = true ]; then
  echo "Plan template drift detected."
  echo "Run: ./scripts/sync-plan-template.sh"
  exit 1
fi

cp "$SOURCE" "$TARGET"
echo "Synced docs/plans/active/plan-template.md from canonical planner template."
