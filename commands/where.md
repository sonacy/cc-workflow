---
description: "Show current workflow state, progress, and what to do next"
---

# /where — Where Am I?

Show the current cc-workflow state and suggest the next action.

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
```
No active workflow. Start one with `/plan <description>`.
```
Stop here.

## Step 2: Show State

Read the state file and present:

```
## Workflow: {{feature}}

**Branch**: {{branch}}
**Phase**: {{phase}}
**Plan**: {{plan_dir}}/
**Started**: {{created_at}}

### Progress

| # | Step | Status |
|---|------|--------|
| 1 | {{name}} | done ({{short_commit}}) |
| 2 | {{name}} | in-progress |
| 3 | {{name}} | pending |

{{completed}}/{{total}} steps complete

### Bugs Fixed

{{from debug_log, or "None"}}
```

## Step 3: Suggest Next Action

Based on the current phase, suggest what to do:

- **phase = plan**: "Plan is in draft. Review docs at `{{plan_dir}}/` and re-run `/plan` to finalize."
- **phase = plan-complete**: "Plan is ready. Run `/implement` to start Step 1."
- **phase = implement**:
  - If there's a step with status `in-progress`: "Step {{id}} is in progress. Run `/implement` to continue."
  - If all completed: "All steps done. Run `/debug` if issues found, or `/done` to wrap up."
  - Otherwise: "Run `/implement` to start Step {{next_pending_id}}: {{name}}."
- **phase = debug**: "In debug mode. Run `/debug <bug>` to fix another issue, `/implement` to resume steps, or `/done` to wrap up."

**Do NOT execute any action. Only show state and suggest.**
