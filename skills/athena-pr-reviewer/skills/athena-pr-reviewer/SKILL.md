---
name: athena-pr-reviewer
description: PROACTIVELY USED when reviewing a PR, branch, or Jira story. Handles code review against requirements and provides actionable feedback.
---

# Athena PR Reviewer

## Instructions

### 1. Detect PR Target

Parse user input to identify the PR:

- **Direct PR reference** (`PR 123`, `#123`): Extract number directly
- **Jira ticket** (`PROJ-123`): Run `gh pr list --search "PROJ-123" --json number --jq '.[0].number'`
- **Current branch**: Run `gh pr view --json number --jq '.number'`
- **No PR found**: Extract Jira from branch with `git branch --show-current | grep -oE '[A-Z]+-[0-9]+'`

### 2. Gather Data (Script)

Run the gather-context script which collects all data in parallel:

```bash
~/.claude/skills/athena-pr-reviewer/scripts/gather-context.sh ${PR_NUM} ${JIRA_TICKET}
```

This script:
- Creates work directory at `/tmp/athena-review-${PR_NUM}/`
- Fetches in parallel: PR metadata, diff, Jira ticket, epic, CLAUDE.md guidelines, git blame, prior PR comments
- Writes combined context to `${WORK_DIR}/context.md`
- Writes diff to `${WORK_DIR}/diff.patch`

Output files:
- `context.md` - Combined PR + Jira + guidelines + history data
- `diff.patch` - Full PR diff
- `pr.json` - Raw PR metadata
- `jira.json` - Raw Jira ticket data
- `epic.json` - Epic context (if linked)
- `guidelines.md` - All CLAUDE.md files from repo
- `blame.md` - Git blame for changed files (who wrote what, when)
- `prior-comments.md` - Comments from past PRs touching same files

### 3. Detect and Select Reviewers

Before running reviews, detect available reviewer agents and let the user select which to use.

#### 3.1 Detect Available Reviewers

**Built-in reviewers (always available):**
- 6 Claude specialists: comment-analyzer, test-analyzer, error-hunter, type-reviewer, code-reviewer, simplifier
- External LLMs: Gemini, Codex (auto-detected by run-reviews.sh)

**Dynamic reviewers:**
Check available `subagent_type` values in your context for additional reviewers:
1. Pattern match - Find agents where name or description contains "reviewer" or "review"
2. Exclude: `athena-pr-reviewer` (this skill), data-gathering agents (hermes-pr-courier, heimdall-pr-guardian, etc.)

#### 3.2 Present Selection UI

Use `AskUserQuestion` with pagination to let user select reviewers:

**Rules:**
- Max 4 options per question, max 4 questions per call
- Each batch shows "All in this batch" + 3 actual reviewers
- Use `multiSelect: true`
- Group by category (Built-in specialists, External agents, Dynamic agents)

**Example for 11 reviewers:**
```
Question 1/4 - "Select reviewers: Built-in specialists"
  [ ] All in this batch (Select all 3)
  [ ] comment-analyzer - Documentation & comments
  [ ] test-analyzer - Test coverage
  [ ] error-hunter - Error handling

Question 2/4 - "Select reviewers: More specialists"
  [ ] All in this batch (Select all 3)
  [ ] type-reviewer - Type design
  [ ] code-reviewer - General code quality
  [ ] simplifier - Code complexity

Question 3/4 - "Select reviewers: External LLMs"
  [ ] All in this batch (Select all 2)
  [ ] gemini - Google Gemini analysis
  [ ] codex - OpenAI Codex analysis

Question 4/4 - "Select reviewers: Dynamic agents"
  [ ] All in this batch (Select all N)
  [ ] {detected-agent-1} - {description}
  [ ] {detected-agent-2} - {description}
```

#### 3.3 Parse Selection

- If "All in this batch" selected → include all reviewers from that batch
- Otherwise include only individually selected reviewers
- Store final list of selected reviewers for step 4

### 4. Run Reviews (Selected Reviewers in Parallel)

Execute all selected reviews simultaneously in a SINGLE message.

**In ONE message, run all selected reviewers:**

#### 4.1 External LLMs (if selected)

If Gemini or Codex were selected, start with `run_in_background: true`:
```bash
~/.claude/skills/athena-pr-reviewer/scripts/run-reviews.sh ${WORK_DIR}
```

#### 4.2 Built-in Claude Specialists (if selected)

For each selected built-in specialist, spawn a Task agent:

| Specialist | Prompt File | Output File |
|------------|-------------|-------------|
| comment-analyzer | `prompts/comment-analyzer.md` | `claude-comments.md` |
| test-analyzer | `prompts/test-analyzer.md` | `claude-tests.md` |
| error-hunter | `prompts/error-hunter.md` | `claude-errors.md` |
| type-reviewer | `prompts/type-reviewer.md` | `claude-types.md` |
| code-reviewer | `prompts/code-reviewer.md` | `claude-general.md` |
| simplifier | `prompts/simplifier.md` | `claude-simplify.md` |

```
Task: general-purpose
Prompt: "Read ~/.claude/skills/athena-pr-reviewer/prompts/{SPECIALIST}.md for instructions.
Then read ${WORK_DIR}/context.md and ${WORK_DIR}/diff.patch. Perform the review. Output markdown."
Save to: ${WORK_DIR}/reviews/{OUTPUT_FILE}
```

#### 4.3 Dynamic Reviewer Agents (if selected)

For each selected dynamic agent, spawn using its own agent type:

```
Task: {agent-name}
Prompt: "Review the PR for code quality issues.

Context file: ${WORK_DIR}/context.md (contains requirements, PR metadata, guidelines)
Diff file: ${WORK_DIR}/diff.patch (annotated with line numbers)

Use your expertise to identify issues. For each finding include:
- File path and line number (use format from diff annotations)
- Severity: Critical/High/Medium/Low
- Confidence: 0-100
- Description and suggested fix

Write your review output to: ${WORK_DIR}/reviews/{agent-name}.md"
```

#### 4.4 Wait for Completion

After all Task agents complete, use `BashOutput` to check if external LLMs finished (if they were selected).

### 5. Aggregate Reviews

Read ALL review files from `${WORK_DIR}/reviews/` directory and combine findings.

**Possible reviewers (depending on selection):**
- External: gemini.md, codex.md
- Built-in: claude-comments.md, claude-tests.md, claude-errors.md, claude-types.md, claude-general.md, claude-simplify.md
- Dynamic: {agent-name}.md (any additional detected agents)

**Confidence Filtering:**
- Drop findings with confidence < 80
- Keep findings 50-79 only if flagged by 2+ reviewers

**Priority Boost Rule:** Items flagged by 2+ reviewers get bumped up one severity level.

| Reviewers | Original | Final Severity |
|-----------|----------|----------------|
| 3+        | High     | Critical       |
| 2         | High     | Critical       |
| 3+        | Medium   | High           |
| 2         | Medium   | High           |
| 1         | Any      | No boost       |

Deduplicate similar findings, noting which reviewer(s) flagged each and average confidence.

### 5.5 Verify Findings

For each aggregated finding, verify against actual code to filter hallucinations:

1. Read `${WORK_DIR}/diff.patch` to get the actual code
2. For each finding with file:line reference:
   - Extract the actual code at that location from the diff
   - Compare the finding's description to what the code actually does
3. Use the verifier prompt (`~/.claude/skills/athena-pr-reviewer/prompts/verifier.md`) to validate each finding
4. Filter based on verdict:
   - **✓ VERIFIED** → Keep in final output
   - **✗ REJECTED** → Write to `${WORK_DIR}/rejected.md` with reason
   - **⚠️ PARTIAL** → Keep but move to "Suggestions" section

Output verified findings to `${WORK_DIR}/verified-findings.md`

### 6. Synthesize Actionable Items

Present combined review to user:

```markdown
# PR Review: {PR_TITLE} (#{PR_NUM})

## Requirements Status
| Requirement | Status | Notes |
|-------------|--------|-------|

## Action Items (Verified)

### Critical (consensus, verified)
- [ ] file:line - issue - fix [reviewer1 + reviewer2 + reviewer3] (3+, avg 92%) ✓

### High Priority (verified)
- [ ] file:line - issue - fix [reviewer1 + reviewer2] ← boosted (2, avg 85%) ✓
- [ ] file:line - issue - fix [reviewer1] (95%) ✓

### Medium Priority (verified)
- [ ] file:line - issue - fix [reviewer1] (88%) ✓

### Suggestions
- improvements (including PARTIAL findings downgraded from higher severity)

## Rejected Findings
Findings that failed verification are saved to: `${WORK_DIR}/rejected.md`

## Review Sources
[List all .md files found in ${WORK_DIR}/reviews/]

## Recommendation: APPROVE / REQUEST_CHANGES
```

## Examples

**User:** "Review PR 456"
1. Detect PR 456, find linked Jira ticket
2. Gather context via script (parallel CLI calls)
3. Detect available reviewers (built-in + any dynamic agents)
4. Present selection UI - user picks which reviewers to run
5. Run selected reviews in parallel
6. Aggregate findings, boost items flagged by 2+ reviewers
7. Verify findings against actual diff (filter hallucinations)
8. Present verified actionable summary

**User:** "Review CSD-123"
1. Find PR linked to CSD-123
2. Gather context including acceptance criteria
3. Present reviewer selection (may include custom security-reviewer agent if installed)
4. Run selected reviews in parallel
5. Present findings with reviewer attribution

**User:** "Review this branch"
1. Get PR from current branch
2. Extract Jira from branch name if needed
3. Detect all available reviewers
4. User selects reviewers via paginated UI
5. Full review workflow with selected reviewers
