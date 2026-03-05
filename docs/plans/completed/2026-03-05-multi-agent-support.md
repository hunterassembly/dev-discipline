---
summary: "Design for multi-agent orchestrator support in dev-discipline."
read_when:
  - Working on multi-agent coordination, orchestrator integration, or branch-based workflows.
---

# Multi-Agent Orchestrator Support

## What We're Building

Branch-native multi-agent support that adds zero overhead for single-agent users. Each agent works on its own branch, hooks enforce discipline per-branch as they already do, and a new merge-gate reconciliation script audits branch work before merge.

## Why This Approach

Git already solves distributed coordination — branches are isolation, merges are synchronization. Rather than building a coordination layer (locking, agent registries, task routing), we lean into git's existing model and add only what's missing: agent identity tagging, branch-scoped reconciliation, and an orchestrator-facing skill.

## Key Decisions

- Branch-native over coordination layer: git does the hard work, we just need conventions
- $AGENT_ID is optional and environment-set: zero impact when unset (single-agent)
- Merge-gate reconciliation is a new script, not a modification to existing session-end reconciliation
- Orchestrator skill is instructional (markdown), not enforcement (scripts)
- No orchestrator-specific adapters — generic enough for Symphony, Codex, or any system that reads markdown

## Changes

1. Post-commit hook: tag diary entries with $AGENT_ID when set
2. reconcile.sh findings extraction: tag findings with $AGENT_ID when set
3. New script: scripts/reconcile-branch.sh (branch-scoped audit)
4. New skill: skills/orchestrator/SKILL.md (orchestrator contract)
5. Doc updates: README, CHANGELOG

## What We Deliberately Don't Build

- No locking/mutex — branches are isolation
- No agent registry — orchestrator manages identity
- No orchestrator-specific integrations
- No multi-agent findings routing
- No changes to existing hooks (pre-commit, commit-msg, plan enforcement)
