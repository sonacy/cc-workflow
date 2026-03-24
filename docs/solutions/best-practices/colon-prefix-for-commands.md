---
date: 2026-03-23
feature: Colon prefix + no auto-advance + /where command
category: best-practices
symptoms: Hyphen-prefixed commands (/cc-plan) don't match plugin namespacing convention
root_cause: Claude Code plugins use colon separator (everything-claude-code:plan) while we used hyphen
---

# Use colon separator for command prefixes

## Symptoms
Commands like `/cc-plan` worked but looked inconsistent with plugin conventions like `/everything-claude-code:plan`.

## Root Cause
Claude Code's plugin system uses colon (`:`) as the namespace separator. Using hyphen (`-`) was functional but non-standard.

## Solution
Changed install.sh to use colon separator: `/cc:plan` instead of `/cc-plan`. Filenames use colon too (`cc:plan.md`), which is POSIX-valid.

## Prevention
Follow the platform's existing conventions for namespacing.
