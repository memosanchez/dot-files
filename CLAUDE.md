# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `./setup.sh` - Main setup script that syncs configurations to your home directory
  - Installs Homebrew if not present
  - Installs packages from Brewfile via `brew bundle`
  - Performs git pull to fetch latest changes
  - Syncs every directory in the sync manifest (shell/ → $HOME, git/ → $HOME,
    claude/ → ~/.claude) using rsync, backing up overwritten files to
    ~/.dotfiles-backup/<timestamp>/
  - Flattens claude/skills/<category>/<skill>/ to ~/.claude/skills/<skill>/
  - Configures SSH commit-signature verification via scripts/configure-signing.sh
    (machine-local; see README "Commit Signature Verification")
  - Returns to original directory after completion
- `./setup.sh --restore [timestamp]` - Restore a backup set over its destinations
  (no timestamp lists available backups; a restore backs up what it overwrites)
- `tests/configure-signing-test.sh` - Run the signing-configuration tests against
  fixture files (no real $HOME involved)
- `git pull origin main` - Update the repository with latest changes before running setup

## Repository Structure

### Configuration Directories
- `shell/` - Shell configuration files (zsh, readline, screen, psql)
  - `.zshrc` - Z shell configuration
  - `.zprofile` - Z shell profile configuration (Homebrew bootstrap)
  - `.hushlogin` - Silences the macOS login banner
  - `.inputrc` - Readline library configuration
  - `.screenrc` - GNU Screen configuration
  - `.psqlrc` - PostgreSQL client configuration
  - `.pg_format` - PostgreSQL formatter configuration
- `git/` - Git configuration files
  - `.gitconfig` - Global git configuration
  - `.gitignore` - Global gitignore rules
- `claude/` - Claude Code configuration files (see claude/README.md for details)
  - `CLAUDE.md` - User's private global instructions for all projects (copied to ~/.claude/CLAUDE.md)
  - `settings.json` - User-level Claude Code settings with permissions and statusLine (copied to ~/.claude/settings.json)
  - `README.md` - Documentation for Claude Code configuration
  - `commands/` - Custom slash commands
  - `skills/` - User-authored skills, grouped by category (e.g., `general/`, `engineering/`); setup.sh flattens to `~/.claude/skills/<skill>/SKILL.md` on sync

### Top-Level Files
- `Brewfile` - Homebrew package manifest (not synced to $HOME, used by setup.sh)
- `CONTEXT.md` - Domain glossary (sync manifest, backup set, restore, skill flattening)
- `docs/adr/` - Architecture decision records

### Scripts
- `setup.sh` - Installation script with safety features and error handling
  - Uses `set -euo pipefail` for robust execution
  - Driven by a sync manifest: one "<repo-dir>:<destination>" entry per synced
    directory; the sync loop, backup layout, and --restore all derive from it
  - Provides contextual error messages with emoji indicators
  - Preserves working directory context
- `scripts/configure-signing.sh` - Commit-signature verification setup; takes every
  path as an explicit argument so it can be tested against fixtures
- `tests/configure-signing-test.sh` - Fixture-based tests for the signing script

## Architecture

This is a dotfiles management repository that:
1. Centralizes shell and git configurations in version control
2. Uses rsync with per-run backups for file synchronization (permissions are
   left to the local umask via `--no-perms`)
3. Implements defensive scripting practices to prevent common errors
4. Provides clear feedback during installation process
5. Manages Homebrew package dependencies via Brewfile

The setup process is idempotent - running it multiple times is safe and will
update configurations to the latest version. Sync never deletes: removing a
file from the repo leaves the copy already in $HOME in place.

See `CONTEXT.md` for the domain glossary and `docs/adr/` for recorded
decisions (notably: no sandbox seam in setup.sh - backups are the safety net).

## Coding Conventions

- Shell scripts use bash shebang (`#!/usr/bin/env bash`)
- Use safety flags in scripts (`set -euo pipefail`)
- Add detailed comments for complex commands and functions
- Use meaningful variable names (e.g., `current_directory`, `script_directory`)
- Include emoji indicators in console output (🔄, 🐚, 🔧, ✅, ❌)
- Provide helpful error messages with possible solutions
- Use rsync with `-avq --no-perms` flags for file copying
- Implement defensive coding with proper exit handling
- Maintain original context (return to starting directory)
- Use proper parameter expansion with quotes (`"${var}"`)
