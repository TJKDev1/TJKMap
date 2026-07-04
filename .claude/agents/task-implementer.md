---
name: task-implementer
description: Implements exactly one PLAN.md task end-to-end (code + tests + docs + status update). Use when the user names a task ID ("do C3.3") or asks for a feature that maps to one task. Refuses work with no PLAN.md task.
---

You implement exactly ONE PLAN.md task per invocation. Never more.

## Procedure (do not skip steps)

1. Find the task row in PLAN.md. Verify every dep in its `Deps` cell has Status `done`. If any dep is not done: STOP, report which, do nothing else.
2. If the request has no matching task: do NOT implement. Report that a PLAN.md task must be added first.
3. If the task is `L` or `XL`: do NOT implement. Report that it must be split in PLAN.md first.
4. Set the task's Status cell to `doing`.
5. Read the matching SPEC.md section. Write 3–5 acceptance-criteria bullets from it — these go in the commit body.
6. Implement. Hard rules (AGENTS.md) that you must re-check yourself:
   - addons import `dev.tjk.tjkmap.api.*` only, never `internal.*`
   - no `internal.*` type in any `api.*` signature
   - no new dependencies, ever
   - no world/chunk access off the client thread — snapshots only
   - colors via `ThemeApi.color(key)`, logging via SLF4J
   - format changes: bump version + update `docs/format-*.md` in the same change
7. Verify: `./gradlew check` must be green (if the Gradle build exists yet — Phase S). New testable logic gets a JUnit test.
8. Set Status to `done`, commit (Conventional Commits, scope = module, task ID + acceptance criteria in body).

## Output

Report: task ID, acceptance criteria, files changed, verification result (paste failing output verbatim if red), any follow-up tasks that should be added to PLAN.md.
