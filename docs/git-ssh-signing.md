# Git SSH commit-signature verification

How to make `git` verify your own SSH-signed commits locally, and why it needs
a small per-machine step that is intentionally not tracked in this repo.

## TL;DR

Your commits are already signed. Git just cannot *verify* them until you give it
an allowed-signers file. Without one, signature-aware commands print:

```
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
```

and `git log --pretty=%G?` returns `N`, which looks like "unsigned" but is not.
The fix is one small file plus one config line, both machine-local. Run the
script in [The fix](#the-fix) on any machine where you want local verification.

## Symptoms

Any signature-aware command surfaces it:

```
git log --show-signature
git log -1 --pretty='%G?'
git verify-commit HEAD
```

You get the `allowedSignersFile` error, and `%G?` returns `N` (or `E` on some
commits). It reads as unsigned. It is not.

## What is actually happening

Signing and verifying are two different things.

- **Signing is already on.** The global config sets `commit.gpgsign = true`,
  `gpg.format = ssh`, and `user.signingkey` points at your SSH public key (the
  first two live in the tracked `git/.gitconfig`, the key path in the untracked
  `~/.gitconfig.local`). Every commit carries a real
  `gpgsig -----BEGIN SSH SIGNATURE-----` header.
- **Verifying an SSH signature needs an allowed-signers file:** a list mapping a
  committer email to the public key allowed to sign for it
  (`gpg.ssh.allowedSignersFile`). That was never set, so git cannot verify and
  prints the error.

So `%G? = N` describes a verification that could not run, not a missing
signature. To check presence directly, without verifying:

```
git cat-file commit HEAD | grep "BEGIN SSH SIGNATURE"
```

## Two things that make the naive fix wrong

1. **One key, two emails.** You sign with a single key but commit under two
   identities: your personal email from global config, and your work email
   pulled in from `~/.gitconfig-brillian` for `brillianco` remotes. SSH
   verification matches the commit's committer email against a principal in the
   allowed-signers file, so the file must list **both** emails against the same
   key. The common one-liner that uses `git config user.email` captures only
   whichever identity is active where you run it, so it verifies one set of
   repos and silently fails the other.

2. **Keys differ per machine, so this stays machine-local.** The allowed-signers
   file embeds the public key, and your signing key is different on each machine.
   A copy tracked in this (public) repo would bake in one machine's key and fail
   verification everywhere else. That is the same reason `user.signingkey`
   already lives in the untracked `~/.gitconfig.local`. The allowed-signers file
   belongs in the same place and is generated from each machine's own key.

## The fix

Run this on any machine where you want local verification. It reads that
machine's own signing key and committer emails, so nothing is hardcoded and
nothing sensitive is written into this repo.

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. This machine's SSH signing key, comment stripped -> "ssh-ed25519 AAAA..."
signingkey=$(git config --get user.signingkey || true)
[ -n "${signingkey}" ] || { echo "user.signingkey is not set" >&2; exit 1; }
signingkey=${signingkey/#\~/${HOME}}          # expand a leading ~
[ -f "${signingkey}" ] || { echo "signing key not found: ${signingkey}" >&2; exit 1; }
key=$(cut -d' ' -f1-2 "${signingkey}")

# 2. The committer emails this machine signs as. Work first when present, so
#    `git verify-commit` displays the identity you use most here. The first
#    principal is the one git shows, so reorder to taste.
emails=()
if [ -f "${HOME}/.gitconfig-brillian" ]; then
  work=$(git config -f "${HOME}/.gitconfig-brillian" user.email || true)
  [ -n "${work}" ] && emails+=("${work}")
fi
personal=$(git config --global user.email || true)
[ -n "${personal}" ] && emails+=("${personal}")
[ "${#emails[@]}" -gt 0 ] || { echo "no committer email found in git config" >&2; exit 1; }

# 3. Build the allowed-signers file (machine-local, not tracked in this repo).
mkdir -p "${HOME}/.config/git"
: > "${HOME}/.config/git/allowed_signers"
for email in "${emails[@]}"; do
  printf '%s %s\n' "${email}" "${key}" >> "${HOME}/.config/git/allowed_signers"
done

# 4. Point git at it, in the untracked machine-local config.
git config -f "${HOME}/.gitconfig.local" gpg.ssh.allowedSignersFile '~/.config/git/allowed_signers'

echo "Done. ~/.config/git/allowed_signers now contains:"
cat "${HOME}/.config/git/allowed_signers"
```

That produces `~/.config/git/allowed_signers` (your key, one line per identity):

```
<work-email>     ssh-ed25519 AAAA...
<personal-email> ssh-ed25519 AAAA...
```

and adds this block to `~/.gitconfig.local`:

```ini
[gpg "ssh"]
  allowedSignersFile = ~/.config/git/allowed_signers
```

## Verify it worked

```bash
git config gpg.ssh.allowedSignersFile     # -> ~/.config/git/allowed_signers
git verify-commit HEAD                     # -> Good "git" signature for <you>
git log -1 --pretty='%G? %GS'              # -> G <you>
```

`%G?` should be `G`, and the `allowedSignersFile` error should be gone.

## What still will not verify locally (and that is expected)

Do not read these as "unsigned" or try to re-sign them.

- **Squash-merged commits on `main`** have committer `noreply@github.com` and are
  signed by GitHub's own web-flow key, which is a GPG key on a different
  verification path. They show `%G?` of `E` or `N` locally even though GitHub
  marks them Verified.
- **Commits made on another machine** were signed with that machine's key. To
  verify those here too, add that machine's public key to `allowed_signers` (one
  more line per email). For confirming your current work it is not needed.

## A note on the displayed name

`git verify-commit` names the **first** principal that maps to the key, not
necessarily the commit's committer. Both of your identities map to the same key,
so the script lists the email you use most on this machine first.

## Optional: automate in setup.sh

This is a manual step on purpose, because the key is per-machine and must not be
tracked here. If you would rather have it run on every `setup.sh`, the script
above is idempotent and reads only local values (it never publishes a key), so
it can be dropped in as a setup step.
