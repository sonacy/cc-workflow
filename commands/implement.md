---
description: "Implement the next step from the plan, review, then commit and push"
---

# /implement — Implement One Step

You are in Phase 2 of cc-workflow. Your job is to implement one step from the plan, get it reviewed, then commit and push.

## Input

Argument: $ARGUMENTS

- `next` (default, or no argument) — implement the next pending step
- `status` — show progress overview without implementing anything
- `<number>` — implement a specific step by ID (e.g., `/implement 3`)

## Step 1: Load State

Read `.claude/workflow/state.json`.

If the file doesn't exist:
> No active workflow found. Run `/plan <description>` to start one.

If `phase` is `plan` (not yet confirmed):
> Plan is still in draft. Review the docs at `{{plan_dir}}/` and confirm to proceed.

If `phase` is `done`:
> This workflow is already complete. Run `/plan <description>` to start a new one.

Valid phases to proceed: `plan-complete`, `implement`, `debug`

If coming from `debug` phase, update phase to `implement`.

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

Run `/implement` to continue with Step 2.
```

Return after showing status — do not implement anything.

## Step 3: Load Plan Context

Read ALL plan documents to provide full context:
- `{{plan_dir}}/plan.md` — implementation steps
- `{{plan_dir}}/architecture.md` — design decisions, ERD, API contracts
- `{{plan_dir}}/prd.md` — requirements and acceptance criteria

Also check `docs/solutions/` for any relevant past learnings that could help with this step.

## Step 4: Identify Target Step

- If argument is a number, find that step in state.steps
- If argument is `next` or empty, find the first step with `status: "pending"`
- If no pending steps remain, tell user: "All steps are done! Run `/debug` if you found issues, or `/done` to wrap up."

Update the target step's status to `in-progress` in state.json.
Update phase to `implement`.

## Step 5: Show Step Details

```
## Implementing Step {{id}}/{{total}}: {{name}}

{{step_description_from_plan}}

**Files**: {{files_to_create_or_modify}}
**Complexity**: {{complexity}}
**Depends on**: {{dependencies}}
```

## Step 6: Implement

Implement the step according to the plan:
- Follow the architecture decisions in `architecture.md`
- Follow existing project patterns and conventions
- Keep changes focused on this step only
- Write clean, readable code

If the project has existing tests, run them after implementation to ensure nothing is broken.

## Step 7: Two-Layer Code Review

### 7a: Spec Compliance Review

Dispatch a **code-reviewer** agent to check spec compliance. Provide:
- The step description from the plan
- The acceptance criteria from the PRD
- The git diff of changes made in this step

Ask it to verify:
- Does the implementation match what the plan specified?
- Are the acceptance criteria met?
- Is there scope creep (code that wasn't in the plan)?

Fix any spec compliance issues before proceeding.

### 7b: Code Quality Review

Dispatch the appropriate language-specific reviewer agent:
- TypeScript/JavaScript → **typescript-reviewer** agent
- Python → **python-reviewer** agent
- Go → **go-reviewer** agent
- Rust → **rust-reviewer** agent
- Java → **java-reviewer** agent
- Other → **code-reviewer** agent (generic)

Provide the full git diff and ask for:
- CRITICAL issues (bugs, security, data loss) — must fix
- HIGH issues (architecture, error handling, test gaps) — should fix
- MEDIUM/LOW issues — note but don't block

Fix CRITICAL issues. Fix HIGH issues if straightforward. Proceed after fixing.

## Step 8: Commit and Push

Stage and commit the changes:

```bash
git add <changed_files>
git commit -m "{{branch_type}}({{scope}}): {{step_description}} [step {{id}}/{{total}}]"
git push -u origin {{branch}}
```

Where:
- `scope` is derived from the primary module/component being changed
- `step_description` is a concise summary of what was implemented

## Step 9: Update State

Update `.claude/workflow/state.json`:
- Set the step's `status` to `done`
- Set the step's `commit` to the commit SHA
- Update `updated_at`

## Step 10: Report Progress

```
## Step {{id}}/{{total}} complete: {{name}}

{{brief_summary_of_what_was_done}}

Commit: {{short_sha}} — {{commit_message}}

{{if more steps}}
Next: Run `/implement` for Step {{next_id}}: {{next_name}}
{{else}}
All steps complete! Run `/debug` if you found issues, or `/done` to wrap up.
{{end}}
```
