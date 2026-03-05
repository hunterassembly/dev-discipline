#!/usr/bin/env bash
set -euo pipefail

# Validate execution plans against Codex Exec Plans-required sections.
#
# Usage:
#   validate-plan.sh docs/plans/active/my-plan.md
#   validate-plan.sh docs/plans/active/*.md
#   validate-plan.sh                     # validates all active plans except README/template

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

err()  { echo -e "${RED}❌ $1${NC}"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; WARNINGS=$((WARNINGS + 1)); }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }

required_headings=(
  "Purpose / Big Picture"
  "Progress"
  "Surprises & Discoveries"
  "Decision Log"
  "Outcomes & Retrospective"
  "Context and Orientation"
  "Plan of Work"
  "Architecture Impact"
  "Concrete Steps"
  "Validation and Acceptance"
  "Idempotence and Recovery"
  "Artifacts and Notes"
  "Interfaces and Dependencies"
)

has_heading() {
  local file="$1"
  local heading="$2"
  grep -qiE "^#{2,3}[[:space:]]+${heading}[[:space:]]*$" "$file"
}

extract_section() {
  local file="$1"
  local section="$2"
  awk -v section="$section" '
    BEGIN { in_section = 0 }
    $0 ~ "^##[[:space:]]+" section "[[:space:]]*$" { in_section = 1; next }
    in_section && $0 ~ "^##[[:space:]]+" { in_section = 0 }
    in_section { print }
  ' "$file"
}

section_non_empty() {
  local content="$1"
  # Remove whitespace-only lines and markdown list markers before counting.
  local stripped
  stripped=$(printf "%s\n" "$content" | sed 's/^[[:space:]-]*//g' | sed '/^[[:space:]]*$/d')
  [ -n "$stripped" ]
}

validate_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    err "$file does not exist"
    return
  fi

  local file_errors_before="$ERRORS"
  echo "Validating: $file"

  for heading in "${required_headings[@]}"; do
    if ! has_heading "$file" "$heading"; then
      err "$file missing required section: $heading"
    fi
  done

  for section in \
    "Purpose / Big Picture" \
    "Context and Orientation" \
    "Plan of Work" \
    "Architecture Impact" \
    "Validation and Acceptance" \
    "Idempotence and Recovery"; do
    section_body=$(extract_section "$file" "$section")
    if ! section_non_empty "$section_body"; then
      err "$file has empty section: $section"
    fi
  done

  if ! grep -qE '^- \[[ xX]\]' "$file"; then
    warn "$file should include checklist items under Progress"
  fi

  progress_body=$(extract_section "$file" "Progress")
  progress_items=$(printf "%s\n" "$progress_body" | grep -E '^- \[[ xX]\]' | wc -l | tr -d ' ' || true)
  progress_dated=$(printf "%s\n" "$progress_body" | grep -E '^[[:space:]]*-[[:space:]]\[[ xX]\][[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}' | wc -l | tr -d ' ' || true)
  if [ "$progress_items" -lt 2 ]; then
    warn "$file should have at least two progress checklist entries"
  fi
  if [ "$progress_items" -gt 0 ] && [ "$progress_dated" -eq 0 ]; then
    warn "$file progress entries should include dates (YYYY-MM-DD ...)"
  fi

  local concrete_steps
  concrete_steps=$(extract_section "$file" "Concrete Steps")
  local step_count
  step_count=$(printf "%s\n" "$concrete_steps" | grep -E '^[0-9]+\.[[:space:]]' | wc -l | tr -d ' ' || true)
  local benefit_count
  benefit_count=$(printf "%s\n" "$concrete_steps" | grep -E '^User benefit:' | wc -l | tr -d ' ' || true)

  if [ "$step_count" -gt 0 ] && [ "$benefit_count" -lt "$step_count" ]; then
    err "$file has $step_count concrete step(s) but only $benefit_count 'User benefit:' line(s)"
  fi

  validation_body=$(extract_section "$file" "Validation and Acceptance")
  validation_checks=$(printf "%s\n" "$validation_body" | grep -E '^- \[[ xX]\]' | wc -l | tr -d ' ' || true)
  if [ "$validation_checks" -eq 0 ]; then
    err "$file should include checklist acceptance checks under Validation and Acceptance"
  fi

  architecture_impact_body=$(extract_section "$file" "Architecture Impact")
  if ! printf "%s\n" "$architecture_impact_body" | grep -qiE '(yes|no)'; then
    warn "$file Architecture Impact should explicitly state if ARCHITECTURE.md update is needed (yes/no)"
  fi

  recovery_body=$(extract_section "$file" "Idempotence and Recovery")
  if ! printf "%s\n" "$recovery_body" | grep -qiE '(rollback|retry|recover|idempotent)'; then
    err "$file Idempotence and Recovery should mention rollback, retry, recovery, or idempotence strategy"
  fi

  if [ "$ERRORS" -eq "$file_errors_before" ]; then
    ok "$file passed execution-plan checks"
  fi
}

declare -a files
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    files+=("$arg")
  done
else
  while IFS= read -r f; do
    files+=("$f")
  done < <(find docs/plans/active -maxdepth 1 -type f -name '*.md' ! -name 'README.md' ! -name 'plan-template.md' | LC_ALL=C sort)
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "No plan files to validate."
  exit 0
fi

for f in "${files[@]}"; do
  validate_file "$f"
done

if [ "$WARNINGS" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Execution plan validation: $WARNINGS warning(s), $ERRORS error(s)"
fi

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
