#!/usr/bin/env bash
set -euo pipefail

# Validate ARCHITECTURE.md has required orientation sections and basic quality.
#
# Usage:
#   validate-architecture.sh
#   validate-architecture.sh /path/to/ARCHITECTURE.md

ARCH_FILE="${1:-ARCHITECTURE.md}"

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
  "System Intent"
  "Architecture at a Glance"
  "Code Map"
  "Runtime Flows"
  "Architectural Invariants"
  "Boundaries and Interfaces"
  "Cross-Cutting Concerns"
  "What We Deliberately Do Not Do"
  "How to Change This Architecture"
)

if [ ! -f "$ARCH_FILE" ]; then
  err "Missing $ARCH_FILE"
fi

has_heading() {
  local heading="$1"
  grep -qiE "^##[[:space:]]+${heading}[[:space:]]*$" "$ARCH_FILE"
}

extract_section() {
  local section="$1"
  awk -v section="$section" '
    BEGIN { in_section = 0 }
    $0 ~ "^##[[:space:]]+" section "[[:space:]]*$" { in_section = 1; next }
    in_section && $0 ~ "^##[[:space:]]+" { in_section = 0 }
    in_section { print }
  ' "$ARCH_FILE"
}

section_non_empty() {
  local content="$1"
  local stripped
  stripped=$(printf "%s\n" "$content" | sed 's/^[[:space:]-]*//g' | sed '/^[[:space:]]*$/d')
  [ -n "$stripped" ]
}

if [ "$ERRORS" -eq 0 ]; then
  for heading in "${required_headings[@]}"; do
    if ! has_heading "$heading"; then
      err "$ARCH_FILE missing required section: $heading"
    fi
  done

  for section in "${required_headings[@]}"; do
    body=$(extract_section "$section")
    if ! section_non_empty "$body"; then
      err "$ARCH_FILE has empty section: $section"
    fi
  done

  code_map=$(extract_section "Code Map")
  code_map_items=$(printf "%s\n" "$code_map" | grep -E '^- ' | wc -l | tr -d ' ' || true)
  if [ "$code_map_items" -lt 2 ]; then
    warn "$ARCH_FILE Code Map should include at least two module/path bullets"
  fi

  invariants=$(extract_section "Architectural Invariants")
  invariant_items=$(printf "%s\n" "$invariants" | grep -E '^- ' | wc -l | tr -d ' ' || true)
  if [ "$invariant_items" -lt 2 ]; then
    warn "$ARCH_FILE Architectural Invariants should include at least two explicit invariants"
  fi

  boundaries=$(extract_section "Boundaries and Interfaces")
  if ! printf "%s\n" "$boundaries" | grep -qiE '(contract|dependency|boundary|interface)'; then
    warn "$ARCH_FILE Boundaries and Interfaces should describe contracts/dependencies explicitly"
  fi
fi

if [ "$ERRORS" -eq 0 ]; then
  ok "$ARCH_FILE passed architecture checks"
fi

if [ "$WARNINGS" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Architecture validation: $WARNINGS warning(s), $ERRORS error(s)"
fi

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
