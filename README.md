# Dev Discipline

Agent Skills for AI coding discipline. Built on the [open agent skills standard](https://agentskills.io).

Works with [Codex CLI](https://github.com/openai/codex), Claude Code, and any agent that supports the skills spec.

## What It Does

Three-layer system that enforces coding discipline without killing speed:

1. **`dev-discipline`** — Work contract + git hooks. The agent reads the rules before coding; hooks enforce them on every commit.
2. **`dev-diary`** — Automatic commit log. Post-commit hook writes entries; the skill helps you review and navigate them.
3. **`dev-reconciliation`** — End-of-session audit. Reviews all commits for atomicity, test gaps, doc staleness, and decision documentation.

## Install

### In a project (repo-scoped)

Copy the skills into your project:

```bash
# From your project root
mkdir -p .agents/skills
cp -r path/to/dev-discipline/skills/* .agents/skills/
```

Or add as a git submodule:

```bash
git submodule add https://github.com/hunterassembly/dev-discipline.git .dev-discipline
ln -s ../.dev-discipline/skills/dev-discipline .agents/skills/dev-discipline
ln -s ../.dev-discipline/skills/dev-diary .agents/skills/dev-diary
ln -s ../.dev-discipline/skills/dev-reconciliation .agents/skills/dev-reconciliation
```

### For all projects (user-scoped)

```bash
cp -r skills/* ~/.agents/skills/
```

### Setup

Run the setup script to install git hooks:

```bash
.agents/skills/dev-discipline/scripts/setup.sh
```

This will:
- Install pre-commit, commit-msg, and post-commit hooks
- Create `.dev/diary/`, `.dev/decisions/`, and `.dev/WORKLOG.md`
- Add `.dev/diary/` to `.gitignore`

## Skills

### `dev-discipline`
The core discipline contract. Activates on any code change task.

**Enforces:**
- One concern per commit
- Conventional commit messages with `why:` lines
- Test coverage for behavioral changes
- No debug artifacts in commits

**Git hooks:**
- `pre-commit` — Warns on large commits, missing tests, debug statements, conflict markers
- `commit-msg` — Blocks non-conventional messages, requires `why:` line
- `post-commit` — Auto-appends diary entry (timestamp, hash, files, stats)

### `dev-diary`
Reviews and navigates the auto-generated commit diary.

**Can:**
- Summarize today's work
- Generate standup updates
- Find when specific files changed

### `dev-reconciliation`
End-of-session audit agent.

**Reviews:**
- Commit atomicity (single concern?)
- Test gap analysis (behavioral changes covered?)
- Commit message quality
- Doc staleness
- Uncaptured architectural decisions

**Run standalone:**
```bash
.agents/skills/dev-reconciliation/scripts/reconcile.sh --since "8 hours ago"
```

## What Gets Committed?

When you run setup, `.dev/` is created with both tracked and local-only content:

| Path | Tracked? | Purpose |
|------|----------|---------|
| `.dev/contract.md` | ✅ Yes | Discipline rules (shared with team) |
| `.dev/decisions/` | ✅ Yes | Architectural decision records |
| `.dev/WORKLOG.md` | ✅ Yes | Project worklog |
| `.dev/diary/` | ❌ No (gitignored) | Auto-generated commit diary (local) |
| `.dev/.last-reconciliation` | ❌ No | Reconciliation timestamp (local) |

## Uninstall

```bash
.agents/skills/dev-discipline/scripts/teardown.sh
```

Removes hooks, bridge references from AGENTS.md/CLAUDE.md, and Claude Code rules. Does **not** delete `.dev/` (that's your data).

## Philosophy

- **Hooks enforce, instructions guide.** AGENTS.md tells the agent what to do; hooks verify it happened.
- **Warn, don't block** (mostly). Pre-commit warnings don't kill flow. Commit-msg errors do block — bad messages are never worth it.
- **Keep hooks dumb and fast.** No AI calls in hooks. Save AI for reconciliation.
- **Dev diary writes itself.** Post-commit hook logs metadata. AI summarizes later.
- **Agent-agnostic.** Works with Codex, Claude Code, or any tool that runs git.

## Structure

```
skills/
├── dev-discipline/
│   ├── SKILL.md              # Work contract + rules
│   ├── scripts/
│   │   └── setup.sh          # Install hooks, create dirs
│   └── assets/
│       ├── pre-commit         # Diff analysis, test check
│       ├── commit-msg         # Conventional commit enforcement
│       └── post-commit        # Dev diary auto-append
├── dev-diary/
│   └── SKILL.md              # Diary review + navigation
└── dev-reconciliation/
    ├── SKILL.md              # Reconciliation agent instructions
    └── scripts/
        └── reconcile.sh      # Standalone reconciliation launcher
```

## License

Apache-2.0
