---
name: orchestrator
description: >
  Coordination contract for multi-agent orchestrators (Symphony, Codex, etc.).
  Use when decomposing work into tasks for multiple agents. Defines branching
  strategy, agent identity, plan requirements, and merge protocol.
  Do not use for single-agent workflows — agents should read dev-discipline instead.
license: MIT
metadata:
  author: hunterassembly
  version: "0.1.0"
---

# Orchestrator Contract

You are coordinating multiple agents working on the same codebase. This project uses dev-discipline for commit hygiene. Follow these rules when decomposing and assigning work.

## Routing Guidance

- Use when: orchestrating multiple agents on a shared codebase, decomposing features into agent tasks, managing parallel workstreams
- Do not use when: single-agent session (use dev-discipline skill instead)
- Primary outputs: well-scoped agent task assignments with branch isolation and merge gates

## Rules

### 1. One concern per agent

Each agent gets exactly one logical concern. Don't assign "build auth and update the header" to one agent. Split them into separate tasks with separate agents.

### 2. Branch per task

Each agent works on its own branch off the base branch. Name branches:

```
agent/<agent-id>/<concern>
```

Examples:
- `agent/agent-1/add-rate-limiting`
- `agent/agent-2/fix-header-layout`

Never assign multiple agents to the same branch.

### 3. Set AGENT_ID

Pass the agent identifier as an environment variable:

```bash
AGENT_ID=agent-1 <your agent command>
```

This tags diary entries and findings so work is attributable across concurrent agents.

### 4. Plan requirement

If a task will touch 5+ source files, include this in the agent's task description:

> Before coding, create an execution plan at `docs/plans/active/<branch-name>.md` using the template at `docs/plans/active/plan-template.md`.

The pre-commit hook will block significant changes without a plan regardless, but telling the agent upfront avoids a failed commit cycle.

### 5. Agent bootstrap

Every agent must, before writing code:

1. Read `.dev/contract.md`
2. Check the scoped findings file for this branch or `AGENT_ID` under `.dev/findings/` when present; otherwise read `.dev/FINDINGS.md`
3. Scan `.dev/learnings/` for relevant patterns
4. Understand its assigned scope — don't drift into other agents' concerns

### 6. Merge protocol

Before merging an agent's branch:

1. Clean up commit history on that branch:
   - checkpoint `fixup!` / `squash!` commits are allowed during implementation,
   - but handoff history should be consolidated into concern-level commits with clear `why:` lines.
2. Run the branch reconciliation merge gate:

```bash
scripts/reconcile-branch.sh agent/<agent-id>/<concern> --base main
```

This always runs deterministic merge checks first and only escalates to LLM review automatically when the branch looks broad or risky. Force review for critical branches with `--review always`, or skip it explicitly with `--review never` when you only want the deterministic gate.
The script hard-fails if checkpoint commits remain or if non-checkpoint commits are missing `why:` lines.

Do not merge branches with a NEEDS WORK verdict. Assign the same agent to fix findings first.

### 7. Merge order

When multiple branches are ready:
- Merge branches that don't touch overlapping files first
- For branches with overlapping files, merge sequentially and let the later agent resolve conflicts on its branch before re-running reconciliation

## What the orchestrator does NOT do

- Don't modify `.dev/` files directly — agents do that through hooks and reconciliation
- Don't bypass hooks (`--no-verify`) on behalf of agents
- Don't merge without running branch reconciliation
- Don't assign cleanup of `.dev/`, `docs/plans/`, or `.dev/decisions/` — these are protected artifacts
