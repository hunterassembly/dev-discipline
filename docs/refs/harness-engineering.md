---
summary: "Practical harness-engineering loop for agent-ready repositories."
read_when:
  - Establishing or auditing how a repo supports autonomous agents.
---

# Harness Engineering

This repo models a harness-engineering workflow: structure context for agents, evaluate behavior continuously, and prune entropy.

## Loop

1. Encode context in short, stable docs (`AGENTS.md`, `ARCHITECTURE.md`, `docs/design`, `docs/refs`).
2. Build with explicit commit/test/doc discipline (`dev-discipline` hooks).
3. Track quality drift and reconciliation outputs (`docs/quality`, `.dev/diary`).
4. Maintain eval assets close to code (`evals/`).
5. Use living execution plans for non-trivial implementation (`.agent/PLANS.md`, `docs/plans/active/`).
6. Perform periodic entropy cleanup (stale plans, docs drift, dead artifacts).

## Minimum Operating Checklist

- `AGENTS.md` routes to key docs and rules.
- `ARCHITECTURE.md` provides a concise map of boundaries and invariants.
- `.dev/contract.md` exists and is enforced by hooks.
- `docs/design/core-beliefs.md` defines non-negotiables.
- `evals/` contains cases and rubrics for critical behavior.
- `.agent/PLANS.md` defines execution-plan operating expectations.
- End-of-session reconciliation is part of handoff.

## Source References

- OpenAI Harness Engineering: https://openai.com/index/harness-engineering/
- Codex Exec Plans: https://developers.openai.com/cookbook/articles/codex_exec_plans
- Matklad ARCHITECTURE.md approach: https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html
- Eval-driven system design cookbook: https://cookbook.openai.com/examples/evaluation/use-cases/eval-driven_system_design_from_prototype_to_production
- OpenAI Evals guide: https://platform.openai.com/docs/guides/evals
