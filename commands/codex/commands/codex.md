---
name: codex
description: OpenAI Codex CLI Integration
---

# OpenAI Codex CLI Integration

Use the Codex CLI to leverage GPT-5-Codex for coding tasks. Supports local execution and cloud mode with parallel experimentation.

## Basic Usage

**Local execution (immediate, in your repo):**
```bash
codex exec "Your prompt here"
```

**With full auto mode (skip approvals):**
```bash
codex exec --full-auto "Fix all TypeScript errors in src/"
```

## Common Use Cases

### Code Review

```bash
codex exec "Review this diff for bugs and security issues: $(git diff HEAD~1)"
```

### Implementation Tasks

```bash
codex exec "Add input validation to all API endpoints in src/api/"
```

### Refactoring

```bash
codex exec "Refactor the caching layer to use Redis instead of in-memory"
```

### Bug Fixing

```bash
codex exec --full-auto "Fix all TypeScript errors in src/"
```

## Image/Design Input

Codex supports image input for UI/design tasks. In interactive mode:
- **Paste**: Ctrl+V to paste screenshot from clipboard
- **Drag**: Drag image file into terminal

```bash
# Start interactive mode for image tasks
codex
# Then paste/drag your image and type your prompt
```

## Cloud Execution (Parallel Experimentation)

For heavy tasks or comparing multiple approaches:

```bash
# Generate 3 different solutions in parallel cloud sandboxes
codex cloud exec --env ENV_ID --attempts 3 "Optimize database queries in src/db/"

# Browse cloud tasks interactively
codex cloud
```

**Note**: Cloud mode requires environment setup. Run `codex cloud` and press Ctrl+O to configure.

## When to Use This Command

Invoke this command when:
- Running **parallel experiments** with best-of-N (cloud mode)
- Working with **UI mockups or screenshots** for design-to-code
- Delegating a task to run **asynchronously in the cloud**
- Leveraging **GPT-5-Codex** for coding tasks
- Need tasks to run in **isolated sandboxes**

## Execution Instructions

1. Determine the appropriate mode:
   - `codex exec` for immediate local execution
   - `codex cloud exec` for parallel/async cloud execution
2. Construct the command with the user's prompt
3. Use the Bash tool to execute the command
4. Capture and return Codex's response
5. Summarize key outputs if response is long

## Output Handling

```bash
# Pipe output to file
codex exec "Generate release notes" | tee release-notes.md

# JSON output for scripting
codex exec --json "Analyze dependencies"
```

## Important Notes

- Codex runs inside your Git repository by default
- Use `--full-auto` to skip approval prompts (use carefully)
- Cloud mode runs in isolated sandboxes - safe for risky experiments
- Image paste works in interactive mode, not in `exec`
- Results from cloud tasks persist for later review

## Requirements

- Codex CLI installed: `npm install -g @openai/codex`
- Authentication: `codex auth` or set `CODEX_API_KEY`
- Verify installation: `codex --version`
