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

test_pre_commit_blocks_cross_boundary_source_change_without_plan_update() {
  local tmp_home tmp_repo hook_output hook_code
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_hook_bootstrap.log 2>&1

  (
    cd "$tmp_repo"
    mkdir -p src lib
    for i in 1 2 3 4; do
      echo "const src$i = $i;" > "src/feature_$i.ts"
      echo "const lib$i = $i;" > "lib/feature_$i.ts"
      git add "src/feature_$i.ts" "lib/feature_$i.ts"
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
  ) && pass "pre-commit blocks broad cross-boundary source changes without plan updates" \
    || fail "pre-commit blocks broad cross-boundary source changes without plan updates"
}

test_pre_commit_allows_small_single_boundary_change_without_plan_update() {
  local tmp_home tmp_repo hook_output hook_code
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/tmp/devdisc_test_small_hook_bootstrap.log 2>&1

  (
    cd "$tmp_repo"
    mkdir -p src
    for i in 1 2 3 4 5; do
      echo "const v$i = $i;" > "src/feature_$i.ts"
      git add "src/feature_$i.ts"
    done
    set +e
    hook_output=$(.git/hooks/pre-commit 2>&1)
    hook_code=$?
    set -e
    echo "$hook_output" > /tmp/devdisc_test_small_hook_output.log

    if [ "$hook_code" -eq 0 ] && ! echo "$hook_output" | grep -q "requires an execution plan update"; then
      exit 0
    fi
    exit 1
  ) && pass "pre-commit allows small single-boundary source changes without a plan" \
    || fail "pre-commit allows small single-boundary source changes without a plan"
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
  if grep -q "resolve_findings_file" "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile.sh" \
    && grep -q ".dev/findings/" "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile.sh"; then
    pass "reconcile.sh resolves shared or scoped findings files"
  else
    fail "reconcile.sh resolves shared or scoped findings files"
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
    mkdir -p src lib
    for i in 1 2 3 4; do
      echo "const src$i = $i;" > "src/feature_$i.ts"
      echo "const lib$i = $i;" > "lib/feature_$i.ts"
      git add "src/feature_$i.ts" "lib/feature_$i.ts"
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
    mkdir -p src lib
    for i in 1 2 3 4; do
      echo "const src$i = $i;" > "src/feature_$i.ts"
      echo "const lib$i = $i;" > "lib/feature_$i.ts"
      git add "src/feature_$i.ts" "lib/feature_$i.ts"
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
    mkdir -p src lib
    for i in 1 2 3 4; do
      echo "const src$i = $i;" > "src/feature_$i.ts"
      echo "const lib$i = $i;" > "lib/feature_$i.ts"
      git add "src/feature_$i.ts" "lib/feature_$i.ts"
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

test_setup_creates_findings_and_learnings_directories() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  if [ -d "$tmp_repo/.dev/findings" ] && [ -d "$tmp_repo/.dev/learnings" ]; then
    pass "setup creates .dev/findings/ and .dev/learnings/ directories"
  else
    fail "setup creates .dev/findings/ and .dev/learnings/ directories"
  fi
}

test_reconcile_scopes_findings_by_agent() {
  local tmp_home tmp_repo output_file fake_bin
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  fake_bin=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  cat > "$fake_bin/codex" << 'EOF'
#!/usr/bin/env bash
cat << 'REPORT'
# Reconciliation Report — 2026-03-12

## Summary
Scoped findings test.

## Test Gaps
- [ ] Add a regression test

## Doc Updates Needed
- [ ] Update README

## Decisions to Document
- [ ] Capture the heuristic change

## Diary Summary
Test summary.
REPORT
EOF
  chmod +x "$fake_bin/codex"

  (
    cd "$tmp_repo"
    echo "base" > tracked.txt
    git add tracked.txt
    git commit --no-verify -m "$(printf 'feat(core): add tracked file\n\nwhy: create a commit for reconciliation coverage')" >/dev/null 2>&1
    PATH="$fake_bin:$PATH" AGENT_ID=test-agent HOME="$tmp_home" "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile.sh" --since "24 hours ago" --agent codex >/tmp/devdisc_test_reconcile_scope.log 2>&1
  )

  output_file="$tmp_repo/.dev/findings/agent-test-agent.md"
  if [ -f "$output_file" ] && [ ! -f "$tmp_repo/.dev/FINDINGS.md" ] && grep -q "agent-test-agent.md" "$output_file"; then
    pass "reconcile scopes findings to an agent-specific file"
  else
    fail "reconcile scopes findings to an agent-specific file"
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

test_post_commit_tags_agent_id() {
  local tmp_home tmp_repo diary_content
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    echo "test" > testfile.txt
    git add testfile.txt
    AGENT_ID=test-agent-42 git commit --no-verify -m "$(printf 'feat(x): test agent tagging\n\nwhy: verifying agent identity appears in diary entries')" >/dev/null 2>&1
  )

  diary_file=$(ls "$tmp_repo/.dev/diary/"*.md 2>/dev/null | head -1)
  if [ -n "$diary_file" ] && grep -q "test-agent-42" "$diary_file"; then
    pass "post-commit tags diary entry with AGENT_ID"
  else
    fail "post-commit tags diary entry with AGENT_ID"
  fi
}

test_post_commit_no_tag_without_agent_id() {
  local tmp_home tmp_repo diary_content
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    echo "test" > testfile.txt
    git add testfile.txt
    unset AGENT_ID
    git commit --no-verify -m "$(printf 'feat(x): test no agent tag\n\nwhy: verifying no agent tag when AGENT_ID is unset')" >/dev/null 2>&1
  )

  diary_file=$(ls "$tmp_repo/.dev/diary/"*.md 2>/dev/null | head -1)
  if [ -n "$diary_file" ] && ! grep -q "\[agent:" "$diary_file"; then
    pass "post-commit omits agent tag when AGENT_ID unset"
  else
    fail "post-commit omits agent tag when AGENT_ID unset"
  fi
}

test_reconcile_branch_script_exists() {
  if [ -x "$REPO_ROOT/skills/dev-reconciliation/scripts/reconcile-branch.sh" ]; then
    pass "reconcile-branch.sh exists and is executable"
  else
    fail "reconcile-branch.sh exists and is executable"
  fi
}

test_orchestrator_skill_exists() {
  if [ -f "$REPO_ROOT/skills/orchestrator/SKILL.md" ] && grep -q "AGENT_ID" "$REPO_ROOT/skills/orchestrator/SKILL.md"; then
    pass "orchestrator skill exists with AGENT_ID guidance"
  else
    fail "orchestrator skill exists with AGENT_ID guidance"
  fi
}

test_commit_msg_allows_fixup_commits() {
  local tmp_repo hook_output hook_code
  tmp_repo=$(mktemp -d)
  git init "$tmp_repo" >/dev/null 2>&1

  local hook_src="$REPO_ROOT/skills/dev-discipline/assets/commit-msg"
  cp "$hook_src" "$tmp_repo/.git/hooks/commit-msg"
  chmod +x "$tmp_repo/.git/hooks/commit-msg"

  local msg_file="$tmp_repo/.git/COMMIT_EDITMSG"
  printf 'fixup! feat(auth): add rate limiting' > "$msg_file"

  set +e
  hook_output=$("$tmp_repo/.git/hooks/commit-msg" "$msg_file" 2>&1)
  hook_code=$?
  set -e

  if [ "$hook_code" -eq 0 ]; then
    pass "commit-msg allows fixup! checkpoint commits"
  else
    fail "commit-msg allows fixup! checkpoint commits (code=$hook_code)"
  fi
}

test_commit_msg_allows_squash_commits() {
  local tmp_repo hook_output hook_code
  tmp_repo=$(mktemp -d)
  git init "$tmp_repo" >/dev/null 2>&1

  local hook_src="$REPO_ROOT/skills/dev-discipline/assets/commit-msg"
  cp "$hook_src" "$tmp_repo/.git/hooks/commit-msg"
  chmod +x "$tmp_repo/.git/hooks/commit-msg"

  local msg_file="$tmp_repo/.git/COMMIT_EDITMSG"
  printf 'squash! feat(auth): add rate limiting' > "$msg_file"

  set +e
  hook_output=$("$tmp_repo/.git/hooks/commit-msg" "$msg_file" 2>&1)
  hook_code=$?
  set -e

  if [ "$hook_code" -eq 0 ]; then
    pass "commit-msg allows squash! checkpoint commits"
  else
    fail "commit-msg allows squash! checkpoint commits (code=$hook_code)"
  fi
}

test_post_commit_logs_concerns() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    echo "test" > testfile.txt
    git add testfile.txt
    git commit --no-verify -m "$(printf 'feat(auth): change login flow\n\nwhy: simplifying auth reduces attack surface\nconcern: this changes session handling — verify no active sessions break')" >/dev/null 2>&1
  )

  diary_file=$(ls "$tmp_repo/.dev/diary/"*.md 2>/dev/null | head -1)
  if [ -n "$diary_file" ] && grep -q "verify no active sessions break" "$diary_file"; then
    pass "post-commit logs concern: lines in diary"
  else
    fail "post-commit logs concern: lines in diary"
  fi
}

test_reconcile_branch_rejects_checkpoint_commits() {
  local tmp_home tmp_repo output_file
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  output_file=$(mktemp)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git branch -M main >/dev/null 2>&1 || true

    echo "base" > base.txt
    git add base.txt
    git commit --no-verify -m "$(printf 'feat(core): seed base commit\n\nwhy: establish merge base for branch checks')" >/dev/null 2>&1

    git checkout -b agent/test/checkpoint >/dev/null 2>&1
    echo "work" > work.txt
    git add work.txt
    git commit --no-verify -m "fixup! feat(core): seed base commit" >/dev/null 2>&1
  )

  if (cd "$tmp_repo" && "$REPO_ROOT/scripts/reconcile-branch.sh" "agent/test/checkpoint" --base main --dry-run >"$output_file" 2>&1); then
    fail "reconcile-branch blocks unsquashed checkpoint commits"
  else
    if grep -qi "checkpoint commits are still present" "$output_file"; then
      pass "reconcile-branch blocks unsquashed checkpoint commits"
    else
      fail "reconcile-branch blocks unsquashed checkpoint commits"
    fi
  fi
}

test_reconcile_branch_rejects_missing_why() {
  local tmp_home tmp_repo output_file
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  output_file=$(mktemp)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git branch -M main >/dev/null 2>&1 || true

    echo "base" > base.txt
    git add base.txt
    git commit --no-verify -m "$(printf 'feat(core): seed base commit\n\nwhy: establish merge base for branch checks')" >/dev/null 2>&1

    git checkout -b agent/test/missing-why >/dev/null 2>&1
    echo "work" > work.txt
    git add work.txt
    git commit --no-verify -m "feat(core): add branch work without why" >/dev/null 2>&1
  )

  if (cd "$tmp_repo" && "$REPO_ROOT/scripts/reconcile-branch.sh" "agent/test/missing-why" --base main --dry-run >"$output_file" 2>&1); then
    fail "reconcile-branch blocks non-checkpoint commits missing why"
  else
    if grep -qi "missing a required 'why:' line" "$output_file"; then
      pass "reconcile-branch blocks non-checkpoint commits missing why"
    else
      fail "reconcile-branch blocks non-checkpoint commits missing why"
    fi
  fi
}

test_reconcile_branch_allows_clean_history_in_dry_run() {
  local tmp_home tmp_repo output_file
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  output_file=$(mktemp)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git branch -M main >/dev/null 2>&1 || true

    echo "base" > base.txt
    git add base.txt
    git commit --no-verify -m "$(printf 'feat(core): seed base commit\n\nwhy: establish merge base for branch checks')" >/dev/null 2>&1

    git checkout -b agent/test/clean >/dev/null 2>&1
    echo "work" > work.txt
    git add work.txt
    git commit --no-verify -m "$(printf 'feat(core): add clean branch work\n\nwhy: verify merge gate allows clean concern-level history')" >/dev/null 2>&1
  )

  if (cd "$tmp_repo" && "$REPO_ROOT/scripts/reconcile-branch.sh" "agent/test/clean" --base main --dry-run >"$output_file" 2>&1); then
    if grep -q "LLM review skipped" "$output_file"; then
      pass "reconcile-branch skips LLM review for low-risk clean branches"
    else
      fail "reconcile-branch skips LLM review for low-risk clean branches"
    fi
  else
    fail "reconcile-branch skips LLM review for low-risk clean branches"
  fi
}

test_reconcile_branch_escalates_risky_history_in_dry_run() {
  local tmp_home tmp_repo output_file
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  output_file=$(mktemp)

  HOME="$tmp_home" "$REPO_ROOT/scripts/new-project-bootstrap.sh" --init-git "$tmp_repo" >/dev/null 2>&1

  (
    cd "$tmp_repo"
    git branch -M main >/dev/null 2>&1 || true

    echo "base" > base.txt
    git add base.txt
    git commit --no-verify -m "$(printf 'feat(core): seed base commit\n\nwhy: establish merge base for branch checks')" >/dev/null 2>&1

    git checkout -b agent/test/risky >/dev/null 2>&1
    mkdir -p src lib
    for i in 1 2 3; do
      echo "const src$i = $i;" > "src/feature_$i.ts"
      echo "const lib$i = $i;" > "lib/feature_$i.ts"
      git add "src/feature_$i.ts" "lib/feature_$i.ts"
    done
    git commit --no-verify -m "$(printf 'feat(core): add broad branch work\n\nwhy: verify risky branches still get deeper review')" >/dev/null 2>&1
  )

  if (cd "$tmp_repo" && "$REPO_ROOT/scripts/reconcile-branch.sh" "agent/test/risky" --base main --dry-run >"$output_file" 2>&1); then
    if grep -q "Prompt that would be sent" "$output_file" && grep -q "Risk Signals" "$output_file"; then
      pass "reconcile-branch escalates risky branches to LLM review"
    else
      fail "reconcile-branch escalates risky branches to LLM review"
    fi
  else
    fail "reconcile-branch escalates risky branches to LLM review"
  fi
}

test_bootstrap_installs_planner_and_scaffold
test_pre_commit_blocks_cross_boundary_source_change_without_plan_update
test_pre_commit_allows_small_single_boundary_change_without_plan_update
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
test_setup_creates_findings_and_learnings_directories
test_reconcile_scopes_findings_by_agent
test_reconcile_script_archives_resolved_findings
test_contract_has_protected_artifacts_rule
test_post_commit_tags_agent_id
test_post_commit_no_tag_without_agent_id
test_reconcile_branch_script_exists
test_orchestrator_skill_exists
test_commit_msg_allows_fixup_commits
test_commit_msg_allows_squash_commits
test_post_commit_logs_concerns
test_reconcile_branch_rejects_checkpoint_commits
test_reconcile_branch_rejects_missing_why
test_reconcile_branch_allows_clean_history_in_dry_run
test_reconcile_branch_escalates_risky_history_in_dry_run

echo ""
echo "Test results: $PASS_COUNT passed, $FAIL_COUNT failed"
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
