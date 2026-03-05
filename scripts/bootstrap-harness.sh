#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for candidate in \
  "$REPO_ROOT/skills/dev-discipline/scripts/bootstrap-harness.sh" \
  "$REPO_ROOT/.agents/skills/dev-discipline/scripts/bootstrap-harness.sh" \
  "$HOME/.agents/skills/dev-discipline/scripts/bootstrap-harness.sh"; do
  if [ -f "$candidate" ]; then
    exec "$candidate" "$@"
  fi
done

echo "Could not find dev-discipline harness bootstrap implementation."
echo "Expected one of:"
echo "  skills/dev-discipline/scripts/bootstrap-harness.sh"
echo "  .agents/skills/dev-discipline/scripts/bootstrap-harness.sh"
echo "  ~/.agents/skills/dev-discipline/scripts/bootstrap-harness.sh"
exit 1
