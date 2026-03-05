#!/usr/bin/env bash
set -euo pipefail

# Dev Discipline — Teardown Script
# Removes hooks and bridge references. Does NOT delete .dev/ (your data).

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "${REPO_ROOT:-}" ]; then
  echo "❌ Not inside a git repository."
  exit 1
fi

HOOKS_DIR="$REPO_ROOT/.git/hooks"
SKILL_DIR=""
REMOVED=0

# Find the skill directory
for candidate in \
  "$REPO_ROOT/.agents/skills/dev-discipline" \
  "$REPO_ROOT/skills/dev-discipline" \
  "$HOME/.agents/skills/dev-discipline"; do
  if [ -f "$candidate/SKILL.md" ]; then
    SKILL_DIR="$candidate"
    break
  fi
done

echo "🧹 Dev Discipline Teardown"
echo "   Repo: $REPO_ROOT"
echo ""

# Remove hook symlinks (only if they point to our assets)
for hook in pre-commit commit-msg post-commit; do
  TARGET="$HOOKS_DIR/$hook"
  if [ -L "$TARGET" ]; then
    LINK_TARGET=$(readlink "$TARGET")
    if echo "$LINK_TARGET" | grep -q "dev-discipline"; then
      rm "$TARGET"
      echo "✅ Removed $hook hook"
      REMOVED=$((REMOVED + 1))
    else
      echo "⏭️  $hook hook points elsewhere ($LINK_TARGET), skipping"
    fi
  elif [ -f "$TARGET" ]; then
    echo "⏭️  $hook hook is not a symlink (may not be ours), skipping"
  fi
done

# Remove bridge line from AGENTS.md
AGENTS_FILE="$REPO_ROOT/AGENTS.md"
if [ -f "$AGENTS_FILE" ] && grep -qF '.dev/contract.md' "$AGENTS_FILE" 2>/dev/null; then
  # Remove the Dev Discipline section (header + blank line + bridge line)
  sed -i '' '/^## Dev Discipline$/,/\.dev\/contract\.md/d' "$AGENTS_FILE" 2>/dev/null || \
  sed -i '/^## Dev Discipline$/,/\.dev\/contract\.md/d' "$AGENTS_FILE" 2>/dev/null || true
  sed -i '' '/\.agent\/PLANS\.md/d' "$AGENTS_FILE" 2>/dev/null || \
  sed -i '/\.agent\/PLANS\.md/d' "$AGENTS_FILE" 2>/dev/null || true
  sed -i '' '/ARCHITECTURE\.md/d' "$AGENTS_FILE" 2>/dev/null || \
  sed -i '/ARCHITECTURE\.md/d' "$AGENTS_FILE" 2>/dev/null || true
  # Clean up trailing blank lines
  sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$AGENTS_FILE" 2>/dev/null || true
  echo "✅ Removed contract reference from AGENTS.md"
  REMOVED=$((REMOVED + 1))
fi

# Remove bridge line from CLAUDE.md
CLAUDE_FILE="$REPO_ROOT/CLAUDE.md"
if [ -f "$CLAUDE_FILE" ] && grep -qF '.dev/contract.md' "$CLAUDE_FILE" 2>/dev/null; then
  sed -i '' '/@\.dev\/contract\.md/d' "$CLAUDE_FILE" 2>/dev/null || \
  sed -i '/@\.dev\/contract\.md/d' "$CLAUDE_FILE" 2>/dev/null || true
  echo "✅ Removed contract import from CLAUDE.md"
  REMOVED=$((REMOVED + 1))
fi

# Remove Claude Code rule
CLAUDE_RULE="$REPO_ROOT/.claude/rules/dev-discipline.md"
if [ -f "$CLAUDE_RULE" ]; then
  rm "$CLAUDE_RULE"
  echo "✅ Removed .claude/rules/dev-discipline.md"
  REMOVED=$((REMOVED + 1))
fi

echo ""
if [ "$REMOVED" -gt 0 ]; then
  echo "🎉 Removed $REMOVED item(s). .dev/ directory preserved (your data)."
else
  echo "Nothing to remove — dev discipline doesn't appear to be installed."
fi
