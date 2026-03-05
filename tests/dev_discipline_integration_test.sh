#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "PASS: $1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "FAIL: $1"
}

assert_file_exists() {
  local path="$1"
  [ -f "$path" ]
}

test_bootstrap_installs_planner_and_scaffold() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  if HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_bootstrap.log 2>&1 \
    && assert_file_exists "$tmp_home/.agents/skills/planner/SKILL.md" \
    && assert_file_exists "$tmp_repo/.agent/PLANS.md" \
    && assert_file_exists "$tmp_repo/docs/plans/active/plan-template.md"; then
    pass "bootstrap installs planner and scaffolds plan files"
  else
    fail "bootstrap installs planner and scaffolds plan files"
  fi
}

test_pre_commit_blocks_large_source_change_without_plan_update() {
  local tmp_home tmp_repo hook_output hook_code
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_hook_bootstrap.log 2>&1

  (
    cd "$tmp_repo"
    for i in 1 2 3 4 5; do
      echo "const v$i = $i;" > "feature_$i.ts"
      git add "feature_$i.ts"
    done
    set +e
    hook_output=$(.git/hooks/pre-commit 2>&1)
    hook_code=$?
    set -e
    echo "$hook_output" > /tmp/devdisc_test_hook_output.log
    if [ "$hook_code" -ne 0 ] && echo "$hook_output" | grep -q "requires an execution plan update"; then
      exit 0
    fi
    exit 1
  ) && pass "pre-commit blocks significant source changes without plan updates" \
    || fail "pre-commit blocks significant source changes without plan updates"
}

test_planner_validator_checks_quality_rules() {
  local tmp_home tmp_repo validator
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_planner_bootstrap.log 2>&1

  validator="$tmp_home/.agents/skills/planner/scripts/validate-plan.sh"
  cp "$tmp_repo/docs/plans/active/plan-template.md" "$tmp_repo/docs/plans/active/bad-plan.md"
  sed -i.bak '/^User benefit:/d' "$tmp_repo/docs/plans/active/bad-plan.md"
  sed -i.bak 's/Describe rollback, retry, and safe re-run strategy for interrupted execution./Document routine operations only./' "$tmp_repo/docs/plans/active/bad-plan.md"
  rm -f "$tmp_repo/docs/plans/active/"*.bak

  if (cd "$tmp_repo" && "$validator" docs/plans/active/bad-plan.md >/tmp/devdisc_test_planner_output.log 2>&1); then
    fail "planner validator enforces user-benefit and recovery quality"
  else
    if grep -q "User benefit" /tmp/devdisc_test_planner_output.log && grep -q "Idempotence and Recovery" /tmp/devdisc_test_planner_output.log; then
      pass "planner validator enforces user-benefit and recovery quality"
    else
      fail "planner validator enforces user-benefit and recovery quality"
    fi
  fi
}

test_sync_plan_template_detects_drift() {
  local tmp_home tmp_repo sync_script
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_sync_bootstrap.log 2>&1
  sync_script="$tmp_home/.agents/skills/dev-discipline/scripts/sync-plan-template.sh"

  echo "drift" >> "$tmp_repo/docs/plans/active/plan-template.md"
  if (cd "$tmp_repo" && "$sync_script" --check >/tmp/devdisc_test_sync_output.log 2>&1); then
    fail "sync-plan-template detects drift in check mode"
  else
    if grep -q "drift detected" /tmp/devdisc_test_sync_output.log; then
      pass "sync-plan-template detects drift in check mode"
    else
      fail "sync-plan-template detects drift in check mode"
    fi
  fi
}

test_migrate_planner_updates_legacy_references() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_migrate_bootstrap.log 2>&1
  mkdir -p "$tmp_home/.agents/skills/exec-plan-discipline"
  echo "legacy" > "$tmp_home/.agents/skills/exec-plan-discipline/marker.txt"
  mkdir -p "$tmp_repo/.agent"
  cat > "$tmp_repo/.agent/PLANS.md" << 'EOF'
Use ~/.agents/skills/exec-plan-discipline/scripts/validate-plan.sh
EOF

  if (cd "$tmp_repo" && HOME="$tmp_home" "$REPO_ROOT/scripts/migrate-planner.sh" >/tmp/devdisc_test_migrate_output.log 2>&1) \
    && [ -d "$tmp_home/.agents/skills/planner" ] \
    && [ ! -d "$tmp_home/.agents/skills/exec-plan-discipline" ] \
    && grep -q "skills/planner/scripts/validate-plan.sh" "$tmp_repo/.agent/PLANS.md"; then
    pass "migrate-planner updates legacy skill directory and references"
  else
    fail "migrate-planner updates legacy skill directory and references"
  fi
}

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
    fail "commit-msg rejects short why line (code=$hook_code)"
  fi
}

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
    fail "commit-msg rejects parrot why line (code=$hook_code)"
  fi
}

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
    fail "commit-msg rejects filler why line (code=$hook_code)"
  fi
}

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

test_reconcile_script_references_findings() {
  if grep -q "FINDINGS" "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile.sh"; then
    pass "reconcile.sh references FINDINGS extraction"
  else
    fail "reconcile.sh references FINDINGS extraction"
  fi
}

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

test_pre_commit_does_not_overwrite_existing_plan() {
  local tmp_home tmp_repo hook_output
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git checkout -b feat/existing-plan >/dev/null 2>&1
    mkdir -p docs/plans/active
    echo "# My existing plan" > docs/plans/active/existing-plan.md
    for i in 1 2 3 4 5; do
      echo "const v$i = $i;" > "feature_$i.ts"
      git add "feature_$i.ts"
    done
    set +e
    hook_output=$(.git/hooks/pre-commit 2>&1)
    set -e

    # Should NOT overwrite, and content should still be original
    if grep -q "My existing plan" docs/plans/active/existing-plan.md && echo "$hook_output" | grep -qi "update and stage"; then
      exit 0
    fi
    echo "OUTPUT: $hook_output" >&2
    exit 1
  ) && pass "pre-commit does not overwrite existing plan" \
    || fail "pre-commit does not overwrite existing plan"
}

test_setup_creates_learnings_directory() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  if [ -d "$tmp_repo/.dev/learnings" ]; then
    pass "setup creates .dev/learnings/ directory"
  else
    fail "setup creates .dev/learnings/ directory"
  fi
}

test_reconcile_script_archives_resolved_findings() {
  if grep -q "learnings" "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile.sh" \
    && grep -q "RESOLVED" "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile.sh"; then
    pass "reconcile.sh archives resolved findings to learnings"
  else
    fail "reconcile.sh archives resolved findings to learnings"
  fi
}

test_contract_has_protected_artifacts_rule() {
  if grep -q "Never delete or suggest removing" "$REPO_ROOT/skills/dev-discipline/assets/contract.md"; then
    pass "contract.md has protected artifacts rule"
  else
    fail "contract.md has protected artifacts rule"
  fi
}

test_bootstrap_installs_planner_and_scaffold
test_pre_commit_blocks_large_source_change_without_plan_update
test_planner_validator_checks_quality_rules
test_sync_plan_template_detects_drift
test_migrate_planner_updates_legacy_references
test_commit_msg_rejects_short_why_line
test_commit_msg_rejects_parrot_why_line
test_commit_msg_rejects_filler_why_line
test_commit_msg_accepts_good_why_line
test_reconcile_script_references_findings
test_pre_commit_scaffolds_plan_on_block
test_pre_commit_scaffolds_plan_with_timestamp_on_main
test_pre_commit_does_not_overwrite_existing_plan
test_setup_creates_learnings_directory
test_reconcile_script_archives_resolved_findings
test_contract_has_protected_artifacts_rule

echo ""
echo "Test results: $PASS_COUNT passed, $FAIL_COUNT failed"
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
