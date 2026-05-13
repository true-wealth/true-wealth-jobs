# True Wealth — Jobs Repo

This repo lists open positions at True Wealth AG and lets candidates apply directly
from the terminal using Claude Code.

## On startup

1. Run `git pull` to fetch the latest open positions. If the pull fails (no network,
   detached HEAD, etc.), warn the user that the listing may be stale and continue.

2. Glob `skills/*/job_description.md`. For each file found, read the first `#` heading
   to get the position title.

3. Present the open positions as a numbered list and ask the user which one they are
   interested in.

4. Once the user selects a position, follow the instructions in the corresponding
   `skills/<dir>/SKILL.md` to run the application flow for that position.

## If no positions are found

Tell the user that there are no open positions at the moment and refer them to
`jobs@truewealth.ch` for future opportunities.
