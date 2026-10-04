#!/usr/bin/env bash

# Tests for the `gone` alias in git/.gitconfig, read straight from that file
# and run in fixture repos under a temp directory. A bare repo stands in for
# GitHub, and a stub gh answers PR lookups from a per-fixture PR list. The
# real ~/.gitconfig and the real gh are never used.
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gitconfig="${script_directory}/../git/.gitconfig"

# Physical path, since git reports worktree paths with symlinks resolved
# (macOS temp dirs live under the /var -> /private/var link)
test_root="$(cd "$(mktemp -d)" && pwd -P)"
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

alias_value="$(git config -f "$gitconfig" --get alias.gone)" \
  || { echo "❌ git/.gitconfig has no parseable alias.gone"; exit 1; }

# Isolated git: no system or personal config (signing, fetch.prune), only the
# alias under test plus an identity for fixture commits
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$test_root/gitconfig"
git config -f "$GIT_CONFIG_GLOBAL" user.name "Test"
git config -f "$GIT_CONFIG_GLOBAL" user.email "test@example.com"
git config -f "$GIT_CONFIG_GLOBAL" init.defaultBranch main
git config -f "$GIT_CONFIG_GLOBAL" alias.gone "$alias_value"

# Stub gh: answers `gh pr list --head <branch> --state <state> --jq <filter>`
# by running the caller's own filter (with /usr/bin/jq) over the matching PRs
# in $GH_PRS, one "<branch> <state> <head sha>" line per PR. GH_OFFLINE=1
# fails every call the way a dropped network does.
mkdir -p "$test_root/bin"
cat > "$test_root/bin/gh" <<'STUB'
#!/bin/sh
if [ -n "${GH_OFFLINE-}" ]; then echo "error connecting to api.github.com" >&2; exit 1; fi
[ "$1 $2" = "pr list" ] || { echo "stub gh: unexpected call: $*" >&2; exit 2; }
shift 2
head= state= filter=.
while [ $# -gt 0 ]; do
  case $1 in
    --head) head=$2; shift ;;
    --state) state=$2; shift ;;
    --jq) filter=$2; shift ;;
  esac
  shift
done
awk -v head="$head" -v state="$state" '$1 == head && $2 == state { print $3 }' "$GH_PRS" |
  jq -Rn '[inputs | {headRefOid: .}]' | jq -r "$filter"
STUB
chmod +x "$test_root/bin/gh"
export PATH="$test_root/bin:/usr/bin:/bin"

# Each test gets a fresh fixture: a bare origin, a clone at $repo with one
# commit on main, and an empty PR list. The space in the path is deliberate.
new_fixture() {
  fixture="$test_root/fixture $tests-$RANDOM"
  repo="$fixture/repo"
  mkdir -p "$fixture"
  git init -q --bare "$fixture/origin.git"
  git clone -q "$fixture/origin.git" "$repo" 2>/dev/null
  git -C "$repo" commit -q --allow-empty -m "initial"
  git -C "$repo" push -q origin main
  export GH_PRS="$fixture/prs"
  : > "$GH_PRS"
}

# Push a branch with one commit of its own, tracking origin/<name>
push_branch() {
  git -C "$repo" switch -q -c "$1" main
  git -C "$repo" commit -q --allow-empty -m "$1"
  git -C "$repo" push -q -u origin "$1" 2>/dev/null
  git -C "$repo" switch -q main
}

add_worktree() {
  git -C "$repo" worktree add -q "$fixture/wt-$1" "$1"
}

# What GitHub does when a PR is merged or closed: record the PR at the
# branch's current tip, then delete the remote branch
finish_pr() {
  local state="$1" branch="$2"
  echo "$branch $state $(git -C "$repo" rev-parse "refs/heads/$branch")" >> "$GH_PRS"
  git -C "$fixture/origin.git" branch -q -D "$branch"
}

# The usual starting point: a branch in its own worktree whose PR merged
merged_worktree() {
  push_branch "$1"
  add_worktree "$1"
  finish_pr merged "$1"
}

# Run `git gone` from a directory, capturing stdout and stderr in $output and
# the exit status in $status
run_gone() {
  local directory="$1"
  shift
  status=0
  output="$(git -C "$directory" gone "$@" 2>&1)" || status=$?
}

branch_state() {
  git -C "$repo" show-ref -q --verify "refs/heads/$1" && echo present || echo deleted
}

worktree_state() {
  [ -d "$fixture/wt-$1" ] && echo present || echo removed
}

output_line() {
  printf '%s\n' "$output" | grep -Fx -- "$1" || true
}

assert_line() {
  assert_equals "$1" "$(output_line "$1")" "$2"
}

assert_kept() {
  assert_equals "present" "$(worktree_state "$1")" "keeps the worktree"
  assert_equals "present" "$(branch_state "$1")" "keeps the branch"
}

echo "— merged branch in a clean worktree —"
new_fixture
merged_worktree feature
run_gone "$repo"
assert_equals "removed" "$(worktree_state feature)" "removes the worktree"
assert_equals "deleted" "$(branch_state feature)" "deletes the branch"
assert_line "Removed worktree $fixture/wt-feature" "reports the removed worktree"

echo "— only branches whose upstream is gone —"
new_fixture
push_branch merged
finish_pr merged merged
push_branch live
git -C "$repo" branch -q local-only main
run_gone "$repo"
assert_equals "deleted" "$(branch_state merged)" "deletes a merged branch that has no worktree"
assert_equals "present" "$(branch_state live)" "keeps a branch whose upstream still exists"
assert_equals "present" "$(branch_state local-only)" "keeps a branch that was never pushed"
assert_equals "present" "$(branch_state main)" "keeps main"

echo "— branch sharing its name with a tag —"
new_fixture
push_branch release
finish_pr merged release
git -C "$repo" tag release main
run_gone "$repo"
assert_equals "deleted" "$(branch_state release)" "looks up the PR by the branch name, not heads/<name>"

echo "— commits added after the PR merged —"
new_fixture
merged_worktree feature
git -C "$fixture/wt-feature" commit -q --allow-empty -m "after merge"
run_gone "$repo"
assert_kept feature
assert_line "Kept feature: no merged PR at this commit" "says why it kept the branch"

echo "— PR closed without merging —"
new_fixture
push_branch feature
add_worktree feature
finish_pr closed feature
run_gone "$repo"
assert_kept feature
assert_line "Kept feature: no merged PR at this commit" "says why it kept the branch"

echo "— gh not installed —"
new_fixture
merged_worktree feature
PATH="/usr/bin:/bin" run_gone "$repo"
assert_kept feature
assert_equals "git gone: gh not found, nothing deleted" "$output" "stops with a single message"
assert_equals "1" "$status" "exits non-zero"

echo "— fetch fails after the branch was already marked gone —"
new_fixture
merged_worktree feature
git -C "$repo" fetch -q --prune
git -C "$repo" remote set-url origin "$fixture/unreachable.git"
run_gone "$repo"
assert_kept feature
assert_equals "nonzero" "$([ "$status" -ne 0 ] && echo nonzero)" "exits non-zero"

echo "— gh cannot reach GitHub —"
new_fixture
merged_worktree feature
GH_OFFLINE=1 run_gone "$repo"
assert_kept feature
assert_line "Kept feature: couldn't check PR" "says the PR check failed"

echo "— worktree with uncommitted work —"
new_fixture
merged_worktree feature
echo "draft" > "$fixture/wt-feature/notes.txt"
run_gone "$repo"
assert_kept feature
assert_equals "draft" "$(cat "$fixture/wt-feature/notes.txt" 2>/dev/null)" "keeps the uncommitted file"
assert_line "Kept feature: $fixture/wt-feature was not removed" "says the worktree was not removed"

echo "— locked worktree —"
new_fixture
merged_worktree feature
git -C "$repo" worktree lock --reason "on an external drive" "$fixture/wt-feature"
run_gone "$repo"
assert_kept feature
assert_line "Kept feature: $fixture/wt-feature was not removed" "says the worktree was not removed"

echo "— run from inside the gone branch's worktree —"
new_fixture
merged_worktree feature
run_gone "$fixture/wt-feature"
assert_kept feature
assert_line "Skipped feature: checked out in $fixture/wt-feature" "says why it skipped the branch"

echo "— gone branch checked out in the main worktree, run from a linked one —"
new_fixture
push_branch other
add_worktree other
push_branch feature
finish_pr merged feature
git -C "$repo" switch -q feature
run_gone "$fixture/wt-other"
assert_equals "feature" "$(git -C "$repo" branch --show-current)" "leaves the main worktree on its branch"
assert_equals "present" "$(branch_state feature)" "keeps the branch"
assert_line "Skipped feature: checked out in $repo" "says why it skipped the branch"

echo "— dry run (-n) —"
new_fixture
merged_worktree feature
push_branch unmerged
finish_pr closed unmerged
run_gone "$repo" -n
assert_kept feature
assert_line "git worktree remove $fixture/wt-feature" "prints the worktree removal"
assert_line "git branch -D feature" "prints the branch deletion"
assert_line "Kept unmerged: no merged PR at this commit" "still runs the PR check"
assert_equals "" "$(output_line "git branch -D unmerged")" "does not list a branch that fails the PR check"

echo "— unknown argument —"
new_fixture
merged_worktree feature
run_gone "$repo" --dry-run
assert_kept feature
assert_equals "usage: git gone [-n]" "$output" "prints usage"
assert_equals "2" "$status" "exits 2"

echo ""
echo "$tests tests, $failures failure(s)"
[ "$failures" -eq 0 ] || exit 1
