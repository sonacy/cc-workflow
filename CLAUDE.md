# cc-workflow

4-phase workflow: `/plan` → `/implement` → `/debug` → `/done`

## Rules

- No implementation without a confirmed plan.
- No fix without root cause investigation first.
- **Never auto-advance between phases.** Each command finishes and suggests the next step, but WAITS for the user to invoke it. Never run `/implement` after `/plan`, or `/done` after `/implement`, without the user explicitly calling the command.

## File Locations

- **Commands**: `commands/{plan,implement,debug,done,where}.md` — source; installed to `<project>/.claude/commands/`
- **State**: `<project>/.claude/workflow/state.json` — tracks phase, steps, commits
- **Plans**: `<project>/.claude/plans/<YYYY-MM-DD>-<slug>/` — prd.md, architecture.md, plan.md
- **Learnings**: `<project>/docs/solutions/<category>/` — captured by `/done`
- **Templates**: `templates/` — document templates used by `/plan`

## Branch Naming

`feat/`, `fix/`, `chore/`, or `refactor/` + slug. Conventional commits with `[step N/M]` during `/implement`.
