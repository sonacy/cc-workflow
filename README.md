# cc-workflow

A 4-phase Claude Code workflow for feature development. Plan, implement, debug, ship.

Inspired by [GSD](https://github.com/pashpashpash/get-shit-done), [Compound Engineering](https://github.com/rooben-me/compound-engineering-plugin), and [Superpowers](https://github.com/jasonjmcghee/claude-code-superpower) — simplified to 4 commands that map to a natural development pattern.

## The Workflow

```
/plan  →  /implement  →  /debug  →  /done
  │           │             │          │
  │     one step at    one bug at   verify +
  │       a time        a time     learnings +
  │           │             │       docs + PR
  ▼           ▼             ▼
discuss    implement    root cause
research   two-layer    investigation
PRD        review       minimal fix
arch       commit+push  commit+push
plan
review
branch
```

## Install

```bash
# From the cc-workflow directory, install into your project
./install.sh /path/to/your/project

# Or cd into your project and run
/path/to/cc-workflow/install.sh .
```

This copies commands into your project's `.claude/commands/` directory so they're available as `/plan`, `/implement`, `/debug`, `/done`.

## Quick Start

### 1. Plan

```
/plan add user authentication with JWT
```

Claude will:
- Research your codebase and relevant libraries
- Ask you multiple-choice questions about gray-area decisions
- Generate a PRD, architecture doc (with ERD), and step-by-step plan
- Review the plan for quality (max 3 iterations)
- Present for your confirmation
- Create a `feat/user-auth-jwt` branch and commit plan docs

### 2. Implement

```
/implement
```

Claude will:
- Read the plan and pick the next step
- Implement the step following architecture decisions
- Run two-layer review: spec compliance + code quality
- Commit and push

Repeat `/implement` for each step. Use `/implement status` to check progress.

### 3. Debug

```
/debug login fails when password is empty
```

Claude will:
- Investigate root cause systematically (read error → reproduce → check changes → identify cause)
- Apply minimal fix targeting root cause
- Verify no regressions
- Commit and push

Repeat `/debug` for each bug found.

### 4. Done

```
/done
```

Claude will:
- Run build, lint, tests, security scan
- Final code review with actionable items
- Capture learnings to `docs/solutions/` for future reuse
- Update README/CLAUDE.md if needed
- Archive state and suggest creating a PR

## What Gets Created

In your project:

```
.claude/
├── commands/              # The 4 workflow commands
│   ├── plan.md
│   ├── implement.md
│   ├── debug.md
│   └── done.md
├── workflow/
│   ├── state.json         # Active workflow state (auto-managed)
│   └── archive/           # Completed workflow states
├── plans/
│   └── 2026-03-23-user-auth-jwt/
│       ├── prd.md         # Product requirements
│       ├── architecture.md # System design + ERD
│       └── plan.md        # Step-by-step implementation plan
├── templates/cc-workflow/  # Document templates
└── skills/workflow-state/  # State management conventions

docs/
└── solutions/             # Captured learnings (created by /done)
    ├── build-errors/
    ├── runtime-errors/
    └── best-practices/
```

## Command Reference

### `/plan <description>`

Starts a new feature workflow.

1. Discuss — capture your preferences on gray-area decisions (multiple choice)
2. Research — codebase, library docs, web search, past learnings
3. Generate — PRD, architecture (ERD, API contracts), implementation plan
4. Review loop — plan-checker verifies quality (max 3 rounds)
5. Confirm — you approve before any branch is created
6. Branch — creates `feat/`, `fix/`, `chore/`, or `refactor/` branch

### `/implement [next|status|<step#>]`

Implements one step from the plan.

- `next` (default) — implement the next pending step
- `status` — show progress without implementing
- `3` — implement step 3 specifically

Each step: implement → spec compliance review → code quality review → commit + push.

### `/debug <bug description>`

Fixes one bug with systematic diagnosis.

1. Root cause investigation (read error → reproduce → check changes → identify cause)
2. Minimal fix targeting root cause
3. Verify no regressions
4. Commit and push

Can be run multiple times — one bug per invocation.

### `/done [skip-verify]`

Completes the workflow.

1. Verification — build, lint, tests, security scan
2. Code review — full diff with actionable items
3. Capture learnings — `docs/solutions/` + ECC memory
4. Update docs — README, CLAUDE.md, CHANGELOG
5. Archive state and suggest PR creation

`skip-verify` skips step 1.

## ECC Compatibility

cc-workflow delegates to [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) agents with full context prompts:

| Agent | Used by | Purpose |
|-------|---------|---------|
| **planner** | `/plan` | Generate implementation plan |
| **architect** | `/plan` | Generate architecture doc |
| **code-reviewer** | `/plan`, `/implement`, `/done` | Plan review, spec compliance, final review |
| **security-reviewer** | `/done` | Security scan |
| **Language-specific reviewers** | `/implement`, `/debug` | Code quality (typescript, python, go, etc.) |

MCP servers (optional, graceful fallback):
- **context7** — library documentation
- **exa** — web search
- **github** — code search

## Design Philosophy

| Principle | From | How |
|-----------|------|-----|
| Fresh context per agent | GSD | Dispatch agents with full task context, not session history |
| Knowledge compounding | Compound Eng. | `docs/solutions/` captures learnings searchable by future `/plan` |
| Plan review loop | GSD | Max 3 iterations before confirming plan |
| Two-layer review | Superpowers | Spec compliance first, then code quality |
| Systematic debugging | Superpowers | Root cause investigation before any fix |
| Discuss before plan | GSD | Capture user preferences on gray areas upfront |
| Simple over comprehensive | cc-workflow | 4 commands, not 44. Use ECC's agents, don't rebuild them. |

## License

MIT
