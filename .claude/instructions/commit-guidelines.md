# Commit Guidelines

Use these guidelines when writing git commit messages for the VESPR Wallet project.

This guide is about commit message content and structure, not about what should be committed. You should already have decided what changes to commit and staged them.

## Ticket Number

- Always include the ticket number if available.
- If not provided, extract from your current branch (e.g., linear/ves-375-description → [VES-375]).
- Use git branch --show-current if unsure.

## Commit Message First Line 1. Include ticket number (if any) 2. Include component name 3. Format:

[Ticket ID][Component] Brief description

Examples:
[VES-123][UI] Remove wave gesture listener from lock screen
[VES-124][Settings] Add toggle for proximity sensor feature

## Commit Categories

Always split changes by category, using one or more of these tags:

- [CHORE] – Maintenance tasks that don’t affect app behavior (cleanup scripts, update configs, dependency bumps, lint fixes, removed imports, removed unused variables, minor non-functional refactors like variable name change, etc.)
- [FEAT] – New user-facing features (staking dashboard, dark mode toggle)
- [FIX] – Bug fixes (crash on launch, sync issues)
- [REFACTOR] – Bigger internal changes that don’t affect functionality (rename, restructure, cleanup) but are generally larger in scope and can be seen as a regression risk. Very simple cleanup and renames should be marked as CHORE.
- [TEST] – Add, update, or remove tests
- [DOCS] – Documentation only (README, inline docs)
- [SECURITY] – Security fixes or hardening (patch CVE, input validation)

## Example Commit

```
[VES-123][Component] Brief description of change

[CHORE]
- Update CI workflow for new Node.js version

[FEAT]
- Add settings import/export

[FIX]
- Resolve crash when importing wallet
```

## Commit Process

1. Check branch for ticket number.
2. Read staged changes (ignore unstaged changes)
3. Write commit message using the format above.

## Good Practices

- Be specific: “Fix wallet sync null pointer exception” beats “Fix bug”
- Group related changes: Don’t mix unrelated work
- Present tense: “Add”, not “Added”
- Reference affected files/components where relevant
- First line ≤ 60 chars: Put details in body if needed
- Blank line between subject and body
- Bullet points for multiple items
- Categorize every change by tag(s)

## If No Ticket

If there’s truly no ticket (rare), start with the relevant category tag(s) in the first line (e.g., [DOCS] Update README for v2.0 launch).

## Other instructions

- Do not add anything like "Generated with Claude code" or similar.
- Do not add anything like "Co-authored by Claude code" or similar.
- Do not add any remarks about Claude being involved in the process of committing.

## Modifiying generated files

- When generated files are modified, we should not mention this explicitly in changelog.
- Exception: If let's say we updated some deps (or changed their config) and a lot of generated files are changed as a consequence, you should mention a CHORE about many files being re-generated.