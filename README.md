# cc-workflow

A 4-phase Claude Code workflow for feature development. Plan, implement, debug, ship.

```
/plan  →  /implement  →  /debug  →  /done
         /where  /revert  /archive
```

## Install

### Option 1: Claude Code plugin (recommended)

Add the marketplace, then install the plugin:

```
/plugin marketplace add https://github.com/sonacy/cc-workflow
/plugin install cc-workflow@cc-workflow
```

From a local clone:

```
/plugin marketplace add /path/to/cc-workflow
/plugin install cc-workflow@cc-workflow
```

Commands land as `/plan`, `/implement`, `/debug`, `/done`, `/where`, `/revert`, `/archive`. Claude Code namespaces to `/cc-workflow:<cmd>` on conflict.

Update / uninstall:

```
/plugin marketplace update cc-workflow
/plugin update cc-workflow@cc-workflow
/plugin uninstall cc-workflow@cc-workflow
```

### Option 2: Install script (legacy)

```bash
./install.sh /path/to/your/project
```

Detects naming conflicts (e.g., ECC plugin) and asks for a prefix:

```
Prefix (or Enter to skip): cc
```

With prefix `cc`, commands become `/cc:plan`, `/cc:implement`, etc. Re-running install detects the existing prefix and lets you change it.

## Commands

### /plan \<description\>

Researches codebase, asks about gray-area decisions, generates PRD + architecture + implementation plan, reviews the plan, creates branch, commits docs.

### /implement

Implements ALL pending steps sequentially (no stopping between steps). After all steps: runs lint, test, build — fixes errors automatically. Then detects platform (GitHub/GitLab) and creates PR/MR.

### /debug \<bug\>

Investigates root cause systematically, applies minimal fix, verifies no regressions, commits and pushes. Run once per bug.

### /done

Runs mandatory interactive code review — presents findings, waits for your approval before fixing. Re-runs lint/test/build after fixes. Generates `review.md` — a session review capturing plan decisions, implementation, bugs/fixes with durations and conversation rounds, code review results, and learnings. Checks merge status, switches to default branch.

### /where

Shows current workflow state: phase, step progress, bugs fixed, and what to do next.

### /revert \<phase\>

Revert to a previous phase:
- `/revert plan` — discard everything, delete branch, start fresh
- `/revert implement` — discard code, keep plan docs
- `/revert debug` — discard debug fixes, keep implementation

### /archive

Abandon the current feature. Asks for a reason, writes an archive doc, deletes the branch, switches to default branch.

## License

MIT
