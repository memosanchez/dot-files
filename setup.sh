#!/usr/bin/env bash

# set -e: Exit immediately if a command exits with non-zero status
# set -u: Treat unset variables as an error
# set -o pipefail: Return value of a pipeline is the value of the last command to exit with non-zero status
set -euo pipefail

# Store the current directory and script directory
current_directory="$(pwd)"

# dirname: Extracts the directory part of a pathname
# BASH_SOURCE[0]: Array containing source filename of the current script
# ${...}: Parameter expansion syntax
script_directory="$(dirname "${BASH_SOURCE[0]}")"


# Check if script directory exists and perform git pull
if [ -d "$script_directory" ]; then
  cd "$script_directory" || { echo "❌ Oops! Couldn't access the script directory."; exit 1; }
  
  # Check for uncommitted changes
  if git status --porcelain | grep -q .; then
    echo "⚠️  Warning: You have uncommitted changes in this repository."
    read -p "   Continue anyway? (y/N) " -n 1 -r
    echo # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "❌ Setup cancelled. Please commit or stash your changes first."
      exit 1
    fi
  fi
  
  echo "🔄 Fetching the latest updates from the repository..."
  git pull origin main --quiet || { echo "❌ Git pull failed. Are you connected to the internet?"; exit 1; }
fi

echo "🐚 Copying shell configuration files to home directory..."
rsync -avq --no-perms shell/ "$HOME" || { echo "❌ Shell configuration sync failed. Check permissions?"; exit 1; }
# rsync: Remote sync tool for copying files
# -a: Archive mode (equivalent to -rlptgoD) - preserves almost everything
#     -r: Recursive (include subdirectories)
#     -l: Copy symlinks as symlinks
#     -p: Preserve permissions
#     -t: Preserve modification times
#     -g: Preserve group
#     -o: Preserve owner
#     -D: Preserve device files and special files
# -v: Verbose output
# -q: Quiet mode (suppresses non-error messages)
# --no-perms: Don't preserve permissions

echo "🔧 Setting up git configuration files..."
rsync -avq --no-perms git/ "$HOME" || { echo "❌ Git configuration sync failed. Check permissions?"; exit 1; }

echo "🤖 Setting up Claude configuration..."
rsync -avq --no-perms claude/ "$HOME" || { echo "❌ Claude configuration sync failed. Check permissions?"; exit 1; }

# Return to the original directory
cd "$current_directory" || { echo "❌ Couldn't return to where you started."; exit 1; }

echo "✅ Done."
