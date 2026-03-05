#!/usr/bin/env bash
set -euo pipefail

# Local docs drift scanner.
# Default: scans commit activity from the last 24 hours and writes a checklist report.
#
# Usage:
#   doc-gardener.sh
#   doc-gardener.sh --since "72 hours ago"
#   doc-gardener.sh --since "8 hours ago" --report docs/quality/custom-report.md

SINCE="24 hours ago"
REPORT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      if [[ $# -lt 2 ]]; then
        echo "❌ --since requires a value."
        exit 1
      fi
      SINCE="$2"
      shift 2
      ;;
    --report)
      if [[ $# -lt 2 ]]; then
        echo "❌ --report requires a value."
        exit 1
      fi
      REPORT_PATH="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: doc-gardener.sh [--since \"24 hours ago\"] [--report docs/quality/file.md]"
      exit 1
      ;;
  esac
done

DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="docs/quality"
if [ -z "$REPORT_PATH" ]; then
  REPORT_PATH="$OUTPUT_DIR/doc-gardener-$DATE.md"
fi

mkdir -p "$OUTPUT_DIR"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCS_LIST="$SCRIPT_DIR/docs-list.sh"

DOCS_LIST_OK=true
DOCS_LIST_OUTPUT="docs-list not available"
if [ -x "$DOCS_LIST" ]; then
  if DOCS_LIST_OUTPUT=$("$DOCS_LIST" 2>&1); then
    DOCS_LIST_OK=true
  else
    DOCS_LIST_OK=false
  fi
fi

CHANGED_FILES=$(git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | sed '/^$/d' | sort -u || true)

if [ -z "$CHANGED_FILES" ]; then
  SOURCE_COUNT=0
  TEST_COUNT=0
  DOC_COUNT=0
  PLAN_COUNT=0
  DECISION_COUNT=0
  EVAL_COUNT=0
else
  SOURCE_COUNT=$(printf "%s\n" "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx|py|rb|go|rs|java|swift|kt|m|mm|c|cc|cpp|h)$' | grep -Ev '(test|spec|_test|\.test\.|\.spec\.)' | wc -l | tr -d ' ' || true)
  TEST_COUNT=$(printf "%s\n" "$CHANGED_FILES" | grep -Ei '(test|spec|_test|\.test\.|\.spec\.)' | wc -l | tr -d ' ' || true)
  DOC_COUNT=$(printf "%s\n" "$CHANGED_FILES" | grep -E '(^docs/|README\.md$|CHANGELOG\.md$|\.md$)' | wc -l | tr -d ' ' || true)
  PLAN_COUNT=$(printf "%s\n" "$CHANGED_FILES" | grep -E '^docs/plans/' | wc -l | tr -d ' ' || true)
  DECISION_COUNT=$(printf "%s\n" "$CHANGED_FILES" | grep -E '^\.dev/decisions/' | wc -l | tr -d ' ' || true)
  EVAL_COUNT=$(printf "%s\n" "$CHANGED_FILES" | grep -E '^evals/' | wc -l | tr -d ' ' || true)
fi

if [ "$SOURCE_COUNT" -eq 0 ]; then
  DOC_COVERAGE=100
else
  DOC_COVERAGE=$((DOC_COUNT * 100 / SOURCE_COUNT))
  if [ "$DOC_COVERAGE" -gt 100 ]; then
    DOC_COVERAGE=100
  fi
fi

if [ "$SOURCE_COUNT" -gt 0 ] && [ "$PLAN_COUNT" -eq 0 ]; then
  PLAN_HYGIENE=60
else
  PLAN_HYGIENE=100
fi

if [ "$SOURCE_COUNT" -gt 0 ] && [ "$DECISION_COUNT" -eq 0 ]; then
  DECISION_SIGNAL=85
else
  DECISION_SIGNAL=100
fi

if [ "$SOURCE_COUNT" -gt 0 ] && [ "$EVAL_COUNT" -eq 0 ]; then
  EVAL_SIGNAL=70
else
  EVAL_SIGNAL=100
fi

OVERALL=$(((DOC_COVERAGE + PLAN_HYGIENE + DECISION_SIGNAL + EVAL_SIGNAL) / 4))

{
  echo "---"
  echo "summary: \"Local docs drift report and quality snapshot ($DATE).\""
  echo "read_when:"
  echo "  - Ending a coding session and checking docs/plan drift."
  echo "---"
  echo
  echo "# Doc Gardener Report — $DATE"
  echo
  echo "## Inputs"
  echo
  echo "- Since: \`$SINCE\`"
  echo "- Source files changed: $SOURCE_COUNT"
  echo "- Test files changed: $TEST_COUNT"
  echo "- Docs files changed: $DOC_COUNT"
  echo "- Plan files changed: $PLAN_COUNT"
  echo "- Decision files changed: $DECISION_COUNT"
  echo "- Eval files changed: $EVAL_COUNT"
  echo
  echo "## Quality Snapshot"
  echo
  echo "- Overall: **$OVERALL/100**"
  echo "- Docs coverage signal: **$DOC_COVERAGE/100**"
  echo "- Plan hygiene signal: **$PLAN_HYGIENE/100**"
  echo "- Decision log signal: **$DECISION_SIGNAL/100**"
  echo "- Eval coverage signal: **$EVAL_SIGNAL/100**"
  echo
  echo "## Checklist"
  echo

  if [ "$SOURCE_COUNT" -gt 0 ] && [ "$DOC_COUNT" -eq 0 ]; then
    echo "- [ ] Source files changed but no docs changed. Add or update docs."
  else
    echo "- [x] Docs updates present or no source changes."
  fi

  if [ "$SOURCE_COUNT" -gt 0 ] && [ "$PLAN_COUNT" -eq 0 ]; then
    echo "- [ ] No plan artifact changed under \`docs/plans/\`. Add or update plan status."
  else
    echo "- [x] Plan artifacts updated or no source changes."
  fi

  if [ "$SOURCE_COUNT" -gt 0 ] && [ "$DECISION_COUNT" -eq 0 ]; then
    echo "- [ ] No decision record updates detected. If architecture changed, log a decision in \`.dev/decisions/\`."
  else
    echo "- [x] Decision records updated or not needed in this range."
  fi

  if [ "$SOURCE_COUNT" -gt 0 ] && [ "$EVAL_COUNT" -eq 0 ]; then
    echo "- [ ] No eval updates detected under \`evals/\`. Add or update eval cases/rubrics for new behavior."
  else
    echo "- [x] Eval artifacts updated or not needed in this range."
  fi

  if [ "$DOCS_LIST_OK" = false ]; then
    echo "- [ ] \`docs-list\` checks failed. Fix docs front matter before handoff."
  else
    echo "- [x] \`docs-list\` checks passed."
  fi

  echo
  echo "## Notes"
  echo
  echo "Update \`docs/QUALITY_SCORE.md\` with this snapshot if it reflects your current project state."
} > "$REPORT_PATH"

echo "✅ Doc gardener report written to $REPORT_PATH"
echo "Snapshot: overall=$OVERALL docs=$DOC_COVERAGE plan=$PLAN_HYGIENE decision=$DECISION_SIGNAL eval=$EVAL_SIGNAL"

if [ "$DOCS_LIST_OK" = false ]; then
  echo ""
  echo "$DOCS_LIST_OUTPUT"
  exit 1
fi
