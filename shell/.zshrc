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

## NVM plugin configuration
## Only use lazy loading in interactive shells - it has bugs in non-interactive contexts
## (e.g., Claude Code shell commands fail with "_omz_nvm_setup_completion not found")
if [[ -o interactive ]]; then
  zstyle ':omz:plugins:nvm' lazy yes           # Defer nvm loading for faster startup
  ## Also lazy-load on git: git hooks (e.g. husky post-checkout running pnpm) inherit
  ## PATH from the shell, so nvm must activate the .nvmrc version before git runs
  zstyle ':omz:plugins:nvm' lazy-cmd git
fi
zstyle ':omz:plugins:nvm' autoload yes         # Auto-use .nvmrc files
zstyle ':omz:plugins:nvm' silent-autoload yes  # Suppress version switch output

## Load Oh My Zsh plugins
plugins=(
  git
  nvm
)

## Initialize Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

## ZSH plugins (installed via Homebrew, managed in Brewfile)
## Syntax highlighting must be sourced last per its documentation
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Completions
## Homebrew completions (must be after Oh My Zsh to avoid double compinit)
if [[ -n "$HOMEBREW_PREFIX" ]] && [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
fi

# Prompt
autoload -U promptinit; promptinit
prompt pure

# Development Tools
## Prepend a directory to PATH once — skips missing dirs and duplicates
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

## pnpm (global binaries live directly in PNPM_HOME, per pnpm's own snippet)
export PNPM_HOME="$HOME/Library/pnpm"
path_prepend "$PNPM_HOME"

## asdf version manager
path_prepend "${ASDF_DATA_DIR:-$HOME/.asdf}/shims"

## User local bin
path_prepend "$HOME/.local/bin"

## PostgreSQL tools
path_prepend "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/libpq/bin"

## Google Cloud SDK (gcloud, bq, gsutil, etc.)
path_prepend "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/bin"
### gcloud shell completion
if [ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc" ]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc"
fi

# Machine-specific overrides (not tracked in dotfiles)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

