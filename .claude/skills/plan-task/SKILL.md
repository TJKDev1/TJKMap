---
name: plan-task
description: Workflow for picking up, executing, and closing a PLAN.md task in this repo. Use whenever starting any implementation work, when the user names a task ID (e.g. "do C3.3"), or when a request has no matching task.
---

# Executing a PLAN.md task

## 1. Select & validate

- Locate the task ID in `PLAN.md`. Confirm every listed dep has Status `done`. If a dep is open, stop and report — don't build on missing foundations.
- Set the task's Status cell to `doing` when you start.
- Write 3–5 acceptance-criteria bullets from the relevant SPEC.md section; they go in the commit/PR body.
- No matching task for the request? Draft a new task row (ID in the right phase, complexity, deps), add it to PLAN.md, and confirm scope with the user before implementing.
- Task feels bigger than `L`? Split it into subtasks in PLAN.md first.

## 2. Read contracts

- Read the relevant SPEC.md section (§ references in PLAN rows and module names map to SPEC §3.x).
- If the task says "spec first" (formats, packets, APIs): write/update the doc (`docs/format-*.md` or javadoc), then implement.

## 3. Implement

- Respect AGENTS.md hard rules (dogfooding, no internal leaks, no deps, threading, ThemeApi, client-only).
- New public API → also run `./gradlew apiDocs` and check `docs/api-changes.md` for breaking changes.
- Related skills: `new-api-surface`, `new-map-layer`, `new-data-format`.

## 4. Verify (Definition of Done, SPEC §10)

```bash
./gradlew check      # unit + ArchUnit + checkstyle — must be green
./gradlew runClient  # if behavior is visual/interactive
```

## 5. Close out

- Set the task's Status cell to `done` in PLAN.md (append PR link if there is one).
- Commit: Conventional Commits, scope = module, task ID in body.
- Summarize: what changed, how verified, any follow-up tasks added to PLAN.md.
