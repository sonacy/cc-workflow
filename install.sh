#!/usr/bin/env bash
set -euo pipefail

# cc-workflow installer
# Copies commands, skills, and templates into the target project's .claude/ directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "Installing cc-workflow into: $TARGET_DIR"

# Verify target is a git repo
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "Error: $TARGET_DIR is not a git repository."
  echo "Usage: ./install.sh [target-project-path]"
  echo "  Defaults to current directory if no path given."
  exit 1
fi

# Create directories
mkdir -p "$TARGET_DIR/.claude/commands"
mkdir -p "$TARGET_DIR/.claude/workflow"
mkdir -p "$TARGET_DIR/.claude/workflow/archive"

# Copy commands (project-local, so /plan etc. work directly)
for cmd in plan implement debug done; do
  cp "$SCRIPT_DIR/commands/$cmd.md" "$TARGET_DIR/.claude/commands/$cmd.md"
  echo "  Installed command: /$cmd"
done

# Copy templates (used by /plan to generate docs)
mkdir -p "$TARGET_DIR/.claude/templates/cc-workflow"
for tmpl in prd architecture plan state; do
  cp "$SCRIPT_DIR/templates/$tmpl.md" "$TARGET_DIR/.claude/templates/cc-workflow/$tmpl.md"
done
echo "  Installed templates: prd, architecture, plan, state"

# Copy workflow-state skill
mkdir -p "$TARGET_DIR/.claude/skills/workflow-state"
cp "$SCRIPT_DIR/skills/workflow-state/SKILL.md" "$TARGET_DIR/.claude/skills/workflow-state/SKILL.md"
echo "  Installed skill: workflow-state"

echo ""
echo "Done! cc-workflow is installed."
echo ""
echo "Usage:"
echo "  /plan <description>     Start planning a feature"
echo "  /implement              Implement the next step"
echo "  /debug <bug>            Fix a bug with TDD"
echo "  /done                   Finish and prepare for PR"
