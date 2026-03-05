# Contributing

## Setup

```bash
git clone https://github.com/hunterassembly/dev-discipline.git
cd dev-discipline
scripts/new-project-bootstrap.sh
```

This installs the hooks on this repo itself — we eat our own dogfood.

## Making Changes

1. Read `.dev/contract.md` before you start
2. Check `.dev/FINDINGS.md` for open items
3. One concern per commit, conventional format, `why:` line
4. Run `scripts/test.sh` before pushing
5. Run `scripts/health-check.sh --since "24 hours ago"` for a full quality pass

## Tests

```bash
scripts/test.sh
```

Integration tests live in `tests/`. They spin up temporary repos, install hooks, and verify enforcement behavior.

## Project Structure

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the system map — boundaries, invariants, and runtime flows.

Key directories:
- `skills/` — Skill packages (the actual product)
- `scripts/` — User-facing wrapper scripts
- `docs/` — Operational guidance, references, and workflow playbooks
- `tests/` — Integration tests

## Docs Conventions

All docs under `docs/` require YAML front matter:

```yaml
---
summary: "One-line description."
read_when:
  - "When you need to understand X."
---
```

This metadata enables agent routing — agents use `summary` and `read_when` to decide which docs to load.

## Releasing

Update `CHANGELOG.md` under `## Unreleased`, then tag.
