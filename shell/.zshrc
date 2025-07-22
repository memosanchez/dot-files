# Homebrew
# ** Needs to happen before calling oh-my-zsh
# if type brew &>/dev/null
# then
#   FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#   autoload -Uz compinit
#   compinit
# fi

# Options
COMPLETION_WAITING_DOTS="true"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

# Oh my Zsh
export ZSH="$HOME/.oh-my-zsh"

# Automatically updates Oh My Zsh when a new version is available
zstyle ':omz:update' mode auto
plugins=(
  git
  # zsh-autosuggestions
  # zsh-syntax-highlighting  # Needs to be installed via homebrew or https://github.com/zsh-users/zsh-syntax-highlighting.git
)
source $ZSH/oh-my-zsh.sh


# Initialize prompt system
autoload -U promptinit; promptinit

# Set prompt
ZSH_THEME="" # Disable OMZ theme
prompt pure

# ZSH Plugins from Homebrew
# Check if zsh-autosuggestions is installed
if ! brew list zsh-syntax-highlighting &>/dev/null; then
  echo "Installing zsh-syntax-highlighting..."
  brew install zsh-syntax-highlighting
fi

# Check if zsh-autosuggestions is installed
if ! brew list zsh-autosuggestions &>/dev/null; then
  echo "Installing zsh-autosuggestions..."
  brew install zsh-autosuggestions
fi

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# libpq
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# CLAUDE
alias claude="/Users/memo/.claude/local/claude"