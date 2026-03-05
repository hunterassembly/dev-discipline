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
