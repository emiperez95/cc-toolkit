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

### Skills

| Name | Description |
|------|-------------|
| **athena-pr-reviewer** | Multi-LLM PR reviewer with up to 8 parallel reviewers (auto-detects available LLM providers) |

**Athena Features:**
- 6 specialized Claude reviewers (comments, tests, errors, types, general, simplifier)
- Optional Gemini and Codex reviewers (auto-detected, gracefully skipped if not installed)
- Annotated diff with explicit line numbers for accurate references
- Verification step to filter hallucinated findings
- Consensus boosting for issues flagged by multiple reviewers

## Requirements

- **GitHub CLI** (`gh`): Required for PR-related agents
- **Atlassian CLI** (`acli`): Required for Jira agents
- **rclone**: Required for Google Drive agent (clio-docs-oracle)
- **Notion MCP**: Required for Notion agent (minerva-notion-oracle)
- **Gemini CLI**: Optional, enhances athena-pr-reviewer
- **Codex CLI**: Optional, enhances athena-pr-reviewer

## License

MIT
