# State File Reference

## Location

`.claude/workflow/state.json` in the target project.

## Schema

See `skills/workflow-state/SKILL.md` for the full schema definition, valid phase transitions, and error recovery procedures.

## Quick Reference

```json
{
  "version": "1.0",
  "feature": "string — human-readable name",
  "slug": "string — url-safe identifier",
  "branch": "string — git branch name",
  "branch_type": "feat|fix|chore|refactor",
  "phase": "plan|plan-complete|implement|debug|done",
  "plan_dir": "string — relative path to plan docs",
  "created_at": "ISO 8601",
  "updated_at": "ISO 8601",
  "steps": [
    {
      "id": "number",
      "name": "string",
      "status": "pending|in-progress|done|skipped",
      "commit": "string|null — commit SHA"
    }
  ],
  "debug_log": [
    {
      "description": "string",
      "commit": "string",
      "fixed_at": "ISO 8601"
    }
  ]
}
```
