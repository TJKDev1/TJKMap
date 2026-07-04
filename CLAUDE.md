# CLAUDE.md

@AGENTS.md

## Claude-specific notes

- Follow AGENTS.md as the single source of truth for rules; this file only adds Claude workflow hints.
- Before implementing, state which PLAN.md task ID you are executing. If the request maps to no task, propose a PLAN.md addition first.
- Use the repo skills in `.claude/skills/` when their trigger matches (API changes, map layers, data formats, task workflow).
- After editing anything under `.claude/skills/` or `.claude/agents/`, run `scripts/sync-skills.ps1` and commit the regenerated `.agents/` mirror in the same commit. Never edit `.agents/` directly.
- Prefer `./gradlew check` over full `build` for iteration; run `runClient` only when render behavior must be observed.
