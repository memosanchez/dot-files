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

## Architecture

This is a dotfiles management repository that:
1. Uses rsync with per-run backups for file synchronization (permissions are
   left to the local umask via `--no-perms`)
2. Drives the sync from a manifest in setup.sh: one "<repo-dir>:<destination>"
   entry per synced directory; the sync loop, backup layout, and --restore all
   derive from it
3. Keeps `Brewfile` out of the sync manifest - it is only consumed by
   setup.sh, never copied to $HOME
4. Passes every path into `scripts/configure-signing.sh` as an explicit
   argument so the script can be tested against fixtures

The setup process is idempotent - running it multiple times is safe and will
update configurations to the latest version. Sync never deletes: removing a
file from the repo leaves the copy already in $HOME in place.

See `CONTEXT.md` for the domain glossary and `docs/adr/` for recorded
decisions (notably: no sandbox seam in setup.sh - backups are the safety net).

## Coding Conventions

- Include emoji indicators in console output (🔄, 🐚, 🔧, ✅, ❌)
- Use rsync with `-avq --no-perms` flags for file copying
- Maintain original context (return to starting directory)
