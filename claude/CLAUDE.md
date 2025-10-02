# Code Style Guidelines

## General Principles
- Write clear, maintainable, and well-documented code
- Favor explicitness over cleverness
- Follow the principle of least surprise
- Keep functions small and focused on a single responsibility

## Markdown
- Files should be well-structured with clear headings and subheadings
- Markdown files (*.md) should include a metadata section at the top with creation date and last modified date
- Use proper formatting: **bold** for emphasis, `code` for inline code, code blocks with language specification
- Keep line length reasonable (80-100 chars) for readability in diffs
- Do NOT add date metadata to code files (TypeScript, JavaScript, Python, etc.) - only to Markdown documentation

## TypeScript
- Avoid the use of `any` type - use `unknown` or proper types instead
- Prefer interfaces for object shapes, types for unions/intersections
- Use strict mode settings (strict: true in tsconfig)
- Document complex types with JSDoc comments
- Use readonly for immutable data structures
- Prefer const assertions where appropriate

## JavaScript
- Use modern ES6+ features (const/let, arrow functions, destructuring, async/await)
- Avoid var declarations
- Use strict equality (===) over loose equality (==)
- Handle promises properly - always catch errors

## Python
- Follow PEP 8 style guidelines
- Use type hints for function signatures
- Write docstrings for modules, classes, and functions
- Prefer list comprehensions over map/filter for readability

## Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Enable safety flags: `set -euo pipefail`
- Quote variable expansions: `"${var}"`
- Add descriptive comments for complex commands
- Exit with meaningful error messages

# Git & Version Control

## Commit Messages
- Use conventional commit format: `type(scope): description`
- Types: feat, fix, docs, style, refactor, test, chore, perf
- Keep subject line under 72 characters
- Use imperative mood: "Add feature" not "Added feature"
- Include context in the body for non-trivial changes
- Reference issue numbers when applicable

## Pull Requests
- Use descriptive titles following commit message format
- Include "## Summary" section with bullet points of changes
- Include "## Test Plan" section with testing steps
- Include "## Breaking Changes" section if applicable
- Link related issues and PRs
- Keep PRs focused - one feature or fix per PR
- Ensure CI passes before requesting review

## Branching
- Use descriptive branch names: `feature/add-user-auth`, `fix/login-crash`
- Keep branches short-lived - merge frequently
- Rebase on main/master before merging to keep history clean

# Testing

## Philosophy
- Write tests for all new features and bug fixes
- Aim for high coverage but prioritize meaningful tests over coverage percentage
- Test behavior, not implementation details 
- Use descriptive test names that explain what is being tested

## Test Structure
- Arrange-Act-Assert (AAA) pattern
- One assertion per test when possible
- Use test fixtures and factories for complex setup
- Mock external dependencies appropriately

## Test Types
- Unit tests: Test individual functions/methods in isolation
- Integration tests: Test component interactions
- E2E tests: Test critical user workflows
- Run tests before committing code

# Code Review

## When Reviewing
- Check for logical errors and edge cases
- Verify tests are adequate and passing
- Ensure code follows style guidelines
- Look for security vulnerabilities
- Consider performance implications
- Suggest improvements, don't just criticize

## When Being Reviewed
- Keep PRs reasonably sized (< 400 lines when possible)
- Respond to all comments
- Be open to feedback and suggestions
- Don't take criticism personally

# Documentation

## Code Documentation
- Write self-documenting code with clear names
- Add comments for "why" not "what" - code shows what, comments explain why
- Document public APIs thoroughly
- Keep documentation up-to-date with code changes
- Include usage examples for complex functions

## Project Documentation
- Keep README.md current with setup instructions
- Document architecture decisions
- Maintain changelog for user-facing changes
- Include troubleshooting guides

# Error Handling

## General Principles
- Fail fast and loud - don't hide errors
- Provide actionable error messages
- Log errors with sufficient context for debugging
- Use appropriate error types/classes
- Clean up resources in error cases (use try/finally or context managers)

## Specific Practices
- Validate inputs early
- Don't catch exceptions you can't handle
- Include error codes for user-facing errors
- Distinguish between expected errors (validation) and unexpected errors (bugs)

# Workflow

## Development Process
- Be sure to lint and type check when you're done making a series of code changes
- Run tests before committing
- When presented with a Github link, use the github CLI to appropriately interact with it
- When creating context files, prefix the filename with `CC-` and use kebab-case for the filename
- Review your own changes before pushing (git diff)

## Tools & Commands
- Use GitHub CLI for PR/issue operations when available
- Prefer specialized tools (Read, Edit, Write) over bash commands for file operations
- Run common checks automatically: lint, test, type-check, build

# Security

## Best Practices
- Never commit secrets, tokens, or credentials
- Use environment variables for configuration
- Validate and sanitize all user input
- Follow the principle of least privilege
- Keep dependencies up-to-date
- Review security advisories for dependencies
