---
name: dev-discipline
description: >
  Enforces commit discipline for AI coding agents. Use when making code changes, preparing commits,
  or setting up repo discipline hooks. Avoid for read-only research tasks with no file changes.
  Ensures one concern per commit, conventional commit messages, test coverage for behavioral
  changes, and decision documentation. Produces a disciplined commit workflow and installs git hooks.
license: MIT
metadata:
  author: hunterassembly
  version: "0.1.0"
---

# Dev Discipline

You are working in a project that enforces coding discipline. Follow these rules for every code change.

## Routing Guidance

- Use when: writing code, staging changes, preparing commit messages, or bootstrapping `.dev/` discipline files
- Do not use when: only reading code, brainstorming, or doing documentation review with zero code changes
- Primary outputs: clean commit boundaries, conventional commit messages with `why:`, up-to-date `.dev/` records, and harness scaffolding (`AGENTS.md`, `docs/`, `evals/`)

## Before You Start

1. Run `scripts/setup.sh` if git hooks aren't installed yet (check: `.git/hooks/pre-commit` should be a symlink or contain dev-discipline logic)
   - setup also bootstraps missing harness docs/evals via `scripts/bootstrap-harness.sh`
2. Read the worklog if one exists: `.dev/WORKLOG.md`
3. Check `.dev/FINDINGS.md` for open items from previous reconciliation. Address open items before starting new work.
4. Scan `.dev/learnings/` for patterns relevant to your current task.
5. If docs exist, run docs index (`scripts/docs-list.sh` or `.agents/skills/dev-discipline/scripts/docs-list.sh`) to load relevant guidance (`summary` + `read_when`)
6. Understand what you're about to change and why before writing code
7. For longer tasks, create or update an active plan under `docs/plans/active/`
8. For non-trivial implementation, follow `.agent/PLANS.md` and use the full execution-plan structure in `docs/plans/active/plan-template.md`
9. Keep plan template synced from canonical planner template:
   - `scripts/sync-plan-template.sh --check`

## Commit Rules

### One Concern Per Commit
- Final handoff commits should address exactly ONE logical change
- Don't mix refactors with features
- Don't mix formatting with bug fixes
- If you catch yourself doing two things, commit the first, then start the second
- During active implementation, fast checkpoint commits are allowed (`fixup!` / `squash!`)
- Before handoff/review, consolidate checkpoints into concern-level commits with clear `why:` lines

### Conventional Commits
Format every commit message as:

```
type(scope): description

why: one-line explanation of the decision or motivation
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

The `why:` line is mandatory. It captures the reasoning, not just the what.

Optional `concern:` line flags worries for reconciliation review:
```
concern: this changes the auth flow — verify no sessions break
```

### Examples

Good:
```
feat(search): add fuzzy matching for typo tolerance

why: users frequently misspell product names, losing 12% of searches
```

Bad:
```
update search and fix header and add tests
```

## Testing Rules

- **Behavioral changes require tests.** If you changed what code *does*, prove it works.
- **Bug fixes require regression tests.** Show the bug existed, show it's fixed.
- **Refactors should not change test outcomes.** If tests break after a refactor, you changed behavior.
- Don't write tests for test coverage metrics. Write tests that verify intent.

## Documentation Rules

- If you change a public API, update its documentation
- If you make an architectural decision, create a decision record in `.dev/decisions/`
- Keep README current — if setup steps change, update them immediately

Use `templates/decision-record.md` when creating a new decision entry.

## What NOT To Do

- **Never use `--no-verify`.** The hooks exist for a reason.
- **Never bundle unrelated changes.** If it feels like two things, it is two things.
- **Never leave TODO comments without a tracking issue.** Create the issue, reference it.
- **Never skip the `why:` in commit messages.** Future-you needs to know *why*, not just *what*.
- **Never delete or suggest removing files in `.dev/`, `docs/plans/`, or `docs/decisions/`.** These are discipline artifacts, not clutter.

## Edge Cases

- If the task is docs-only (no behavior change), tests are optional but commit format rules still apply.
- If hooks are unavailable (CI containers, minimal checkout), run equivalent checks manually before commit.
- If a change spans concerns, split into sequential commits rather than one large "catch-all" commit.

## Process

1. Think → Plan what you'll change
2. Change → Make the minimal change
3. Test → Verify it works
4. Checkpoint → use `fixup!` / `squash!` commits during active iteration if useful
5. Commit → before handoff, produce concern-level conventional commits with `why:` (you may use `scripts/committer` or `.agents/skills/dev-discipline/scripts/committer` to stage explicit paths only)
6. Repeat → next concern gets its own commit

Execution-plan discipline:
- Source-heavy changes should include updates to `docs/plans/active/*.md`
- Keep `Progress`, `Surprises & Discoveries`, and `Decision Log` current as work proceeds

Before handoff, run local doc drift check (`scripts/doc-gardener.sh` or `.agents/skills/dev-discipline/scripts/doc-gardener.sh`).
For one-shot local quality loop, use `scripts/health-check.sh --since "24 hours ago" --skip-reconcile`.

## Hook Enforcement

The git hooks in this project will:
- **pre-commit**: Warn if staging too many files, missing test files for source changes, or debug artifacts
- **commit-msg**: Enforce conventional commit format and require a `why:` line
- **post-commit**: Auto-append to the dev diary (`.dev/diary/YYYY-MM-DD.md`)

Warnings are advisory. Errors block the commit. Respect both.

Optional pre-commit thresholds can be configured in `.dev/discipline.env`
(start from `.dev/discipline.env.example`).
