# Skills from mattpocock/skills are vendored as an editable fork

Since v1.2.0, mattpocock/skills ships as a read-only Claude Code marketplace
plugin that auto-updates. We stay on vendored copies in `claude/skills/`
instead (decided 2026-08-06): this repo carries purposeful local edits the
plugin cannot hold — Linear issue-tracker support (`issue-tracker-linear.md`
and its wiring in `setup-skills`), the `setup-matt-pocock-skills` →
`setup-skills` rename and de-branding (every pointer to it included), and
`two-axis-review`, a rename-fork of upstream's `code-review` with narrowed
triggers that avoids colliding with Claude Code's built-in command (every
caller re-pointed at it).
The cost is a manual upstream sync per release: a three-way merge against
the upstream version last synced from, re-applying the local edits above.
Blob-matching files against upstream git history separates local edits from
staleness. Codex metadata (`agents/` dirs) is stripped on vendoring; the
`ask-matt` router, the `misc/` and `in-progress/` buckets, and `pr`
(replaced by our own, 2026-10-06) are deliberately not vendored.
A replaced skill still gets a look on every sync: diff upstream's `pr`
against the release last reviewed (v1.3.1, the version ours replaced), and
when it changed, summarise the changes and ask the user which, if any, to
fold into ours; then record the new release here as last reviewed. The
other skips stay silent.
