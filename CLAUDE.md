# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `./setup.sh` - Main setup script that syncs configurations to your home directory
  - Performs git pull to fetch latest changes
  - Copies shell/, git/, and claude/ directories to $HOME using rsync
  - Returns to original directory after completion
- `git pull origin main` - Update the repository with latest changes before running setup

## Repository Structure

### Configuration Directories
- `shell/` - Shell configuration files (bash, zsh, readline, screen, psql)
  - `.bash_profile` - Bash login shell configuration
  - `.bash_prompt` - Custom bash prompt configuration  
  - `.zshrc` - Z shell configuration
  - `.zprofile` - Z shell profile configuration
  - `.inputrc` - Readline library configuration
  - `.screenrc` - GNU Screen configuration
  - `.psqlrc` - PostgreSQL client configuration
  - `.pg_format` - PostgreSQL formatter configuration
- `git/` - Git configuration files
  - `.gitconfig` - Global git configuration
  - `.gitignore` - Global gitignore rules
- `claude/` - Claude Code configuration files
  - `.claude/settings.json` - User-level Claude Code settings

### Scripts
- `setup.sh` - Installation script with safety features and error handling
  - Uses `set -euo pipefail` for robust execution
  - Provides contextual error messages with emoji indicators
  - Preserves working directory context

## Architecture

This is a dotfiles management repository that:
1. Centralizes shell and git configurations in version control
2. Uses rsync for efficient, permission-preserving file synchronization
3. Implements defensive scripting practices to prevent common errors
4. Provides clear feedback during installation process

The setup process is idempotent - running it multiple times is safe and will update configurations to the latest version.

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
