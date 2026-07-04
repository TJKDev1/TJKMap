# Contributing to TJK's Minimap

Contributions welcome — from humans, humans with AI assistants, and autonomous agents. AI-assisted PRs are explicitly fine here; we tool for them. What matters is that the rules below hold.

## Before you start

1. Read `VISION.md` — especially the **locked decisions** table. PRs that fight a locked decision get closed; open an issue instead.
2. Read `SPEC.md` for the module you're touching.
3. Find (or add) your task in `PLAN.md`. One task = one PR. Mention the task ID in the PR description.
4. If you use an AI agent, point it at `AGENTS.md` (Claude Code picks it up via `CLAUDE.md` automatically).

## The non-negotiables

These are enforced by the build (`./gradlew check`) — CI must be green:

- Addons import `dev.tjk.tjkmap.api.*` only, never `internal.*`.
- No `internal.*` types in `api.*` signatures.
- No dependencies beyond Fabric API.
- No hardcoded colors in render/HUD code (use `ThemeApi`).
- No `System.out` — SLF4J loggers.

And enforced by review:

- Format changes bump the format version and update `docs/format-*.md` in the same PR.
- Public API changes have javadoc, appear in regenerated `docs/api.md`, and breaking changes are logged in `docs/api-changes.md`.
- World/chunk access only on the client thread (see SPEC §3.1 for the snapshot pattern).
- Client-only: nothing that loads server-side; capability handshake stays non-bypassable.

## Workflow

```bash
git checkout -b feat/<task-id>-short-name
./gradlew check        # must pass locally before pushing
./gradlew runClient    # manual verify for anything visual
```

- **Commits:** Conventional Commits — `feat(core): ...`, `fix(radar): ...`, `docs: ...`. Scope = module name. Task ID in the body.
- **PR description:** what + why + task ID + how you verified it (tests / runClient / both). For visual changes attach a screenshot.
- **Tests:** anything testable without booting Minecraft gets a plain JUnit test (formats, math, scheduling, parsing). See SPEC §9/§10.

## AI-assisted contributions

- You own what your agent produces. Review its diff like you wrote it, because for review purposes you did.
- Don't paste raw agent transcripts into PRs; the description should read like an engineer wrote it (your agent can draft it — see `.claude/skills/plan-task`).
- Agents get the same CI, the same review, the same standards. "The AI did it" is not a defect category.
- Building an *addon* rather than contributing to core? Start from `addon-template/` — it has its own AGENTS.md, skills, and `docs/kickstart-prompt.md` is a one-paste bootstrap for any chatbot.

## Reporting bugs / proposing features

- Bugs: MC version, mod version, other map-adjacent mods installed, logs, repro steps.
- Features: check ROADMAP.md and VISION.md scope first. Core stays small — many features belong in an addon (possibly yours!).

## License

MIT. By contributing you agree your contribution is MIT-licensed. No CLA.
