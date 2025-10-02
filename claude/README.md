# Claude Code Configuration

This directory contains Claude Code configuration files that are synced to `~/.claude/` by the `setup.sh` script.

**Created:** 2025-10-01
**Last Modified:** 2025-10-01

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

#### Permissions
- **allow**: Commands that Claude can execute without asking for approval
  - Package manager commands (npm, pnpm, yarn lint/test/build/typecheck)
  - GitHub CLI commands (pr, issue, repo, run operations)
  - Read-only git commands (status, log, diff, show, branch, remote)
  - Common shell utilities (find, ls, diff, grep, cat, head, tail, wc, which)
  - Version checks (python, node, npm)
  - Docker read operations (ps, images, logs)
  - WebFetch for documentation sites (anthropic, github, stackoverflow, MDN)

- **deny**: Dangerous commands that are explicitly blocked
  - Destructive file operations (`rm -rf`, `dd`, `mkfs`)
  - Force git operations (`push --force`, `reset --hard`)
  - Dangerous permission changes (`chmod -R 777`)

#### Status Line
Custom status line configuration that displays the current model (Sonnet/Opus/Haiku) with color coding:
- Sonnet: Cyan (color 96)
- Opus: Magenta (color 95)
- Haiku: Green (color 92)
- Unknown: White (color 97)

#### Environment Variables
The `env` object can be used to set environment variables for Claude Code sessions.

#### Co-authorship
`includeCoAuthoredBy` is set to `false` by default. Set to `true` to include Claude as a co-author in git commits.

### `settings.local.json.example`
Template for project-specific settings. To use:

1. Copy to `.claude/settings.local.json` in any project directory
2. Customize permissions and environment variables for that project
3. Settings are merged with global settings (project settings take precedence)

**Note:** `settings.local.json` files should generally be gitignored to avoid committing local development preferences.

## Directory Structure

```
claude/
├── README.md                      # This file
├── CLAUDE.md                      # Global instructions for Claude Code
├── settings.json                  # Global user settings
├── settings.local.json.example    # Template for project-specific settings
└── commands/                      # Custom slash commands (optional)
    ├── review.md                  # Example: /review command
    └── test-plan.md               # Example: /test-plan command
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
1. Copy `settings.local.json.example` to your project's `.claude/` directory
2. Rename to `settings.local.json`
3. Customize as needed
4. Add to `.gitignore` if desired

#### Custom Slash Commands
Create markdown files in `claude/commands/`:
```bash
mkdir -p claude/commands
echo "Review this code for potential bugs and improvements" > claude/commands/review.md
```

Then use with `/review` in Claude Code sessions.

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
