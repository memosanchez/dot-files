Analyze the staged changes and draft a commit message following this format:

```
type(scope): brief description (max 72 chars)

[Optional body: explain WHY the change was made, not WHAT was changed]
[Include context, motivation, and any important details]

[Optional footer: breaking changes, issue references, etc.]
```

**Commit types:**
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes (formatting, no logic change)
- refactor: Code refactoring (no functional change)
- test: Adding or updating tests
- chore: Maintenance tasks (dependencies, build config, etc.)
- perf: Performance improvements

**Guidelines:**
- Use imperative mood: "Add feature" not "Added feature"
- Keep subject line under 72 characters
- Focus body on WHY, not WHAT
- Reference issue numbers if applicable
