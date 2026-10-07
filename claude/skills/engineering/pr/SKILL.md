---
name: pr
description: "Use when writing a PR body."
---

Write the PR body to this template:

```markdown
## Summary

- <what changed and why: 1–3 bullets>

## Test plan

- [ ] <a step the reviewer performs by hand>
```

Write in the user's domain language from `GLOSSARY.md`, with no preamble. The reviewer reads the actual diff in GitHub's Files Changed tab, so the body carries what the diff can't show.

## Summary

Lead each bullet with the _why_: the motivation, the constraint, the reason a line stays or goes. Name the change itself in a few words; the diff holds the detail.

When the change is **structural** (a flow rewired across files, a refactor that moves responsibility, new UI composition), add the smallest view that shows the new shape, right under the bullet it supports: a call tree, a component tree, a shallow file tree, or a Mermaid diagram.

```text
submitForm
  createSession
    persistPrompt
    expandSkillMention   # new
  navigateToSession
```

## Test plan

List only manual checks a reviewer performs by hand: the behaviour to try, the edge case to poke. CI and hooks already prove lint, types, tests, and build.

For a **visual** change, add before/after screenshots when the environment can capture them.

## Risk

Add a `## Risk` section only for a **one-way door**: a change that is hard to walk back, such as a data migration, a deletion, a public API or contract change, or config other systems depend on. Say what breaks if the change is wrong and how to recover.
