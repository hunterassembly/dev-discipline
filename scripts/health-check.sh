#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for candidate in \
  "$REPO_ROOT/skills/dev-discipline/scripts/health-check.sh" \
  "$REPO_ROOT/.agents/skills/dev-discipline/scripts/health-check.sh" \
  "$HOME/.agents/skills/dev-discipline/scripts/health-check.sh"; do
  if [ -f "$candidate" ]; then
    exec "$candidate" "$@"
  fi
done

echo "Could not find health-check implementation."
echo "Expected one of:"
echo "  skills/dev-discipline/scripts/health-check.sh"
echo "  .agents/skills/dev-discipline/scripts/health-check.sh"
echo "  ~/.agents/skills/dev-discipline/scripts/health-check.sh"
exit 1
