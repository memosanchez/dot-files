# Claude Code Configuration

This directory contains Claude Code configuration files that are synced to `~/.claude/` by the `setup.sh` script.

**Created:** 2025-10-01
**Last Modified:** 2026-07-13

## Files

### `CLAUDE.md`
User's private global instructions for all projects. This file provides Claude Code with:
- Code style guidelines for multiple languages (TypeScript, JavaScript, Python, Shell)
- Git commit message and PR formatting standards
- Testing philosophy and best practices
- Code review guidelines
- Documentation standards
- Error handling principles
- Security best practices

This file is copied to `~/.claude/CLAUDE.md` and applies to all Claude Code sessions.

### `settings.json`
Global user-level settings for Claude Code. Includes:

#### Effort Level
`effortLevel` is set to `"xhigh"` for deepest persistent reasoning. Valid values per the docs: `"low"`, `"medium"`, `"high"`, `"xhigh"`. The session-only `/effort max` command is *not* a valid settings value — it gets silently dropped if used in JSON. See https://code.claude.com/docs/en/settings.

#### Auto Updates
`autoUpdatesChannel` is set to `"stable"` to pin to the stable release channel (~1 week behind `"latest"`) for fewer surprise regressions. There is no documented `autoUpdates: false` toggle — `autoUpdatesChannel` is the only update control.

#### MCP Servers
`enableAllProjectMcpServers` is set to `false` explicitly. This blocks any project's `.mcp.json` from auto-activating MCP servers without manual approval. Pair with `enabledMcpjsonServers` / `disabledMcpjsonServers` arrays for fine-grained control.

#### Permissions
- **defaultMode**: `"acceptEdits"` — auto-accepts `Read`/`Write`/`Edit` tool calls without prompting. Bash and other risky tools still prompt. Valid values: `"default"`, `"acceptEdits"`, `"plan"`, `"auto"`, `"dontAsk"`, `"bypassPermissions"`.

- **additionalDirectories**: `["~/.claude/"]` — lets Claude read your memory, plans, transcripts, and shell snapshots cross-session without per-prompt approval.

- **allow**: Commands that Claude can execute without asking for approval
  - Package manager commands (npm, pnpm, yarn lint/test/build/typecheck)
  - GitHub CLI read commands (pr, issue, repo, run operations, `gh api`)
  - Read-only git commands (status, log, diff, show, branch, remote, tag -l, stash list, fetch, ls-files, rev-parse)
  - Read-only Homebrew commands (list, info, search, config, doctor)
  - Read-only `mise` commands (current, ls, which)
  - Shell utilities (ls, diff, wc, which, jq, rg)
  - Version checks (python, node, npm)
  - Docker read operations (ps, images, logs)
  - WebFetch for documentation sites (anthropic, github, stackoverflow, MDN)

- **deny**: Dangerous commands that are explicitly blocked
  - Destructive file operations (`rm -rf`, `dd`, `mkfs`)
  - All `sudo` commands
  - Force git operations (`push --force`, `reset --hard`)
  - Destructive git operations (`checkout --`, `clean`)
  - Dangerous permission changes (`chmod -R 777`)
  - Sensitive file reads (`.env`, `.pem`, `.key`, secrets, credentials, `.aws`, `.ssh`)

#### Hooks
- **SessionStart (compact)**: Re-injects key reminders after auto-compaction to prevent Claude from forgetting preferences in long conversations

#### Plugins
All entries reference the `claude-plugins-official` marketplace.

Enabled:
- **context7** — fetch up-to-date library/framework documentation
- **frontend-design** — production-grade frontend component generation
- **linear** — Linear issue tracking and project management (OAuth)
- **playwright** — browser automation, testing, screenshots
- **typescript-lsp** — TypeScript language server integration
- **feature-dev** — guided feature development with codebase understanding
- **commit-commands** — git commit/push/PR helpers
- **terraform** — Terraform registry lookups and HCP workspace tools
- **elixir-ls-lsp** — Elixir language server integration

Explicitly disabled (kept in file for documentation):
- **vercel** — Vercel deploy / project management
- **posthog** — PostHog analytics integration

#### Status Line
Custom status line displaying model name and context window usage:
- Model name with color coding: Sonnet (cyan), Opus (magenta), Haiku (green)
- Context window usage percentage with color coding: green (< 60%), yellow (60-79%), red (80%+)

#### Environment Variables
The `env` object can be used to set environment variables for Claude Code sessions.

#### Co-authorship
`attribution.commit` and `attribution.pr` control commit/PR attribution templates. Both are empty strings here to suppress the `Co-Authored-By: Claude` trailer in commits and PR descriptions. The older `includeCoAuthoredBy` boolean is deprecated in current docs — use `attribution` instead.

### Project-Specific Settings
You can create `.claude/settings.local.json` in any project directory to override global settings:

```json
{
  "env": {"PROJECT_VAR": "value"},
  "permissions": {
    "allow": ["Bash(make:*)"]
  }
}
```

Settings are merged with global settings (project settings take precedence). Add to `.gitignore` to avoid committing local preferences.

### `skills/`
User-authored skills, organized in the repo by category but **flattened on sync** to `~/.claude/skills/<skill>/SKILL.md`. Claude Code only discovers skills one level deep, so categories exist purely for repo organization — `setup.sh` strips the category folder when copying.

Repo layout:
```
skills/
├── general/
│   └── branch-status/SKILL.md
└── engineering/
    └── pre-commit-check/SKILL.md
```

After `./setup.sh` runs:
```
~/.claude/skills/
├── branch-status/SKILL.md
└── pre-commit-check/SKILL.md
```

**Rules enforced by setup.sh:**
- Every SKILL.md must live inside a category folder (no `skills/<skill>/SKILL.md` at the top level — setup will bail).
- Skill names must be unique across categories (no two categories can both define `branch-status` — setup will bail).

A skill is a packaged set of instructions Claude can invoke — automatically (when a request matches the skill's `description` frontmatter) or manually via `/<skill-name>` (unless `disable-model-invocation: true` is set). See https://code.claude.com/docs/en/skills for the full authoring guide.

**Minimum SKILL.md shape:**
```markdown
---
description: One-line summary Claude uses to decide when this skill applies. Be specific about triggers.
---

# my-skill

Instructions for Claude go here as plain Markdown.
```

Most skills here track [Matt Pocock's skills repo](https://github.com/mattpocock/skills) (last synced 2026-07-08), with three local adaptations: the setup skill is de-branded to `setup-skills`, Linear is a first-class issue tracker option (`setup-skills/issue-tracker-linear.md`), and upstream's `code-review` is adopted as `two-axis-review` with narrowed triggers — its upstream name shadows Claude Code's built-in `/code-review` in the CLI (see mattpocock/skills#483). `confirm-findings` and `pre-commit-check` are original to this repo. Upstream's `research` skill is deliberately skipped — Claude Code ships deep-research built in.

Skills currently in this repo:

**general/**
- `grilling` — the shared interview discipline (model-invoked; the engine behind the grill-* skills)
- `grill-me` — run a `/grilling` session on a plan or design
- `handoff` — write a handoff document so a fresh agent can pick up the current conversation
- `setup-skills` — per-repo config the engineering skills read: issue tracker (Linear/GitHub/GitLab/local), triage labels, domain doc layout
- `teach` — multi-session teaching workspace (missions, lessons, learning records)
- `writing-great-skills` — reference for authoring predictable skills (with `GLOSSARY.md`)

**engineering/**
- `codebase-design` — shared deep-module vocabulary and principles (with `DEEPENING.md`, `DESIGN-IT-TWICE.md`)
- `confirm-findings` — re-verify a review's findings against actual file lines before acting on them
- `diagnosing-bugs` — disciplined diagnosis loop: feedback loop → reproduce + minimise → hypothesise → instrument → fix
- `domain-modeling` — build/sharpen the domain model; updates `CONTEXT.md` and ADRs inline
- `grill-with-docs` — grilling session that also maintains the domain docs
- `implement` — implement a spec or tickets via `/tdd` at pre-agreed seams
- `improve-codebase-architecture` — scan for deepening opportunities, present as an HTML report, grill through picks
- `pre-commit-check` — run lint/typecheck/test/build as a pre-commit gate (auto-detects package manager)
- `prototype` — throwaway prototype to answer a design question (logic TUI or UI variants)
- `tdd` — red → green loop with seams, anti-patterns, and loop rules
- `to-spec` — synthesize the conversation into a spec and publish to the configured tracker
- `to-tickets` — break a plan/spec into tracer-bullet tickets with native blocking edges
- `triage` — move issues (and external PRs) through a triage-role state machine
- `two-axis-review` — review a diff on two axes: Standards (repo standards + Fowler smells) and Spec (does it match the ticket?), in parallel sub-agents
- `wayfinder` — plan work too big for one session as a map of investigation tickets

To start a new skill, copy any of the above into the category folder that fits, then rename the directory and edit the frontmatter.

## Directory Structure

```
claude/
├── README.md         # This file
├── CLAUDE.md         # Global instructions for Claude Code
├── settings.json     # Global user settings
├── commands/         # Custom slash commands (add your own)
└── skills/           # User-authored skills, grouped by category
    ├── general/
    │   ├── grill-me/  grilling/  handoff/  setup-skills/
    │   └── teach/  writing-great-skills/
    └── engineering/
        ├── codebase-design/  confirm-findings/  diagnosing-bugs/
        ├── domain-modeling/  grill-with-docs/  implement/
        ├── improve-codebase-architecture/  pre-commit-check/  prototype/
        └── tdd/  to-spec/  to-tickets/  triage/  two-axis-review/  wayfinder/
```

## Usage

### Installation
Run the main setup script from the repository root:
```bash
./setup.sh
```

This will:
1. Pull latest changes from the repository
2. Sync `claude/` directory to `~/.claude/`
3. Create backups of any existing files

### Customization

#### Adding New Permissions
Edit `settings.json` and add to the `allow` or `deny` arrays:
```json
{
  "permissions": {
    "allow": [
      "Bash(your-command:*)"
    ]
  }
}
```

#### Creating Project-Specific Settings
1. Create `.claude/settings.local.json` in your project directory
2. Add your custom settings (permissions, env vars, etc.)
3. Add to `.gitignore` to keep it local

#### Custom Slash Commands
Create markdown files in `claude/commands/` to add custom commands:
```bash
mkdir -p claude/commands
echo "Your custom command prompt here" > claude/commands/my-command.md
```

Then use with `/my-command` in Claude Code sessions.

## Best Practices

1. **Version Control**: Keep `CLAUDE.md` and `settings.json` in version control to share preferences across machines
2. **Local Settings**: Use `settings.local.json` for machine-specific or project-specific overrides
3. **Permission Management**: Regularly review and update permissions as your workflow evolves
4. **Documentation**: Update this README when adding new configuration patterns
5. **Security**: Be cautious with `allow` permissions - prefer explicit over broad patterns

## Troubleshooting

### Settings Not Taking Effect
- Ensure you ran `./setup.sh` after making changes
- Check that files are in `~/.claude/` (not just the repo)
- Restart Claude Code session

### Permission Denied Errors
- Add the command to the `allow` list in `settings.json`
- Check that the pattern matches (use `*` wildcards appropriately)
- Remember that `Bash()` wraps command names

### Status Line Not Showing
- Verify `jq` is installed: `which jq`
- Check the command syntax in `settings.json`
- Look for shell errors in terminal output

## References

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Settings Reference](https://docs.anthropic.com/claude/docs/claude-code/settings)
- [Slash Commands Guide](https://docs.anthropic.com/claude/docs/claude-code/slash-commands)
