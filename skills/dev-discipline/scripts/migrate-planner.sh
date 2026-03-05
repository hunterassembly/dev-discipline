#!/usr/bin/env bash
set -euo pipefail

# Migrate legacy exec-plan-discipline references to planner.
#
# Usage:
#   migrate-planner.sh

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "${REPO_ROOT:-}" ]; then
  echo "Not inside a git repository."
  exit 1
fi

replace_in_file() {
  local file="$1"
  local search="$2"
  local replace="$3"
  if [ ! -f "$file" ]; then
    return 0
  fi
  if ! grep -q "$search" "$file"; then
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  sed "s|$search|$replace|g" "$file" > "$tmp"
  mv "$tmp" "$file"
  echo "updated: ${file#"$REPO_ROOT"/}"
}

rename_skill_dir() {
  local parent="$1"
  local legacy="$parent/exec-plan-discipline"
  local planner="$parent/planner"

  if [ -d "$legacy" ] && [ ! -d "$planner" ]; then
    mv "$legacy" "$planner"
    echo "renamed skill directory: $legacy -> $planner"
  elif [ -d "$legacy" ] && [ -d "$planner" ]; then
    cp -R "$legacy/." "$planner/"
    rm -rf "$legacy"
    echo "merged legacy skill into planner: $planner"
  fi
}

rename_skill_dir "$REPO_ROOT/.agents/skills"
rename_skill_dir "$HOME/.agents/skills"

replace_in_file "$REPO_ROOT/AGENTS.md" "exec-plan-discipline" "planner"
replace_in_file "$REPO_ROOT/.agent/PLANS.md" "exec-plan-discipline" "planner"
replace_in_file "$REPO_ROOT/README.md" "exec-plan-discipline" "planner"
replace_in_file "$REPO_ROOT/docs/refs/harness-engineering.md" "exec-plan-discipline" "planner"
replace_in_file "$REPO_ROOT/docs/slash-commands/README.md" "exec-plan-discipline" "planner"

if [ -f "$REPO_ROOT/scripts/validate-exec-plan.sh" ] && [ ! -f "$REPO_ROOT/scripts/planner" ]; then
  cat > "$REPO_ROOT/scripts/planner" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
exec "$REPO_ROOT/scripts/validate-exec-plan.sh" "$@"
EOF
  chmod +x "$REPO_ROOT/scripts/planner"
  echo "created: scripts/planner"
fi

BOOTSTRAP_SCRIPT=""
for candidate in \
  "$REPO_ROOT/skills/dev-discipline/scripts/bootstrap-harness.sh" \
  "$REPO_ROOT/.agents/skills/dev-discipline/scripts/bootstrap-harness.sh" \
  "$HOME/.agents/skills/dev-discipline/scripts/bootstrap-harness.sh"; do
  if [ -x "$candidate" ]; then
    BOOTSTRAP_SCRIPT="$candidate"
    break
  fi
done

if [ -n "$BOOTSTRAP_SCRIPT" ]; then
  "$BOOTSTRAP_SCRIPT" >/dev/null || true
fi

echo "planner migration complete."
