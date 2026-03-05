---
summary: "Enforce architecture-impact discipline alongside planner workflow."
read_when:
  - Committing architecture-affecting updates to dev-discipline workflows.
---

# Execution Plan: Enforce architecture approach in discipline toolkit

## Purpose / Big Picture

Ensure architecture changes are consistently captured, validated, and discoverable so users can trust this toolkit to keep repo structure and system boundaries clear over time.

## Progress

- [x] 2026-03-04 21:10 - plan created
- [x] 2026-03-04 21:15 - architecture validator and wrappers added
- [x] 2026-03-04 21:22 - planner template + skill updated with Architecture Impact
- [x] 2026-03-04 21:30 - setup/bootstrap/hook/CI docs wired for architecture approach
- [x] 2026-03-04 21:40 - validation and integration tests completed

## Surprises & Discoveries

- Pre-commit plan enforcement excludes `plan-template.md`, so a real active plan file is needed for large source commits.
- Local health-check creates date-stamped doc-gardener artifacts that are useful for inspection but not always desirable in every commit.

## Decision Log

- 2026-03-04: Added a dedicated architecture validator script in planner and stable root wrappers to keep interfaces consistent.
- 2026-03-04: Added `/architecture` playbook instead of embedding all architecture rules in `/planner` for clearer separation of responsibilities.
- 2026-03-04: Kept architecture checks warning-level in pre-commit for broad changes; hard failure remains focused on missing execution plans.

## Outcomes & Retrospective

- Architecture documentation is now part of the standard workflow and quality checks.
- Planner workflow now explicitly tracks architecture impact.
- Remaining follow-up: tune architecture warning thresholds based on real-world commit behavior.

## Context and Orientation

- `skills/planner/scripts/validate-architecture.sh`
- `skills/planner/templates/{exec-plan.md,architecture.md}`
- `skills/dev-discipline/assets/pre-commit`
- `skills/dev-discipline/scripts/{setup.sh,teardown.sh,bootstrap-harness.sh,health-check.sh}`
- `scripts/{planner,validate-exec-plan.sh,validate-architecture.sh,architecture}`
- `docs/refs/{harness-engineering.md,architecture-approach.md,hook-config.md}`
- `docs/slash-commands/{README.md,planner.md,architecture.md}`
- `ARCHITECTURE.md`

## Plan of Work

- In scope:
  - Add architecture validation tooling and wrapper commands.
  - Integrate architecture impact into plan template and planner skill instructions.
  - Wire setup/bootstrap/hook/health-check/CI/docs to enforce and explain architecture discipline.
- Out of scope:
  - Project-specific architecture content beyond toolkit-level defaults.
  - Blocking commits on architecture updates for all source changes.

## Architecture Impact

- Impacted architecture areas:
  - Toolkit workflow boundaries (planning, architecture docs, enforcement hooks, CI quality loop).
- Invariants affected:
  - Non-trivial work must include structured planning with explicit architecture-impact statements.
  - Architecture map remains a concise orientation artifact with defined required sections.
- `ARCHITECTURE.md` update needed? (`yes`/`no`): yes
- If no, why not:
  - n/a

## Concrete Steps

1. [done] Add architecture validator and stable wrapper commands.
User benefit: users can run one clear command to verify architecture docs are complete and useful.
2. [done] Extend planner template/skill to require Architecture Impact and architecture validation.
User benefit: implementation plans now make system-level consequences explicit before and during coding.
3. [done] Integrate architecture approach into setup/bootstrap, hook config, slash docs, and README.
User benefit: teams adopting the toolkit get architecture discipline automatically with minimal setup effort.
4. [done] Add architecture checks into quality workflow and CI.
User benefit: regressions in architecture documentation are caught early, not after handoff confusion.

## Validation and Acceptance

- [x] Run shell syntax checks for updated scripts.
- [x] Run docs index/front-matter checks (`./scripts/docs-list.sh`).
- [x] Run planner validation (`./scripts/planner docs/plans/active/plan-template.md`).
- [x] Run architecture validation (`./scripts/validate-architecture.sh ARCHITECTURE.md`).
- [x] Run integration tests (`./scripts/test.sh`).

## Idempotence and Recovery

All added scripts are safe to rerun; setup/bootstrap use create-missing behavior and wrappers only delegate. If changes fail validation, recover by editing docs/scripts and retrying checks. Rollback is a standard git revert of this commit; no data migration or irreversible state changes are introduced.

## Artifacts and Notes

- Added architecture playbook: `docs/slash-commands/architecture.md`
- Added architecture validator wrappers: `scripts/validate-architecture.sh`, `scripts/architecture`
- Added architecture map: `ARCHITECTURE.md`
- Added architecture approach reference: `docs/refs/architecture-approach.md`

## Interfaces and Dependencies

- Depends on local shell tooling (`bash`, `git`, `grep`, `awk`, `sed`, `find`).
- CI interface: `.github/workflows/quality.yml` running root wrappers.
- Human interface: slash playbooks (`/planner`, `/architecture`) and docs references.
