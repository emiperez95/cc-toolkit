---
name: memory-compact
description: Compact and reorganize Claude Code memory files for the current project
---

# Memory Compact

Analyze and reorganize the Claude Code auto-memory files for the current project. This command helps keep memory files clean, well-structured, and within size limits.

## Steps

1. **Locate memory files**: Find the memory directory for the current project at `~/.claude/projects/<sanitized-path>/memory/` where the path is derived from the current working directory (replace leading `/` with `-`, then all `/` with `-`).

2. **Read all memory files**: Read every `.md` file in the memory directory. If no files exist, inform the user and stop.

3. **Analyze for issues**:
   - MEMORY.md over 200 lines (hard limit, prefer under 150)
   - Redundant or duplicate entries across files
   - Stale information (completed one-off task notes that don't reveal reusable patterns)
   - Tiny topic files under 15 lines that could merge into MEMORY.md or another file
   - Large topic files over 80 lines that should be split
   - Contradictory information
   - Poor organization (related items scattered across files)

4. **Present a proposal** showing:
   - Current state: list each file with line count and brief summary
   - Issues found
   - Proposed state: for each file that would change, show the FULL proposed contents
   - Files to delete (if any)
   - New files to create (if any)

5. **Wait for user approval** before making any changes. Do NOT write any files until the user explicitly approves.

6. **Apply changes**: Write modified files, delete removed files, create new topic files.

## Guidelines

- MEMORY.md is the index file loaded into every session's system prompt — keep it concise
- MEMORY.md hard limit: 200 lines. Target: under 150 lines
- Topic files should be 15-80 lines each
- Remove completed one-off task notes UNLESS they reveal reusable patterns
- Preserve genuine project knowledge: architecture decisions, debugging insights, conventions, user preferences
- When splitting MEMORY.md, keep a brief reference/link in MEMORY.md pointing to the new topic file
- Prefer fewer, well-organized files over many tiny ones
