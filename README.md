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

Fastest path for a brand-new or overhauled repo:

```bash
./scripts/new-project-bootstrap.sh
```

This installs/updates skills into `~/.agents/skills` and runs setup in the current repo.
Use `./scripts/new-project-bootstrap.sh --init-git /path/to/repo` to initialize git automatically.

Manual path:

Run the setup script to install git hooks:

```bash
~/.agents/skills/dev-discipline/scripts/setup.sh
```

This will:
- Install pre-commit, commit-msg, and post-commit hooks
- Create `.dev/diary/`, `.dev/decisions/`, and `.dev/WORKLOG.md`
- Add `.dev/diary/` and `.dev/.last-reconciliation` to `.gitignore`
- Scaffold missing harness-engineering artifacts (`AGENTS.md`, `.agent/PLANS.md`, docs skeleton, evals skeleton)

Optional helper scripts (repo root):

```bash
./scripts/docs-list.sh     # Validate docs front matter + list docs
./scripts/committer "fix: ..." path/to/file path/to/other
./scripts/doc-gardener.sh  # Generate local docs/plan drift report + score snapshot
./scripts/bootstrap-harness.sh # Scaffold AGENTS/docs/evals (safe to re-run)
./scripts/planner docs/plans/active/<plan>.md # Validate plan format
./scripts/sync-plan-template.sh --check # Detect drift from canonical planner template
./scripts/health-check.sh --since "24 hours ago" --skip-reconcile # One-shot local quality loop
./scripts/migrate-planner.sh # Migrate legacy exec-plan-discipline refs to planner
./scripts/validate-architecture.sh ARCHITECTURE.md # Validate architecture map headings/content
./scripts/architecture ARCHITECTURE.md # Alias for architecture validation
./scripts/test.sh # Run integration tests for hooks/scripts
./scripts/new-project-bootstrap.sh # Install skills + run setup in one command
```

If you only installed `skills/*`, run helpers from the skill path:

```bash
~/.agents/skills/dev-discipline/scripts/docs-list.sh
~/.agents/skills/dev-discipline/scripts/committer "fix: ..." path/to/file
~/.agents/skills/dev-discipline/scripts/doc-gardener.sh --since "24 hours ago"
~/.agents/skills/dev-discipline/scripts/bootstrap-harness.sh
```

### Harness Quickstart

For a new or overhauled repo, run this loop:

1. `~/.agents/skills/dev-discipline/scripts/setup.sh`
2. `~/.agents/skills/dev-discipline/scripts/docs-list.sh`
3. `~/.agents/skills/dev-discipline/scripts/doc-gardener.sh --since "24 hours ago"`
4. `~/.agents/skills/dev-reconciliation/scripts/reconcile.sh --since "24 hours ago"`
5. `/planner` (or `./scripts/planner docs/plans/active/<plan>.md`)
6. `/architecture` (or `./scripts/validate-architecture.sh ARCHITECTURE.md`)
7. `./scripts/health-check.sh --since "24 hours ago"`

## Skills

### `dev-discipline`
The core discipline contract. Activates on any code change task.

**Enforces:**
- One concern per commit
- Conventional commit messages with `why:` lines
- Test coverage for behavioral changes
- No debug artifacts in commits
- Execution-plan discipline for non-trivial work (Codex Exec Plans format)

**Git hooks:**
- `pre-commit` — Warns on large commits, missing tests, debug statements, conflict markers
- `pre-commit` — Requires execution-plan updates for significant source changes and validates required plan sections
- `commit-msg` — Blocks non-conventional messages, requires `why:` line
- `post-commit` — Auto-appends diary entry (timestamp, hash, files, stats)

Hook tuning:
- Copy `.dev/discipline.env.example` to `.dev/discipline.env` to adjust pre-commit thresholds.
- See `docs/refs/hook-config.md` for variable reference.

### `dev-diary`
Reviews and navigates the auto-generated commit diary.

**Can:**
- Summarize today's work
- Generate standup updates
- Find when specific files changed
- Use a reusable standup template for consistent updates

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

### `planner`
Enforces Codex Exec Plans structure for implementation plans and architecture-impact hygiene.

**Can:**
- Validate required execution-plan sections
- Require user-benefit narratives for concrete steps
- Check progress checklist hygiene
- Catch malformed plans before commit
- Validate `ARCHITECTURE.md` structure when architecture changes are involved

**Run standalone:**
```bash
~/.agents/skills/planner/scripts/validate-plan.sh docs/plans/active/<plan>.md
~/.agents/skills/planner/scripts/validate-architecture.sh ARCHITECTURE.md
```

## Shell Tips Alignment

This repo now incorporates several patterns from the OpenAI skills + shell guidance:

- **Routing-style skill descriptions**: each `SKILL.md` now has explicit "use when / do not use when / outputs" guidance
- **Template-backed outputs**: report and standup templates live inside skill directories so agents can produce consistent output quickly
- **Edge-case handling in shell scripts**: reconciliation handles no-commit ranges safely and checks diary coverage across all dates in range
- **More explicit local state handling**: setup now ignores `.dev/.last-reconciliation` by default
- **Portable workflow playbooks**: slash-command docs (`planner`, `architecture`, `reconcile`, `handoff`, `pickup`) are reusable in any project
- **Docs hygiene checks**: `scripts/docs-list.sh` enforces `summary` and `read_when` in docs front matter
- **Safer commit workflow**: optional `scripts/committer` stages only explicitly listed files
- **Local docs drift loop**: `scripts/doc-gardener.sh` creates a checklist report and quality snapshot

## General-Use Design

This repo is intentionally project-agnostic:

- No machine-specific absolute paths in scripts
- Minimal shell dependencies (bash, git, standard Unix tools)
- Docs and workflow helpers can be copied into any repo
- Skill guidance focuses on discipline patterns, not framework-specific conventions

## Local Quality Loop

For a local-first quality pass (no GitHub Actions required):

1. `./scripts/docs-list.sh`
2. `./scripts/doc-gardener.sh --since "24 hours ago"`
3. `./scripts/planner docs/plans/active/<plan>.md` (for active initiatives)
4. `./scripts/validate-architecture.sh ARCHITECTURE.md`
5. `.agents/skills/dev-reconciliation/scripts/reconcile.sh --since "24 hours ago"`
6. Update `docs/QUALITY_SCORE.md` from the latest local reports

## AGENTS.md Checklist

Use `docs/agents-quality-checklist.md` to audit repo-level agent instructions.
It is designed as a fast pass/fail rubric for safety, workflow clarity, tooling, and verification discipline.

## Slash Commands

Reusable workflow playbooks live in:

- `docs/slash-commands/README.md`
- `docs/slash-commands/planner.md`
- `docs/slash-commands/architecture.md`
- `docs/slash-commands/reconcile.md`
- `docs/slash-commands/handoff.md`
- `docs/slash-commands/pickup.md`

## What Gets Committed?

When you run setup, `.dev/` is created with both tracked and local-only content:

| Path | Tracked? | Purpose |
|------|----------|---------|
| `.dev/contract.md` | ✅ Yes | Discipline rules (shared with team) |
| `.dev/decisions/` | ✅ Yes | Architectural decision records |
| `.dev/WORKLOG.md` | ✅ Yes | Project worklog |
| `.dev/FINDINGS.md` | ✅ Yes | Open items from last reconciliation (read by next session) |
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
- **Plans are living docs.** Non-trivial implementation follows execution-plan workflow.
- **Agent-agnostic.** Works with Codex, Claude Code, or any tool that runs git.

## Structure

```
skills/
├── dev-discipline/
│   ├── SKILL.md              # Work contract + rules
│   ├── templates/
│   │   └── decision-record.md # ADR-style decision template
│   ├── scripts/
│   │   ├── setup.sh          # Install hooks, create dirs
│   │   ├── bootstrap-harness.sh # Scaffold AGENTS/docs/evals
│   │   ├── sync-plan-template.sh # Sync docs plan template from canonical planner template
│   │   ├── health-check.sh   # One-shot local quality loop
│   │   ├── migrate-planner.sh # Migrate legacy planner references
│   │   ├── teardown.sh       # Uninstall hooks + bridges
│   │   ├── docs-list.sh      # Docs index + front-matter checks
│   │   ├── committer         # Explicit-file commit helper
│   │   └── doc-gardener.sh   # Local docs/plan drift scanner
│   └── assets/
│       ├── pre-commit         # Diff analysis, test check
│       ├── commit-msg         # Conventional commit enforcement
│       ├── post-commit        # Dev diary auto-append
│       └── discipline.env.example # Optional hook-threshold config template
├── dev-diary/
│   ├── SKILL.md              # Diary review + navigation
│   └── templates/
│       └── standup-update.md  # Daily update format
├── planner/
│   ├── SKILL.md              # Codex Exec Plans compliance skill
│   ├── templates/
│   │   └── exec-plan.md       # Execution-plan template
│   └── scripts/
│       ├── validate-plan.sh   # Required-section validator
│       └── validate-architecture.sh # ARCHITECTURE.md section/content validator
└── dev-reconciliation/
    ├── SKILL.md              # Reconciliation agent instructions
    ├── templates/
    │   └── reconciliation-report.md # Report skeleton
    └── scripts/
        └── reconcile.sh      # Standalone reconciliation launcher

scripts/
├── docs-list.sh              # Wrapper to dev-discipline docs-list
├── committer                 # Wrapper to dev-discipline committer
├── doc-gardener.sh           # Wrapper to dev-discipline doc-gardener
├── bootstrap-harness.sh      # Wrapper to scaffold AGENTS/docs/evals
├── validate-exec-plan.sh     # Backward-compatible wrapper to plan validator
├── planner                   # Alias command for plan validation
├── validate-architecture.sh  # Wrapper to architecture validator
├── architecture              # Alias command for architecture validation
├── sync-plan-template.sh     # Keep docs plan template synced with canonical planner template
├── health-check.sh           # One-shot local quality loop
├── migrate-planner.sh        # Migrate legacy planner references
├── test.sh                   # Run local integration tests
└── new-project-bootstrap.sh  # One-command install + setup bootstrap

docs/
├── QUALITY_SCORE.md
├── agents-quality-checklist.md
├── design/
│   ├── README.md
│   └── core-beliefs.md
├── refs/
│   ├── README.md
│   ├── harness-engineering.md
│   ├── architecture-approach.md
│   └── hook-config.md
├── quality/
│   ├── README.md
│   └── entropy-garbage-collection.md
├── plans/
│   ├── active/
│   │   ├── README.md
│   │   └── plan-template.md
│   └── completed/
│       └── README.md
├── slash-commands.md
└── slash-commands/
    ├── README.md
    ├── architecture.md
    ├── planner.md
    ├── reconcile.md
    ├── handoff.md
    └── pickup.md

.agent/
└── PLANS.md                  # Execution-plan operating standard (Codex Exec Plans)

ARCHITECTURE.md               # High-level map of boundaries, invariants, and flows

evals/
├── README.md
├── cases/
│   └── README.md
├── rubrics/
│   └── README.md
└── runs/
    └── README.md
```

## License

Apache-2.0
