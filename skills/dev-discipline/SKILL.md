---
name: dev-discipline
description: >
  Enforces commit discipline for AI coding agents. Activates on any code change task.
  Ensures one concern per commit, conventional commit messages, test coverage for behavioral
  changes, and decision documentation. Installs git hooks for automated enforcement.
  Use when starting a coding session or making code changes.
license: Apache-2.0
metadata:
  author: hunterassembly
  version: "0.1.0"
---

# Dev Discipline

You are working in a project that enforces coding discipline. Follow these rules for every code change.

## Before You Start

1. Run `scripts/setup.sh` if git hooks aren't installed yet (check: `.git/hooks/pre-commit` should be a symlink or contain dev-discipline logic)
2. Read the worklog if one exists: `.dev/WORKLOG.md`
3. Understand what you're about to change and why before writing code

## Commit Rules

### One Concern Per Commit
- Each commit addresses exactly ONE logical change
- Don't mix refactors with features
- Don't mix formatting with bug fixes
- If you catch yourself doing two things, commit the first, then start the second

### Conventional Commits
Format every commit message as:

```
type(scope): description

why: one-line explanation of the decision or motivation
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

The `why:` line is mandatory. It captures the reasoning, not just the what.

### Examples

Good:
```
feat(search): add fuzzy matching for typo tolerance

why: users frequently misspell product names, losing 12% of searches
```

Bad:
```
update search and fix header and add tests
```

## Testing Rules

- **Behavioral changes require tests.** If you changed what code *does*, prove it works.
- **Bug fixes require regression tests.** Show the bug existed, show it's fixed.
- **Refactors should not change test outcomes.** If tests break after a refactor, you changed behavior.
- Don't write tests for test coverage metrics. Write tests that verify intent.

## Documentation Rules

- If you change a public API, update its documentation
- If you make an architectural decision, create a decision record in `.dev/decisions/`
- Keep README current — if setup steps change, update them immediately

## What NOT To Do

- **Never use `--no-verify`.** The hooks exist for a reason.
- **Never bundle unrelated changes.** If it feels like two things, it is two things.
- **Never leave TODO comments without a tracking issue.** Create the issue, reference it.
- **Never skip the `why:` in commit messages.** Future-you needs to know *why*, not just *what*.

## Process

1. Think → Plan what you'll change
2. Change → Make the minimal change
3. Test → Verify it works
4. Commit → One concern, conventional format, with `why:`
5. Repeat → Next concern gets its own commit

## Hook Enforcement

The git hooks in this project will:
- **pre-commit**: Warn if staging too many files, missing test files for source changes, or debug artifacts
- **commit-msg**: Enforce conventional commit format and require a `why:` line
- **post-commit**: Auto-append to the dev diary (`.dev/diary/YYYY-MM-DD.md`)

Warnings are advisory. Errors block the commit. Respect both.
