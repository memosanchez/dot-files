---
description: Run the project's lint, type-check, test, and build commands as a pre-commit gate. Use when the user asks to verify code before committing/pushing, run all checks, or ask "is this ready?".
---

# pre-commit-check

Run the project's quality gates in order and report a pass/fail summary. Stop at the first failure and show the relevant error output so the user can fix it.

## Steps

1. **Detect the package manager** — check lockfiles in this order:
   - `pnpm-lock.yaml` → use `pnpm`
   - `yarn.lock` → use `yarn`
   - `package-lock.json` or `bun.lockb` → use `npm` or `bun` respectively
   - none → fall through to non-JS gates below

2. **Run the JS/TS gates** (in this order, skip any whose script doesn't exist in `package.json`):
   - lint: `<pm> run lint`
   - type-check: `<pm> run typecheck` (or `tsc --noEmit` if no script)
   - test: `<pm> run test`
   - build: `<pm> run build`

3. **Non-JS fallbacks** (run if applicable, skip otherwise):
   - `Makefile` with a `check` target → `make check`
   - `justfile` with a `check` recipe → `just check`
   - `Cargo.toml` → `cargo check && cargo test`
   - `go.mod` → `go vet ./... && go test ./...`

4. **Report**: one line per step with ✅ / ❌. On the first failure, print the last 20 lines of stderr and stop.

## Output shape

```
pre-commit-check (<package-manager or "make"/etc>)
  ✅ lint
  ✅ typecheck
  ❌ test
     <last 20 lines of failure output>
```

If everything passes, end with `Ready to commit.`
