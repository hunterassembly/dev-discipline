---
summary: "Pass/fail rubric for operational AGENTS.md quality."
read_when:
  - Creating or auditing AGENTS.md guidance for a repo.
---

# AGENTS.md Quality Checklist

Use this checklist to evaluate whether an `AGENTS.md` is actually operational.
If a section fails, fix it before relying on the agent in production repos.

## 1) Ownership + Intent

- [ ] Names an owner and contact path (who to ask when docs conflict)
- [ ] States mission in 1-2 lines (what this repo optimizes for)
- [ ] Defines communication style (verbosity, format, decision logging)

Why this matters:
Clear ownership and style reduce hesitation and rework when edge cases appear.

## 2) Runtime + Workspace Topology

- [ ] Defines canonical workspace root(s) and clone locations
- [ ] Explains host switching rules (local vs remote, SSH behavior)
- [ ] Lists critical paths (runbooks, keys, dashboards, docs)
- [ ] States where to place 3rd-party vs first-party repos

Why this matters:
Agents spend less time discovering context and more time shipping.

## 3) Safety Guardrails (Non-Negotiable)

- [ ] Explicitly bans destructive git/file operations without consent
- [ ] Requires safe delete method (for example `trash` instead of `rm`)
- [ ] Defines branch/push permissions and consent boundaries
- [ ] Covers code-signing/security-sensitive operations

Why this matters:
Prevents irreversible damage and protects trust in autonomous edits.

## 4) Execution Protocol

- [ ] Defines commit format and scope rules (for example Conventional Commits)
- [ ] Requires regression tests for bug fixes when appropriate
- [ ] Sets file size/complexity limits and split guidance
- [ ] Defines review behavior for external PR feedback

Why this matters:
Consistency and smaller units make reviews and rollbacks safer.

## 5) Verify-Until-Green Loop

- [ ] Requires local gate before handoff (lint/typecheck/tests/docs)
- [ ] Defines how to investigate and rerun any shared verification step beyond the local gate
- [ ] States fallback when blocked (what is missing, what was attempted)
- [ ] Encourages end-to-end verification over partial checks

Why this matters:
Delivery quality becomes observable instead of assumed.

## 6) Tooling Contract

- [ ] Lists preferred tools and exact invocation patterns
- [ ] Documents required “first-run” setup commands
- [ ] Includes fallback tools when primary path fails
- [ ] Keeps tool catalog path up to date

Why this matters:
Fewer ad-hoc choices, lower variance between sessions/agents.

## 7) Documentation Workflow

- [ ] Requires docs discovery before coding (`docs:list`/equivalent)
- [ ] Requires doc updates when behavior/API changes
- [ ] Defines cross-link/read-when guidance for related docs

Why this matters:
Knowledge stays current, reducing repeated mistakes.

## 8) Prompt Ergonomics

- [ ] Uses short, actionable bullets over long prose
- [ ] Separates hard rules from preferences
- [ ] Includes examples for high-risk workflows
- [ ] Avoids contradictory instructions

Why this matters:
Agents follow precise instructions more reliably than ambiguous text.

## Quick Score

- 0-5 missing: Strong
- 6-10 missing: Usable but risky
- 11+ missing: Rewrite recommended

## Copy-Ready Starter Section

Paste into a new `AGENTS.md` and tailor quickly:

```md
## Agent Operating Contract
- Owner: <name> (<contact>)
- Mission: <1 line>
- Work style: <verbosity/format>
- Workspace roots: <paths>
- Safety: no destructive git/file ops without explicit consent
- Commits: Conventional Commits; one concern per commit
- Verification: run lint/typecheck/tests/docs before handoff
- Shared verification: inspect failures, rerun, fix until green
- Docs: read docs index before coding; update docs with behavior/API changes
```
