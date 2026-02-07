---
name: harvest-timesheet
description: Automate Harvest timesheet filling from Google Calendar meetings. Reads meetings for a target month, categorizes them, and fills Harvest rows. Invoke manually via /harvest-timesheet.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - TodoWrite
  - mcp__plugin_harvest-timesheet_chrome-devtools__take_snapshot
  - mcp__plugin_harvest-timesheet_chrome-devtools__take_screenshot
  - mcp__plugin_harvest-timesheet_chrome-devtools__click
  - mcp__plugin_harvest-timesheet_chrome-devtools__fill
  - mcp__plugin_harvest-timesheet_chrome-devtools__fill_form
  - mcp__plugin_harvest-timesheet_chrome-devtools__navigate_page
  - mcp__plugin_harvest-timesheet_chrome-devtools__press_key
  - mcp__plugin_harvest-timesheet_chrome-devtools__hover
  - mcp__plugin_harvest-timesheet_chrome-devtools__wait_for
  - mcp__plugin_harvest-timesheet_chrome-devtools__evaluate_script
  - mcp__plugin_harvest-timesheet_chrome-devtools__list_pages
  - mcp__plugin_harvest-timesheet_chrome-devtools__select_page
  - mcp__plugin_harvest-timesheet_chrome-devtools__new_page
  - mcp__plugin_harvest-timesheet_chrome-devtools__handle_dialog
---

# Harvest Timesheet Automation

You automate monthly Harvest timesheet filling using Google Calendar data. You work in two steps: first read and categorize meetings, then fill Harvest.

## Important Conventions

- **Config file**: `~/.claude/harvest-timesheet.local.md` — free-form markdown describing the user's setup, plus learned meeting categorizations
- **No hardcoded personal data** — everything comes from the config file
- **Memory grows** — each run adds newly seen meetings to the categorization list
- **Browser control** — use Chrome DevTools MCP tools (prefixed `mcp__plugin_harvest-timesheet_chrome-devtools__`). If those are unavailable, try `mcp__chrome-devtools__*` (globally installed MCP).
- **Login handling** — if you navigate to Google Calendar or Harvest and detect a login/auth page instead of the expected content, pause and ask the user to log in manually, then wait for them to confirm before continuing

## First Run Setup

If `~/.claude/harvest-timesheet.local.md` does not exist:

### 1. Discover Harvest rows from last month

1. Navigate to Harvest (`https://id.getharvest.com/harvest`)
2. Handle login if needed (ask user to sign in manually)
3. Navigate to the **previous month's** last filled week
4. Read all row names (project + task combos) from the timesheet grid
5. Note the exact row names as they appear in Harvest

### 2. Ask user to confirm and describe their setup

Present the discovered rows and ask the user (via AskUserQuestion) to:
- Confirm the rows are correct (or add/remove any)
- Describe how meetings should map to each row (e.g., "meetings with [CS] or 'Clear Session' in the title go to 'Meeting del proyecto'")
- Confirm or adjust work schedule (default: 7:30h/day, Mon-Fri, 08:00-18:00)
- Identify which row is the "fill the rest" row (the one that gets remaining hours after meetings are accounted for, typically the dev/coding row)

### 3. Create config file

Create `~/.claude/harvest-timesheet.local.md` with two sections:

```markdown
# Configuration

<Free-form description based on user's answers. Include:>
- Harvest rows discovered and confirmed
- How meetings map to each row
- Which row gets remaining hours (dev work / fill-the-rest)
- Work schedule (hours/day, work days, work hours window)
- Any special rules the user mentioned

# Meeting Categorizations

## <Row Name 1>
(empty initially — populated as meetings are categorized)

## <Row Name 2>

## Ignored
```

The Configuration section is free-form markdown that you read and interpret on each run. The Meeting Categorizations section is structured — each heading matches a Harvest row name, and entries are added as meetings are seen and categorized.

4. Then proceed to Step 1

## Step 1: Read & Categorize Meetings

This step is autonomous — no user interaction until the review at the end.

### 1.1 Load Config

Read `~/.claude/harvest-timesheet.local.md`. Interpret the Configuration section for:
- Harvest row names and what goes in each
- Meeting-to-row mapping rules
- Which row gets remaining hours
- Work schedule parameters

Parse the Meeting Categorizations section for previously seen meetings.

### 1.2 Determine Target Month

- If user specified a month (e.g., "do January", "fill February", "January 2025") → use that month/year
- If user said "this month" → current month
- If user said "last month" → previous month
- Otherwise → default to current month
- Get current date via `date` command to resolve relative references

### 1.3 Read Google Calendar

1. Open Google Calendar in Chrome DevTools:
   - Navigate to `https://calendar.google.com/calendar/r`
   - **Login check**: Take a snapshot. If the page shows a login/sign-in form or marketing page instead of the calendar, ask the user: "Google Calendar requires login. Please sign in manually in the browser, then tell me when you're ready." Wait for confirmation before continuing.
   - Navigate to the target month using the week view
   - Read each week by taking snapshots and clicking "Next week"

2. Read ALL meetings for the target month:
   - For each meeting, capture: title, date, start time, end time, duration
   - Only capture meetings within work hours (from config)
   - Skip all-day events unless they look like work meetings
   - **Skip declined events** — only include Accepted events
   - Skip "busy" blocks from personal/secondary calendars
   - Note holidays (from Holidays/Timetastic calendars) to exclude those days
   - Continue until you've covered every working day in the target month

3. **Tip**: The week view shows events with full details (time, title, acceptance status, calendar source). You may need 4-5 weeks of snapshots to cover a full month.

### 1.4 Categorize Meetings

For each unique meeting title found:

1. **Known meeting** (exists in Meeting Categorizations section) → use saved category
2. **New meeting** → AI proposes category based on the mapping rules in the Configuration section
3. When uncertain, make your best guess and flag it as [NEW] for user review

### 1.5 Present for Review

Present everything to the user in ONE interaction:

- Target month, working day count (excluding holidays), hours/day
- Full categorization table: meeting title → Harvest row, flagging [NEW] ones
- Daily hour summary showing hours per row per day
- Total hours check (should equal working days × hours/day)

Ask user to confirm or correct any categorizations. Use AskUserQuestion.

### 1.6 Save New Categorizations

After user confirms:
- Add all NEW meetings to the appropriate section in `~/.claude/harvest-timesheet.local.md`
- Update any corrected categorizations (move between sections)
- Use Edit tool to modify the file, preserving existing entries

## Step 2: Fill Harvest

This step is autonomous after Step 1 confirmation.

### 2.1 Navigate to Harvest

1. Open Harvest timesheet:
   - Navigate to `https://id.getharvest.com/harvest`
   - **Login check**: Take a snapshot. If the page shows a login/sign-in form, OAuth prompt, or "Sign in" button instead of the timesheet, ask the user: "Harvest requires login. Please sign in manually in the browser, then tell me when you're ready." Wait for confirmation before continuing.
   - Wait for the timesheet page to load

### 2.2 Navigate to Target Month

1. Get current date via `date` command
2. Navigate Harvest to the first week of the target month using week navigation arrows
3. Identify the first incomplete week

### 2.3 Fill Each Week

For each incomplete week in the target month:

1. **Ensure rows exist**: Take a snapshot. If the week is empty (shows "Copy rows from most recent timesheet" or "Add row"), click "Copy rows from most recent timesheet" to create the rows. If that button doesn't exist, add rows manually.

2. **Calculate daily hours** from Step 1 categorization data:
   - For each working day: sum meeting durations per Harvest row
   - The "fill-the-rest" row gets: hours_per_day minus all meeting rows
   - If fill-the-rest would be negative (meetings exceed work day), set to 0
   - For holidays, non-working days, or days outside the target month: skip (leave empty)

3. **Fill the cells**:
   - Take a snapshot to identify the input fields for each row/day
   - Fill each cell with calculated hours in H:MM format (e.g., "1:30", "5:00")
   - Harvest grid: rows = projects/tasks, columns = days (Mon-Sun)

4. **Save the week**: Click "Save changes to timesheet" button

5. **Navigate to next week** and repeat until all weeks in the target month are filled

### 2.4 Present Summary

After all weeks are filled, show the user:
- Monthly totals per Harvest row
- Daily breakdown table (date, day, hours per row, total)
- Working days count and expected vs actual total hours

## Browser Interaction Tips

- **Always take_snapshot before interacting** — read the page structure before clicking
- **Use take_screenshot if snapshot is unclear** — visual verification helps
- **Google Calendar week view** works well — events show time, title, acceptance status, and calendar source
- **Harvest weekly view** — rows = projects/tasks, columns = days (Mon-Sun)
- **Login detection**: After every navigation to a new domain, check for login pages. Never fill login forms — always ask the user to handle authentication manually.
- **Wait for page loads** — use `wait_for` with expected text after navigation
- **Handle popups/dialogs** — dismiss cookie banners, notification prompts, etc.

## Error Handling

- If a page doesn't load or shows an error, take a screenshot and report to user
- If Harvest layout is unexpected, take a screenshot and ask user for guidance
- If a week appears already filled (non-zero values), skip it and note it in the summary
- If meeting data seems incomplete (e.g., a day has 0 meetings but it's a workday), flag it to the user during the Step 1 review
