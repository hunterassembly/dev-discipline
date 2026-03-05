#!/usr/bin/env bash
set -euo pipefail

# Dev Discipline — Harness Bootstrap
# Scaffolds lightweight harness-engineering artifacts for agent-readable repos.
# Safe to run repeatedly; only creates missing files/directories.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "${REPO_ROOT:-}" ]; then
  echo "Not inside a git repository."
  exit 1
fi

mkdir -p \
  "$REPO_ROOT/.agent" \
  "$REPO_ROOT/docs/design" \
  "$REPO_ROOT/docs/refs" \
  "$REPO_ROOT/docs/quality" \
  "$REPO_ROOT/docs/plans/active" \
  "$REPO_ROOT/docs/plans/completed" \
  "$REPO_ROOT/evals/cases" \
  "$REPO_ROOT/evals/rubrics" \
  "$REPO_ROOT/evals/runs"

ensure_file() {
  local path="$1"
  if [ -f "$path" ]; then
    return 0
  fi
  cat > "$path"
  echo "created: ${path#"$REPO_ROOT"/}"
}

ensure_file_from_source() {
  local target="$1"
  local source="$2"
  if [ -f "$target" ]; then
    return 0
  fi
  if [ ! -f "$source" ]; then
    return 1
  fi
  cp "$source" "$target"
  echo "created: ${target#"$REPO_ROOT"/}"
}

ensure_file "$REPO_ROOT/docs/design/README.md" << 'EOF'
---
summary: "Design docs index for architecture decisions and system behavior."
read_when:
  - Designing or changing architecture-level behavior.
---

# Design Docs

Store architecture and design docs here.
EOF

ensure_file "$REPO_ROOT/docs/refs/README.md" << 'EOF'
---
summary: "Reference docs index for stable commands, contracts, and definitions."
read_when:
  - Looking up stable project conventions or command references.
---

# References

Use this folder for evergreen references:

- API contracts
- command references
- glossary/domain terms
- coding conventions

Keep references short and link out to deeper docs when needed.

Starter references:

- `harness-engineering.md` — operating loop for agent context, evals, and entropy control
- `hook-config.md` — pre-commit threshold configuration and tuning
- `architecture-approach.md` — `ARCHITECTURE.md` structure and maintenance approach
EOF

ensure_file "$REPO_ROOT/docs/quality/README.md" << 'EOF'
---
summary: "Quality docs index for audits, reports, and local quality loops."
read_when:
  - Reviewing quality health before handoff or release.
---

# Quality Docs

Store reconciliation reports, quality snapshots, and cleanup checklists here.
EOF

ensure_file "$REPO_ROOT/docs/plans/active/README.md" << 'EOF'
---
summary: "Active execution plans index for in-flight implementation work."
read_when:
  - Starting, resuming, or reviewing non-trivial implementation work.
---

# Active Plans

Keep one markdown execution plan per active initiative.
Follow the Codex Exec Plans structure from `docs/plans/active/plan-template.md`.

Recommended conventions:

- keep `Progress` current as a living checklist
- log surprises and decisions as they happen
- include user-benefit narrative for each concrete step
- link to related docs/issues/PRs
EOF

ensure_file "$REPO_ROOT/docs/plans/completed/README.md" << 'EOF'
---
summary: "Completed plans index for historical context."
read_when:
  - Looking up why/how prior initiatives were executed.
---

# Completed Plans

Move finished plans here for durable historical context.
EOF

PLANNER_TEMPLATE_SOURCE=""
for candidate in \
  "$REPO_ROOT/skills/planner/templates/exec-plan.md" \
  "$REPO_ROOT/.agents/skills/planner/templates/exec-plan.md" \
  "$HOME/.agents/skills/planner/templates/exec-plan.md"; do
  if [ -f "$candidate" ]; then
    PLANNER_TEMPLATE_SOURCE="$candidate"
    break
  fi
done

if [ -n "$PLANNER_TEMPLATE_SOURCE" ]; then
  ensure_file_from_source "$REPO_ROOT/docs/plans/active/plan-template.md" "$PLANNER_TEMPLATE_SOURCE" || true
else
  echo "warning: planner template source not found; docs/plans/active/plan-template.md was not auto-created."
fi

ARCH_TEMPLATE_SOURCE=""
for candidate in \
  "$REPO_ROOT/skills/planner/templates/architecture.md" \
  "$REPO_ROOT/.agents/skills/planner/templates/architecture.md" \
  "$HOME/.agents/skills/planner/templates/architecture.md"; do
  if [ -f "$candidate" ]; then
    ARCH_TEMPLATE_SOURCE="$candidate"
    break
  fi
done

if [ -n "$ARCH_TEMPLATE_SOURCE" ]; then
  ensure_file_from_source "$REPO_ROOT/ARCHITECTURE.md" "$ARCH_TEMPLATE_SOURCE" || true
else
  echo "warning: architecture template source not found; ARCHITECTURE.md was not auto-created."
fi

ensure_file "$REPO_ROOT/docs/QUALITY_SCORE.md" << 'EOF'
---
summary: "Simple quality scoreboard for local discipline signals."
read_when:
  - Checking project health before handoff or release.
---

# Quality Score

## Latest Snapshot

- Date: _not set yet_
- Overall: _n/a_
- Docs coverage: _n/a_
- Plan hygiene: _n/a_
- Decision signal: _n/a_
- Eval coverage: _n/a_
- Source report: _n/a_
EOF

ensure_file "$REPO_ROOT/docs/design/core-beliefs.md" << 'EOF'
---
summary: "Core system beliefs and non-negotiable quality constraints."
read_when:
  - Starting a project or changing architecture-level behavior.
---

# Core Beliefs

Keep this short. These are the principles your agents should optimize for.

## Product Truths

- Users should feel faster after every release.
- Latency and correctness both matter on the critical path.
- Every major capability must have an eval before broad rollout.

## Engineering Truths

- Behavior changes are shipped only with tests.
- Every agent action must be observable from logs, traces, or artifacts.
- Prompts, tools, and policies evolve through measured eval results.

## Decision Rules

- Prefer simple, reversible changes with fast feedback.
- Document tradeoffs before irreversible architecture choices.
- Keep AGENTS.md as a routing map; keep details in docs.
EOF

ensure_file "$REPO_ROOT/docs/refs/harness-engineering.md" << 'EOF'
---
summary: "Harness-engineering operating loop for repo setup, evals, and maintenance."
read_when:
  - Bootstrapping agent workflows in a new or overhauled repository.
---

# Harness Engineering Loop

## 1) Encode context

- Keep `AGENTS.md` short and map to deeper docs.
- Keep `ARCHITECTURE.md` as the stable architecture map.
- Put stable conventions in `docs/refs/`.
- Keep design intent in `docs/design/`.

## 2) Ship through evals

- Store eval inputs in `evals/cases/`.
- Store grading rubrics in `evals/rubrics/`.
- Track run summaries in `evals/runs/`.

## 3) Continuous cleanup

- Run docs checks and drift scans during handoff:
  - `./scripts/docs-list.sh`
  - `./scripts/doc-gardener.sh --since "24 hours ago"`
- Reconcile commits before PRs:
  - `.agents/skills/dev-reconciliation/scripts/reconcile.sh --since "24 hours ago"`
- Use execution plans for non-trivial work:
  - `.agent/PLANS.md`
  - `docs/plans/active/plan-template.md`

## 4) Keep entropy low

- One concern per commit.
- Link architecture changes to decision records in `.dev/decisions/`.
- Update docs in the same PR as behavior changes.

## Source references

- OpenAI Harness Engineering: https://openai.com/index/harness-engineering/
- Codex Exec Plans: https://developers.openai.com/cookbook/articles/codex_exec_plans
- Matklad ARCHITECTURE.md approach: https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html
- Eval-driven system design cookbook: https://cookbook.openai.com/examples/evaluation/use-cases/eval-driven_system_design_from_prototype_to_production
- OpenAI Evals guide: https://platform.openai.com/docs/guides/evals
EOF

ensure_file "$REPO_ROOT/docs/refs/architecture-approach.md" << 'EOF'
---
summary: "Approach for keeping ARCHITECTURE.md concise, stable, and operational."
read_when:
  - Establishing architecture documentation standards for a repo.
---

# ARCHITECTURE.md Approach

Use `ARCHITECTURE.md` as the system map, not a complete design spec.

## Principles

- Keep it short enough to be read in one pass.
- Focus on orientation: where code lives, boundaries, and invariants.
- Document deliberate non-goals to avoid accidental scope creep.
- Treat it as stable context, not a change log.

## Required Contents

- System intent
- Architecture overview
- Code map
- Runtime flows
- Architectural invariants
- Boundaries/interfaces
- Cross-cutting concerns
- Explicit non-goals
- Change process

## Maintenance Rule

Update `ARCHITECTURE.md` when boundaries or invariants change.
If no architecture impact, record that explicitly in the execution plan.

## Source

- Matklad on `ARCHITECTURE.md`: https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html
EOF

ensure_file "$REPO_ROOT/docs/refs/hook-config.md" << 'EOF'
---
summary: "Hook threshold configuration for commit-size and plan-enforcement tuning."
read_when:
  - Adjusting pre-commit strictness for team size or repo complexity.
---

# Hook Configuration

`pre-commit` reads optional config from `.dev/discipline.env` (or `DEV_DISCIPLINE_CONFIG_FILE`).

Start from `.dev/discipline.env.example` and tune as needed:

- `DEV_DISCIPLINE_WARN_FILE_COUNT` (default `10`)
- `DEV_DISCIPLINE_LARGE_FILE_COUNT` (default `20`)
- `DEV_DISCIPLINE_WARN_DIR_COUNT` (default `4`)
- `DEV_DISCIPLINE_PLAN_REQUIRED_SOURCE_FILE_COUNT` (default `5`)
- `DEV_DISCIPLINE_ARCHITECTURE_WARN_SOURCE_FILE_COUNT` (default `8`)
- `DEV_DISCIPLINE_ARCHITECTURE_WARN_DIR_COUNT` (default `3`)

Higher thresholds reduce friction; lower thresholds increase discipline.
EOF

ensure_file "$REPO_ROOT/.agent/PLANS.md" << 'EOF'
# Execution Plan Operating Standard

Use execution plans for all non-trivial implementation work. Plans are living docs, not static proposals.

## Source

- Codex Exec Plans: https://developers.openai.com/cookbook/articles/codex_exec_plans

## Rules

- Keep one active plan file per initiative in `docs/plans/active/`.
- Use the full section structure from `docs/plans/active/plan-template.md`.
- Use `/planner` (or `~/.agents/skills/planner/scripts/validate-plan.sh`) before commit.
- Update `Progress`, `Surprises & Discoveries`, and `Decision Log` as work proceeds.
- Include user-benefit narrative for each concrete step.
- Record architecture impact explicitly and update `ARCHITECTURE.md` when boundaries/invariants change.
- Move completed plans to `docs/plans/completed/`.

## Enforcement

- `pre-commit` warns on source changes without plan updates.
- `pre-commit` blocks significant source changes without plan updates.
- `pre-commit` validates required execution-plan sections for changed plan files.
EOF

ensure_file "$REPO_ROOT/docs/quality/entropy-garbage-collection.md" << 'EOF'
---
summary: "Simple entropy control checklist for ongoing repository maintenance."
read_when:
  - Running end-of-day or pre-release quality cleanup.
---

# Entropy and Garbage Collection

Use this checklist during weekly maintenance or before major releases.

- [ ] Stale plans moved from `docs/plans/active/` to `docs/plans/completed/`
- [ ] Dead docs archived or removed
- [ ] Outdated prompts, scripts, and references pruned
- [ ] Evals updated for newly introduced behaviors
- [ ] Quality snapshot refreshed in `docs/QUALITY_SCORE.md`
EOF

ensure_file "$REPO_ROOT/evals/README.md" << 'EOF'
# Evals

Use this folder to keep eval assets close to the code.

- `cases/`: input samples and expected outcomes
- `rubrics/`: grading definitions and pass criteria
- `runs/`: lightweight run summaries and regressions

Start small:
1. Add 10-20 representative cases.
2. Define pass/fail criteria before changing prompts/tools.
3. Track every meaningful prompt or policy change against those cases.
EOF

ensure_file "$REPO_ROOT/evals/cases/README.md" << 'EOF'
# Eval Cases

Store canonical examples covering:

- happy path
- edge cases
- known regressions
- adversarial/abuse cases (when relevant)
EOF

ensure_file "$REPO_ROOT/evals/rubrics/README.md" << 'EOF'
# Eval Rubrics

Define explicit grading criteria for quality:

- correctness
- policy compliance
- safety and refusal behavior
- style/tone constraints (if user-visible)
EOF

ensure_file "$REPO_ROOT/evals/runs/README.md" << 'EOF'
# Eval Runs

Store lightweight run summaries and regression notes here.

Suggested naming:

- `YYYY-MM-DD-<capability>-run.md`
EOF

ensure_file "$REPO_ROOT/AGENTS.md" << 'EOF'
# AGENTS.md

## Mission

Ship reliable product changes quickly while keeping agent behavior auditable.

## Read First

1. `.dev/contract.md`
2. `ARCHITECTURE.md`
3. `docs/design/core-beliefs.md`
4. `docs/refs/harness-engineering.md`
5. `.agent/PLANS.md`

## Repo Map

- `docs/design/`: architecture decisions and system behavior
- `docs/refs/`: stable operating references
- `docs/quality/`: audits and quality snapshots
- `docs/plans/active/`: in-flight plans
- `docs/plans/completed/`: archived plans
- `evals/`: eval cases, rubrics, and run notes
- `ARCHITECTURE.md`: architecture map, invariants, and boundaries

## Working Rules

- One concern per commit
- Conventional commit format with `why:`
- Behavior changes require tests and docs updates
- Non-trivial work requires an execution plan update in `docs/plans/active/`
- Use `planner` to create/validate active plans
- Run local quality loop before handoff
EOF

echo "Harness bootstrap complete."
