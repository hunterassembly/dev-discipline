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
- Move completed plans to `docs/plans/completed/`.

## Enforcement

- `pre-commit` warns on source changes without plan updates.
- `pre-commit` blocks significant source changes without plan updates.
- `pre-commit` validates required execution-plan sections for changed plan files.
