# Homebrew bootstrap. The path is hardcoded because brew can't be found via
# PATH before this runs; shellenv also exports HOMEBREW_PREFIX for .zshrc.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# mise shims for login shells that never reach an interactive prompt (IDEs, GUI
# apps, and the git hooks they run), so node and terraform still follow .nvmrc
# and .terraform-version there. .zshrc's `mise activate` takes over in terminals.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh --shims)"
