# Issue tracker: Linear

Issues and specs for this repo live in Linear. Use the Linear MCP plugin tools for all operations.

**Team:** _<fill in — the Linear team this repo's issues belong to>_
**Project:** _<fill in, or "none" — the default Linear project for this repo's issues>_

If the team or project above is not filled in and the user hasn't said which to use, ask before creating anything — don't guess.

## Conventions

- **Create an issue**: `save_issue` with `title`, `team`, and a Markdown `description` (no `id` — that would update). Set `project` when the repo has a default project.
- **Read an issue**: `get_issue` with the identifier (e.g. `ENG-123`), plus `list_comments` for the discussion.
- **List issues**: `list_issues` filtered by `team`/`project`/`label`/`state` as appropriate.
- **Comment on an issue**: `save_comment` with the issue identifier.
- **Apply / remove labels**: `save_issue` with `labels`. The `labels` array **replaces** the full label set — include the labels you want to keep, not only the new ones. Only apply labels that already exist on the team (`list_issue_labels`) — don't invent new ones unless the user asks.
- **Close**: `save_issue` with `state` set to the appropriate workflow state (`Done` for completed, `Canceled` for wontfix).
- **Statuses vs labels**: Linear has workflow states (Triage, Backlog, Todo, In Progress, Done, Canceled) *and* labels. Triage roles map to labels by default (see `triage-labels.md`), but `needs-triage` may map to Linear's built-in Triage status on teams that have it enabled — record the mapping there.

## Pull requests as a triage surface

Not applicable. PRs live on the git host, not in Linear, so `/triage` covers Linear issues only. If this repo also treats external PRs as a request surface, describe that workflow here as freeform prose.

## When a skill says "publish to the issue tracker"

Create a Linear issue with `save_issue` in the team (and project) above.

## When a skill says "fetch the relevant ticket"

Run `get_issue` with the identifier, then `list_comments` for the discussion.

## Blocking relationships

Linear has native blocking relations — use them instead of "Blocked by" text lines:

- **Add an edge**: `save_issue` with `blockedBy` (issue identifiers that gate this one) or `blocks`. Both are append-only.
- **Remove an edge**: `save_issue` with `removeBlockedBy` / `removeBlocks`.
- **Sub-issues**: `save_issue` with `parentId` for parent/child structure.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: an issue created with `parentId` set to the map. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: native relations via `blockedBy` (see above). A ticket is unblocked when every blocker is closed.
- **Frontier query**: `list_issues` with `parentId` set to the map and `state` open, drop any with an open blocker (check relations via `get_issue`) or an assignee; first in map order wins.
- **Claim**: `save_issue` with `assignee: "me"` — the session's first write.
- **Resolve**: `save_comment` with the answer, `save_issue` with `state: Done`, then append a context pointer to the map's Decisions-so-far.
