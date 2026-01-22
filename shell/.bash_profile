export LANG=en_US.UTF-8

for file in ~/.{bash_colors,bash_prompt}; do
  [ -r "$file" ] && source "$file"
done
unset file

## Update window size after every command
shopt -s checkwinsize

## Make sure we have /usr/local/bin
export PATH="/usr/local/bin:$PATH"

## Add user bin directory to path
export PATH="$HOME/bin:$PATH"

## Add user local bin directory to path
export PATH="$HOME/.local/bin:$PATH"

## Colorized Output
export CLICOLOR=1

## Big ass history
shopt -s histappend
shopt -s cmdhist
export HISTFILESIZE=100000
export HISTSIZE=500000
export HISTCONTROL="erasedups:ignoreboth"
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

## Git/bash completion (requires: brew install bash-completion@2)
if command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  if [[ -r "${BREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    source "${BREW_PREFIX}/etc/profile.d/bash_completion.sh"
  fi
fi

