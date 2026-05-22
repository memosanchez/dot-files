---
name: confirm-findings
description: Re-verify a prior review's findings by reading the actual file lines, grading each YES/NO with a reason, and producing a grouped, actionable report. Use after a code review or audit has produced a list of findings and you want them re-checked before acting on them.
disable-model-invocation: true
allowed-tools: Read Grep Glob
---

# confirm-findings

Re-verify each finding from the prior review before it's acted on. Treat the prior pass as a hypothesis, not a fact.

## Protocol

1. **Read & confirm** — for every finding:
   - Open the file with the Read tool and read the cited lines directly. Don't trust memory or summaries from the prior turn.
   - Cross-check relevant documentation if the finding references an API, library behavior, or convention.
   - Follow the code path far enough to understand the actual impact.

2. **Grade** — for each finding, state **YES** (confirmed) or **NO** (rejected) with one specific reason citing the file and lines you read. Check the finding against the rules in `CLAUDE.md` before grading.

3. **Report** — group confirmed findings by severity:
   - **CRITICAL / HIGH / MEDIUM / LOW**
   - Each entry includes: `path:line`, a one-line description, a minimal remediation snippet, and a short comment to leave for the engineer.
   - List rejected findings at the end with the reason they were dropped.

## Engineer comment tone

- **Unclear finding** → phrase the comment as a question ("Should this also handle the empty-array case?"). If you're not sure it's a real issue, don't assert that it is.
- **Clear finding** → phrase the comment as a statement ("Missing null check on `user`. Line 42 will throw if the upstream call returns null.").
- **Always speak with humility** — no "obviously", "just", "simply", or blame. Aim for a peer offering a careful read, not a verdict.
