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
# diary/ is gitignored (auto-generated, local only)
# decisions/ and WORKLOG.md are meant to be committed (shared project knowledge)
mkdir -p "$DEV_DIR/diary" "$DEV_DIR/decisions"
echo "✅ Created .dev/diary/ (local, gitignored) and .dev/decisions/ (tracked)"

# Copy contract.md into .dev/
CONTRACT_SRC="$SKILL_DIR/assets/contract.md"
if [ -f "$CONTRACT_SRC" ]; then
  cp "$CONTRACT_SRC" "$DEV_DIR/contract.md"
  echo "✅ Installed .dev/contract.md"
else
  echo "⚠️  No contract.md asset found, skipping"
fi

# Install hooks as symlinks (so submodule updates propagate automatically)
for hook in pre-commit commit-msg post-commit; do
  ASSET="$SKILL_DIR/assets/$hook"
  TARGET="$HOOKS_DIR/$hook"

  if [ ! -f "$ASSET" ]; then
    echo "⚠️  No $hook asset found, skipping"
    continue
  fi

  # Make asset executable
  chmod +x "$ASSET"

  # Check if already correctly symlinked
  if [ -L "$TARGET" ]; then
    CURRENT=$(readlink "$TARGET")
    if [ "$CURRENT" = "$ASSET" ]; then
      echo "✅ $hook hook already installed (symlink current)"
      continue
    fi
  fi

  # Backup existing non-symlink hook (only if it's not one of ours)
  if [ -f "$TARGET" ] && [ ! -L "$TARGET" ]; then
    cp "$TARGET" "$TARGET.bak"
    echo "📦 Backed up existing $hook → $hook.bak"
  fi

  ln -sf "$ASSET" "$TARGET"
  echo "✅ Installed $hook hook (symlink → $ASSET)"
done

# Create .dev/WORKLOG.md if it doesn't exist (tracked — shared project context)
if [ ! -f "$DEV_DIR/WORKLOG.md" ]; then
  cat > "$DEV_DIR/WORKLOG.md" << 'EOF'
# Worklog

## In Progress


## Blocked


## Done (Recent)

EOF
  echo "✅ Created .dev/WORKLOG.md (tracked)"
fi

# Add .dev/diary/ to .gitignore if not already there
if [ -f "$REPO_ROOT/.gitignore" ]; then
  if ! grep -q '.dev/diary/' "$REPO_ROOT/.gitignore" 2>/dev/null; then
    echo "" >> "$REPO_ROOT/.gitignore"
    echo "# Dev discipline diary (local, auto-generated)" >> "$REPO_ROOT/.gitignore"
    echo ".dev/diary/" >> "$REPO_ROOT/.gitignore"
    echo "✅ Added .dev/diary/ to .gitignore"
  fi
else
  # Create .gitignore with diary entry
  echo "# Dev discipline diary (local, auto-generated)" > "$REPO_ROOT/.gitignore"
  echo ".dev/diary/" >> "$REPO_ROOT/.gitignore"
  echo "✅ Created .gitignore with .dev/diary/"
fi

# Bridge into AGENTS.md (for Codex CLI and other AGENTS.md-aware tools)
AGENTS_FILE="$REPO_ROOT/AGENTS.md"
BRIDGE_LINE="Before any code changes, read \`.dev/contract.md\` and follow its rules."
if [ -f "$AGENTS_FILE" ]; then
  if ! grep -qF '.dev/contract.md' "$AGENTS_FILE" 2>/dev/null; then
    echo "" >> "$AGENTS_FILE"
    echo "## Dev Discipline" >> "$AGENTS_FILE"
    echo "" >> "$AGENTS_FILE"
    echo "$BRIDGE_LINE" >> "$AGENTS_FILE"
    echo "✅ Added contract reference to AGENTS.md"
  else
    echo "✅ AGENTS.md already references contract"
  fi
fi

# Bridge into CLAUDE.md (for Claude Code)
CLAUDE_FILE="$REPO_ROOT/CLAUDE.md"
CLAUDE_BRIDGE="@.dev/contract.md"
if [ -f "$CLAUDE_FILE" ]; then
  if ! grep -qF '.dev/contract.md' "$CLAUDE_FILE" 2>/dev/null; then
    echo "" >> "$CLAUDE_FILE"
    echo "$CLAUDE_BRIDGE" >> "$CLAUDE_FILE"
    echo "✅ Added contract import to CLAUDE.md"
  else
    echo "✅ CLAUDE.md already references contract"
  fi
fi

# Create Claude Code rule if .claude/ exists
CLAUDE_RULES_DIR="$REPO_ROOT/.claude/rules"
if [ -d "$REPO_ROOT/.claude" ]; then
  mkdir -p "$CLAUDE_RULES_DIR"
  if [ ! -f "$CLAUDE_RULES_DIR/dev-discipline.md" ]; then
    cat > "$CLAUDE_RULES_DIR/dev-discipline.md" << 'EOF'
---
paths:
  - "**/*"
---

# Dev Discipline

Read and follow `.dev/contract.md` before making any code changes.
All commits must use conventional format with a `why:` line.
One concern per commit. Behavioral changes require tests.
Never use `--no-verify`.
EOF
    echo "✅ Created .claude/rules/dev-discipline.md"
  else
    echo "✅ .claude/rules/dev-discipline.md already exists"
  fi
fi

echo ""
echo "🎉 Dev discipline installed."
echo "   Contract:  .dev/contract.md"
echo "   Diary:     .dev/diary/ (gitignored)"
echo "   Decisions: .dev/decisions/ (tracked)"
echo "   Worklog:   .dev/WORKLOG.md (tracked)"
