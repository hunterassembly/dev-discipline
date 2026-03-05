---
summary: "Execution-plan playbook for creating and validating Codex Exec Plans."
read_when:
  - Starting non-trivial implementation work that needs a living plan.
---

# /planner

Goal: ensure implementation work has a compliant, living execution plan before major coding changes.

## Inputs

- Initiative title
- Target files/scope
- Success criteria and validation checks

## Steps

1. Start from `docs/plans/active/plan-template.md`.
2. Fill all required execution-plan sections.
3. For each concrete step, add a `User benefit:` line.
4. Update `Progress`, `Surprises & Discoveries`, and `Decision Log` as work proceeds.
5. Validate with:
   - `./scripts/planner docs/plans/active/<plan>.md`

## Output Contract

- Plan file under `docs/plans/active/`
- All required sections present
- User-benefit narrative included for each concrete step
- Validator returns success
