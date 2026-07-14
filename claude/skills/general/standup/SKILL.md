---
name: standup
description: Generate a copy-pasteable Slack standup message from the user's GitHub activity in Brillian repos (brillianco org) on the previous working day. Use when the user asks for a standup, daily standup, Slack standup, or daily update.
---

# Slack Standup

Build a Slack standup message from the user's GitHub activity. Brillian work
only: never include anything outside the `brillianco` GitHub org.

## Workflow

1. **Find the target day.** The previous working day, based on today's date
   from the environment context. On Monday the target day is Friday (include
   weekend activity too if there is any).

2. **Collect GitHub activity** with the `gh` CLI, scoped to `brillianco`
   (replace `<DAY>` with the target day as `YYYY-MM-DD`):

   ```bash
   # PRs merged on the target day
   gh search prs --author=@me --owner=brillianco --merged --merged-at=<DAY> \
     --json number,title,url,repository

   # All of the user's open PRs
   gh search prs --author=@me --owner=brillianco --state=open \
     --json number,title,url,repository,createdAt,updatedAt
   ```

3. **Sort each open PR into a bucket:**
   - **Opened on the target day**: goes in the first section as a bullet
     describing the work.
   - **Opened earlier, with activity on the target day** (`updatedAt` on or
     after the target day): check what happened with
     `gh pr view <N> --repo brillianco/<repo> --json commits,comments,reviews`.
     If the user pushed commits or replied on the target day, add a first
     section bullet about addressing feedback, e.g.
     `* Addressed review feedback on the financial performance step move :github-pr:[#254](<pr-url>)`
   - **Opened earlier, no activity from anyone on the target day**
     (`updatedAt` before the target day): it is stuck waiting on review.
     Add a Blockers entry: `* Approval on :github-pr:[#<number>](<pr-url>)`

4. **Write the first section.** One bullet per merged or active PR from
   steps 2 and 3. Keep each bullet short: a phrase of roughly 12 words or
   fewer that leads with what changed, based on the PR title and description.
   Add a brief why only when it fits inside that same short phrase, otherwise
   leave it out. Do not restate the PR title verbatim or pad with context the
   reader does not need. End each bullet with the PR link in this exact form:
   `:github-pr:[#<number>](<pr-url>)`.

5. **Write the Today section.**
   - If any of the user's PRs in the message are still open, start with
     `* Merge these in :crossed_fingers:`. Under it, add one sub-bullet per
     open PR that has a matching Linear ticket, as a link plus a short
     phrase: `    * [BRI-475](https://linear.app/brillian/issue/BRI-475) always-clickable Save button`.
     Match PRs to tickets by the issue identifier in the PR branch name
     (`gh pr view <N> --repo brillianco/<repo> --json headRefName`). A PR
     with no ticket in its branch name gets no sub-bullet.
   - The user's other started Linear issues (use the Linear tools, filtered
     to assignee = user, state started) that have no matching open PR each
     get their own top-level bullet: ticket link plus its title or a short
     phrase. Linear state can be stale, so first check whether the ticket's
     branch already merged
     (`gh pr list --repo brillianco/<repo> --state merged --head <gitBranchName>`).
     If it did, leave the ticket out and tell the user, outside the standup
     message, that it looks shipped and probably needs closing.
   - Always end with `* Pull from Backlog`.

6. **Write the Blockers section.** Stale PRs from step 3 appear as
   `Approval on` entries. Add anything the user explicitly mentions, e.g.
   `Alignment on BRI-460 (Welcome screen)`. If there is nothing, write `None`.

7. **Output** the finished message in a fenced code block so it can be
   copied into Slack as-is. Never post it anywhere; output in chat only.

## Format rules

- Section headers on their own line: `Yesterday:`, `Today:`, `Blockers:`.
  Use `Previously:` instead of `Yesterday:` when the covered day is not
  literally yesterday (e.g. a Monday standup covering Friday).
- Bullets use `* `. Sub-bullets are indented four spaces. One short phrase
  each, roughly 12 words or fewer. Lead with the change. Plain everyday
  words, no semicolons, no em dashes.
- Linear tickets are always links: `[BRI-424](https://linear.app/brillian/issue/BRI-424)`.
- `:github-pr:` and `:crossed_fingers:` are Slack emoji codes; keep them as
  literal text.

## Example output

```
Yesterday:
* Required QBO data, not just a connection, for the Financials step :github-pr:[#243](https://github.com/brillianco/bn-frontend/pull/243)
* Added an onboarding error boundary for faster step recovery :github-pr:[#244](https://github.com/brillianco/bn-frontend/pull/244)
* Addressed review feedback on the Save & Continue fix :github-pr:[#245](https://github.com/brillianco/bn-frontend/pull/245)

Today:
* Merge these in :crossed_fingers:
    * [BRI-441](https://linear.app/brillian/issue/BRI-441) QBO data required for the Financials step
* [BRI-460](https://linear.app/brillian/issue/BRI-460) Add welcome screen to onboarding flow
* Pull from Backlog

Blockers:
* Approval on :github-pr:[#240](https://github.com/brillianco/bn-frontend/pull/240)
```
