Update the current branch's Pull Request description with a changelog entry.

## Safety Checks

Before proceeding, verify:

1. Run `git status` to check for uncommitted changes
2. Run `git diff @{upstream}` to check if local branch differs from remote
3. Run `gh pr view --json number` to check if a PR exists for this branch

If any of these fail (uncommitted changes, branch differs from remote, or no PR exists), ask the user what they want to do before proceeding.

## Generate Changelog

1. Get PR info: `gh pr view --json number,title,body,commits,files,headRefName`
2. Get the diff: `gh pr diff`
3. Check for Linear ticket references (e.g., `ENG-123`, `PROJ-456`) in branch name, PR title, or commit messages
4. Analyze the changes and write a changelog following the common-changelog style guide:

### Common-Changelog Style Rules

- **Imperative mood**: Use present-tense verbs like "Add", "Fix", "Refactor", "Bump", "Document", "Deprecate" (NOT past tense)
- **Self-describing**: Each entry must be understandable without reading the category heading
- **Categories** (use only those that apply, in this order):
  - Changed - modifications to existing functionality
  - Added - new functionality
  - Removed - deleted functionality
  - Fixed - bug fixes
- **Breaking changes**: Prefix with `**Breaking:**` and list first within each category
- **References**: Do NOT self-link to the current PR (it's redundant). If the project uses Linear and there's a ticket reference in commits or branch name (e.g., `ENG-123`), include it as a link: `Add user authentication ([ENG-123](https://linear.app/team/issue/ENG-123))`
- **Single line per change**: Keep entries scannable, move details to commit messages
- **Merge related commits**: Combine multiple commits addressing one feature into a single entry
- **Skip no-ops**: Exclude commits that negate each other
- **Exclude**: Dotfile changes, dev-only dependency updates, minor code style changes, documentation formatting only
- **Include**: Refactorings (potential side effects), runtime environment changes, new features, new documentation

### Format

```markdown
### Added
- Add feature X ([ENG-123](https://linear.app/team/issue/ENG-123))
- Add feature Y

### Fixed
- Fix bug in Z
```

## Update PR

1. Get current PR body: `gh pr view --json body -q .body`
2. If body has existing content, append the changelog section
3. If body is empty, use just the changelog
4. Update the PR: `gh pr edit --body "NEW_BODY"`

Report success and show the updated PR description.
