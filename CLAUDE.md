# cc-workflow

A 4-phase Claude Code workflow framework for feature development. Inspired by GSD, Compound Engineering, and Superpowers — simplified to 4 clear phases that map to a natural development pattern.

## Phases

```
/plan → /implement → /debug → /done
```

1. **`/plan <description>`** — Discuss preferences, research, generate PRD + architecture + steps, review loop, create branch
2. **`/implement [next|status|<step#>]`** — Implement one step at a time, two-layer review, commit + push
3. **`/debug <bug description>`** — Systematic root cause investigation, minimal fix, commit + push (repeatable)
4. **`/done [skip-verify]`** — Verify, review, capture learnings to `docs/solutions/`, update docs, suggest PR

## Rules

1. **No fix without root cause investigation first.** Read error → reproduce → check recent changes → identify cause → then fix.
2. **No implementation without a confirmed plan.** User must explicitly approve the plan before any code is written.

## Installation

Run `./install.sh` in a target project to copy commands into `.claude/commands/`.

## Conventions

### State File

Location: `<project>/.claude/workflow/state.json`

Tracks current phase, feature name, branch, and step progress. Created by `/plan`, updated by all commands, archived by `/done`.

### Plan Documents

Location: `<project>/.claude/plans/<YYYY-MM-DD>-<feature-slug>/`

Contains:
- `prd.md` — Product requirements, user stories, acceptance criteria
- `architecture.md` — System design, ERD, component diagram, tech choices
- `plan.md` — Step-by-step implementation plan with test strategy

### Learnings

Location: `<project>/docs/solutions/<category>/<slug>.md`

Created by `/done` for each non-trivial bug fixed. Searchable by `/plan` in future workflows. Categories: build-errors, test-failures, runtime-errors, integration-issues, logic-errors, best-practices.

### Branch Naming

Derived from feature description during `/plan`:
- `feat/<slug>` — New features
- `fix/<slug>` — Bug fixes
- `chore/<slug>` — Maintenance tasks
- `refactor/<slug>` — Code refactoring

### Commit Messages

Conventional commits with step reference:
- `feat(scope): description [step N/M]` — During `/implement`
- `fix(scope): description` — During `/debug`
- `docs: update project documentation` — During `/done`

## ECC Agent Integration

Each command dispatches specific ECC agents with full context (not name-drops — actual delegation with prompts):

### /plan
- **architect** agent — Produces architecture doc from PRD + research notes
- **planner** agent — Produces step-by-step implementation plan from PRD + architecture
- **code-reviewer** agent — Plan review loop (max 3 iterations) to check step quality

### /implement
- **code-reviewer** agent — Spec compliance review (does implementation match plan?)
- **Language-specific reviewer** — Code quality review (typescript-reviewer, python-reviewer, go-reviewer, etc.)

### /debug
- **Language-specific reviewer** — Reviews non-trivial fixes

### /done
- **security-reviewer** agent — Scans full branch diff for vulnerabilities
- **code-reviewer** agent — Final review of all changes, produces actionable items

## MCP Servers (best-effort, graceful fallback)

- **context7** — Library/framework documentation lookup
- **exa** — Web search for patterns and solutions
- **github** — Code search for existing implementations

## Design Influences

| Framework | What we took | What we simplified |
|-----------|-------------|-------------------|
| **GSD** | Plan review loop, discuss phase for user preferences | 44 commands → 4, wave execution → sequential |
| **Compound Engineering** | `docs/solutions/` knowledge capture, actionable review items | 25 agents → use ECC's existing agents |
| **Superpowers** | Two-layer review (spec + quality), systematic debugging | Subagent templates → agent dispatch with context |
