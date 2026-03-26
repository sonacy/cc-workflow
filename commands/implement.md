---
description: "Implement ALL steps from the plan sequentially, run lint/test, create PR/MR"
---

# /implement — Implement All Steps

You are in Phase 2 of cc-workflow. Your job is to implement ALL remaining steps from the plan sequentially, run lint/test/build after, fix any errors, then create a PR/MR.

**Do NOT stop between steps. Implement all pending steps in one go. Show progress as each step completes.**

## Input

Argument: $ARGUMENTS

- (empty) — implement all pending steps sequentially
- `status` — show progress overview without implementing anything

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
> No active workflow found. Run `/plan <description>` to start one.

If `phase` is `plan` (not yet confirmed):
> Plan is still in draft. Review the docs at `{{plan_dir}}/` and confirm to proceed.

If `phase` is `done`:
> This workflow is already complete. Run `/plan <description>` to start a new one.

Valid phases to proceed: `plan-complete`, `implement`, `debug`

## Step 2: Handle "status" Command

If argument is `status`, show progress and stop:

```
## Workflow: {{feature}}
**Branch**: {{branch}} | **Phase**: {{phase}}

| # | Step | Status |
|---|------|--------|
| 1 | {{name}} | done ({{commit}}) |
| 2 | {{name}} | in-progress |
| 3 | {{name}} | pending |

Progress: 1/3 steps complete
```

Return after showing status — do not implement anything.

## Step 3: Load Plan Context

Read ALL plan documents to provide full context:
- `{{plan_dir}}/plan.md` — implementation steps
- `{{plan_dir}}/architecture.md` — design decisions, ERD, API contracts
- `{{plan_dir}}/prd.md` — requirements and acceptance criteria

Also check `docs/solutions/` for any relevant past learnings.

## Step 4: Implement All Pending Steps

First, check for any step with `status: "in-progress"` — this means a previous run was interrupted. Resume from that step with a message: "Resuming Step {{id}} (was in-progress from a previous run)."

Then, for each step with `status: "pending"` or `"in-progress"`, in order:

### 4a: Show Progress

```
## Implementing Step {{id}}/{{total}}: {{name}}
```

### 4b: Implement

- Follow the architecture decisions in `architecture.md`
- Follow existing project patterns and conventions
- Keep changes focused on this step only
- Write clean, readable code

### 4c: Commit

After each step:
```bash
git add <changed_files>
git commit -m "{{branch_type}}({{scope}}): {{step_description}} [step {{id}}/{{total}}]"
```

### 4d: Update State

- Set the step's `status` to `done`
- Set the step's `commit` to the commit SHA
- Update `updated_at`
- Set `phase` to `implement`

### 4e: Continue to Next Step

**Do NOT stop. Proceed to the next pending step immediately.**

Repeat 4a-4d for all pending steps.

## Step 5: Run Lint, Tests, and Build

After ALL steps are implemented, run the project's quality checks:

### 5a: Build
Detect and run the project's build command:
- `npm run build` / `pnpm build` / `yarn build`
- `cargo build`
- `go build ./...`
- `make build`

### 5b: Lint
Run the project's linter:
- `npm run lint` / `pnpm lint`
- `cargo clippy`
- `golangci-lint run`
- `ruff check .`

### 5c: Tests
Run the full test suite:
- `npm test`
- `cargo test`
- `go test ./...`
- `pytest`

### 5d: Fix Errors

If any check fails:
1. Read the error output
2. Fix the issue
3. Re-run the failing check
4. Repeat until all checks pass (maximum 3 attempts per check — if still failing after 3, surface the error to user and stop)
5. Commit fixes: `fix: resolve lint/test/build errors`

If a check doesn't apply (no build system, no linter, no tests), skip it.

## Step 6: Push

```bash
git push -u origin {{branch}}
```

## Step 7: Create PR/MR

Detect the default branch and platform:

1. Detect default branch: `git remote show origin | grep 'HEAD branch'` → fallback to main/master/develop
2. Check remote URL: `git remote get-url origin`
3. If contains `github.com`:
   - Check if `gh` CLI is available: `which gh`
   - If yes: `gh pr create --title "{{feature}}" --body "{{auto-generated summary}}"`
   - If no: Tell user to create PR manually on GitHub
4. If contains `gitlab.com` or `gitlab`:
   - Check if `glab` CLI is available: `which glab`
   - If yes: `glab mr create --title "{{feature}}" --description "{{auto-generated summary}}"`
   - If no: Tell user to create MR manually on GitLab
5. Otherwise:
   - Tell user: "Push is done. Please create a PR/MR on your platform for branch `{{branch}}`."

The auto-generated summary should include:
- Feature name
- List of implementation steps with commit SHAs
- Files changed (`git diff --stat {{default_branch}}...HEAD`)

## Step 8: Report

```
## Implementation Complete: {{feature}}

### Steps Completed
| # | Step | Commit |
|---|------|--------|
| 1 | {{name}} | {{short_sha}} |
| 2 | {{name}} | {{short_sha}} |
...

### Quality Checks
Build: PASS/FAIL | Lint: PASS/FAIL | Tests: PASS/FAIL

### PR/MR
{{PR_URL or "Please create manually"}}

Next: `/debug <bug>` if you found issues, or `/done` to wrap up.
Run `/where` to check your current state at any time.
```

**STOP HERE. Do NOT auto-advance to the next phase. Wait for the user to invoke the next command.**
