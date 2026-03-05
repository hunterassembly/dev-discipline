#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for new or overhauled repositories.
# Installs dev-discipline skills to ~/.agents/skills and runs setup in target repo.
#
# Usage:
#   ./scripts/new-project-bootstrap.sh
#   ./scripts/new-project-bootstrap.sh /path/to/target-repo
#   ./scripts/new-project-bootstrap.sh --init-git /path/to/new-repo

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TOOLKIT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SOURCE_SKILLS_DIR="$TOOLKIT_ROOT/skills"
USER_SKILLS_DIR="$HOME/.agents/skills"
TARGET_REPO="$PWD"
INIT_GIT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --init-git)
      INIT_GIT=true
      shift
      ;;
    *)
      TARGET_REPO="$1"
      shift
      ;;
  esac
done

if [ ! -d "$SOURCE_SKILLS_DIR/dev-discipline" ]; then
  echo "Could not find source skills at $SOURCE_SKILLS_DIR"
  exit 1
fi

if [ ! -d "$TARGET_REPO" ]; then
  echo "Target path does not exist: $TARGET_REPO"
  exit 1
fi

if ! git -C "$TARGET_REPO" rev-parse --show-toplevel >/dev/null 2>&1; then
  if [ "$INIT_GIT" = true ]; then
    git -C "$TARGET_REPO" init >/dev/null
    echo "Initialized git repository at $TARGET_REPO"
  else
    echo "Target is not a git repository: $TARGET_REPO"
    echo "Run with --init-git to initialize automatically."
    exit 1
  fi
fi

mkdir -p "$USER_SKILLS_DIR"

install_skill() {
  local skill_name="$1"
  local src="$SOURCE_SKILLS_DIR/$skill_name"
  local dest="$USER_SKILLS_DIR/$skill_name"

  mkdir -p "$dest"
  cp -R "$src/." "$dest/"
  echo "Installed/updated skill: $skill_name -> $dest"
}

for skill_path in "$SOURCE_SKILLS_DIR"/*; do
  if [ -d "$skill_path" ] && [ -f "$skill_path/SKILL.md" ]; then
    install_skill "$(basename "$skill_path")"
  fi
done

for scripts_dir in "$USER_SKILLS_DIR"/*/scripts; do
  if [ -d "$scripts_dir" ]; then
    chmod +x "$scripts_dir"/* 2>/dev/null || true
  fi
done

SETUP_SCRIPT="$USER_SKILLS_DIR/dev-discipline/scripts/setup.sh"
if [ ! -x "$SETUP_SCRIPT" ]; then
  echo "Setup script not executable: $SETUP_SCRIPT"
  exit 1
fi

(
  cd "$TARGET_REPO"
  "$SETUP_SCRIPT"
) >/tmp/dev-discipline-bootstrap-setup.log 2>&1 || {
  cat /tmp/dev-discipline-bootstrap-setup.log
  exit 1
}

echo "Bootstrap complete."
echo "Target repo: $(git -C "$TARGET_REPO" rev-parse --show-toplevel)"
echo "Installed skills at: $USER_SKILLS_DIR"
echo ""
echo "Suggested next checks:"
echo "  ~/.agents/skills/dev-discipline/scripts/docs-list.sh"
echo "  ~/.agents/skills/dev-discipline/scripts/doc-gardener.sh --since \"24 hours ago\""
echo "  ~/.agents/skills/planner/scripts/validate-plan.sh docs/plans/active/<plan>.md"
