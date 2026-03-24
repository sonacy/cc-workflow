#!/usr/bin/env bash
set -euo pipefail

# cc-workflow installer
# Copies commands, skills, and templates into the target project's .claude/ directory
# Detects naming conflicts and applies optional prefix
# Supports re-install: reads existing config, cleans old files, installs new ones

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

COMMANDS=(plan implement debug done where)
CONFIG_FILE="$TARGET_DIR/.claude/.cc-workflow-config"
PREFIX=""
OLD_PREFIX=""

# --- Detect existing installation ---
if [ -f "$CONFIG_FILE" ]; then
  OLD_PREFIX=$(grep '^prefix=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || true)
  if [ -n "$OLD_PREFIX" ]; then
    echo ""
    echo "Existing installation found (prefix: '${OLD_PREFIX}')."
    echo "Commands: /${OLD_PREFIX}:plan, /${OLD_PREFIX}:implement, /${OLD_PREFIX}:debug, /${OLD_PREFIX}:done, /${OLD_PREFIX}:where"
  else
    echo ""
    echo "Existing installation found (no prefix)."
    echo "Commands: /plan, /implement, /debug, /done"
  fi
  echo ""
  echo "Options:"
  echo "  1. Press Enter to re-install with same prefix"
  echo "  2. Enter a new prefix to change it"
  echo "  3. Enter 'none' to remove prefix"
  echo ""
  read -rp "Prefix [${OLD_PREFIX:-none}]: " input
  if [ "$input" = "none" ]; then
    PREFIX=""
  elif [ -n "$input" ]; then
    PREFIX="$input"
  else
    PREFIX="$OLD_PREFIX"
  fi

  # Clean up old command files (both colon and hyphen style)
  for cmd in "${COMMANDS[@]}"; do
    if [ -n "$OLD_PREFIX" ]; then
      # Remove colon-style (current format)
      old_file="$TARGET_DIR/.claude/commands/${OLD_PREFIX}:${cmd}.md"
      [ -f "$old_file" ] && rm "$old_file"
      # Remove hyphen-style (legacy format)
      old_file="$TARGET_DIR/.claude/commands/${OLD_PREFIX}-${cmd}.md"
      [ -f "$old_file" ] && rm "$old_file"
    else
      old_file="$TARGET_DIR/.claude/commands/${cmd}.md"
      [ -f "$old_file" ] && rm "$old_file"
    fi
  done
  echo "  Removed old command files."
else
  # --- Fresh install: conflict detection ---
  conflicts=()
  for cmd in "${COMMANDS[@]}"; do
    # Check global commands
    if [ -f "$HOME/.claude/commands/$cmd.md" ]; then
      conflicts+=("$cmd (global: ~/.claude/commands/$cmd.md)")
    fi
    # Check target project already has these commands (not from us)
    if [ -f "$TARGET_DIR/.claude/commands/$cmd.md" ]; then
      if ! grep -q "cc-workflow" "$TARGET_DIR/.claude/commands/$cmd.md" 2>/dev/null; then
        conflicts+=("$cmd (project: .claude/commands/$cmd.md)")
      fi
    fi
  done

  # Check for ECC plugin (provides /plan, /debug as skills)
  if [ -f "$HOME/.claude/plugin.json" ] || [ -d "$HOME/.claude/plugins/cache/everything-claude-code" ]; then
    for cmd in plan debug; do
      if [[ ! " ${conflicts[*]:-} " =~ " $cmd " ]]; then
        conflicts+=("$cmd (ECC plugin skill)")
      fi
    done
  fi

  if [ ${#conflicts[@]} -gt 0 ]; then
    echo ""
    echo "Naming conflicts detected:"
    for c in "${conflicts[@]}"; do
      echo "  - /$c"
    done
    echo ""
    echo "Options:"
    echo "  1. Enter a prefix (e.g., 'cc' → /cc:plan, /cc:implement, /cc:debug, /cc:done, /cc:where)"
    echo "  2. Press Enter to install anyway (commands may shadow existing ones)"
    echo ""
    read -rp "Prefix (or Enter to skip): " PREFIX
    PREFIX="${PREFIX:-}"
  fi
fi

# --- Install commands ---
mkdir -p "$TARGET_DIR/.claude/commands"
mkdir -p "$TARGET_DIR/.claude/workflow"
mkdir -p "$TARGET_DIR/.claude/workflow/archive"

for cmd in "${COMMANDS[@]}"; do
  if [ -n "$PREFIX" ]; then
    dest_name="${PREFIX}:${cmd}.md"
  else
    dest_name="${cmd}.md"
  fi

  # Copy and apply prefix to cross-references inside the file
  if [ -n "$PREFIX" ]; then
    sed \
      -e "s|\`/plan\`|\`/${PREFIX}:plan\`|g" \
      -e "s|\`/implement\`|\`/${PREFIX}:implement\`|g" \
      -e "s|\`/debug\`|\`/${PREFIX}:debug\`|g" \
      -e "s|\`/done\`|\`/${PREFIX}:done\`|g" \
      -e "s|\`/plan |\`/${PREFIX}:plan |g" \
      -e "s|\`/implement |\`/${PREFIX}:implement |g" \
      -e "s|\`/debug |\`/${PREFIX}:debug |g" \
      -e "s|\`/done |\`/${PREFIX}:done |g" \
      -e "s|# /plan |# /${PREFIX}:plan |g" \
      -e "s|# /implement |# /${PREFIX}:implement |g" \
      -e "s|# /debug |# /${PREFIX}:debug |g" \
      -e "s|# /done |# /${PREFIX}:done |g" \
      -e "s|\`/where\`|\`/${PREFIX}:where\`|g" \
      -e "s|\`/where |\`/${PREFIX}:where |g" \
      -e "s|# /where |# /${PREFIX}:where |g" \
      "$SCRIPT_DIR/commands/$cmd.md" > "$TARGET_DIR/.claude/commands/$dest_name"
  else
    cp "$SCRIPT_DIR/commands/$cmd.md" "$TARGET_DIR/.claude/commands/$dest_name"
  fi

  if [ -n "$PREFIX" ]; then
    echo "  Installed command: /${PREFIX}:${cmd}"
  else
    echo "  Installed command: /$cmd"
  fi
done

# --- Install templates ---
mkdir -p "$TARGET_DIR/.claude/templates/cc-workflow"
for tmpl in prd architecture plan state; do
  cp "$SCRIPT_DIR/templates/$tmpl.md" "$TARGET_DIR/.claude/templates/cc-workflow/$tmpl.md"
done
echo "  Installed templates: prd, architecture, plan, state"

# --- Install skill ---
mkdir -p "$TARGET_DIR/.claude/skills/workflow-state"
cp "$SCRIPT_DIR/skills/workflow-state/SKILL.md" "$TARGET_DIR/.claude/skills/workflow-state/SKILL.md"
echo "  Installed skill: workflow-state"

# --- Save config ---
mkdir -p "$(dirname "$CONFIG_FILE")"
cat > "$CONFIG_FILE" <<EOF
# cc-workflow installation config
prefix=${PREFIX}
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source_dir=${SCRIPT_DIR}
EOF
echo "  Saved config: .claude/.cc-workflow-config"

# --- Summary ---
echo ""
echo "Done! cc-workflow is installed."
echo ""
if [ -n "$PREFIX" ]; then
  echo "Usage (with prefix '${PREFIX}'):"
  echo "  /${PREFIX}:plan <description>     Start planning a feature"
  echo "  /${PREFIX}:implement              Implement the next step"
  echo "  /${PREFIX}:debug <bug>            Fix a bug"
  echo "  /${PREFIX}:done                   Finish and prepare for PR"
  echo "  /${PREFIX}:where                  Show current state and next action"
else
  echo "Usage:"
  echo "  /plan <description>     Start planning a feature"
  echo "  /implement              Implement the next step"
  echo "  /debug <bug>            Fix a bug"
  echo "  /done                   Finish and prepare for PR"
  echo "  /where                  Show current state and next action"
fi
