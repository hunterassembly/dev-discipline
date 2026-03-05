# Agents

This repo uses [dev-discipline](https://github.com/hunterassembly/dev-discipline) to enforce coding discipline via git hooks.

## Before You Start

1. Run `scripts/new-project-bootstrap.sh` if hooks aren't installed (check: `.git/hooks/pre-commit` exists)
2. Read `.dev/contract.md` — the rules you must follow
3. Check `.dev/FINDINGS.md` for open items from previous reconciliation
4. Scan `.dev/learnings/` for patterns relevant to your task
5. Run `scripts/docs-list.sh` to discover relevant docs

## Skills

| Skill | Path | Use When |
|-------|------|----------|
| dev-discipline | `skills/dev-discipline/SKILL.md` | Writing code, preparing commits, setting up hooks |
| planner | `skills/planner/SKILL.md` | Creating or validating execution plans for non-trivial work |
| dev-diary | `skills/dev-diary/SKILL.md` | Summarizing or navigating the auto-generated commit diary |
| dev-reconciliation | `skills/dev-reconciliation/SKILL.md` | Running end-of-session audits |
| orchestrator | `skills/orchestrator/SKILL.md` | Multi-agent coordination (set `AGENT_ID` env var first) |

## Key Commands

- `scripts/health-check.sh --since "24h ago"` — full local quality loop
- `scripts/test.sh` — run integration tests
- `scripts/planner docs/plans/active/<plan>.md` — validate a plan
- `scripts/validate-architecture.sh` — validate ARCHITECTURE.md
- `scripts/reconcile-branch.sh <branch>` — branch merge-gate audit

## Commit Rules

- One concern per commit, conventional format: `type(scope): description`
- Mandatory `why:` line in commit body
- `fixup!`/`squash!` checkpoints allowed during active work — clean before handoff
- Optional `concern:` line to flag risky changes
- Never use `--no-verify`
