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

# DEBUG: Log all calls to this hook
DEBUG_LOG="/tmp/athena-hook-debug.log"
echo "=== $(date) ===" >> "$DEBUG_LOG"

# Read permission request from stdin
REQUEST=$(cat)
echo "INPUT: $REQUEST" >> "$DEBUG_LOG"
TOOL=$(echo "$REQUEST" | jq -r '.tool_name // empty')

# Exit early if missing tool (no decision, let normal flow continue)
[[ -z "$TOOL" ]] && exit 0

case "$TOOL" in
  # NOTE: Skill confirmation intentionally NOT auto-approved
  # Users should confirm they want to run the skill (can disable via settings)

  "Bash")
    # Extract command from tool_input JSON object
    COMMAND=$(echo "$REQUEST" | jq -r '.tool_input.command // empty')
    [[ -z "$COMMAND" ]] && exit 0

    # Match athena scripts regardless of install location (global or local .claude/skills/)
    # Pattern: */athena-pr-reviewer/scripts/{script}.sh {args}
    # Security: Still requires the full skill path structure, not just script name
    if [[ "$COMMAND" == *"/athena-pr-reviewer/scripts/gather-context.sh "* ]] || \
       [[ "$COMMAND" == *"/athena-pr-reviewer/scripts/run-reviews.sh "* ]] || \
       [[ "$COMMAND" == *"/athena-pr-reviewer/scripts/annotate-diff.sh "* ]]; then
      echo "DECISION: allow (Bash script match)" >> "$DEBUG_LOG"
      echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
      exit 0
    fi
    # Allow mkdir for athena work directories
    if [[ "$COMMAND" == "mkdir -p /tmp/athena-review-"* ]]; then
      echo "DECISION: allow (mkdir athena work dir)" >> "$DEBUG_LOG"
      echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
      exit 0
    fi
    echo "BASH NO MATCH - command was: $COMMAND" >> "$DEBUG_LOG"
    ;;

  "Edit"|"Write")
    # Extract file_path from tool_input JSON object
    FILE_PATH=$(echo "$REQUEST" | jq -r '.tool_input.file_path // empty')
    [[ -z "$FILE_PATH" ]] && exit 0

    # Strict regex: /tmp/athena-review-{id}/reviews/{lowercase-with-hyphens}.md
    # ID can be PR number (digits) or Jira ticket (e.g., CSD-2472)
    # This prevents injection attacks - only matches our exact output pattern
    if [[ "$FILE_PATH" =~ ^/tmp/athena-review-[A-Za-z0-9-]+/reviews/[a-z][a-z0-9-]*\.md$ ]]; then
      echo "DECISION: allow (Edit/Write review file)" >> "$DEBUG_LOG"
      echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
      exit 0
    fi
    # Also allow specific files in work directory root
    if [[ "$FILE_PATH" =~ ^/tmp/athena-review-[A-Za-z0-9-]+/(context\.md|diff\.patch|verified-findings\.md|rejected\.md)$ ]]; then
      echo "DECISION: allow (Edit/Write work file)" >> "$DEBUG_LOG"
      echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
      exit 0
    fi
    ;;
esac

# Default: pass through to normal permission flow
# This does NOT deny - it just doesn't auto-approve (exit with no output)
echo "DECISION: pass (no match)" >> "$DEBUG_LOG"
exit 0
