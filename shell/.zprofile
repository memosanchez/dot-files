# Homebrew bootstrap. The path is hardcoded because brew can't be found via
# PATH before this runs; shellenv also exports HOMEBREW_PREFIX for .zshrc.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
