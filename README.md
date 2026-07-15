# dot Files

```text
     _       _      __ _ _
  __| | ___ | |_   / _(_) | ___  ___
 / _` |/ _ \| __| | |_| | |/ _ \/ __|
| (_| | (_) | |_  |  _| | |  __/\__ \
 \__,_|\___/ \__| |_| |_|_|\___||___/
```

A collection of shell and git configuration files to maintain a consistent development environment across machines.

## 🔧 Installation

The `setup.sh` script handles the installation process:

1. Updates the repository with the latest changes
2. Installs Homebrew packages from the `Brewfile`
3. Copies configurations to `$HOME`, backing up anything it overwrites

### Backups & Restore

Every run writes the files it overwrites to `~/.dotfiles-backup/<timestamp>/`,
mirroring where they came from. To roll back:

```bash
./setup.sh --restore                  # list available backups
./setup.sh --restore 20260708-152724  # play one back over $HOME
```

A restore backs up whatever it overwrites into a fresh backup set, so a
restore can be undone the same way. Files a sync newly created are not part
of any backup set, so a restore does not remove them.

## 📂 Repository Structure

- `shell/` - Shell configuration files (zsh)
- `git/` - Git configuration files
- `claude/` - Claude Code configuration files
- `scripts/` - Helper scripts called by `setup.sh`
- `tests/` - Fixture-based tests for the helper scripts
- `docs/adr/` - Architecture decision records
- `CONTEXT.md` - Domain glossary for this repo

## 🔑 Per-Machine Configuration

Both `.gitconfig` and `.zshrc` support machine-specific overrides via local files that are **not tracked** in the repo. Create these on each machine as needed.

### Shell Overrides (`~/.zshrc.local`)

For machine-specific environment variables, aliases, or tool configuration:

```bash
# ~/.zshrc.local (example: use 1Password SSH agent)
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

### Git Overrides (`~/.gitconfig.local`)

The shared `.gitconfig` enables SSH commit signing and includes `~/.gitconfig.local` for machine-specific overrides.

### Signing Key (required per machine)

```ini
# ~/.gitconfig.local
[user]
  signingkey = ~/.ssh/id_ed25519.pub
```


### Directory-Based Email Overrides (optional)

To use a different email for repos in a specific directory, add an `includeIf` rule and a matching config file:

```ini
# ~/.gitconfig.local
[user]
  signingkey = ~/.ssh/id_ed25519.pub

[includeIf "gitdir:~/work/"]
  path = ~/.gitconfig-work
```

```ini
# ~/.gitconfig-work
[user]
  email = you@work.com
```

### GitHub Setup

Each machine's SSH public key must be added to GitHub as a **Signing Key** (separate from Authentication):

1. Copy your public key: `cat ~/.ssh/id_ed25519.pub`
2. Go to **GitHub → Settings → SSH and GPG keys → New SSH key**
3. Set **Key type** to **Signing Key** and paste the key

### Commit Signature Verification

With the signing key configured, `setup.sh` also makes `git verify-commit` work
locally: it maps each committer email to this machine's public key in
`~/.config/git/allowed_signers` and sets `gpg.ssh.allowedSignersFile` in
`~/.gitconfig.local`. Both stay machine-local because signing keys differ per
machine and this repo is public. Existing `allowed_signers` lines are
preserved, so manual additions survive re-runs.

To check it, `git log -1 --pretty='%G? %GS'` should print `G <you>`. An `N`
means "could not verify", not "unsigned".

Two cases never verify locally, and that is expected - don't try to fix them:

- **Squash-merged commits on `main`** are signed by GitHub's web-flow GPG key.
  They show `E` or `N` locally even though GitHub marks them Verified.
- **Commits from another machine** were signed with that machine's key. To
  verify them here, append that machine's public key to `allowed_signers`
  (one line per email).
