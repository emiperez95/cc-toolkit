#!/bin/bash
# Auto-approve athena-pr-reviewer operations
#
# SECURITY: Uses strict pattern matching to prevent exploitation
# - Skill: NOT auto-approved (intentional gate for user control)
# - Bash: exact script paths only (gather-context.sh, run-reviews.sh, annotate-diff.sh)
# - Edit/Write: strict regex for /tmp/athena-review-{PR_NUM}/ files only
#
# This hook is bundled with the athena-pr-reviewer plugin and runs on every
# permission request. It only auto-approves operations that are:
# 1. Specific to this skill's workflow
# 2. Limited to safe, predictable paths
# 3. Cannot be exploited via path injection

set -euo pipefail

# Read permission request from stdin
REQUEST=$(cat)
TOOL=$(echo "$REQUEST" | jq -r '.tool // empty')
TOOL_INPUT=$(echo "$REQUEST" | jq -r '.toolInput // empty')

# Exit early if missing data
[[ -z "$TOOL" || -z "$TOOL_INPUT" ]] && echo '{"decision": "pass"}' && exit 0

case "$TOOL" in
  # NOTE: Skill confirmation intentionally NOT auto-approved
  # Users should confirm they want to run the skill (can disable via settings)

  "Bash")
    # Exact script paths only - no wildcards in matching
    # Only approve our specific scripts with any arguments
    SCRIPT_DIR="$HOME/.claude/skills/athena-pr-reviewer/scripts"
    if [[ "$TOOL_INPUT" == "$SCRIPT_DIR/gather-context.sh "* ]] || \
       [[ "$TOOL_INPUT" == "$SCRIPT_DIR/run-reviews.sh "* ]] || \
       [[ "$TOOL_INPUT" == "$SCRIPT_DIR/annotate-diff.sh "* ]]; then
      echo '{"decision": "allow"}'
      exit 0
    fi
    ;;

  "Edit"|"Write")
    # Strict regex: /tmp/athena-review-{digits}/reviews/{lowercase-with-hyphens}.md
    # This prevents injection attacks - only matches our exact output pattern
    if [[ "$TOOL_INPUT" =~ ^/tmp/athena-review-[0-9]+/reviews/[a-z][a-z0-9-]*\.md$ ]]; then
      echo '{"decision": "allow"}'
      exit 0
    fi
    # Also allow specific files in work directory root
    if [[ "$TOOL_INPUT" =~ ^/tmp/athena-review-[0-9]+/(context\.md|diff\.patch|verified-findings\.md|rejected\.md)$ ]]; then
      echo '{"decision": "allow"}'
      exit 0
    fi
    ;;
esac

# Default: pass through to normal permission flow
# This does NOT deny - it just doesn't auto-approve
echo '{"decision": "pass"}'
