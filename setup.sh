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

# Sync manifest: one "<repo-dir>:<destination>" entry per synced directory.
# The sync loop, the backup layout, and --restore all derive from this list,
# so it is the single place to add or remove a synced directory. The repo dir
# name doubles as the backup subfolder name.
sync_manifest=(
  "shell:$HOME"
  "git:$HOME"
  "claude:$HOME/.claude"
)

backup_root="$HOME/.dotfiles-backup"

# Copy one directory into place, backing up anything overwritten.
# Backups mirror the destination: a file replaced under <destination> lands
# under $backup_directory/<backup_name> at the same relative path, which is
# exactly the layout restore_backup plays back.
#
# rsync flags:
# -a: Archive mode (recursive, preserves symlinks, times, group, owner)
# -v -q: Verbose but quiet (errors only)
# --no-perms: Don't preserve permissions (let the local umask decide)
# --backup / --backup-dir: Keep copies of files that would be overwritten
# Note: no --delete — removing a file from the repo never removes it from
# the destination.
sync_dir() {
  local source="$1" destination="$2" backup_name="$3"
  shift 3
  rsync -avq --no-perms --backup --backup-dir="$backup_directory/$backup_name" "$@" \
    "$source" "$destination" \
    || { echo "❌ ${source} sync failed. Check permissions?"; exit 1; }
}

# Play a backup set back over its destinations. Walks the same manifest as
# the sync loop: each entry restores $backup/<repo-dir>/ onto <destination>.
# Skills backups nest under claude/skills, so the claude entry covers them.
restore_backup() {
  local timestamp="${1:-}"
  local backup entry name destination

  if [ -z "$timestamp" ]; then
    echo "Usage: ./setup.sh --restore <timestamp>"
    echo ""
    echo "Available backups:"
    if [ -d "$backup_root" ] && [ -n "$(ls -A "$backup_root" 2>/dev/null)" ]; then
      # Backup names are self-generated timestamps, safe for ls
      # shellcheck disable=SC2012
      ls -1 "$backup_root" | sed 's/^/   /'
    else
      echo "   (none)"
    fi
    exit 0
  fi

  backup="$backup_root/$timestamp"
  if [ ! -d "$backup" ]; then
    echo "❌ No backup found at $backup"
    echo "   Run ./setup.sh --restore to list available backups."
    exit 1
  fi

  for entry in "${sync_manifest[@]}"; do
    name="${entry%%:*}"
    destination="${entry#*:}"
    [ -d "$backup/$name" ] || continue
    echo "♻️  Restoring $name → $destination"
    rsync -avq --no-perms "$backup/$name/" "$destination" \
      || { echo "❌ Restore of $name failed. Check permissions?"; exit 1; }
  done
  echo "✅ Restored backup $timestamp."
}

# Flatten skills: claude/skills/<category>/<skill>/ → ~/.claude/skills/<skill>/
# Skills are organized into category folders in the repo, but Claude Code only
# discovers them one level deep — categories exist purely for repo organization.
sync_skills() {
  [ -d "claude/skills" ] || return 0
  local loose_skills duplicates category_dir

  # Bail if any SKILL.md is sitting flat (not inside a category folder)
  loose_skills="$(find claude/skills -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null)"
  if [ -n "$loose_skills" ]; then
    echo "❌ Found SKILL.md files outside a category folder:"
    # sed prefixes every line of a multi-line variable; ${var//} can't anchor
    # shellcheck disable=SC2001
    echo "$loose_skills" | sed 's/^/   /'
    echo "   Move each into claude/skills/<category>/<skill-name>/SKILL.md"
    exit 1
  fi

  # Bail if two categories define the same skill name (would silently clobber)
  # Skill directory names are repo-controlled, safe for xargs
  # shellcheck disable=SC2038
  duplicates="$(find claude/skills -mindepth 2 -maxdepth 2 -type d 2>/dev/null | xargs -n1 basename 2>/dev/null | sort | uniq -d)"
  if [ -n "$duplicates" ]; then
    echo "❌ Duplicate skill names across categories:"
    # shellcheck disable=SC2001
    echo "$duplicates" | sed 's/^/   - /'
    echo "   Each skill name must be unique across all category folders."
    exit 1
  fi

  mkdir -p "$HOME/.claude/skills"
  for category_dir in claude/skills/*/; do
    [ -d "$category_dir" ] || continue
    sync_dir "$category_dir" "$HOME/.claude/skills/" "claude/skills"
  done
}

# --restore replays a previous backup instead of running setup
if [ "${1:-}" = "--restore" ]; then
  restore_backup "${2:-}"
  exit 0
fi

# Create timestamped backup directory
backup_directory="$backup_root/$(date +%Y%m%d-%H%M%S)"
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

# Sync every directory in the manifest to its destination
for entry in "${sync_manifest[@]}"; do
  name="${entry%%:*}"
  destination="${entry#*:}"
  case "$name" in
    shell)  echo "🐚 Copying shell configuration files to home directory..." ;;
    git)    echo "🔧 Setting up git configuration files..." ;;
    claude) echo "🤖 Setting up Claude configuration..." ;;
    *)      echo "📁 Syncing ${name}/ → ${destination}..." ;;
  esac
  mkdir -p "$destination" || { echo "❌ Failed to create ${destination}. Check permissions?"; exit 1; }
  if [ "$name" = "claude" ]; then
    # skills/ needs a flattening pass (category folders stripped), so it is
    # excluded here and handled by sync_skills below.
    sync_dir "$name/" "$destination" "$name" --exclude='skills'
  else
    sync_dir "$name/" "$destination" "$name"
  fi
done
sync_skills

echo "🔏 Configuring local commit-signature verification..."
# Everything signing-related is machine-local: signing keys differ per
# machine, so none of it is tracked in this repo. The script exits 0 without
# failing setup when signing is not configured on this machine yet.
# Background: README.md "Commit Signature Verification"
"${script_directory}/scripts/configure-signing.sh" \
  "$HOME/.gitconfig" \
  "$HOME/.gitconfig.local" \
  "$HOME/.config/git/allowed_signers" \
  "$HOME/.gitconfig-brillian" "$HOME/.gitconfig-work"

# Return to the original directory
cd "$current_directory" || { echo "❌ Couldn't return to where you started."; exit 1; }

# Report the backup, or clean it up when nothing was overwritten this run
if [ -n "$(find "$backup_directory" -type f 2>/dev/null | head -1)" ]; then
  echo "💾 Backed up existing files to: $backup_directory"
  echo "   To restore: ./setup.sh --restore $(basename "$backup_directory")"
else
  find "$backup_directory" -type d -empty -delete 2>/dev/null || true
fi

echo "✅ Done."
