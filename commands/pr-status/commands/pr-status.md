---
name: pr-status
description: Get all my open PRs with CI state, reviews, comments, and freshness
---

# PR Status

Get a full status view of all your open PRs on the current repo.

## Execution

Run these bash commands to gather PR data:

### Step 1: Get PR list with metadata

```bash
gh pr list --author @me --state open --json number,title,headRefName,baseRefName,mergeable,reviewDecision,commits,updatedAt --limit 30
```

### Step 2: Get CI checks, comments, and merge state for each PR

```bash
for pr in $(gh pr list --author @me --state open --json number -q '.[].number'); do
  echo "===PR:$pr==="
  echo "---checks---"
  gh pr checks $pr 2>/dev/null
  echo "---comments---"
  review_comments=$(gh api repos/{owner}/{repo}/pulls/$pr/reviews --jq '[.[] | select(.user.login != "vercel[bot]" and .user.login != "github-actions[bot]")] | length' 2>/dev/null)
  pr_comments=$(gh api repos/{owner}/{repo}/pulls/$pr/comments --jq 'length' 2>/dev/null)
  issue_comments=$(gh api repos/{owner}/{repo}/issues/$pr/comments --jq '[.[] | select(.user.login != "vercel[bot]" and .user.login != "github-actions[bot]")] | length' 2>/dev/null)
  echo "reviews:$review_comments pr:$pr_comments issue:$issue_comments"
  echo "---merge---"
  gh api repos/{owner}/{repo}/pulls/$pr --jq '.mergeable_state' 2>/dev/null
done
```

## Presentation Instructions

Present the results as a markdown table ordered by last commit date (most recent first), with these columns:

| # | Ticket | Title | CI | Reviews | Comments | Up to date? | Last commit |
|---|--------|-------|-----|---------|----------|-------------|-------------|

Column details:
- **#**: PR number (bold)
- **Ticket**: Extract CSD-XXXX from the PR title if present, otherwise "—"
- **Title**: Short description (strip the ticket number prefix)
- **CI**: Summarize check status — "Pass" if all pass, "Fail" with failed check name if any fail, ignore Vercel preview/storybook skips
- **Reviews**: "Approved", "Changes requested", or "Needs review"
- **Comments**: Summarize non-bot review comments and PR comments (e.g., "2 review + 3 PR comments"), "None" if zero
- **Up to date?**: "Behind" if mergeable_state is "behind", "**Conflicts**" (bold) if "dirty" or mergeable is CONFLICTING, "Up to date" if "clean"
- **Last commit**: Relative time from the last commit date (e.g., "Today", "2 days ago", "6 months ago")

After the table, add a brief summary:
- Count of approved PRs ready to merge (after rebase)
- Count of PRs with conflicts
- Count of PRs with CI failures
- Flag any PRs older than 30 days as stale
