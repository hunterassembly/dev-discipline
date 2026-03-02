#!/usr/bin/env bash
set -euo pipefail

# Lists docs and validates lightweight front matter contracts.
# Usage:
#   docs-list.sh            # uses ./docs
#   docs-list.sh path/to/docs

DOCS_DIR="${1:-docs}"
ERRORS=0

if [ ! -d "$DOCS_DIR" ]; then
  echo "No docs directory at '$DOCS_DIR'. Nothing to validate."
  exit 0
fi

echo "Listing markdown docs in '$DOCS_DIR'..."

while IFS= read -r file; do
  rel_path="$file"
  case "$rel_path" in
    "$DOCS_DIR"/*) rel_path="${rel_path#"$DOCS_DIR"/}" ;;
  esac

  first_line=$(sed -n '1p' "$file")
  if [ "$first_line" != "---" ]; then
    echo "$rel_path - [missing front matter]"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  frontmatter_end=$(awk 'NR>1 && /^---[[:space:]]*$/ { print NR; exit }' "$file")
  if [ -z "$frontmatter_end" ]; then
    echo "$rel_path - [unterminated front matter]"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  frontmatter=$(sed -n "2,$((frontmatter_end - 1))p" "$file")
  summary=$(printf "%s\n" "$frontmatter" | sed -n 's/^summary:[[:space:]]*//p' | head -n 1)
  summary=$(printf "%s" "$summary" | sed "s/^['\"]//; s/['\"]$//")

  if [ -z "$summary" ]; then
    echo "$rel_path - [summary missing]"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if ! printf "%s\n" "$frontmatter" | grep -q '^read_when:[[:space:]]*'; then
    echo "$rel_path - [read_when missing]"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if printf "%s\n" "$frontmatter" | grep -q '^read_when:[[:space:]]*\[[[:space:]]*\]'; then
    echo "$rel_path - [read_when empty]"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo "$rel_path - $summary"
done < <(find "$DOCS_DIR" -type f -name '*.md' ! -path '*/archive/*' ! -path '*/research/*' | LC_ALL=C sort)

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "docs-list failed: $ERRORS file(s) need front matter fixes."
  echo "Expected keys: summary, read_when."
  exit 1
fi

echo ""
echo "docs-list passed."
