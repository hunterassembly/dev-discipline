---
summary: "End-of-session reconciliation playbook for commit discipline and test/doc gaps."
read_when:
  - Auditing recent work before PR or session end.
---

# /reconcile

Goal: produce a reconciliation report that identifies process and quality gaps without auto-fixing code.

## Inputs

- Optional time range (default: last 24 hours)
- Current repo state and recent commits

## Steps

1. Gather commits and diffs for the target range.
2. Compare commit history to diary entries (if diary exists).
3. Audit:
   - commit atomicity
   - test coverage gaps
   - commit message quality (`why:` included)
   - doc staleness
   - missing decision records
4. Produce a markdown report with actionable checklists.

## Output Contract

- Start with `# Reconciliation Report — YYYY-MM-DD`
- Include:
  - Summary
  - Commit Audit
  - Test Gaps
  - Doc Updates Needed
  - Decisions to Document
  - Possible Hook Bypasses
  - Diary Summary
