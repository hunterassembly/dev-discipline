---
summary: "Core beliefs template for harness-engineering projects."
read_when:
  - Bootstrapping a project or revisiting system-wide priorities.
---

# Core Beliefs

Use this document to keep product and engineering priorities legible to both humans and agents.

## Product Truths

- Reliability and user trust beat raw feature velocity.
- Critical-path behavior should have explicit eval coverage.
- Every release should either reduce friction or increase capability.

## Engineering Truths

- Behavior changes require tests and documented rationale.
- Agent actions should be observable through logs, traces, or artifacts.
- Prompts and policies are code; version and evaluate them.

## Decision Rules

- Prefer simple and reversible changes.
- Capture architectural choices in `.dev/decisions/`.
- Keep `AGENTS.md` short; put details in docs and references.
