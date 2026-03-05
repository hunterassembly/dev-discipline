---
name: planner
description: >
  Ensures implementation plans follow the Codex Exec Plans standard. Use when creating,
  updating, or reviewing plan files under docs/plans/active/. Produces compliant plans
  with required sections, living progress updates, and explicit user-benefit steps.
license: MIT
metadata:
  author: hunterassembly
  version: "0.1.0"
---

# Planner

Use this skill to keep implementation plans compliant with the Codex Exec Plans format.

## Routing Guidance

- Use when: drafting or updating `docs/plans/active/*.md` plans, or reviewing plan compliance
- Do not use when: task is trivial and does not need an implementation plan
- Primary outputs: an execution plan that passes validation and is useful for handoff/resume

## Source

- Codex Exec Plans: https://developers.openai.com/cookbook/articles/codex_exec_plans

## Required Structure

Every active plan must include these sections:

1. `Purpose / Big Picture`
2. `Progress`
3. `Surprises & Discoveries`
4. `Decision Log`
5. `Outcomes & Retrospective`
6. `Context and Orientation`
7. `Plan of Work`
8. `Architecture Impact`
9. `Concrete Steps`
10. `Validation and Acceptance`
11. `Idempotence and Recovery`
12. `Artifacts and Notes`
13. `Interfaces and Dependencies`

## Process

1. Start from `templates/exec-plan.md` (or `docs/plans/active/plan-template.md`).
2. Fill all required sections with concrete repo-specific details.
3. In `Concrete Steps`, include a `User benefit:` line for each step.
4. In `Architecture Impact`, state whether `ARCHITECTURE.md` must be updated.
5. Add checklist entries under `Progress` and keep them updated as work advances.
6. Run validator:
   - `scripts/validate-plan.sh docs/plans/active/<plan>.md`
7. If architecture changed, update `ARCHITECTURE.md` and validate it:
   - `scripts/validate-architecture.sh`
8. If validation fails, fix and rerun until clean.

## Output Contract

When returning a plan review, provide:

- Compliance status (`pass` or `fail`)
- Missing/invalid sections
- Progress hygiene issues
- Missing user-benefit narratives
- Exact file path validated
