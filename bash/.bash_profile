export LANG=en_US.UTF-8

for file in ~/.{bash_colors,bash_prompt}; do
  [ -r "$file" ] && source "$file"
done
unset file

## Make sure we have /usr/local/bin
export PATH="/usr/local/bin:$PATH"

## Add user bin directory to path
export PATH="$HOME/bin:$PATH"

## Check window size after each command and update if necessary
shopt -s checkwinsize

## Big ass history
export HISTFILESIZE=10000
export HISTSIZE=10000
