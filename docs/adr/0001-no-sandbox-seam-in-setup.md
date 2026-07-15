# setup.sh targets the real $HOME, with backups as the safety net

An architecture review (2026-07-08) proposed routing every write in setup.sh
through a `target_home` seam so the whole script could be exercised against a
sandbox directory in tests. Rejected: this is a personal dotfiles repo, and
setup.sh exists precisely to mutate this machine's real `$HOME`. The safety
mechanism is the timestamped backup set in `~/.dotfiles-backup` plus
`./setup.sh --restore`, not a sandbox. Logic-dense pieces that deserve tests
get them by taking explicit path inputs instead (see
`scripts/configure-signing.sh` and its fixture tests), without a repo-wide
seam.
