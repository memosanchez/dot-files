#!/usr/bin/env bash

# Tests for scripts/configure-signing.sh, exercised against fixture files in
# a temp directory. No real $HOME is read or written.
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
subject="${script_directory}/../scripts/configure-signing.sh"

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

tests=0
failures=0

assert_equals() {
  local expected="$1" actual="$2" message="$3"
  tests=$((tests + 1))
  if [ "$expected" = "$actual" ]; then
    echo "✅ $message"
  else
    echo "❌ $message"
    echo "   expected: $(printf '%q' "$expected")"
    echo "   actual:   $(printf '%q' "$actual")"
    failures=$((failures + 1))
  fi
}

# Each test gets a fresh fixture directory
new_fixture() {
  fixture="$test_root/fixture-$tests-$RANDOM"
  mkdir -p "$fixture"
}

run_subject() {
  "$subject" "$fixture/gitconfig" "$fixture/gitconfig.local" "$fixture/allowed_signers" "$@"
}

echo "— signing not configured —"
new_fixture
touch "$fixture/gitconfig"
output="$(run_subject)"
assert_equals "skipped" "$(echo "$output" | grep -q 'Skipped: signing is not configured' && echo skipped)" \
  "prints a skip notice when no signingkey or email is set"
assert_equals "absent" "$([ -f "$fixture/allowed_signers" ] || echo absent)" \
  "does not create allowed_signers when nothing is configured"

echo "— literal key:: signingkey —"
new_fixture
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "key::ssh-ed25519 AAAALITERAL"
run_subject > /dev/null
assert_equals "personal@example.com ssh-ed25519 AAAALITERAL" "$(cat "$fixture/allowed_signers")" \
  "appends the email mapped to the literal key"
assert_equals "$fixture/allowed_signers" "$(git config -f "$fixture/gitconfig.local" --get gpg.ssh.allowedSignersFile)" \
  "points gpg.ssh.allowedSignersFile at the allowed_signers file"

echo "— public-key path signingkey —"
new_fixture
printf 'ssh-ed25519 AAAAPUBLIC comment@host\n' > "$fixture/id_test.pub"
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "$fixture/id_test.pub"
run_subject > /dev/null
assert_equals "personal@example.com ssh-ed25519 AAAAPUBLIC" "$(cat "$fixture/allowed_signers")" \
  "reads the .pub file and strips the comment field"

echo "— private-key path signingkey —"
new_fixture
printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\n' > "$fixture/id_test"
printf 'ssh-ed25519 AAAAFROMPUB comment@host\n' > "$fixture/id_test.pub"
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "$fixture/id_test"
run_subject > /dev/null
assert_equals "personal@example.com ssh-ed25519 AAAAFROMPUB" "$(cat "$fixture/allowed_signers")" \
  "uses the .pub file sitting next to a private-key path"

echo "— private-key path without a .pub —"
new_fixture
printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\n' > "$fixture/id_test"
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "$fixture/id_test"
output="$(run_subject)"
assert_equals "skipped" "$(echo "$output" | grep -q 'no public key readable' && echo skipped)" \
  "refuses to copy private-key material and skips"
assert_equals "absent" "$([ -f "$fixture/allowed_signers" ] || echo absent)" \
  "does not create allowed_signers on an unreadable key"

echo "— work identity ordering —"
new_fixture
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "key::ssh-ed25519 AAAAMACHINE"
git config -f "$fixture/gitconfig-work" user.email "work@example.com"
run_subject "$fixture/gitconfig-work" "$fixture/gitconfig-missing" > /dev/null
assert_equals "work@example.com ssh-ed25519 AAAAMACHINE" "$(head -n 1 "$fixture/allowed_signers")" \
  "lists the work identity first"
assert_equals "personal@example.com ssh-ed25519 AAAAMACHINE" "$(sed -n '2p' "$fixture/allowed_signers")" \
  "lists the machine identity second"
assert_equals "2" "$(wc -l < "$fixture/allowed_signers" | tr -d ' ')" \
  "skips missing work configs without adding entries"

echo "— idempotency —"
new_fixture
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "key::ssh-ed25519 AAAAIDEM"
run_subject > /dev/null
before="$(cat "$fixture/allowed_signers")"
output="$(run_subject)"
assert_equals "$before" "$(cat "$fixture/allowed_signers")" \
  "a second run leaves allowed_signers unchanged"
assert_equals "configured" "$(echo "$output" | grep -q 'already configured' && echo configured)" \
  "a second run reports already configured"

echo "— hand-edited file without trailing newline —"
new_fixture
printf 'existing@example.com ssh-ed25519 AAAAMANUAL' > "$fixture/allowed_signers"
git config -f "$fixture/gitconfig" user.email "personal@example.com"
git config -f "$fixture/gitconfig" user.signingkey "key::ssh-ed25519 AAAANEW"
run_subject > /dev/null
assert_equals "existing@example.com ssh-ed25519 AAAAMANUAL" "$(head -n 1 "$fixture/allowed_signers")" \
  "preserves the hand-edited line intact"
assert_equals "personal@example.com ssh-ed25519 AAAANEW" "$(sed -n '2p' "$fixture/allowed_signers")" \
  "appends the new entry on its own line"

echo ""
echo "$tests tests, $failures failure(s)"
[ "$failures" -eq 0 ] || exit 1
