---
summary: "Implementation plan for three dev-discipline improvements."
read_when:
  - Working on why-line validation, reconciliation feedback loop, or plan auto-scaffold.
---

# Three Discipline Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix three gaps in dev-discipline: gameable `why:` lines, no reconciliation feedback loop, and unhelpful plan-required error path.

**Architecture:** All changes are shell-only in existing hook/script files plus minor doc updates. No new dependencies. New tracked file `.dev/FINDINGS.md` added to the enforcement surface.

**Tech Stack:** Bash, git hooks, markdown templates

---

## Task 1: `why:` line quality validation in commit-msg hook

**Files:**
- Modify: `skills/dev-discipline/assets/commit-msg:41-49` (after existing why check)

**Step 1: Write failing test — why line too short**

Add to `tests/dev_discipline_integration_test.sh`:

```bash
test_commit_msg_rejects_short_why_line() {
  local tmp_repo hook_output hook_code
  tmp_repo=$(mktemp -d)
  git init "$tmp_repo" >/dev/null 2>&1

  local hook_src="$REPO_ROOT/skills/dev-discipline/assets/commit-msg"
  cp "$hook_src" "$tmp_repo/.git/hooks/commit-msg"
  chmod +x "$tmp_repo/.git/hooks/commit-msg"

  local msg_file="$tmp_repo/.git/COMMIT_EDITMSG"
  printf 'feat(x): add thing\n\nwhy: needed' > "$msg_file"

  set +e
  hook_output=$("$tmp_repo/.git/hooks/commit-msg" "$msg_file" 2>&1)
  hook_code=$?
  set -e

  if [ "$hook_code" -ne 0 ] && echo "$hook_output" | grep -qi "too short"; then
    pass "commit-msg rejects short why line"
  else
    fail "commit-msg rejects short why line (code=$hook_code, output=$hook_output)"
  fi
}
```

**Step 2: Run test to verify it fails**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: FAIL on "commit-msg rejects short why line"

**Step 3: Write failing test — why line parrots subject**

Add to `tests/dev_discipline_integration_test.sh`:

```bash
test_commit_msg_rejects_parrot_why_line() {
  local tmp_repo hook_output hook_code
  tmp_repo=$(mktemp -d)
  git init "$tmp_repo" >/dev/null 2>&1

  local hook_src="$REPO_ROOT/skills/dev-discipline/assets/commit-msg"
  cp "$hook_src" "$tmp_repo/.git/hooks/commit-msg"
  chmod +x "$tmp_repo/.git/hooks/commit-msg"

  local msg_file="$tmp_repo/.git/COMMIT_EDITMSG"
  printf 'feat(auth): add rate limiting\n\nwhy: add rate limiting' > "$msg_file"

  set +e
  hook_output=$("$tmp_repo/.git/hooks/commit-msg" "$msg_file" 2>&1)
  hook_code=$?
  set -e

  if [ "$hook_code" -ne 0 ] && echo "$hook_output" | grep -qi "restates"; then
    pass "commit-msg rejects parrot why line"
  else
    fail "commit-msg rejects parrot why line (code=$hook_code, output=$hook_output)"
  fi
}
```

**Step 4: Run test to verify it fails**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: FAIL on "commit-msg rejects parrot why line"

**Step 5: Write failing test — why line uses filler phrase**

Add to `tests/dev_discipline_integration_test.sh`:

```bash
test_commit_msg_rejects_filler_why_line() {
  local tmp_repo hook_output hook_code
  tmp_repo=$(mktemp -d)
  git init "$tmp_repo" >/dev/null 2>&1

  local hook_src="$REPO_ROOT/skills/dev-discipline/assets/commit-msg"
  cp "$hook_src" "$tmp_repo/.git/hooks/commit-msg"
  chmod +x "$tmp_repo/.git/hooks/commit-msg"

  local msg_file="$tmp_repo/.git/COMMIT_EDITMSG"
  printf 'feat(x): add thing\n\nwhy: because it was needed' > "$msg_file"

  set +e
  hook_output=$("$tmp_repo/.git/hooks/commit-msg" "$msg_file" 2>&1)
  hook_code=$?
  set -e

  if [ "$hook_code" -ne 0 ] && echo "$hook_output" | grep -qi "filler"; then
    pass "commit-msg rejects filler why line"
  else
    fail "commit-msg rejects filler why line (code=$hook_code, output=$hook_output)"
  fi
}
```

**Step 6: Write failing test — valid why line passes**

```bash
test_commit_msg_accepts_good_why_line() {
  local tmp_repo hook_output hook_code
  tmp_repo=$(mktemp -d)
  git init "$tmp_repo" >/dev/null 2>&1

  local hook_src="$REPO_ROOT/skills/dev-discipline/assets/commit-msg"
  cp "$hook_src" "$tmp_repo/.git/hooks/commit-msg"
  chmod +x "$tmp_repo/.git/hooks/commit-msg"

  local msg_file="$tmp_repo/.git/COMMIT_EDITMSG"
  printf 'feat(search): add fuzzy matching for typo tolerance\n\nwhy: users frequently misspell product names, losing 12%% of searches' > "$msg_file"

  set +e
  hook_output=$("$tmp_repo/.git/hooks/commit-msg" "$msg_file" 2>&1)
  hook_code=$?
  set -e

  if [ "$hook_code" -eq 0 ]; then
    pass "commit-msg accepts good why line"
  else
    fail "commit-msg accepts good why line (code=$hook_code, output=$hook_output)"
  fi
}
```

**Step 7: Implement why-line quality checks in commit-msg hook**

In `skills/dev-discipline/assets/commit-msg`, after the existing `why:` presence check (around line 41), add:

```bash
# --- 4. Why line quality ---
WHY_LINE=$(echo "$MSG" | grep -E '^why: .+' | head -1)
if [ -n "$WHY_LINE" ]; then
  WHY_BODY="${WHY_LINE#why: }"
  WHY_LEN=${#WHY_BODY}

  # Minimum length
  if [ "$WHY_LEN" -lt 10 ]; then
    echo -e "${RED}❌ why: line is too short ($WHY_LEN chars, minimum 10).${NC}"
    echo "   The why: should explain motivation, not just restate the change."
    ERRORS=$((ERRORS + 1))
  fi

  # No parrot — why body can't match the subject description
  SUBJECT_DESC=$(echo "$FIRST_LINE" | sed 's/^[a-z]*\([^)]*\)\?: //')
  SUBJECT_LOWER=$(echo "$SUBJECT_DESC" | tr '[:upper:]' '[:lower:]')
  WHY_LOWER=$(echo "$WHY_BODY" | tr '[:upper:]' '[:lower:]')
  if [ "$WHY_LOWER" = "$SUBJECT_LOWER" ]; then
    echo -e "${RED}❌ why: line restates the commit subject. Explain the motivation, not the change.${NC}"
    ERRORS=$((ERRORS + 1))
  fi

  # No filler phrases
  case "$WHY_LOWER" in
    "because it was needed"|"it needed to change"|"needed"|"update"|"fix"|"changes"|"necessary change"|"required")
      echo -e "${RED}❌ why: line uses a filler phrase. Be specific about the motivation.${NC}"
      ERRORS=$((ERRORS + 1))
      ;;
  esac
fi
```

**Step 8: Run all tests to verify they pass**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: All four new tests PASS, all existing tests still PASS

**Step 9: Commit**

```
feat(hooks): add why-line quality validation to commit-msg hook

why: agents game the why: requirement with generic text like "needed" or by restating the subject line
```

---

## Task 2: Reconciliation feedback loop via `.dev/FINDINGS.md`

**Files:**
- Modify: `skills/dev-reconciliation/scripts/reconcile.sh` (extract findings after report)
- Modify: `skills/dev-discipline/SKILL.md` (add FINDINGS.md to "Before You Start")
- Modify: `skills/dev-discipline/assets/contract.md` (add FINDINGS.md to process)
- Modify: `skills/dev-discipline/scripts/setup.sh` (ensure .dev/FINDINGS.md not gitignored)

**Step 1: Write failing test — reconcile.sh produces FINDINGS.md**

Add to `tests/dev_discipline_integration_test.sh`:

```bash
test_reconcile_produces_findings_file() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    echo "const x = 1;" > feature.ts
    git add feature.ts
    git commit --no-verify -m "$(printf 'feat(x): add feature\n\nwhy: initial feature for testing')" >/dev/null 2>&1
  )

  local reconcile_script="$tmp_home/.agents/skills/dev-reconciliation/scripts/reconcile.sh"
  if [ ! -x "$reconcile_script" ]; then
    chmod +x "$reconcile_script"
  fi

  (cd "$tmp_repo" && "$reconcile_script" --since "1 hour ago" --dry-run >/dev/null 2>&1)

  # In dry-run mode we can't test actual findings output, so test the prompt includes findings extraction instruction
  if grep -q "FINDINGS" "$reconcile_script"; then
    pass "reconcile.sh references FINDINGS extraction"
  else
    fail "reconcile.sh references FINDINGS extraction"
  fi
}
```

**Step 2: Run test to verify it fails**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: FAIL

**Step 3: Implement findings extraction in reconcile.sh**

After the agent produces the report and saves it to `$OUTPUT` (around line 178), add:

```bash
# Extract open findings into .dev/FINDINGS.md (tracked, read by next session)
FINDINGS_FILE="$REPO_ROOT/.dev/FINDINGS.md"
FINDINGS_TMP=$(mktemp)
trap 'rm -f "$DIFF_TMP" "$DIARY_AGG_TMP" "$FINDINGS_TMP"' EXIT

cat > "$FINDINGS_TMP" << FEOF
# Open Findings

Last updated: $DATE from reconciliation-$DATE.md

FEOF

# Extract sections from the reconciliation report
for section in "Test Gaps" "Doc Updates Needed" "Decisions to Document"; do
  SECTION_CONTENT=$(sed -n "/^## $section/,/^## /{ /^## $section/d; /^## /d; p; }" "$OUTPUT" 2>/dev/null | sed '/^$/d' || true)
  if [ -n "$SECTION_CONTENT" ]; then
    printf "## %s\n%s\n\n" "$section" "$SECTION_CONTENT" >> "$FINDINGS_TMP"
  fi
done

# Only write if there are actual findings (more than just the header)
FINDINGS_LINE_COUNT=$(wc -l < "$FINDINGS_TMP" | tr -d ' ')
if [ "$FINDINGS_LINE_COUNT" -gt 4 ]; then
  cp "$FINDINGS_TMP" "$FINDINGS_FILE"
  echo "📋 Open findings written to .dev/FINDINGS.md"
else
  # No findings — clear the file if it exists
  if [ -f "$FINDINGS_FILE" ]; then
    echo "# Open Findings" > "$FINDINGS_FILE"
    echo "" >> "$FINDINGS_FILE"
    echo "No open findings as of $DATE." >> "$FINDINGS_FILE"
    echo "✅ No open findings — .dev/FINDINGS.md cleared"
  fi
fi
```

**Step 4: Run test to verify it passes**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: PASS

**Step 5: Update SKILL.md — add FINDINGS.md to Before You Start**

In `skills/dev-discipline/SKILL.md`, in the "Before You Start" section, add after step 2:

```
3. Check `.dev/FINDINGS.md` for open items from previous reconciliation. Address before starting new work.
```

Renumber remaining steps.

**Step 6: Update contract.md — add FINDINGS.md to process**

In `skills/dev-discipline/assets/contract.md`, add to the Process section after "Think":

```
0. **Check** — Read `.dev/FINDINGS.md` if it exists. Resolve open items first.
```

**Step 7: Run all tests**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: All PASS

**Step 8: Commit**

```
feat(reconciliation): extract open findings to tracked .dev/FINDINGS.md

why: reconciliation reports were write-only — no feedback loop into the next agent session
```

---

## Task 3: Plan auto-scaffold on pre-commit block

**Files:**
- Modify: `skills/dev-discipline/assets/pre-commit:83-87` (the plan-required error block)

**Step 1: Write failing test — pre-commit scaffolds plan on block**

Add to `tests/dev_discipline_integration_test.sh`:

```bash
test_pre_commit_scaffolds_plan_on_block() {
  local tmp_home tmp_repo hook_output
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git checkout -b feat/cool-feature >/dev/null 2>&1
    for i in 1 2 3 4 5; do
      echo "const v$i = $i;" > "feature_$i.ts"
      git add "feature_$i.ts"
    done
    set +e
    hook_output=$(.git/hooks/pre-commit 2>&1)
    set -e

    if [ -f "docs/plans/active/cool-feature.md" ] && echo "$hook_output" | grep -q "Scaffolded"; then
      exit 0
    fi
    echo "OUTPUT: $hook_output" >&2
    exit 1
  ) && pass "pre-commit scaffolds plan from template on block" \
    || fail "pre-commit scaffolds plan from template on block"
}
```

**Step 2: Run test to verify it fails**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: FAIL

**Step 3: Write failing test — pre-commit uses timestamp name on main branch**

```bash
test_pre_commit_scaffolds_plan_with_timestamp_on_main() {
  local tmp_home tmp_repo hook_output
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    for i in 1 2 3 4 5; do
      echo "const v$i = $i;" > "feature_$i.ts"
      git add "feature_$i.ts"
    done
    set +e
    hook_output=$(.git/hooks/pre-commit 2>&1)
    set -e

    # Should create a timestamped plan file
    if ls docs/plans/active/plan-*.md >/dev/null 2>&1 && echo "$hook_output" | grep -q "Scaffolded"; then
      exit 0
    fi
    echo "OUTPUT: $hook_output" >&2
    exit 1
  ) && pass "pre-commit scaffolds plan with timestamp on main" \
    || fail "pre-commit scaffolds plan with timestamp on main"
}
```

**Step 4: Write failing test — pre-commit doesn't overwrite existing plan**

```bash
test_pre_commit_does_not_overwrite_existing_plan() {
  local tmp_home tmp_repo hook_output
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git checkout -b feat/existing-plan >/dev/null 2>&1
    echo "# My existing plan" > docs/plans/active/existing-plan.md
    for i in 1 2 3 4 5; do
      echo "const v$i = $i;" > "feature_$i.ts"
      git add "feature_$i.ts"
    done
    set +e
    hook_output=$(.git/hooks/pre-commit 2>&1)
    set -e

    # Should NOT overwrite, and content should still be original
    if grep -q "My existing plan" docs/plans/active/existing-plan.md && echo "$hook_output" | grep -q "update and stage"; then
      exit 0
    fi
    echo "OUTPUT: $hook_output" >&2
    exit 1
  ) && pass "pre-commit does not overwrite existing plan" \
    || fail "pre-commit does not overwrite existing plan"
}
```

**Step 5: Implement plan auto-scaffold in pre-commit hook**

Replace the existing plan-required error block (lines 83-87) with:

```bash
if [ "$SOURCE_FILE_COUNT" -ge "$PLAN_REQUIRED_SOURCE_FILE_COUNT" ] && [ "$PLAN_FILE_COUNT" -eq 0 ]; then
  # Derive plan name from branch
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  case "$BRANCH" in
    main|master|develop|HEAD)
      PLAN_NAME="plan-$(date +%Y-%m-%d)"
      ;;
    *)
      # Strip prefix (feat/, fix/, etc.) and use the rest
      PLAN_NAME=$(echo "$BRANCH" | sed 's|^[a-z]*\/||')
      ;;
  esac
  PLAN_PATH="docs/plans/active/${PLAN_NAME}.md"

  # Find plan template
  PLAN_TEMPLATE=""
  for candidate in \
    "docs/plans/active/plan-template.md" \
    "skills/planner/templates/exec-plan.md" \
    ".agents/skills/planner/templates/exec-plan.md" \
    "$HOME/.agents/skills/planner/templates/exec-plan.md"; do
    if [ -f "$candidate" ]; then
      PLAN_TEMPLATE="$candidate"
      break
    fi
  done

  if [ -f "$PLAN_PATH" ]; then
    # Plan exists but wasn't staged
    err "Significant source change ($SOURCE_FILE_COUNT files) requires an execution plan update. Update and stage existing plan: $PLAN_PATH"
  elif [ -n "$PLAN_TEMPLATE" ]; then
    # Scaffold from template
    mkdir -p "$(dirname "$PLAN_PATH")"
    cp "$PLAN_TEMPLATE" "$PLAN_PATH"
    err "Significant source change ($SOURCE_FILE_COUNT files) requires an execution plan update (docs/plans/active/*.md)."
    echo "   Scaffolded $PLAN_PATH from template."
    echo "   Fill in the required sections, stage it, and re-commit."
  else
    err "Significant source change ($SOURCE_FILE_COUNT files) requires an execution plan update (docs/plans/active/*.md)."
  fi
```

**Step 6: Run all tests**

Run: `bash tests/dev_discipline_integration_test.sh`
Expected: All PASS (new and existing)

**Step 7: Commit**

```
feat(hooks): auto-scaffold plan file when pre-commit blocks for missing plan

why: agents get stuck when plan-required check blocks — they need a concrete file to fill in, not just an error message
```

---

## Task 4: Update docs and run full validation

**Files:**
- Modify: `README.md` (mention FINDINGS.md and why-line quality checks)
- Modify: `CHANGELOG.md` (add entries)

**Step 1: Add FINDINGS.md mention to README's "What Gets Committed?" table**

Add row:
```
| `.dev/FINDINGS.md` | ✅ Yes | Open items from last reconciliation (read by next session) |
```

**Step 2: Add changelog entries**

**Step 3: Run full test suite and health check**

Run: `bash scripts/test.sh`
Expected: All PASS

**Step 4: Commit**

```
docs: document FINDINGS.md, why-line quality checks, and plan auto-scaffold

why: users and agents need to know about the new enforcement behaviors and feedback loop
```
