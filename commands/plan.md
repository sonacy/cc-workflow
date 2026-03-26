---
description: "Start a new feature workflow: research, generate PRD + architecture + implementation plan, create branch"
---

# /plan — Plan a Feature

You are starting Phase 1 of cc-workflow. Your job is to research, design, and produce a complete plan for the feature described below, then create a git branch and initialize tracking state.

## Input

Feature description: $ARGUMENTS

If no description is provided, ask the user: "What do you want to build? Give me a short description."

## Pre-flight Checks

1. Check if `.claude/workflow/state.json` exists:
   - If it exists and `phase` is NOT `done`, warn: "There's an active workflow for **{{feature}}** in phase **{{phase}}**. Finish it with `/done` first, or delete `.claude/workflow/state.json` to start fresh."
   - If it exists and `phase` is `done`, proceed (old state will be archived).
2. Check for uncommitted changes with `git status`. If dirty, warn: "You have uncommitted changes. Commit or stash them before starting a new feature."
3. Note the current branch (should typically be `main` or `develop`).

## Step 1: Generate Slug

Derive a URL-safe slug from the feature description:
- Lowercase, hyphen-separated, max 40 chars
- Example: "user authentication with JWT" → `user-auth-jwt`
- Example: "fix payment timeout bug" → `fix-payment-timeout`

Also determine the branch type from the description:
- Contains "fix", "bug", "patch", "hotfix" → `fix`
- Contains "refactor", "restructure", "reorganize" → `refactor`
- Contains "chore", "update deps", "maintenance", "ci", "config" → `chore`
- Default → `feat`

Set today's date as `YYYY-MM-DD`.

## Step 2: Research

Gather context to inform the plan. Use available tools — gracefully skip any that are unavailable:

1. **Read the codebase**: Use Glob and Read to understand the project structure, existing patterns, key files (package.json, CLAUDE.md, README, src/ structure)
2. **Library docs** (if context7 MCP available): Look up documentation for relevant libraries/frameworks mentioned in the description or found in the project
3. **Web search** (if exa MCP available): Search for patterns, best practices, existing implementations related to the feature
4. **GitHub search** (if github MCP available): Search for existing implementations or templates
5. **Past learnings**: Check `docs/solutions/` for any previously solved problems relevant to this feature. Also check ECC memory at `.claude/projects/*/memory/` for project-specific context.

Collect your findings as research notes — you'll use them in the next steps.

## Step 3: Discuss — Capture User Preferences

Before generating any documents, identify "gray areas" — decisions that have multiple valid approaches. Present them to the user as multiple-choice questions:

```
Before I draft the plan, a few decisions to lock in:

1. **{{gray_area_1}}**: (a) {{option_a}} (b) {{option_b}} (c) {{option_c}}
2. **{{gray_area_2}}**: (a) {{option_a}} (b) {{option_b}}
3. **{{gray_area_3}}**: (a) {{option_a}} (b) {{option_b}}
```

Focus on:
- Visual/UX decisions (if frontend)
- API design choices (REST vs GraphQL, response shape)
- Technology choices with multiple valid options
- Scope boundaries (what's in, what's out)
- Data model trade-offs

**WAIT for user response. Do NOT proceed until the user answers.**

## Step 4: Generate PRD

Using the template from `.claude/templates/cc-workflow/prd.md` as a guide (do NOT use the template literally — adapt it to the actual feature), generate a PRD document:

- Fill in real user stories based on the feature description
- List concrete acceptance criteria (each must be testable)
- Identify technical requirements from your research
- Note what's explicitly out of scope
- Incorporate the user's preferences from Step 3
- List any remaining open questions

Write to: `.claude/plans/{{date}}-{{slug}}/prd.md`

## Step 5: Generate Architecture Document

Dispatch the **architect** agent to produce the architecture document. Provide it with:
- The full PRD content
- Your research notes from Step 2
- The user's preference decisions from Step 3
- The current codebase structure

The agent should produce:
- System context (what exists, what changes)
- Component diagram (mermaid syntax)
- Data model / ERD (mermaid erDiagram syntax) — if the feature involves data
- API contracts — if the feature involves APIs
- Technology choices with rationale

Use the template from `.claude/templates/cc-workflow/architecture.md` as a guide.

Write to: `.claude/plans/{{date}}-{{slug}}/architecture.md`

## Step 6: Generate Implementation Plan

Dispatch the **planner** agent to produce a step-by-step implementation plan. Provide it with:
- The full PRD content
- The architecture document
- Your research notes
- The current codebase structure

The agent should produce:
- Steps ordered by dependency (independent steps first)
- Each step must have: name, description, files to create/modify, complexity, dependencies
- Each step should be completable in one `/implement` invocation (2-5 minute tasks are ideal)
- Include risks and mitigations

Use the template from `.claude/templates/cc-workflow/plan.md` as a guide.

Write to: `.claude/plans/{{date}}-{{slug}}/plan.md`

## Step 7: Plan Review Loop

Dispatch a **code-reviewer** agent to review the plan for quality. Provide it with all three documents (PRD, architecture, plan) and ask it to check:

- Are the steps atomic enough? (Each should be one commit)
- Are dependencies between steps correct?
- Are there missing steps? (Especially: migrations, config, error handling, edge cases)
- Do the steps cover all acceptance criteria?
- Are there risks not addressed?

If the reviewer finds issues, fix the plan and re-review. **Maximum 3 review iterations.** After 3 rounds, proceed with what you have.

## Step 8: Present Plan for Review

Show the user a summary of all three documents:
```
## Plan Summary

**Feature**: {{feature_name}}
**Branch**: {{branch_type}}/{{slug}}
**Plan directory**: .claude/plans/{{date}}-{{slug}}/

### PRD highlights
- {{key_user_stories}}
- {{key_acceptance_criteria}}

### Architecture highlights
- {{key_components}}
- {{key_technology_choices}}

### Implementation Steps ({{N}} steps)
1. {{step_1_name}} ({{complexity}})
2. {{step_2_name}} ({{complexity}})
...

### Risks
- {{top_risks}}

**Review the full docs at `.claude/plans/{{date}}-{{slug}}/` and let me know:**
- "go" — proceed with branch creation
- "fix: ..." — tell me what to change
- Or edit the files directly and say "updated"
```

**WAIT for user confirmation. Do NOT create branch until user says "go" or similar.**

If the user says "fix: ...", update the relevant documents and re-present. Loop until confirmed.

## Step 9: Create Git Branch

After user confirms:
```bash
git checkout -b {{branch_type}}/{{slug}}
```

## Step 10: Initialize State

Create `.claude/workflow/state.json`:
```json
{
  "version": "1.0",
  "feature": "{{feature_name}}",
  "slug": "{{slug}}",
  "branch": "{{branch_type}}/{{slug}}",
  "branch_type": "{{branch_type}}",
  "phase": "plan-complete",
  "plan_dir": ".claude/plans/{{date}}-{{slug}}",
  "created_at": "{{ISO_8601_now}}",
  "updated_at": "{{ISO_8601_now}}",
  "plan_commit": null,
  "steps": [
    {"id": 1, "name": "{{step_1}}", "status": "pending", "commit": null},
    {"id": 2, "name": "{{step_2}}", "status": "pending", "commit": null}
  ],
  "debug_log": []
}
```

Ensure `.claude/workflow/` directory exists first.

## Step 11: Commit Plan Documents

```bash
git add .claude/plans/{{date}}-{{slug}}/ .claude/workflow/state.json
git commit -m "docs: add plan for {{feature_name}}"
```

After committing, update `state.json` to store the plan commit SHA:
- Read the commit SHA: `git rev-parse HEAD`
- Set `"plan_commit": "{{sha}}"` in state.json
- Amend the commit: `git add .claude/workflow/state.json && git commit --amend --no-edit`
```

## Step 12: Done

Tell the user:
```
Plan complete! Created branch `{{branch_type}}/{{slug}}` with plan documents.

.claude/plans/{{date}}-{{slug}}/
  ├── prd.md
  ├── architecture.md
  └── plan.md

Next: Run `/implement` to start Step 1.
You can also run `/where` to check your current state at any time.
```

**STOP HERE. Do NOT auto-advance to `/implement`. Wait for the user to invoke the next command.**
