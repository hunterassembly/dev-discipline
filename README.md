# Dev Discipline

Git hooks and agent skills that keep AI coding agents honest. One concern per commit, real `why:` lines, test coverage, and no sloppy shortcuts.

Built on the [open agent skills standard](https://agentskills.io). Works with Claude Code, Codex CLI, and any agent that runs git.

## The Problem

AI agents write code fast and commit garbage. They bundle 12 unrelated changes into one commit with the message "update code." They skip tests. They leave `console.log` everywhere. They make architectural decisions and document nothing.

You can put rules in your system prompt. Agents will ignore them when it's convenient.

Dev Discipline moves enforcement to git hooks — where agents can't talk their way past it.

## Before / After

Without dev-discipline, an agent commits this:

```
$ git commit -m "update auth and fix styles and add tests"

[main abc1234] update auth and fix styles and add tests
 14 files changed, 847 insertions(+), 203 deletions(-)
```

Three concerns, no explanation, no one will ever understand why.

With dev-discipline installed:

```
$ git commit -m "update auth and fix styles and add tests"
❌ Commit message doesn't follow conventional format.
   Expected: type(scope): description
❌ Missing 'why:' line in commit message.
Commit blocked. Fix your commit message.
```

The agent fixes it:

```
$ git commit -m "feat(auth): add rate limiting to login endpoint

why: brute-force attacks were hitting 100k attempts/day"

✅ [main def5678] feat(auth): add rate limiting to login endpoint
 3 files changed, 42 insertions(+)
```

One concern. Conventional format. The reasoning captured forever.

## What It Does

Four skills that work as a pipeline:

| Skill | Purpose |
|-------|---------|
| **dev-discipline** | Work contract + git hooks. Rules the agent reads before coding; hooks enforce on every commit. |
| **planner** | Execution plan validation. Non-trivial work requires a living plan with progress tracking. |
| **dev-diary** | Automatic commit log. Post-commit hook writes entries; the skill summarizes and navigates them. |
| **dev-reconciliation** | End-of-session audit. Reviews all commits for atomicity, test gaps, doc staleness. Writes findings to `.dev/FINDINGS.md` for the next session. |

## Quick Start

**One command:**

```bash
git clone https://github.com/hunterassembly/dev-discipline.git ~/.dev-discipline
~/.dev-discipline/scripts/new-project-bootstrap.sh
```

This installs skills to `~/.agents/skills/` and sets up hooks in your current repo.

**Or add to a specific project:**

```bash
# From your project root
git submodule add https://github.com/hunterassembly/dev-discipline.git .dev-discipline
.dev-discipline/scripts/new-project-bootstrap.sh
```

**What setup does:**
- Installs `pre-commit`, `commit-msg`, and `post-commit` hooks
- Creates `.dev/` directory (contract, decisions, worklog, diary)
- Scaffolds `AGENTS.md`, `ARCHITECTURE.md`, `docs/`, and `evals/` if missing
- Bridges into `AGENTS.md` and `CLAUDE.md` so agents load the contract automatically

## What Gets Enforced

### At commit time (hooks)

**pre-commit:**
- Warns if too many files staged (is this really one concern?)
- Warns if changes span too many directories
- Warns if source files changed but no test files included
- Blocks if debug statements detected (`console.log`, `debugger`, `breakpoint()`, `binding.pry`)
- Blocks if merge conflict markers found
- Blocks significant source changes (5+ files) without an execution plan — auto-scaffolds a plan file from the template
- Validates plan structure on any changed plan files

**commit-msg:**
- Blocks non-conventional commit messages (must be `type(scope): description`)
- Blocks missing `why:` line
- Blocks `why:` lines that are too short (<10 chars), restate the subject, or use filler phrases

**post-commit:**
- Silently appends commit metadata to `.dev/diary/YYYY-MM-DD.md`

### At session boundaries (reconciliation)

The reconciliation skill audits recent commits and produces a report covering:
- Commit atomicity (single concern?)
- Test gap analysis
- Commit message quality
- Doc staleness
- Undocumented architectural decisions
- Hook bypass detection (commits missing diary entries)

Open findings get extracted to `.dev/FINDINGS.md` — a tracked file that agents read at the start of their next session. When findings are resolved (checked off), the next reconciliation archives them to `.dev/learnings/` as institutional memory — category files (`test-gaps.md`, `doc-updates.md`, `decisions.md`) that accumulate over time and agents scan before starting work.

### Through plans (planner)

Non-trivial work requires a living execution plan in `docs/plans/active/`. Plans have 13 required sections including Architecture Impact, Idempotence and Recovery, and a Progress checklist that stays updated as work proceeds.

When the pre-commit hook blocks for a missing plan, it auto-scaffolds one from the template so the agent has a concrete file to fill in.

## Configuration

Copy `.dev/discipline.env.example` to `.dev/discipline.env` and adjust thresholds:

```bash
DEV_DISCIPLINE_WARN_FILE_COUNT=10        # Warn above this many files
DEV_DISCIPLINE_LARGE_FILE_COUNT=20       # Stronger warning
DEV_DISCIPLINE_WARN_DIR_COUNT=4          # Warn if changes span this many dirs
DEV_DISCIPLINE_PLAN_REQUIRED_SOURCE_FILE_COUNT=5  # Block without plan above this
```

See [`docs/refs/hook-config.md`](docs/refs/hook-config.md) for the full reference.

## Commands

| Command | What it does |
|---------|-------------|
| `scripts/new-project-bootstrap.sh` | One-command install + setup |
| `scripts/health-check.sh --since "24h ago"` | Full local quality loop |
| `scripts/doc-gardener.sh --since "24h ago"` | Docs/plan drift scanner |
| `scripts/docs-list.sh` | Validate docs front matter |
| `scripts/committer "fix: ..." file1 file2` | Stage-only-these-files commit helper |
| `scripts/test.sh` | Run integration tests |
| `scripts/planner docs/plans/active/<plan>.md` | Validate plan format |
| `scripts/validate-architecture.sh` | Validate ARCHITECTURE.md |

## What Gets Committed?

| Path | Tracked? | Purpose |
|------|----------|---------|
| `.dev/contract.md` | Yes | Discipline rules (shared with team) |
| `.dev/decisions/` | Yes | Architectural decision records |
| `.dev/WORKLOG.md` | Yes | Project worklog |
| `.dev/FINDINGS.md` | Yes | Open items from last reconciliation |
| `.dev/learnings/` | Yes | Archived resolved findings (institutional memory) |
| `.dev/diary/` | No | Auto-generated commit diary (local) |
| `.dev/.last-reconciliation` | No | Reconciliation timestamp (local) |

## Uninstall

```bash
~/.agents/skills/dev-discipline/scripts/teardown.sh
```

Removes hooks and bridge references from AGENTS.md/CLAUDE.md. Does not delete `.dev/` — that's your data.

## Philosophy

- **Hooks enforce, instructions guide.** System prompts get ignored. Git hooks don't.
- **Warn, don't block** (mostly). Pre-commit warnings keep flow. Commit-msg errors block — bad messages are never worth it.
- **Keep hooks dumb and fast.** No AI calls in hooks. Shell only. Save AI for reconciliation.
- **The diary writes itself.** Post-commit logs metadata. AI summarizes later.
- **Feedback loops close.** Reconciliation findings feed into the next session automatically.

## License

[MIT](LICENSE)
