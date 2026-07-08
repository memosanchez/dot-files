# Git SSH commit-signature verification

How to make `git` verify your own SSH-signed commits locally, and why part of
the fix is per-machine and intentionally not tracked in this repo.

## TL;DR

Your commits are already signed. Git just cannot *verify* them until you give it
an allowed-signers file. Without one, signature-aware commands print:

```text
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
```

and `git log --pretty='%G?'` returns `N`, which looks like "unsigned" but is not.
The fix is one small file plus one config line, both machine-local. `./setup.sh`
takes care of both on every run (see [The fix](#the-fix)).

## Symptoms

Any signature-aware command surfaces it:

```bash
git log --show-signature
git log -1 --pretty='%G?'
git verify-commit HEAD
```

You get the `allowedSignersFile` error, and `%G?` returns `N` (or `E` on some
commits). It reads as unsigned. It is not.

## What is actually happening

Signing and verifying are two different things.

- **Signing is already on.** The global config sets `commit.gpgsign = true`,
  `gpg.format = ssh`, and `user.signingkey` points at your SSH key (the
  first two live in the tracked `git/.gitconfig`, the key path in the untracked
  `~/.gitconfig.local`). Every commit carries a real
  `gpgsig -----BEGIN SSH SIGNATURE-----` header.
- **Verifying an SSH signature needs an allowed-signers file:** a list mapping a
  committer email to the public key allowed to sign for it
  (`gpg.ssh.allowedSignersFile`). That was never set, so git cannot verify and
  prints the error.

So `%G? = N` describes a verification that could not run, not a missing
signature. To check presence directly, without verifying:

```bash
git cat-file commit HEAD | grep "BEGIN SSH SIGNATURE"
```

## Two things that make the naive fix wrong

1. **One key, two emails.** You sign with a single key but commit under two
   identities: your personal email from global config, and your work email
   pulled in via an `includeIf` config file (`~/.gitconfig-brillian` or
   `~/.gitconfig-work`). SSH verification matches the commit's committer email
   against a principal in the allowed-signers file, so the file must list
   **both** emails against the key each identity signs with. The common
   one-liner that uses `git config user.email` captures only whichever identity
   is active where you run it, so it verifies one set of repos and silently
   fails the other.

2. **Keys differ per machine, so this stays machine-local.** The allowed-signers
   file embeds the public key, and your signing key is different on each machine.
   A copy tracked in this (public) repo would bake in one machine's key and fail
   verification everywhere else. That is the same reason `user.signingkey`
   already lives in the untracked `~/.gitconfig.local`. The allowed-signers file
   belongs in the same place and is generated from each machine's own key.

## The fix

`./setup.sh` configures this automatically on every run, via the
`configure_signing_verification` step in `setup.sh`. On each machine it:

- resolves the global `user.signingkey` to its public key, handling all three
  forms git accepts: a public-key path, a private-key path (it reads the `.pub`
  next to it, never the private key), and a literal `key::` value
- collects every committer email you sign as: work identities from
  `~/.gitconfig-brillian` or `~/.gitconfig-work` first (using that file's own
  `user.signingkey` if it sets one), then the personal email from global config
- appends any missing `<email> <key>` lines to
  `~/.config/git/allowed_signers`, preserving lines that are already there, so
  manual additions survive re-runs
- sets `gpg.ssh.allowedSignersFile` in the untracked `~/.gitconfig.local`

On a machine where signing is not configured yet, the step explains why it was
skipped and the rest of the setup carries on.

The result is `~/.config/git/allowed_signers` (one line per identity):

```text
<work-email>     ssh-ed25519 AAAA...
<personal-email> ssh-ed25519 AAAA...
```

and this block in `~/.gitconfig.local`:

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
  more line per email). Setup runs preserve manually added lines, so the entry
  survives future `./setup.sh` runs. For confirming your current work it is not
  needed.

## A note on the displayed name

`git verify-commit` names the **first** principal in the file that maps to the
key, not necessarily the commit's committer. On a fresh file setup writes work
identities first; because later runs only append missing lines, the order on an
existing file reflects when entries were added. Reorder the lines to taste.
