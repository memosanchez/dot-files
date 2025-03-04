# CLAUDE.md - Dot-Files Repository Guide

## Commands

- `./setup.sh` - Main setup script that syncs configurations to your home directory
- `git pull origin main` - Update the repository with latest changes

## Repository Structure

- `shell/` - Contains shell configuration files that get copied to $HOME
- `git/` - Contains git configuration files that get copied to $HOME
- `setup.sh` - Main script for installation and updates

## Coding Conventions

- Shell scripts use bash shebang (`#!/usr/bin/env bash`)
- Use safety flags in scripts (`set -euo pipefail`)
- Add detailed comments for complex commands and functions
- Use meaningful variable names (e.g., `current_directory`, `script_directory`)
- Include emoji indicators in console output (🔄, 🐚, 🔧, ✅, ❌)
- Provide helpful error messages with possible solutions
- Use rsync for copying files with appropriate flags
- Implement defensive coding with proper exit handling
- Maintain original context (return to starting directory)
- Use proper parameter expansion with quotes (${var})
