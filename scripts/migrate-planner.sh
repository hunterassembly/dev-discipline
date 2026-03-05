#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for candidate in \
  "$REPO_ROOT/skills/dev-discipline/scripts/migrate-planner.sh" \
  "$REPO_ROOT/.agents/skills/dev-discipline/scripts/migrate-planner.sh" \
  "$HOME/.agents/skills/dev-discipline/scripts/migrate-planner.sh"; do
  if [ -f "$candidate" ]; then
    exec "$candidate" "$@"
  fi
done

echo "Could not find migrate-planner implementation."
echo "Expected one of:"
echo "  skills/dev-discipline/scripts/migrate-planner.sh"
echo "  .agents/skills/dev-discipline/scripts/migrate-planner.sh"
echo "  ~/.agents/skills/dev-discipline/scripts/migrate-planner.sh"
exit 1
