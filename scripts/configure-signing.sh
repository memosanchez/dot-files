#!/usr/bin/env bash

# Configure local commit-signature verification.
#
# Maps each committer email to that identity's SSH public key in an
# allowed_signers file, then points git at it via gpg.ssh.allowedSignersFile.
# Makes `git verify-commit` work and silences the recurring
# "gpg.ssh.allowedSignersFile needs to be configured" noise. Existing
# allowed_signers lines are preserved (manual additions survive re-runs);
# only missing entries are appended. Exits 0 without failing the caller when
# signing is not configured yet.
#
# Usage:
#   configure-signing.sh <gitconfig> <gitconfig_local> <allowed_signers> [work_config...]
#
#   gitconfig        config file read (with includes) for user.signingkey and
#                    user.email — normally ~/.gitconfig
#   gitconfig_local  machine-local config file that receives
#                    gpg.ssh.allowedSignersFile — normally ~/.gitconfig.local
#   allowed_signers  file that "email key" entries are appended to — normally
#                    ~/.config/git/allowed_signers
#   work_config...   per-identity config files (e.g. ~/.gitconfig-work), each
#                    contributing its user.email; missing files are skipped
#
# Every path is an explicit argument so the script can be exercised against
# fixture files without touching a real $HOME — see
# tests/configure-signing-test.sh.
# Background: README.md "Commit Signature Verification"

set -euo pipefail

# Resolve a user.signingkey config value to its public key ("ssh-ed25519 AAAA...").
# Handles the three forms git accepts: a literal "key::" value, a public-key
# path, and a private-key path (uses the .pub file next to it). Prints nothing
# and returns non-zero when no public key can be read from the value.
resolve_public_key() {
  local value="$1" line
  if [ "${value#key::}" != "$value" ]; then
    line="${value#key::}"
  else
    # The quoted ~ is deliberate: it matches a literal ~ in the config value
    # shellcheck disable=SC2088
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
  local gitconfig="$1" gitconfig_local="$2" allowed="$3"
  shift 3
  local signingkey machine_key identity_key work_config email entry
  local entries=()
  local added=0

  # This machine's signing key. --includes follows [include] directives (the
  # key normally lives in the included gitconfig.local). `git config` exits 1
  # when the key is simply unset; real failures (e.g. a malformed config
  # file) print to stderr.
  signingkey=""
  if [ -f "$gitconfig" ]; then
    signingkey="$(git config -f "$gitconfig" --includes --get user.signingkey || true)"
  fi
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
  for work_config in "$@"; do
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
  email=""
  if [ -f "$gitconfig" ]; then
    email="$(git config -f "$gitconfig" --includes --get user.email || true)"
  fi
  if [ -n "$email" ] && [ -n "$machine_key" ]; then
    entries+=("$email $machine_key")
  fi

  if [ "${#entries[@]}" -eq 0 ]; then
    echo "   ℹ️  Skipped: signing is not configured (set user.signingkey and user.email in $gitconfig_local)."
    return 0
  fi

  mkdir -p "$(dirname "$allowed")" || { echo "   ⚠️  Skipped: could not create $(dirname "$allowed")."; return 0; }
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
  git config -f "$gitconfig_local" gpg.ssh.allowedSignersFile "$allowed" \
    || { echo "   ⚠️  Wrote $allowed but could not update $gitconfig_local."; return 0; }
  if [ "$added" -gt 0 ]; then
    echo "   ✅ Added $added signer(s) to $allowed and set gpg.ssh.allowedSignersFile."
  else
    echo "   ✅ Commit-signature verification already configured."
  fi
}

if [ "$#" -lt 3 ]; then
  echo "Usage: $(basename "$0") <gitconfig> <gitconfig_local> <allowed_signers> [work_config...]" >&2
  exit 64
fi
configure_signing_verification "$@"
