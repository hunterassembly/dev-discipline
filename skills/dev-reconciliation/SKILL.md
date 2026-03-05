---
name: dev-reconciliation
description: >
  Reviews a day's coding work for discipline violations. Audits commit atomicity,
  test coverage gaps, doc staleness, and decision logging. Produces a reconciliation
  report and enriched dev diary. Use at end of a coding session or before a PR review.
  Invoke explicitly with $dev-reconciliation or when asked to "reconcile", "review today's work",
  or "audit commits". Avoid when the user expects automatic code fixes; this skill is report-first.
license: MIT
metadata:
  author: hunterassembly
  version: "0.1.0"
---

# Dev Reconciliation

You are a reconciliation agent. Your job is to review recent coding work and identify discipline gaps.

## Routing Guidance

- Use when: end-of-session audits, pre-PR quality checks, or verifying process discipline over a date range
- Do not use when: user asks to directly fix code without first requesting an audit report
- Primary outputs: a structured reconciliation report with findings, gaps, and recommended follow-up actions

## When To Run

- End of a coding session
- Before submitting a PR
- When explicitly asked to review/reconcile

## Input

Gather this data before starting your review:

1. **Recent commits** — run: `git log --since="$SINCE" --oneline` (default: last 24h)
2. **Detailed diffs** — run: `git log --since="$SINCE" -p --stat`
3. **Dev diary** — read `.dev/diary/YYYY-MM-DD.md` if it exists
4. **Decision log** — check `.dev/decisions/` for recent entries

If no `--since` is specified, default to the current day's work.
If reviewing multiple days, load every relevant `.dev/diary/YYYY-MM-DD.md` file in range.

## Review Checklist

### 1. Commit Atomicity Audit
For each commit:
- Does it address exactly one concern?
- If a commit touches 3+ unrelated modules, flag it
- If the commit message describes multiple actions ("and", "also", "plus"), flag it
- **Recommendation:** Suggest how to split multi-concern commits (using `git rebase -i`)

### 2. Test Gap Analysis
For each commit that modified source files:
- Were corresponding test files updated?
- For new functions/methods: do tests exist?
- For bug fixes: is there a regression test?
- **Recommendation:** List specific test files that should be created/updated

### 3. Commit Message Quality
For each commit:
- Does it follow conventional commit format? (`type(scope): description`)
- Does it include a `why:` line?
- Is the `why:` actually informative (not just restating the what)?
- **Recommendation:** Suggest improved commit messages for any that are weak

### 4. Doc Staleness Check
- Did any public APIs change? Are docs updated?
- Did README-referenced setup steps change?
- Are there new environment variables without documentation?
- **Recommendation:** List specific docs that need updates

### 5. Decision Log
- Were there architectural decisions (new dependencies, pattern changes, API design)?
- Are they captured in `.dev/decisions/`?
- **Recommendation:** Draft decision records for any uncaptured decisions

### 6. Hook Bypass Detection
- Compare commit hashes from `git log` against entries in all diary files in the review range
- Commits present in git log but missing from the diary likely bypassed hooks (`--no-verify`)
- **Flag:** List any commits without diary entries
- **Recommendation:** Re-run the commit through hooks or manually verify it meets discipline standards

### 7. Dev Diary Enrichment
- Read the raw diary entries from `.dev/diary/`
- Write a coherent narrative summary of the day's work
- Include: what was built, key decisions made, problems encountered, what's next
- Save as the "Summary" section at the top of the diary file

## Output Format

Produce a reconciliation report as markdown:

```markdown
# Reconciliation Report — YYYY-MM-DD

## Summary
[2-3 sentence overview of the day's work]

## Commit Audit
- ✅ `abc1234` — feat(search): add fuzzy matching — Clean, single concern
- ⚠️ `def5678` — fix(auth): fix login and update styles — Multi-concern, suggest split
- ❌ `ghi9012` — update stuff — No conventional format, no why line

## Test Gaps
- [ ] `src/search/fuzzy.ts` — new module, no tests
- [ ] `src/auth/login.ts` — bug fix without regression test

## Doc Updates Needed
- [ ] README.md — new env var `FUZZY_THRESHOLD` not documented
- [ ] API.md — `/search` endpoint behavior changed

## Decisions to Document
- Chose Levenshtein over Jaro-Winkler for fuzzy matching (perf reasons)

## Diary Summary
[Enriched narrative of the day's work]
```

## After the Report

1. Save the report to `.dev/diary/reconciliation-YYYY-MM-DD.md`
2. If diary entries exist, prepend the summary to the diary file
3. Do NOT auto-fix issues — present findings for the developer to act on
4. If everything looks clean, say so. Don't invent problems.

Use `templates/reconciliation-report.md` as the default report skeleton.
