# Homebrew bootstrap. The path is hardcoded because brew can't be found via
# PATH before this runs; shellenv also exports HOMEBREW_PREFIX for .zshrc.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# mise shims for login shells that never reach an interactive prompt (IDEs, GUI
# apps, and the git hooks they run), so node and terraform still follow .nvmrc
# and .terraform-version there. .zshrc's `mise activate` takes over in terminals.
## Static export instead of `mise activate --shims`, which spawns mise just to print this line
[ -d "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims" ] && \
  export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
