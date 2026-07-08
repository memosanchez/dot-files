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
# Ensure ~/.config/git/allowed_signers maps each committer email you sign as
# to that identity's SSH public key, then point git at it via ~/.gitconfig.local.
# Makes `git verify-commit` work and silences the recurring
# "gpg.ssh.allowedSignersFile needs to be configured" noise. Everything here is
# machine-local: signing keys differ per machine, so none of it is tracked in
# this repo. Existing allowed_signers lines are preserved (manual additions
# survive re-runs); only missing entries are appended. Skips without failing
# the setup when signing is not configured on this machine yet.
# Background: README.md "Commit Signature Verification"

# Resolve a user.signingkey config value to its public key ("ssh-ed25519 AAAA...").
# Handles the three forms git accepts: a literal "key::" value, a public-key
# path, and a private-key path (uses the .pub file next to it). Prints nothing
# and returns non-zero when no public key can be read from the value.
resolve_public_key() {
  local value="$1" line
  if [ "${value#key::}" != "$value" ]; then
    line="${value#key::}"
  else
    case "$value" in
      "~/"*) value="$HOME${value#\~}" ;;  # expand a leading ~/ like git does
    esac
    if [ -f "$value.pub" ]; then
      value="$value.pub"                  # private-key path: git uses the .pub
    fi
    [ -f "$value" ] || return 1
    line="$(head -n 1 "$value")" || return 1
  fi
  case "$line" in
    # Only ever emit public-key material; a private-key path without a .pub
    # lands in the fallback and is rejected rather than copied.
    ssh-* | ecdsa-* | sk-*) printf '%s\n' "$line" | cut -d' ' -f1-2 ;;
    *) return 1 ;;
  esac
}

configure_signing_verification() {
  local allowed="$HOME/.config/git/allowed_signers"
  local signingkey machine_key identity_key work_config email entry
  local entries=()
  local added=0

  # This machine's signing key. --includes follows the [include] of
  # ~/.gitconfig.local, where the key lives (includes are off by default when
  # a scope flag is given). `git config` exits 1 when the key is simply unset;
  # real failures (e.g. a malformed config file) print to stderr.
  signingkey="$(git config --global --includes --get user.signingkey || true)"
  machine_key=""
  if [ -n "$signingkey" ]; then
    if ! machine_key="$(resolve_public_key "$signingkey")"; then
      echo "   ⚠️  Skipped: no public key readable from user.signingkey ($signingkey)."
      return 0
    fi
  fi

  # One line per identity you commit as. Work identities first when present,
  # so `git verify-commit` displays them (git shows the first principal that
  # maps to the key). A work config may carry its own user.signingkey;
  # otherwise it signs with the machine key.
  for work_config in "$HOME/.gitconfig-brillian" "$HOME/.gitconfig-work"; do
    [ -f "$work_config" ] || continue
    email="$(git config -f "$work_config" --get user.email || true)"
    [ -n "$email" ] || continue
    signingkey="$(git config -f "$work_config" --get user.signingkey || true)"
    identity_key="$machine_key"
    if [ -n "$signingkey" ]; then
      identity_key="$(resolve_public_key "$signingkey" || true)"
    fi
    if [ -n "$identity_key" ]; then
      entries+=("$email $identity_key")
    fi
  done
  email="$(git config --global --includes --get user.email || true)"
  if [ -n "$email" ] && [ -n "$machine_key" ]; then
    entries+=("$email $machine_key")
  fi

  if [ "${#entries[@]}" -eq 0 ]; then
    echo "   ℹ️  Skipped: signing is not configured (set user.signingkey and user.email in ~/.gitconfig.local)."
    return 0
  fi

  mkdir -p "$HOME/.config/git" || { echo "   ⚠️  Skipped: could not create ~/.config/git."; return 0; }
  touch "$allowed" || { echo "   ⚠️  Skipped: could not write $allowed."; return 0; }
  # A hand-edited last line may lack a newline; don't glue an entry onto it.
  if [ -s "$allowed" ] && [ -n "$(tail -c 1 "$allowed")" ]; then
    echo >> "$allowed" || { echo "   ⚠️  Skipped: could not write $allowed."; return 0; }
  fi
  for entry in "${entries[@]}"; do
    if ! grep -qxF "$entry" "$allowed"; then
      echo "$entry" >> "$allowed" || { echo "   ⚠️  Skipped: could not write $allowed."; return 0; }
      added=$((added + 1))
    fi
  done
  git config -f "$HOME/.gitconfig.local" gpg.ssh.allowedSignersFile '~/.config/git/allowed_signers' \
    || { echo "   ⚠️  Wrote $allowed but could not update ~/.gitconfig.local."; return 0; }
  if [ "$added" -gt 0 ]; then
    echo "   ✅ Added $added signer(s) to $allowed and set gpg.ssh.allowedSignersFile."
  else
    echo "   ✅ Commit-signature verification already configured."
  fi
}
configure_signing_verification

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
