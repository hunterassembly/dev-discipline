#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for candidate in \
  "$REPO_ROOT/skills/planner/scripts/validate-architecture.sh" \
  "$REPO_ROOT/.agents/skills/planner/scripts/validate-architecture.sh" \
  "$HOME/.agents/skills/planner/scripts/validate-architecture.sh"; do
  if [ -f "$candidate" ]; then
    exec "$candidate" "$@"
  fi
done

echo "Could not find architecture validator implementation."
echo "Expected one of:"
echo "  skills/planner/scripts/validate-architecture.sh"
echo "  .agents/skills/planner/scripts/validate-architecture.sh"
echo "  ~/.agents/skills/planner/scripts/validate-architecture.sh"
exit 1
