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

## Check window size after each command and update if necessary
shopt -s checkwinsize

## Colorized Output
export CLICOLOR=1

## Big ass history
shopt -s histappend
shopt -s cmdhist
export HISTFILESIZE=100000
export HISTSIZE=500000
export HISTCONTROL="erasedups:ignoreboth"
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

## Git bash completion
## Requres bash completion in
if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

## Personal Aliases
alias virtualenv3='~/Library/Python/3.5/bin/virtualenv'
