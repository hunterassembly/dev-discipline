---
summary: "Session-start pickup playbook for quickly rehydrating repository context."
read_when:
  - Starting work on an existing branch or interrupted task.
---

# /pickup

Goal: regain full context fast and avoid redundant or conflicting edits.

## Steps

1. Check working tree and branch state.
2. Review latest commits and changed files.
3. Read relevant docs (`docs-list` output and linked docs).
4. Confirm active objective and expected outcome.
5. Note unresolved risks before editing.

## Minimum Commands

```bash
git status -sb
git log --oneline -n 15
git diff --name-only
scripts/docs-list.sh
```

## Output Contract

- Current state summary (2-4 lines)
- What is safe to change now
- What must be verified before handoff
