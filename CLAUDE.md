# CLAUDE.md - Dot-Files Repository Guide

## Commands

- `./setup.sh` - Main setup script that syncs configurations to your home directory
- `git pull origin master` - Update the repository with latest changes

## Repository Structure

- `shell/` - Contains shell configuration files that get copied to $HOME
- `git/` - Contains git configuration files that get copied to $HOME
- `setup.sh` - Main script for installation and updates

## Coding Conventions

- Shell scripts should use bash (`#!/usr/bin/env bash`)
- Add descriptive comments for complex commands
- Use meaningful variable names (e.g., `current_directory`, `script_directory`)
- Add emoji indicators in console output messages for visual cues
- Include detailed error messages that suggest possible solutions
