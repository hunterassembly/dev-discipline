#!/usr/bin/env bash
# Wrapper — routes to the skill implementation
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_SCRIPT=""
for candidate in \
  "$SCRIPT_DIR/../skills/dev-reconciliation/scripts/reconcile-branch.sh" \
  "$HOME/.agents/skills/dev-reconciliation/scripts/reconcile-branch.sh"; do
  if [ -x "$candidate" ]; then
    SKILL_SCRIPT="$candidate"
    break
  fi
done
if [ -z "$SKILL_SCRIPT" ]; then
  echo "❌ reconcile-branch.sh not found in skill directories."
  exit 1
fi
exec "$SKILL_SCRIPT" "$@"
