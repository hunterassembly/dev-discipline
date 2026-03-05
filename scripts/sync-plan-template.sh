#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for candidate in \
  "$REPO_ROOT/skills/dev-discipline/scripts/sync-plan-template.sh" \
  "$REPO_ROOT/.agents/skills/dev-discipline/scripts/sync-plan-template.sh" \
  "$HOME/.agents/skills/dev-discipline/scripts/sync-plan-template.sh"; do
  if [ -f "$candidate" ]; then
    exec "$candidate" "$@"
  fi
done

echo "Could not find sync-plan-template implementation."
echo "Expected one of:"
echo "  skills/dev-discipline/scripts/sync-plan-template.sh"
echo "  .agents/skills/dev-discipline/scripts/sync-plan-template.sh"
echo "  ~/.agents/skills/dev-discipline/scripts/sync-plan-template.sh"
exit 1
