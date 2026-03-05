#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for candidate in \
  "$REPO_ROOT/skills/planner/scripts/validate-plan.sh" \
  "$REPO_ROOT/.agents/skills/planner/scripts/validate-plan.sh" \
  "$HOME/.agents/skills/planner/scripts/validate-plan.sh" \
  "$REPO_ROOT/skills/exec-plan-discipline/scripts/validate-plan.sh" \
  "$REPO_ROOT/.agents/skills/exec-plan-discipline/scripts/validate-plan.sh" \
  "$HOME/.agents/skills/exec-plan-discipline/scripts/validate-plan.sh"; do
  if [ -f "$candidate" ]; then
    exec "$candidate" "$@"
  fi
done

echo "Could not find planner validator implementation."
echo "Expected one of:"
echo "  skills/planner/scripts/validate-plan.sh"
echo "  .agents/skills/planner/scripts/validate-plan.sh"
echo "  ~/.agents/skills/planner/scripts/validate-plan.sh"
exit 1
