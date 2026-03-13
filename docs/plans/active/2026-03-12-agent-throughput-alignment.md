---
summary: "Align discipline workflows with fast agent execution by scoping findings, reducing merge queues, and tightening plan heuristics around risk."
read_when:
  - Updating reconciliation, planning thresholds, or multi-agent coordination behavior.
---

# Execution Plan: Align dev-discipline with fast agent throughput

## Purpose / Big Picture

Reduce workflow friction that only shows up when agents move quickly in parallel: avoid shared findings files that overwrite each other, avoid queueing every branch behind an LLM merge review, and require plans for broad/risky work instead of every 5-file edit.

## Progress

- [x] 2026-03-12 16:20 - plan created
- [x] 2026-03-12 16:25 - implementation started
- [x] 2026-03-12 16:55 - validation complete

## Surprises & Discoveries

- The toolkit repo is not bootstrapped with `.dev/` artifacts or live hooks, so the checked-in contributor guidance currently overstates the repo's self-hosting state.
- `pre-commit` currently counts root-level files as separate top-level directories, which inflates the "multi-directory" signal and makes the plan heuristic noisier than intended.

## Decision Log

- 2026-03-12: Scope reconciliation findings by agent or branch when possible, while keeping `.dev/FINDINGS.md` as the shared single-agent fallback.
- 2026-03-12: Change branch reconciliation to run deterministic merge checks for every branch and invoke LLM review only when risk signals say it is worth the latency.
- 2026-03-12: Shift execution-plan blocking from a raw 5-file threshold to a broader boundary/risk heuristic.

## Outcomes & Retrospective

- Scoped findings now write to `.dev/findings/*.md` for agent or branch work, while single-agent flow keeps `.dev/FINDINGS.md`.
- Branch reconciliation now skips LLM review for low-risk branches and preserves the ability to force review when needed.
- Pre-commit plan gating now keys off broader cross-boundary work instead of a raw 5-file threshold, and the top-level directory signal now treats repo-root files correctly.
- Follow-up worth considering: add a small helper command that tells agents which findings file applies to their current branch to reduce discovery friction further.

## Context and Orientation

- `skills/dev-reconciliation/scripts/reconcile.sh`
- `skills/dev-reconciliation/scripts/reconcile-branch.sh`
- `skills/dev-discipline/assets/pre-commit`
- `skills/dev-discipline/scripts/setup.sh`
- `README.md`
- `ARCHITECTURE.md`
- `AGENTS.md`
- `skills/dev-discipline/SKILL.md`
- `skills/dev-discipline/assets/contract.md`
- `skills/orchestrator/SKILL.md`
- `docs/refs/hook-config.md`
- `tests/dev_discipline_integration_test.sh`

## Plan of Work

- In scope:
  - Add scoped findings output and setup support for scoped findings artifacts.
  - Make branch reconciliation skip LLM review unless the branch is broad or risky, with an override for always/never.
  - Revise plan enforcement heuristics and contributor docs to reflect the new workflow.
  - Update integration tests for the new behavior.
- Out of scope:
  - Rebootstrapping this repository with tracked `.dev/` artifacts.
  - Replacing git-based coordination with a centralized agent scheduler.

## Architecture Impact

- Impacted architecture areas:
  - Feedback loop artifacts, branch merge gate behavior, and plan enforcement heuristics.
- Invariants affected:
  - Hooks remain local-first and shell-only.
  - Multi-agent workflows should not force agents to overwrite shared state during reconciliation.
  - Merge-time AI review should be reserved for work with enough risk to justify the delay.
- `ARCHITECTURE.md` update needed? (`yes`/`no`): yes
- If no, why not:
  - n/a

## Concrete Steps

1. [done] Update reconciliation scripts and setup scaffolding for scoped findings files.
User benefit: concurrent agents keep their own follow-up context instead of overwriting each other, so resumed work starts from the right backlog.
2. [done] Change branch merge-gate behavior to do deterministic checks by default and escalate to LLM review only for risky branches or explicit requests.
User benefit: small safe branches merge faster, while larger or riskier changes still get deeper review before they reach users.
3. [done] Rework the execution-plan block heuristic and fix the top-level directory signal used by pre-commit.
User benefit: users avoid plan ceremony for small mechanical edits while still getting planning discipline on cross-boundary changes that are more likely to affect behavior.
4. [done] Refresh docs and tests so the repo’s contract matches the new execution model.
User benefit: contributors and agents see one accurate workflow, which reduces startup confusion and prevents avoidable failed attempts.

## Validation and Acceptance

- [x] Run `scripts/docs-list.sh`
- [x] Run `scripts/test.sh`
- [x] Run `scripts/planner docs/plans/active/2026-03-12-agent-throughput-alignment.md`
- [x] Run `scripts/validate-architecture.sh`
- [x] Confirm docs describe scoped findings, risk-based merge review, and revised plan thresholds

## Idempotence and Recovery

All script changes are safe to rerun. If reconciliation output paths or gating heuristics misbehave, recover by reverting the touched scripts and docs, then rerun the integration tests to verify the previous workflow.

## Artifacts and Notes

- Audit findings from 2026-03-12 prompted this plan.

## Interfaces and Dependencies

- Local shell tooling (`bash`, `git`, `grep`, `sed`, `awk`, `wc`, `mktemp`)
- Codex or Claude CLI for optional reconciliation LLM review
- Active plan validator in `skills/planner/scripts/validate-plan.sh`
