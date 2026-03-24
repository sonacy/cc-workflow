---
description: "Fix a bug: diagnose root cause, fix, commit and push"
---

# /debug — Fix a Bug

You are in Phase 3 of cc-workflow. Your job is to systematically diagnose a bug, find the root cause, fix it, verify no regressions, then commit and push. This command can be run multiple times — one bug per invocation.

**RULE: No fix without root cause investigation first.**

## Input

Bug description: $ARGUMENTS

If no description is provided, ask: "What issue did you find? Describe the bug, error message, or unexpected behavior."

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
> No active workflow found. Run `/plan <description>` to start one.

Valid phases: `implement`, `debug`

If phase is `plan` or `plan-complete`:
> You haven't implemented anything yet. Run `/implement` first.

If phase is `done`:
> This workflow is already complete. If you found a new bug, start a new workflow with `/plan`.

Update phase to `debug`.

## Step 2: Systematic Root Cause Investigation

Follow this 4-step diagnostic process BEFORE attempting any fix:

### 2a: Read Error Messages Carefully

- Read the exact error message, stack trace, and line numbers
- Identify which component is failing
- Note the exact conditions under which it fails

### 2b: Reproduce Consistently

- Identify the exact steps to reproduce
- Confirm the bug happens every time (not intermittent)
- If the user hasn't provided reproduction steps, ask:
  - What was the expected behavior?
  - What actually happened?
  - What are the exact steps to trigger it?

### 2c: Check Recent Changes

- Run `git log --oneline -10` to see what changed recently
- Run `git diff` on suspicious files
- Check if the bug correlates with a specific commit

### 2d: Identify Root Cause

- Read the relevant source files and existing tests
- Trace the code path from input to failure point
- Identify the ACTUAL root cause, not just the symptom
- For multi-component issues: add diagnostic output at each boundary to isolate WHERE it breaks

**Do NOT proceed to Step 3 until you have identified the root cause.** If you can't determine it, explain what you've found and ask the user for more context.

## Step 3: Fix the Bug

Implement the minimal fix targeting the root cause:
- Fix the ROOT CAUSE, not the symptom
- Keep changes as small as possible
- Don't refactor unrelated code
- Don't add features — only fix the bug

## Step 4: Verify No Regressions

If the project has existing tests, run the full test suite to check for regressions:
- All existing tests must still pass
- If any test breaks, the fix introduced a regression — adjust the fix

If there are no tests, manually verify the fix works and doesn't break existing functionality.

## Step 5: Code Review

For non-trivial fixes (more than a 1-line change), dispatch the appropriate reviewer agent:
- TypeScript/JavaScript → **typescript-reviewer** agent
- Python → **python-reviewer** agent
- Go → **go-reviewer** agent
- Other → **code-reviewer** agent

Provide: the git diff, the bug description, the root cause, and the fix rationale.

Fix any CRITICAL issues found.

## Step 6: Commit and Push

```bash
git add <changed_files>
git commit -m "fix({{scope}}): {{concise_bug_description}}"
git push origin {{branch}}
```

## Step 7: Update State

Update `.claude/workflow/state.json`:
- Add entry to `debug_log`:
  ```json
  {
    "description": "{{bug_description}}",
    "root_cause": "{{root_cause_summary}}",
    "commit": "{{commit_sha}}",
    "fixed_at": "{{ISO_8601_now}}"
  }
  ```
- Update `updated_at`

## Step 8: Ask What's Next

```
Bug fixed and committed: {{short_sha}} — fix({{scope}}): {{description}}
Root cause: {{root_cause_summary}}

Options:
- Found another bug? Run `/debug <description>`
- Want to add more steps? Run `/implement`
- Ready to wrap up? Run `/done`
- Check state: Run `/where`
```

**STOP HERE. Do NOT auto-advance to the next phase. Wait for the user to invoke the next command.**
