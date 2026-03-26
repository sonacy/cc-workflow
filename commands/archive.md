---
description: "Archive and abandon the current feature: write archive doc, reset to default branch"
---

# /archive — Archive and Abandon Feature

Drop the current feature entirely. Write an archive document explaining why it was abandoned, then reset to the default branch.

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
> No active workflow. Nothing to archive.

## Step 2: Ask for Reason

```
Archiving feature: **{{feature}}**
Branch: {{branch}}

This will:
- Write an archive doc explaining why this feature was dropped
- Delete the feature branch (local + remote)
- Switch to the default branch

Why is this feature being archived?
```

**WAIT for user response.**

## Step 3: Write Archive Document

Create `.claude/workflow/archive/{{slug}}-archived.md`:

```markdown
# Archived: {{feature}}

> Archived on {{date}}

## Feature
{{feature description from state}}

## Branch
{{branch}} (deleted)

## Plan
{{plan_dir}}/

## Progress at Archive Time

| # | Step | Status | Commit |
|---|------|--------|--------|
{{steps table from state}}

## Bugs Fixed Before Archive
{{debug_log or "None"}}

## Reason for Archive
{{user's reason}}
```

## Step 4: Clean Up

1. Detect default branch: `git remote show origin | grep 'HEAD branch'`
2. Switch to default branch: `git checkout {{default_branch}}`
3. Pull latest: `git pull origin {{default_branch}}`
4. Delete feature branch locally: `git branch -D {{branch}}`
5. Delete remote branch if pushed: `git push origin --delete {{branch}}` (ignore errors)
6. Remove state file: `rm -f .claude/workflow/state.json`
7. Note: Plan docs in `.claude/plans/` are kept for reference (they're on the deleted branch anyway, but archive doc captures the summary)

## Step 5: Report

```
Feature archived: **{{feature}}**

Archive doc: .claude/workflow/archive/{{slug}}-archived.md
Switched to `{{default_branch}}` (up to date).

Start a new feature: `/plan <description>`
```

**STOP HERE. Do NOT auto-advance. Wait for the user to invoke the next command.**
