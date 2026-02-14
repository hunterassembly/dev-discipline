#!/usr/bin/env bash
set -euo pipefail

# Dev Discipline — Setup Script
# Installs git hooks and creates required directories.
# Run from the project root (or any directory inside the git repo).

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not inside a git repository."
  exit 1
fi

HOOKS_DIR="$REPO_ROOT/.git/hooks"
DEV_DIR="$REPO_ROOT/.dev"
SKILL_DIR=""

# Find the skill directory (look in common locations)
for candidate in \
  "$REPO_ROOT/.agents/skills/dev-discipline" \
  "$REPO_ROOT/skills/dev-discipline" \
  "$HOME/.agents/skills/dev-discipline"; do
  if [ -f "$candidate/SKILL.md" ]; then
    SKILL_DIR="$candidate"
    break
  fi
done

if [ -z "$SKILL_DIR" ]; then
  echo "❌ Could not find dev-discipline skill directory."
  echo "   Expected at .agents/skills/dev-discipline/ or skills/dev-discipline/"
  exit 1
fi

echo "🔧 Dev Discipline Setup"
echo "   Repo: $REPO_ROOT"
echo "   Skill: $SKILL_DIR"
echo ""

# Create .dev directories
mkdir -p "$DEV_DIR/diary" "$DEV_DIR/decisions"
echo "✅ Created .dev/diary/ and .dev/decisions/"

# Install hooks
for hook in pre-commit commit-msg post-commit; do
  ASSET="$SKILL_DIR/assets/$hook"
  TARGET="$HOOKS_DIR/$hook"

  if [ ! -f "$ASSET" ]; then
    echo "⚠️  No $hook asset found, skipping"
    continue
  fi

  if [ -f "$TARGET" ] && [ ! -L "$TARGET" ]; then
    # Backup existing hook
    cp "$TARGET" "$TARGET.bak"
    echo "📦 Backed up existing $hook → $hook.bak"
  fi

  cp "$ASSET" "$TARGET"
  chmod +x "$TARGET"
  echo "✅ Installed $hook hook"
done

# Create .dev/WORKLOG.md if it doesn't exist
if [ ! -f "$DEV_DIR/WORKLOG.md" ]; then
  cat > "$DEV_DIR/WORKLOG.md" << 'EOF'
# Worklog

## In Progress


## Blocked


## Done (Recent)

EOF
  echo "✅ Created .dev/WORKLOG.md"
fi

# Add .dev/diary/ to .gitignore if not already there
if [ -f "$REPO_ROOT/.gitignore" ]; then
  if ! grep -q '.dev/diary/' "$REPO_ROOT/.gitignore" 2>/dev/null; then
    echo "" >> "$REPO_ROOT/.gitignore"
    echo "# Dev discipline diary (local, auto-generated)" >> "$REPO_ROOT/.gitignore"
    echo ".dev/diary/" >> "$REPO_ROOT/.gitignore"
    echo "✅ Added .dev/diary/ to .gitignore"
  fi
fi

echo ""
echo "🎉 Dev discipline hooks installed. You're good to go."
echo "   Diary entries: .dev/diary/"
echo "   Decisions:     .dev/decisions/"
echo "   Worklog:       .dev/WORKLOG.md"
