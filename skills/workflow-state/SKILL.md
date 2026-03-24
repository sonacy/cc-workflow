---
name: workflow-state
description: State management conventions for cc-workflow's 4-phase lifecycle
---

# Workflow State Management

## State File

**Location**: `.claude/workflow/state.json` in the target project.

### Schema

```json
{
  "version": "1.0",
  "feature": "user-authentication",
  "slug": "user-auth",
  "branch": "feat/user-auth",
  "branch_type": "feat",
  "phase": "implement",
  "plan_dir": ".claude/plans/2026-03-23-user-auth",
  "created_at": "2026-03-23T10:00:00Z",
  "updated_at": "2026-03-23T14:30:00Z",
  "steps": [
    {
      "id": 1,
      "name": "Create user model and migration",
      "status": "done",
      "commit": "a1b2c3d"
    },
    {
      "id": 2,
      "name": "Add auth middleware",
      "status": "in-progress",
      "commit": null
    },
    {
      "id": 3,
      "name": "Build login endpoint",
      "status": "pending",
      "commit": null
    }
  ],
  "debug_log": [
    {
      "description": "Login fails with empty password",
      "commit": "d4e5f6a",
      "fixed_at": "2026-03-23T15:00:00Z"
    }
  ]
}
```

### Field Reference

| Field | Type | Set by | Description |
|-------|------|--------|-------------|
| `version` | string | `/plan` | Schema version, always "1.0" |
| `feature` | string | `/plan` | Human-readable feature name |
| `slug` | string | `/plan` | URL-safe identifier derived from feature name |
| `branch` | string | `/plan` | Git branch name (`<type>/<slug>`) |
| `branch_type` | string | `/plan` | One of: feat, fix, chore, refactor |
| `phase` | string | all | Current workflow phase |
| `plan_dir` | string | `/plan` | Relative path to plan documents |
| `created_at` | ISO 8601 | `/plan` | When workflow started |
| `updated_at` | ISO 8601 | all | Last state change |
| `steps` | array | `/plan`, `/implement` | Implementation steps from plan |
| `debug_log` | array | `/debug` | Record of bugs fixed |

### Step Status Values

- `pending` — Not started
- `in-progress` — Currently being implemented
- `done` — Completed and committed
- `skipped` — Explicitly skipped by user

## Phase Transitions

```
(none) ──/plan──▶ plan ──(confirm)──▶ plan-complete
                   ▲                        │
                   │ (refine)          /implement
                   │                        │
                   ▼                        ▼
               plan-complete ◀──── implement ◀──┐
                                    │    ▲      │
                                    │    │  (next step)
                                /debug   │      │
                                    │    └──────┘
                                    ▼
                                  debug ◀──┐
                                    │      │
                                    │  (more bugs)
                                    │      │
                                    └──────┘
                                    │
                                /done
                                    │
                                    ▼
                                  done ──▶ (archived)
```

### Valid Transitions

| From | To | Triggered by |
|------|----|-------------|
| `(none)` | `plan` | `/plan` |
| `plan` | `plan` | User refines plan |
| `plan` | `plan-complete` | User confirms plan |
| `plan-complete` | `implement` | `/implement` |
| `implement` | `implement` | `/implement` (next step) |
| `implement` | `debug` | `/debug` |
| `debug` | `debug` | `/debug` (more bugs) |
| `debug` | `implement` | `/implement` (back to steps) |
| `implement` | `done` | `/done` |
| `debug` | `done` | `/done` |
| `done` | `(archived)` | `/done` completes |

## State Operations

### Reading State

Every command MUST:
1. Check if `.claude/workflow/state.json` exists
2. If not, tell user to run `/plan <description>` first
3. If yes, read and validate the `phase` field
4. If phase is wrong for the command, explain what to do instead

### Writing State

Every command MUST:
1. Update `updated_at` to current ISO 8601 timestamp
2. Update `phase` to the new phase
3. Write the entire state object (not partial updates)
4. Use immutable updates (read → modify copy → write)

### Archiving

When `/done` completes:
1. Move `state.json` to `.claude/workflow/archive/<slug>-<date>.json`
2. Plan documents stay in `.claude/plans/` (they are permanent records)

### Error Recovery

- **Missing state file**: Tell user to run `/plan`
- **Corrupt JSON**: Show error, ask user to check `.claude/workflow/state.json`
- **Branch mismatch**: State says branch X but git is on branch Y — warn user, ask to confirm which is correct
- **Uncommitted changes**: Warn before phase transitions, suggest committing first
