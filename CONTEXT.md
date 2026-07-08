# dot-files

Personal dotfiles: one repo that installs a consistent shell, git, and Claude
Code environment onto each machine.

## Language

**Sync manifest**:
The list in `setup.sh` of repo directories and their destinations
(`shell → $HOME`). The sync loop, the backup layout, and restore all derive
from it.
_Avoid_: dir list, config map

**Backup set**:
One timestamped directory under `~/.dotfiles-backup` holding every file a
single setup run overwrote, mirroring the destinations in the sync manifest.
_Avoid_: snapshot

**Restore**:
Playing a backup set back over its destinations
(`./setup.sh --restore <timestamp>`). The inverse of a sync run.

**Skill flattening**:
The sync step that strips category folders from
`claude/skills/<category>/<skill>/` so skills land flat at
`~/.claude/skills/<skill>/`, the only layout Claude Code discovers.
_Avoid_: skills copy

**Machine-local**:
Config that lives only on one machine and is never tracked in the repo
(`~/.gitconfig.local`, `~/.zshrc.local`, `allowed_signers`). Setup may write
to it, but its contents never flow back into tracked files.
_Avoid_: local override (ambiguous with `settings.local.json`)

**Work identity**:
A per-employer git config file (e.g. `~/.gitconfig-work`) carrying its own
`user.email` and optionally its own signing key. Listed before the machine
identity in `allowed_signers` so `git verify-commit` displays it.

## Example dialogue

> **Dev:** Where do I add a new synced directory?
> **Maintainer:** One entry in the sync manifest. The backup set and restore
> pick it up from there, nothing else to touch.
> **Dev:** And if setup overwrote something I hand-edited on this machine?
> **Maintainer:** It's in the latest backup set. `./setup.sh --restore` lists
> them, then pass the timestamp you want. If it was machine-local config,
> setup only appends to those, it never rewrites them.
