---
summary: "Simple quality scoreboard for local discipline signals."
read_when:
  - Checking project health before handoff or release.
---

# Quality Score

This scoreboard tracks lightweight, local-first quality signals.
Update it from local audits (for example `scripts/doc-gardener.sh` and reconciliation reports).

## Scoring Model

- **Docs coverage signal (0-100):** documentation updates relative to source changes
- **Plan hygiene signal (0-100):** whether active plan artifacts are maintained for in-flight work
- **Decision signal (0-100):** whether architecture-impacting changes are logged in decision records
- **Eval coverage signal (0-100):** whether behavior-changing work is accompanied by eval updates
- **Overall score (0-100):** average of the four signals

## Interpretation

- `90-100`: strong discipline, low drift risk
- `75-89`: good baseline, minor maintenance needed
- `60-74`: medium drift, prioritize docs/plan cleanup
- `<60`: high drift, run local cleanup before major changes

## Latest Snapshot

- Date: _not set yet_
- Overall: _n/a_
- Docs coverage: _n/a_
- Plan hygiene: _n/a_
- Decision signal: _n/a_
- Eval coverage: _n/a_
- Source report: _n/a_

## Run History

| Date | Overall | Docs | Plans | Decisions | Evals | Source Report |
|------|---------|------|-------|-----------|-------|---------------|
