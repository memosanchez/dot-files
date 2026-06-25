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

# Create timestamped backup directory
backup_directory="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_directory"
echo "📦 Creating backup at: $backup_directory"


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

# Install Homebrew and packages
## Check if Homebrew is installed, install if missing
if ! command -v brew &>/dev/null; then
  echo "🍺 Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "❌ Homebrew installation failed. Check your internet connection and try again."
    exit 1
  }
  # Make brew available in the current shell session
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "✅ Homebrew installed successfully."
fi

## Install packages from Brewfile
if command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew packages from Brewfile..."
  brew bundle --file="${script_directory}/Brewfile" || {
    echo "❌ Homebrew package installation failed. Try running 'brew doctor' for diagnostics."
    exit 1
  }
else
  echo "⚠️  Homebrew is not available. Skipping package installation."
  echo "   Install manually: https://brew.sh"
fi

echo "🐚 Copying shell configuration files to home directory..."
rsync -avq --no-perms --backup --backup-dir="$backup_directory/shell" shell/ "$HOME" || { echo "❌ Shell configuration sync failed. Check permissions?"; exit 1; }
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
# --backup: Create backups of files that would be overwritten
# --backup-dir: Specify where to store backup files

echo "🔧 Setting up git configuration files..."
rsync -avq --no-perms --backup --backup-dir="$backup_directory/git" git/ "$HOME" || { echo "❌ Git configuration sync failed. Check permissions?"; exit 1; }

echo "🔏 Configuring local commit-signature verification..."
# Build ~/.config/git/allowed_signers from THIS machine's SSH signing key and
# the committer emails you sign as, then point git at it via ~/.gitconfig.local.
# Makes `git verify-commit` work and silences the recurring
# "gpg.ssh.allowedSignersFile needs to be configured" noise. Everything here is
# machine-local: the signing key differs per machine, so none of it is tracked
# in this repo. Idempotent, and skips quietly if signing is not set up yet.
# Background: docs/git-ssh-signing.md
configure_signing_verification() {
  local signingkey key personal work email
  local allowed="$HOME/.config/git/allowed_signers"
  local emails=()

  signingkey="$(git config --get user.signingkey 2>/dev/null || true)"
  if [ -z "$signingkey" ]; then
    echo "   ℹ️  Skipped: user.signingkey is not set (configure it in ~/.gitconfig.local)."
    return 0
  fi
  signingkey="${signingkey/#\~/$HOME}"   # expand a leading ~
  if [ ! -f "$signingkey" ]; then
    echo "   ℹ️  Skipped: signing key not found at $signingkey."
    return 0
  fi
  key="$(cut -d' ' -f1-2 "$signingkey")" # "ssh-ed25519 AAAA..." without the comment

  # Each identity you commit as. Work first when present, so `git verify-commit`
  # displays it (git shows the first principal that maps to the key).
  if [ -f "$HOME/.gitconfig-brillian" ]; then
    work="$(git config -f "$HOME/.gitconfig-brillian" user.email 2>/dev/null || true)"
    [ -n "$work" ] && emails+=("$work")
  fi
  personal="$(git config --global user.email 2>/dev/null || true)"
  [ -n "$personal" ] && emails+=("$personal")
  if [ "${#emails[@]}" -eq 0 ]; then
    echo "   ℹ️  Skipped: no committer email configured."
    return 0
  fi

  mkdir -p "$HOME/.config/git"
  : > "$allowed"
  for email in "${emails[@]}"; do
    printf '%s %s\n' "$email" "$key" >> "$allowed"
  done
  git config -f "$HOME/.gitconfig.local" gpg.ssh.allowedSignersFile '~/.config/git/allowed_signers'
  echo "   ✅ Wrote $allowed and set gpg.ssh.allowedSignersFile."
}
configure_signing_verification || echo "   ⚠️  Commit-signature verification setup skipped (non-fatal)."

echo "🤖 Setting up Claude configuration..."
mkdir -p "$HOME/.claude" || { echo "❌ Failed to create .claude directory. Check permissions?"; exit 1; }

# Sync everything except skills/ — skills are organized into category folders
# in the repo (claude/skills/<category>/<skill>/SKILL.md) but Claude Code
# expects them flat (~/.claude/skills/<skill>/SKILL.md), so they need a
# separate flattening pass below.
rsync -avq --no-perms --backup --backup-dir="$backup_directory/claude" \
  --exclude='skills' \
  claude/ "$HOME/.claude" || { echo "❌ Claude configuration sync failed. Check permissions?"; exit 1; }

# Flatten skills: claude/skills/<category>/<skill>/ → ~/.claude/skills/<skill>/
if [ -d "claude/skills" ]; then
  # Bail if any SKILL.md is sitting flat (not inside a category folder)
  loose_skills="$(find claude/skills -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null)"
  if [ -n "$loose_skills" ]; then
    echo "❌ Found SKILL.md files outside a category folder:"
    echo "$loose_skills" | sed 's/^/   /'
    echo "   Move each into claude/skills/<category>/<skill-name>/SKILL.md"
    exit 1
  fi

  # Bail if two categories define the same skill name (would silently clobber)
  duplicates="$(find claude/skills -mindepth 2 -maxdepth 2 -type d 2>/dev/null | xargs -n1 basename 2>/dev/null | sort | uniq -d)"
  if [ -n "$duplicates" ]; then
    echo "❌ Duplicate skill names across categories:"
    echo "$duplicates" | sed 's/^/   - /'
    echo "   Each skill name must be unique across all category folders."
    exit 1
  fi

  mkdir -p "$HOME/.claude/skills"
  for category_dir in claude/skills/*/; do
    [ -d "$category_dir" ] || continue
    rsync -avq --no-perms --backup --backup-dir="$backup_directory/claude/skills" \
      "$category_dir" "$HOME/.claude/skills/" || { echo "❌ Skills sync failed. Check permissions?"; exit 1; }
  done
fi

# Return to the original directory
cd "$current_directory" || { echo "❌ Couldn't return to where you started."; exit 1; }

# Check if any files were backed up
if [ -d "$backup_directory" ] && [ "$(find "$backup_directory" -type f 2>/dev/null | head -1)" ]; then
  echo "💾 Backed up existing files to: $backup_directory"
  echo "   To restore: cp -r $backup_directory/* $HOME/"
fi

echo "✅ Done."
