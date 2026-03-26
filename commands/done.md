---
description: "Finish the workflow: code review with user approval, verify, merge check"
---

# /done — Complete the Workflow

You are in Phase 4 of cc-workflow. Your job is to run an interactive code review, apply approved fixes, verify everything passes, then handle merge and cleanup.

## Input

Argument: $ARGUMENTS

- (empty) — run full code review + verification + merge check
- Any text is treated as notes to include in the summary

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
> No active workflow found. Nothing to finish.

Valid phases: `implement`, `debug`

If phase is `plan` or `plan-complete`:
> You haven't implemented anything yet. Run `/implement` first.

## Step 2: Check for Uncommitted Changes

Run `git status`. If there are uncommitted changes:
```
You have uncommitted changes:
{{list of changed files}}

Options:
- "commit" — commit them before review
- "stash" — stash them (review only committed work)
- "cancel" — abort /done
```

**WAIT for user response.** Apply their choice before proceeding.

## Step 3: Code Review (MANDATORY)

**Always run code review before completing.** This is not optional.

Dispatch the **code-reviewer** agent on the full diff since branch creation:

```
Review all changes on this feature branch:

Feature: {{feature_name}}
Branch: {{branch}}
Plan: {{plan_dir}}/

git diff main...HEAD

Review for:
- Does the implementation match the plan?
- Bugs, logic errors, missing edge cases
- Security issues
- Code quality: naming, structure, duplication
- Error handling completeness
```

### 3a: Present Findings to User

Format each finding as:

```
## Code Review Results

### Finding 1: [SEVERITY] {{title}}
**File**: {{file_path}}:{{line}}
**Issue**: {{description}}
**Suggestion**: {{fix}}

### Finding 2: [SEVERITY] {{title}}
...

---
For each finding, respond with:
- "fix N" — apply the suggested fix for finding N
- "fix all" — apply all suggested fixes
- "skip N" — skip finding N
- "skip all" — skip all findings and proceed
- "discuss N" — explain more about finding N
```

**WAIT for user response. Do NOT apply any fixes without user approval.**

### 3b: Apply Approved Fixes

For each finding the user approved:
1. Apply the fix
2. Keep changes minimal and focused

After all approved fixes are applied:
```bash
git add <changed_files>
git commit -m "fix: apply code review fixes"
```

## Step 4: Re-verify After Fixes

If any fixes were applied in Step 3, re-run quality checks:

### 4a: Lint
Run the project's linter. If errors, fix them.

### 4b: Tests
Run the full test suite. If failures, fix them.

### 4c: Build
Run the build. If errors, fix them.

If any fixes were needed:
```bash
git add <changed_files>
git commit -m "fix: resolve lint/test/build errors after review"
```

If no quality checks apply (no linter, no tests, no build), skip this step.

## Step 5: Capture Learnings

Check the `debug_log` in state.json. For each non-trivial bug fixed, create a solution document:

```
Write to: docs/solutions/{{category}}/{{slug}}.md

---
date: {{today}}
feature: {{feature_name}}
category: {{category}}
symptoms: {{what_went_wrong}}
root_cause: {{why}}
---

# {{Problem Title}}

## Symptoms
{{what the user reported}}

## Root Cause
{{the actual cause}}

## Solution
{{what fixed it}}

## Prevention
{{how to avoid this}}
```

If no bugs were fixed, skip this step.

## Step 6: Push

```bash
git push origin {{branch}}
```

## Step 7: Generate Summary

```
## Workflow Complete: {{feature}}

**Branch**: {{branch}}
**Plan**: {{plan_dir}}/

### What Was Built
{{2-3 sentence summary}}

### Files Changed
{{git diff --stat main...HEAD}}

### Implementation Steps
| # | Step | Status | Commit |
|---|------|--------|--------|
{{steps table}}

### Bugs Fixed
{{debug_log or "None"}}

### Code Review
{{count}} findings: {{fixed}} fixed, {{skipped}} skipped
```

## Step 8: Archive State

1. Create `.claude/workflow/archive/` if needed
2. Copy `state.json` to `.claude/workflow/archive/{{slug}}-{{date}}.json`
3. Delete `.claude/workflow/state.json`
4. Commit:
```bash
git add .claude/workflow/
git commit -m "chore: archive workflow state for {{feature}}"
git push origin {{branch}}
```

## Step 9: Merge Check

### 9a: Detect Default Branch

`git remote show origin | grep 'HEAD branch'` → fallback to main/master/develop.

### 9b: Check if Merged

```bash
git fetch origin {{default_branch}}
git branch -r --contains HEAD | grep "origin/{{default_branch}}"
```

### 9c: If NOT Merged

```
Your branch `{{branch}}` is not yet merged into `{{default_branch}}`.

Please merge it via your platform (GitHub, GitLab, etc.):
- Push is done — create/merge the PR/MR
- Or merge locally if that's your workflow

Type "merged" when done, or "skip" to finish without merging.
```

**WAIT for user response.**

If "merged": fetch and re-check. If still not merged, ask again.
If "skip": proceed.

### 9d: Switch to Default Branch

```bash
git checkout {{default_branch}}
git pull origin {{default_branch}}
```

## Step 10: Suggest Next Action

```
Workflow complete! Switched to `{{default_branch}}` (up to date).

Feature: {{feature}}
Branch: {{branch}}

Start a new feature: `/plan <description>`
```

**STOP HERE. The workflow is complete. Do NOT start a new workflow automatically.**
