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

test_bootstrap_installs_planner_and_scaffold
test_pre_commit_blocks_large_source_change_without_plan_update
test_planner_validator_checks_quality_rules
test_sync_plan_template_detects_drift
test_migrate_planner_updates_legacy_references

echo ""
echo "Test results: $PASS_COUNT passed, $FAIL_COUNT failed"
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
