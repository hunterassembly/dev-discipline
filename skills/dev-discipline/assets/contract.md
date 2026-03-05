# Dev Discipline Contract

Before writing any code, read and follow these rules.

## Commit Rules

- **One concern per final commit.** Don't mix refactors with features, formatting with bug fixes.
- **Concern-level, not keystroke-level.** You do not need a commit for every tiny edit.
- **Fast checkpoints are allowed.** Use `fixup!` / `squash!` commits during active iteration when helpful.
- **Clean before handoff.** Before review/merge, squash checkpoint commits into 1-3 concern-level commits with strong `why:` lines.
- **Conventional commit format:**
  ```
  type(scope): description

  why: one-line explanation of the decision or motivation
  ```
  Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`, `ci`, `build`, `revert`
- **The `why:` line is mandatory.** It captures reasoning, not just what changed.
- **Flag concerns.** If you're worried about something in a commit, add a `concern:` line to the message body. It gets logged in the diary for reconciliation to review.
- **Never use `--no-verify`.** The git hooks exist for a reason.

## Testing Rules

- Behavioral changes require tests. If you changed what code *does*, prove it works.
- Bug fixes require regression tests. Show the bug existed, show it's fixed.
- Refactors should not change test outcomes.

## Documentation Rules

- If you change a public API, update its documentation.
- If you make an architectural decision, create a record in `.dev/decisions/`.
- Keep README current.

## Process

0. **Check** — Read `.dev/FINDINGS.md` if it exists. Resolve open items first. Scan `.dev/learnings/` for relevant patterns.
1. **Think** — Plan what you'll change
2. **Change** — Make the minimal change
3. **Test** — Verify it works
4. **Checkpoint** — During active work, use `fixup!` / `squash!` commits if needed
5. **Commit** — Before handoff, produce concern-level conventional commits with `why:`
6. **Repeat** — Next concern gets its own commit

## What NOT To Do

- Never bundle unrelated changes into one commit.
- Never leave TODO comments without a tracking issue.
- Never skip the `why:` in commit messages.
- Never use `--no-verify` to bypass git hooks.
- Never delete or suggest removing files in `.dev/`, `docs/plans/`, or `docs/decisions/`. These are discipline artifacts, not clutter.
