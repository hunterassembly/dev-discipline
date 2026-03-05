---
summary: "Architecture playbook for keeping ARCHITECTURE.md current and enforceable."
read_when:
  - Changing system boundaries, invariants, or high-level runtime flows.
---

# /architecture

Goal: keep `ARCHITECTURE.md` as a concise, reliable map of boundaries, invariants, and major flows.

## Inputs

- Planned or completed architecture-affecting changes
- Updated module/path ownership details
- Boundary or invariant decisions made during implementation

## Steps

1. Open `ARCHITECTURE.md` and update impacted sections (code map, flows, invariants, boundaries).
2. Keep content orientation-focused; avoid turning it into a full design spec or changelog.
3. Ensure non-goals are explicit in `What We Deliberately Do Not Do`.
4. In the active execution plan, set `Architecture Impact` and reference this update.
5. Validate with:
   - `./scripts/validate-architecture.sh ARCHITECTURE.md`

## Output Contract

- `ARCHITECTURE.md` reflects current architecture boundaries/invariants
- Execution plan documents architecture impact (`yes`/`no` + rationale)
- Architecture validator returns success
