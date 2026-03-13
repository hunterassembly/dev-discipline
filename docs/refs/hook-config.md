---
summary: "Hook threshold configuration for commit-size and plan-enforcement tuning."
read_when:
  - Adjusting pre-commit strictness for team size or repo complexity.
---

# Hook Configuration

`pre-commit` reads optional config from `.dev/discipline.env` (or `DEV_DISCIPLINE_CONFIG_FILE`).

Start from `.dev/discipline.env.example` and tune as needed:

- `DEV_DISCIPLINE_WARN_FILE_COUNT` (default `10`)
- `DEV_DISCIPLINE_LARGE_FILE_COUNT` (default `20`)
- `DEV_DISCIPLINE_WARN_DIR_COUNT` (default `4`)
- `DEV_DISCIPLINE_PLAN_REQUIRED_SOURCE_FILE_COUNT` (default `8`)
- `DEV_DISCIPLINE_PLAN_REQUIRED_DIR_COUNT` (default `2`)
- `DEV_DISCIPLINE_ARCHITECTURE_WARN_SOURCE_FILE_COUNT` (default `8`)
- `DEV_DISCIPLINE_ARCHITECTURE_WARN_DIR_COUNT` (default `3`)

Plans are blocked only when broad source changes cross enough boundaries to justify the overhead. Higher thresholds reduce friction; lower thresholds increase discipline.
