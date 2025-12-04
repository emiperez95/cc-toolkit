#!/bin/bash
# Annotates unified diff with explicit line numbers
# Input: unified diff on stdin
# Output: annotated diff on stdout
#
# Format:
#   42:  context line     (unchanged, line 42 in new file)
#   43:+ added line       (added at line 43)
#   44:- removed line     (removed from line 44 in old file)

old_line=0
new_line=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # File header lines - pass through unchanged
    case "$line" in
        "diff --git"*|"index "*|"--- "*|"+++ "*|"Binary files"*)
            echo "$line"
            continue
            ;;
    esac

    # Hunk header - extract starting line numbers
    # Format: @@ -old_start,old_count +new_start,new_count @@
    if [[ "$line" =~ ^@@\ -([0-9]+)(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@ ]]; then
        old_line=${BASH_REMATCH[1]}
        new_line=${BASH_REMATCH[3]}
        echo "$line"
        continue
    fi

    # Context line (starts with space) - both sides advance
    if [[ "$line" =~ ^[[:space:]] ]]; then
        printf "%4d: %s\n" "$new_line" "$line"
        ((old_line++))
        ((new_line++))
        continue
    fi

    # Removed line (starts with -) - only old side advances
    if [[ "$line" == -* ]]; then
        printf "%4d:-%s\n" "$old_line" "${line:1}"
        ((old_line++))
        continue
    fi

    # Added line (starts with +) - only new side advances
    if [[ "$line" == +* ]]; then
        printf "%4d:+%s\n" "$new_line" "${line:1}"
        ((new_line++))
        continue
    fi

    # Empty line in diff (context) - both sides advance
    if [[ -z "$line" ]]; then
        printf "%4d:\n" "$new_line"
        ((old_line++))
        ((new_line++))
        continue
    fi

    # No newline at end of file marker - pass through
    if [[ "$line" == '\\'* ]]; then
        echo "$line"
        continue
    fi

    # Fallback - pass through unchanged
    echo "$line"
done
