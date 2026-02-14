---
name: dev-diary
description: >
  Manages the automatic dev diary — a log of all commits and work sessions.
  The post-commit hook writes raw entries; this skill helps review, summarize,
  and navigate the diary. Use when asked to "show today's work", "summarize
  what happened", or "check the dev diary".
license: Apache-2.0
metadata:
  author: hunterassembly
  version: "0.1.0"
---

# Dev Diary

The dev diary is an automatically maintained log of all commits, located in `.dev/diary/`.

## How It Works

- The `post-commit` git hook (installed by `dev-discipline`) auto-appends an entry for every commit
- Each entry includes: timestamp, commit hash, author, message, files changed, stats
- Entries are grouped by date: `.dev/diary/YYYY-MM-DD.md`
- The diary is gitignored by default (it's a local working document)

## Your Capabilities

### Review Today's Work
Read `.dev/diary/YYYY-MM-DD.md` (today's date) and present a summary:
- How many commits
- What areas of the codebase were touched
- Key changes made

### Summarize a Date Range
Read multiple diary files and produce a narrative summary of work done.

### Find When Something Changed
Search diary files for mentions of specific files, functions, or topics.

### Generate a Standup Update
Read the last 1-2 days of diary entries and draft a standup update:
- What was done
- What's in progress
- What's blocked

## Diary Entry Format

Each entry looks like:

```markdown
---

## 14:32:05 — `a1b2c3d` (Author Name)

**Message:**
feat(search): add fuzzy matching

why: users misspell product names frequently

**Stats:**  3 files changed, 47 insertions(+), 12 deletions(-)

**Files changed:**
- src/search/fuzzy.ts
- src/search/index.ts
- tests/search/fuzzy.test.ts
```

## Tips

- Diary files are append-only during work. The reconciliation skill enriches them afterward.
- If the diary seems empty, check if git hooks are installed (`scripts/setup.sh`).
- The diary is local to your machine. To share work summaries, use the reconciliation report.
