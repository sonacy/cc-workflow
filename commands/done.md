---
description: "Finish the workflow: verify, update docs, capture learnings, suggest PR"
---

# /done — Complete the Workflow

You are in Phase 4 of cc-workflow. Your job is to verify everything works, update documentation, capture learnings for future reuse, archive the workflow state, and suggest creating a PR.

## Input

Argument: $ARGUMENTS

- (empty) — run full verification and wrap-up
- `skip-verify` — skip verification, go straight to docs and wrap-up
- Any other text is treated as notes to include in the summary

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
You have uncommitted changes. Committing them before final verification.
```
Stage and commit: `chore: uncommitted work before verification`

## Step 3: Verification (unless skip-verify)

Run a comprehensive verification of the project:

### 3a: Build
Run the project's build command (detect from package.json scripts, Makefile, Cargo.toml, etc.):
- `npm run build` / `pnpm build` / `yarn build`
- `cargo build`
- `go build ./...`
- `make build`
- Or whatever the project uses

Report: PASS or FAIL with errors.

### 3b: Lint
Run the project's linter:
- `npm run lint` / `pnpm lint`
- `cargo clippy`
- `golangci-lint run`
- `ruff check .`

Report: PASS or FAIL with issues.

### 3c: Tests
Run the full test suite with coverage:
- `npm test -- --coverage`
- `cargo test`
- `go test -cover ./...`
- `pytest --cov`

Report: PASS or FAIL, test count, coverage percentage.

### 3d: Security Scan
Dispatch the **security-reviewer** agent to scan all changes since the base branch. Provide:

```
Scan all changes on this feature branch for security issues:

git diff main...HEAD

Check for:
- Hardcoded secrets (API keys, passwords, tokens)
- SQL injection vulnerabilities
- XSS vulnerabilities
- Unvalidated user input
- Authentication/authorization gaps
- Sensitive data exposure in logs or error messages
```

Report: Issues found (CRITICAL/HIGH/MEDIUM/LOW).

### Verification Summary

```
## Verification Results

| Check | Status | Details |
|-------|--------|---------|
| Build | PASS/FAIL | {{details}} |
| Lint  | PASS/FAIL | {{details}} |
| Tests | PASS/FAIL | {{count}} tests, {{coverage}}% coverage |
| Security | PASS/FAIL | {{issue_count}} issues |
```

If CRITICAL issues exist, warn the user but do NOT block. They can decide whether to fix now or proceed.

## Step 4: Code Review

Dispatch the **code-reviewer** agent on the full diff since branch creation. Provide:

```
Review all changes on this feature branch:

Feature: {{feature_name}}
Branch: {{branch}}
Plan: {{plan_dir}}/

git diff main...HEAD

Focus on:
- Does the implementation match the plan and PRD?
- Are there bugs, logic errors, or missing edge cases?
- Is test coverage adequate?
- Are there architectural concerns?
- Code quality: naming, structure, duplication
```

**Create actionable items** from the review, not just a report:
- CRITICAL/HIGH issues → list specific files and what to fix
- If the user wants to fix them: "Run `/debug <issue>` for each"
- If they want to proceed: continue to next step

## Step 5: Capture Learnings

This is where knowledge compounds. Review the entire workflow and capture anything reusable.

### 5a: Problems Solved

Check the `debug_log` in state.json. For each non-trivial bug fixed, create a solution document:

```
Write to: docs/solutions/{{category}}/{{slug}}.md

---
date: {{today}}
feature: {{feature_name}}
category: {{build-errors|test-failures|runtime-errors|integration-issues|logic-errors|best-practices}}
symptoms: {{what_went_wrong}}
root_cause: {{why}}
---

# {{Problem Title}}

## Symptoms
{{what the user reported or what failed}}

## Root Cause
{{the actual cause, not the symptom}}

## Solution
{{what fixed it and why}}

## Prevention
{{how to avoid this in the future}}
```

Create `docs/solutions/` directory if it doesn't exist. This makes the solution searchable by `/plan` in future workflows.

### 5b: Patterns Discovered

If any non-obvious patterns were established during this workflow (architectural decisions, library usage patterns, testing strategies), save them to ECC memory:

Write to the project's memory directory at `.claude/projects/*/memory/` if it exists, capturing:
- Key technical decisions and their rationale
- Patterns that worked well
- Anti-patterns to avoid

### 5c: Update CLAUDE.md

If the feature introduced new architectural patterns or conventions that future development should follow, append them to CLAUDE.md. Don't update for trivial changes.

## Step 6: Update Documentation

Check if these files need updating based on the changes made:

1. **README.md** — If new public APIs, features, or setup steps were added
2. **CHANGELOG.md** — If it exists, add an entry for this feature

For each file: read the current content, determine if it needs changes based on the feature that was implemented, and update only if necessary. Don't force unnecessary changes.

Commit documentation and learning updates:
```bash
git add docs/solutions/ README.md CLAUDE.md CHANGELOG.md 2>/dev/null
git commit -m "docs: update documentation and learnings for {{feature}}" --allow-empty
```

## Step 7: Generate Summary

Produce a comprehensive summary of the workflow:

```
## Workflow Complete: {{feature}}

**Branch**: {{branch}}
**Duration**: {{created_at}} → {{now}}
**Plan**: {{plan_dir}}/

### What Was Built
{{2-3 sentence summary of the feature}}

### Files Changed
{{list of files created/modified with line counts, from git diff --stat main...HEAD}}

### Implementation Steps
| # | Step | Status | Commit |
|---|------|--------|--------|
| 1 | {{name}} | done | {{short_sha}} |
| 2 | {{name}} | done | {{short_sha}} |
| 3 | {{name}} | skipped | — |

### Bugs Fixed
{{from debug_log with root causes, or "None"}}

### Learnings Captured
{{list of docs/solutions/ files created, or "None"}}

### Test Coverage
{{coverage}}% ({{test_count}} tests)

### Verification
Build: PASS/FAIL | Lint: PASS/FAIL | Tests: PASS/FAIL | Security: PASS/FAIL
```

## Step 8: Archive State

1. Create `.claude/workflow/archive/` directory if it doesn't exist
2. Copy `state.json` to `.claude/workflow/archive/{{slug}}-{{date}}.json`
3. Delete `.claude/workflow/state.json`
4. Commit:
```bash
git add .claude/workflow/
git commit -m "chore: archive workflow state for {{feature}}"
```

## Step 9: Final Push

```bash
git push origin {{branch}}
```

## Step 10: Merge Check

Before completing, ensure the feature branch is merged into the default branch.

### 10a: Detect Default Branch

Determine the default branch name:
1. Try `git remote show origin` and parse "HEAD branch"
2. If that fails, check which of `main`, `master`, `develop` exists locally
3. If none found, ask the user

### 10b: Check if Merged

Check if the feature branch commits are on the default branch:
```bash
git fetch origin {{default_branch}}
git log origin/{{default_branch}} --oneline | grep {{latest_commit_sha}}
```

Or more reliably:
```bash
git branch -r --contains HEAD | grep "origin/{{default_branch}}"
```

### 10c: If NOT Merged

Tell the user:
```
Your branch `{{branch}}` is not yet merged into `{{default_branch}}`.

Please merge it via your platform (GitHub, GitLab, etc.):
- Push is done: create a PR/MR and merge it
- Or merge locally if that's your workflow

Type "merged" when done, or "skip" to finish without merging.
```

**WAIT for user response.**

If the user says "merged":
- Run `git fetch origin {{default_branch}}` and re-check
- If still not merged, tell them: "I don't see the merge on `{{default_branch}}` yet. Please check and try again, or type 'skip'."

If the user says "skip":
- Proceed without merging (they can merge later)

### 10d: Switch to Default Branch

After merge is confirmed (or skipped):
```bash
git checkout {{default_branch}}
git pull origin {{default_branch}}
```

This ensures the user is on an up-to-date default branch, ready for the next `/plan`.

## Step 11: Suggest Next Action

```
Workflow complete! Switched to `{{default_branch}}` (up to date).

Feature: {{feature}}
Branch: {{branch}} (merged)

Start a new feature: `/plan <description>`
```
