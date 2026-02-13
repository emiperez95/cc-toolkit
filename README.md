# CC Toolkit

Claude Code plugins for workflow automation with Jira, GitHub, Notion, and Google Drive.

## Installation

Install all plugins from the marketplace:
```bash
/plugin marketplace add emiperez95/cc-toolkit
```

Or install individual plugins:
```bash
/plugin marketplace add emiperez95/cc-toolkit:atlas-jira-analyst
/plugin marketplace add emiperez95/cc-toolkit:athena-pr-reviewer
```

## Available Plugins

### Agents

| Name | Description |
|------|-------------|
| **atlas-jira-analyst** | Fetches Jira issue information including tickets, epics, acceptance criteria, and comments |
| **apollo-jira-scribe** | Creates and updates Jira tickets including status transitions and sprint assignments |
| **clio-docs-oracle** | Reads Google Drive files (Docs, Sheets, PDFs) and converts them to readable formats |
| **heimdall-pr-guardian** | Monitors PR status including comments, CI/CD checks, approvals, and merge blockers |
| **hermes-pr-courier** | Collects PR content including metadata, file changes, and commit history |
| **minerva-notion-oracle** | Searches and retrieves content from Notion workspaces |

### Commands

| Name | Description |
|------|-------------|
| **gemini** | Leverage Gemini's massive context window for large codebase analysis |
| **codex** | OpenAI Codex CLI with local and cloud execution modes |
| **memory-compact** | Compact and reorganize Claude Code auto-memory files |

### Skills

| Name | Description |
|------|-------------|
| **athena-pr-reviewer** | Multi-LLM PR reviewer with up to 8 parallel reviewers (auto-detects available LLM providers) |
| **harvest-timesheet** | Automate Harvest timesheet filling from Google Calendar meetings |

**Harvest Timesheet Features:**
- Auto-discovers Harvest rows from previous month on first run
- Reads Google Calendar meetings via Chrome DevTools MCP
- Categorizes meetings into Harvest rows with growing memory
- Fills Harvest weekly grid with calculated hours
- Free-form config supports multi-project setups
- Config stored at `~/.claude/harvest-timesheet.local.md`

**Athena Features:**
- 6 specialized Claude reviewers (comments, tests, errors, types, general, simplifier)
- Optional Gemini and Codex reviewers (auto-detected, gracefully skipped if not installed)
- Dynamic reviewer selection UI - choose which reviewers to run
- Annotated diff with explicit line numbers for accurate references
- Verification step to filter hallucinated findings
- Consensus boosting for issues flagged by multiple reviewers

**Athena Auto-Approved Permissions:**

This plugin includes a `PermissionRequest` hook that auto-approves specific operations to reduce permission prompts. You will still be asked to confirm:
1. Skill invocation ("Use skill athena-pr-reviewer?")
2. Reviewer selection (which reviewers to run)

The following are auto-approved with strict pattern matching:

| Operation | Pattern | Security |
|-----------|---------|----------|
| Bash scripts | Exact paths: `~/.claude/skills/athena-pr-reviewer/scripts/*.sh` | Only skill's own scripts |
| Review outputs | Regex: `/tmp/athena-review-[0-9]+/reviews/[a-z][a-z0-9-]*.md` | Only PR work directory |
| Work files | Exact: `context.md`, `diff.patch`, `verified-findings.md`, `rejected.md` | Limited file set |

To disable auto-approval, remove the `hooks/` directory from the plugin.

## Requirements

- **GitHub CLI** (`gh`): Required for PR-related agents
- **Atlassian CLI** (`acli`): Required for Jira agents
- **rclone**: Required for Google Drive agent (clio-docs-oracle)
- **Notion MCP**: Required for Notion agent (minerva-notion-oracle)
- **Chrome DevTools MCP**: Required for harvest-timesheet (bundled with plugin)
- **Gemini CLI**: Optional, enhances athena-pr-reviewer
- **Codex CLI**: Optional, enhances athena-pr-reviewer

## License

MIT
