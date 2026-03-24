# Claude Code Configuration

This directory contains Claude Code configuration files that are synced to `~/.claude/` by the `setup.sh` script.

**Created:** 2025-10-01
**Last Modified:** 2026-03-24

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
`effortLevel` is set to `"max"` for deepest reasoning on Opus 4.6. Other values: `"low"`, `"medium"`, `"high"`, `"auto"`.

#### Permissions
- **allow**: Commands that Claude can execute without asking for approval
  - Package manager commands (npm, pnpm, yarn lint/test/build/typecheck)
  - GitHub CLI read commands (pr, issue, repo, run operations)
  - Read-only git commands (status, log, diff, show, branch, remote, tag -l, stash list)
  - Read-only Homebrew commands (list, info, search, config, doctor)
  - Shell utilities (ls, diff, wc, which, jq)
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
Enabled plugins from the official marketplace:
- **GitHub** — PR reviews, issue management, repo operations (requires `GITHUB_PERSONAL_ACCESS_TOKEN`)
- **Linear** — issue tracking, project management (uses OAuth)
- **Playwright** — browser automation, testing, screenshots

#### Status Line
Custom status line displaying model name and context window usage:
- Model name with color coding: Sonnet (cyan), Opus (magenta), Haiku (green)
- Context window usage percentage with color coding: green (< 60%), yellow (60-79%), red (80%+)

#### Environment Variables
The `env` object can be used to set environment variables for Claude Code sessions.

#### Co-authorship
`attribution.commit` and `attribution.pr` control commit/PR attribution templates.

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

## Directory Structure

```
claude/
├── README.md         # This file
├── CLAUDE.md         # Global instructions for Claude Code
├── settings.json     # Global user settings
└── commands/         # Custom slash commands (add your own)
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
