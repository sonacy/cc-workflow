---
description: "Revert workflow to a previous phase: /revert plan, /revert implement, or /revert debug"
---

# /revert — Revert to a Previous Phase

Revert the workflow to a previous phase by undoing commits. Uses `git reset --soft` to preserve changes in the working directory for review before discarding.

## Input

Argument: $ARGUMENTS

- `plan` — Revert everything (code + plan docs), go back to before the plan. Start fresh.
- `implement` — Revert all code changes but keep plan docs. Go back to plan-complete state.
- `debug` — Revert all debug fix commits but keep implementation commits.

No `/revert done` — after done, code is merged. Use git commands directly if needed.

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
> No active workflow. Nothing to revert.

## Step 2: Validate Revert Target

Check if the current phase has reached the revert target:

| Revert target | Valid when phase is | Invalid when phase is |
|--------------|--------------------|-----------------------|
| `plan` | plan, plan-complete, implement, debug | (always valid if state exists) |
| `implement` | implement, debug | plan, plan-complete → "Nothing to revert. You haven't implemented anything yet." |
| `debug` | debug | plan, plan-complete, implement → "Nothing to revert. You haven't done any debug fixes yet." |

If invalid, tell the user and stop.

## Step 3: Confirm with User

**WARNING**: This is a destructive operation.

```
⚠️ Revert to {{target}} phase

This will:
{{if target == plan}}
- Discard ALL commits on branch `{{branch}}` (plan docs, code, fixes)
- Delete the branch and switch to default branch
- Remove state file and plan directory
{{/if}}
{{if target == implement}}
- Discard all code commits (keep plan docs commit)
- Reset to the plan commit
- Set phase back to plan-complete
- All implementation steps reset to pending
{{/if}}
{{if target == debug}}
- Discard all debug fix commits (keep implementation commits)
- Set phase back to implement
- Clear debug_log
{{/if}}

Type "confirm" to proceed, or anything else to cancel.
```

**WAIT for user response. Do NOT proceed without "confirm".**

## Step 4: Execute Revert

### /revert plan

1. Detect default branch (`git remote show origin | grep 'HEAD branch'`)
2. Switch to default branch: `git checkout {{default_branch}}`
3. Delete the feature branch: `git branch -D {{branch}}`
4. Delete remote branch if pushed: `git push origin --delete {{branch}}` (ignore errors if not pushed)
5. Remove plan directory: `rm -rf {{plan_dir}}`
6. Remove state file: `rm -f .claude/workflow/state.json`

### /revert implement

1. Find the plan commit (the commit with message "docs: add plan for {{feature}}")
2. `git reset --soft {{plan_commit_sha}}`
3. `git reset HEAD .` (unstage everything)
4. `git checkout -- .` (discard all working directory changes)
5. Update state.json:
   - Set phase to `plan-complete`
   - Reset all steps to `pending`, clear commit SHAs
   - Clear debug_log

### /revert debug

1. Find the last implementation commit (last step with status `done` before any debug_log entries)
2. `git reset --soft {{last_implement_commit_sha}}`
3. `git reset HEAD .`
4. `git checkout -- .`
5. Update state.json:
   - Set phase to `implement`
   - Clear debug_log

## Step 5: Report

```
Reverted to {{target}} phase.

{{if target == plan}}
Switched to `{{default_branch}}`. Branch `{{branch}}` deleted.
Start fresh: `/plan <description>`
{{/if}}
{{if target == implement}}
Back to plan-complete. All steps reset to pending.
Plan docs at `{{plan_dir}}/` are intact.
Next: `/implement` to re-implement, or `/plan` to revise the plan.
{{/if}}
{{if target == debug}}
Back to implement phase. Debug fixes discarded.
Next: `/debug <bug>` to try a different fix, or `/done` to wrap up.
{{/if}}
```

**STOP HERE. Do NOT auto-advance. Wait for the user to invoke the next command.**
