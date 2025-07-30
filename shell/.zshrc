# Early Initialization
## Cache Homebrew prefix early for performance throughout the config
if command -v brew &>/dev/null; then
  export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
fi

## History settings for better command recall
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000000
export SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
setopt HIST_VERIFY               # Don't execute immediately upon history expansion
setopt HIST_BEEP                 # Beep when accessing nonexistent history

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
COMPLETION_WAITING_DOTS="true"
ZSH_THEME=""  # Disabled - using Pure prompt instead
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

## Auto-update behavior
zstyle ':omz:update' mode auto

## Helper function to auto-install Oh My Zsh plugins
ensure_plugin() {
  local plugin_name="$1"
  local plugin_repo="$2"
  if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin_name" ]]; then
    echo "Installing $plugin_name..."
    git clone "$plugin_repo" "$ZSH_CUSTOM/plugins/$plugin_name" --quiet
  fi
}

## Install plugins if not present (fast directory check)
[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
  ensure_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
  ensure_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

## Load Oh My Zsh plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

## Initialize Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Completions
## Homebrew completions (must be after Oh My Zsh to avoid double compinit)
if [[ -n "$HOMEBREW_PREFIX" ]] && [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
fi

# Prompt 
autoload -U promptinit; promptinit
prompt pure

# Development Tools
## Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

## pnpm
export PNPM_HOME="$HOME/Library/pnpm"
### Only add if directory exists and not already in PATH
if [ -d "$PNPM_HOME" ]; then
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

## PostgreSQL tools
[ -d "/opt/homebrew/opt/libpq/bin" ] && export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Aliases
## Claude Code CLI
alias claude="~/.claude/local/claude"

