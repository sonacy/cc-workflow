# cc-workflow

A 4-phase Claude Code workflow for feature development. Plan, implement, debug, ship.

```
/plan  →  /implement  →  /debug  →  /done
                  /where (check state anytime)
```

## Install

```bash
./install.sh /path/to/your/project
```

The installer detects naming conflicts with existing tools (e.g., ECC plugin). If conflicts are found, it asks for a prefix:

```
Naming conflicts detected:
  - /plan (ECC plugin skill)
  - /debug (ECC plugin skill)

Prefix (or Enter to skip): cc
```

With prefix `cc`, commands become `/cc:plan`, `/cc:implement`, `/cc:debug`, `/cc:done`, `/cc:where`. All cross-references inside the command files are updated automatically.

Re-running `./install.sh` on an already-installed project detects the existing prefix and lets you keep it, change it, or remove it.

## Usage

Each command finishes and suggests the next step, but **never auto-advances**. You control the pace.

### /plan \<description\>

```
/plan add user authentication with JWT
```

Researches your codebase, asks you about gray-area decisions, generates PRD + architecture + implementation plan, reviews the plan, then creates a branch and commits the docs.

### /implement

```
/implement
```

Picks the next step from the plan, implements it, runs two-layer code review (spec compliance + quality), commits and pushes. Run once per step.

### /debug \<bug\>

```
/debug login fails when password is empty
```

Investigates root cause (read error → reproduce → check changes → identify cause), applies minimal fix, verifies no regressions, commits and pushes. Run once per bug.

### /done

```
/done
```

Runs verification (build, lint, tests, security), final code review, captures learnings to `docs/solutions/`, checks merge status, switches to default branch.

### /where

```
/where
```

Shows current workflow state: phase, step progress, bugs fixed, and what to do next. Read-only — never executes actions.

## License

MIT
