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
2. Copies configurations to `$HOME`

## 📂 Repository Structure

- `shell/` - Shell configuration files
- `git/` - Git configuration files
- `claude/` - Claude Code configuration files

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
