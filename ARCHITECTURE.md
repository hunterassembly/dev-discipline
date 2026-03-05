# Architecture

## System Intent

This repository provides a portable discipline toolkit for AI-assisted software development.
It optimizes for reproducible execution workflows, enforceable commit hygiene, and low operational drift across projects.

## Architecture at a Glance

The system is organized into reusable skill packages plus lightweight wrapper scripts:
- `skills/dev-discipline`: core enforcement, setup/teardown, and local quality loop
- `skills/planner`: execution-plan and architecture validation
- `skills/dev-diary`: commit-diary summarization scaffolding
- `skills/dev-reconciliation`: end-of-session reconciliation launcher and feedback loop
- `skills/orchestrator`: multi-agent coordination contract (branch-native)
- `scripts/`: stable entry points that route to skill implementations

## Code Map

- `skills/dev-discipline/assets/`: git hook assets (`pre-commit`, `commit-msg`, `post-commit`)
- `skills/dev-discipline/scripts/`: bootstrap/setup and maintenance commands
- `skills/planner/scripts/`: plan and architecture validators
- `docs/`: operational guidance, references, and workflow playbooks
- `.github/workflows/quality.yml`: CI checks for docs/scripts/validators/tests
- `tests/`: integration tests for bootstrap and enforcement behavior

## Runtime Flows

- Install flow:
  - `scripts/new-project-bootstrap.sh` installs skills to `~/.agents/skills`
  - runs `setup.sh` in target repo
  - setup links hooks and bootstraps docs/evals/architecture artifacts
- Commit flow:
  - `pre-commit` enforces discipline and plan/architecture checks; auto-scaffolds plan files when blocking
  - `commit-msg` enforces conventional commit + `why:` quality (length, no parrot, no filler); skips `fixup!`/`squash!` checkpoints
  - `post-commit` appends commit metadata to local diary; tags entries with `AGENT_ID` when set; logs `concern:` lines
- Quality flow:
  - `health-check.sh` runs docs checks, template sync checks, validators, drift scan, and optional reconciliation
- Feedback loop:
  - Reconciliation extracts open findings to `.dev/FINDINGS.md`
  - Next session reads FINDINGS before starting work
  - Resolved findings archive to `.dev/learnings/` as institutional memory (category files)
- Multi-agent flow:
  - Each agent works on `agent/<agent-id>/<concern>` branches with `AGENT_ID` env var set
  - `reconcile-branch.sh` runs deterministic merge gates (no unsquashed checkpoints, no missing `why:` lines) before LLM review
  - Orchestrator skill defines coordination contract; no custom coordination layer needed

## Architectural Invariants

- Hook logic is local-first and shell-only; no network dependency in hooks.
- Wrapper scripts remain stable public entry points even if skill internals evolve.
- Execution plans are required for non-trivial source changes.
- Plan template source-of-truth is `skills/planner/templates/exec-plan.md`.
- Docs include front matter (`summary`, `read_when`) for discovery tooling.
- Protected artifacts: `.dev/`, `docs/plans/`, and `docs/decisions/` must never be deleted by agents.
- Multi-agent features are opt-in: zero overhead when `AGENT_ID` is unset.
- Feedback loop is deterministic: findings flow to FINDINGS.md, resolved findings archive to learnings.

## Boundaries and Interfaces

- Skill boundary:
  - Skills own implementation details (`skills/*`)
  - Root `scripts/*` are consumer-facing interfaces
- Enforcement boundary:
  - Hooks provide immediate local gatekeeping
  - CI in `.github/workflows/quality.yml` provides PR-level verification
- Documentation boundary:
  - `docs/refs/` for stable contracts
  - `docs/slash-commands/` for operational playbooks

## Cross-Cutting Concerns

- Reliability: commands are idempotent where possible and fail with explicit errors.
- Portability: only standard shell + git tooling assumptions.
- Observability: reconciliation, diary logs, and quality reports capture work evidence.
- Safety: no destructive git operations embedded in workflow scripts.

## What We Deliberately Do Not Do

- No framework-specific architecture assumptions.
- No mandatory external services for local enforcement.
- No hidden automation that modifies source behavior outside explicit scripts/hooks.

## How to Change This Architecture

- Update relevant execution plan under `docs/plans/active/` with `Architecture Impact`.
- Update this `ARCHITECTURE.md` when boundaries, invariants, or top-level flows change.
- Run local checks:
  - `./scripts/validate-architecture.sh`
  - `./scripts/planner docs/plans/active/<plan>.md`
  - `./scripts/health-check.sh --since "24 hours ago" --skip-reconcile`
