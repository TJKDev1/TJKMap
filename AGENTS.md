# AGENTS.md — rules for AI agents working in this repo

This is the canonical agent instruction file. `CLAUDE.md` includes it by reference. Human contributors: read `CONTRIBUTING.md` (agents should read it too).

## What this project is

TJK's Minimap (`tjkmap`) — client-only Fabric minimap/world-map mod built as a framework: core engine + public API, all features (radar, cave mode, …) are addons on that API. Read in this order before non-trivial work:

1. `VISION.md` — goals and **locked decisions** (do not relitigate them)
2. `SPEC.md` — module specs and contracts
3. `PLAN.md` — task list; every code change should map to a task ID

> **⚠ Phase S incomplete:** the automated gates referenced below (Gradle apiJar dogfood enforcement, ArchUnit, checkstyle, CI `check`) do NOT exist yet — Phase S tasks create them. Until then the rules apply **manually**: re-check them yourself before every commit, or run the `rules-reviewer` subagent. Remove this notice when S1.6/S1.7 land.

## Hard rules (violating these = wrong PR, no matter how nice the code)

1. **Dogfooding:** addon modules (`addons/*`) may import `dev.tjk.tjkmap.api.*` ONLY. Never `internal.*`. The build enforces this; do not weaken the enforcement.
2. **API/internal split:** no `internal.*` type in any `api.*` method signature, field, or supertype.
3. **No new dependencies.** Fabric API only. Do not add libraries, not even "small" ones. Locked decision.
4. **Threading:** never touch world/chunk objects off the client thread. Scanning works on snapshots captured on-thread (SPEC §3.1).
5. **No hardcoded colors** in render/HUD code — go through `ThemeApi.color(key)`. Checkstyle blocks it; don't suppress.
6. **Data formats are contracts.** Any change to tile/waypoint/config/theme/packet formats: bump the format version AND update the matching `docs/format-*.md` in the same change.
7. **Public API changes:** javadoc required; log breaking changes in `docs/api-changes.md`; regenerate `docs/api.md` (`./gradlew apiDocs`).
8. **Client-only.** No server-side code paths. Capability handshake is receive-only (SPEC §3.9) and must stay non-bypassable — never add an override for server verdicts.
9. **Locked decisions** in VISION.md's table (loader, language, license, mod id, dependency policy, …) are not up for discussion in a PR. Propose changes in an issue instead.

## Working conventions

- **One task = one change.** Pick a task ID from `PLAN.md`, respect its listed deps, tick the checkbox/status when done. Task too big? Split it in PLAN.md first.
- **Spec first for formats and APIs:** when a task says "spec first", write/update the doc, then implement.
- **Tests per Definition of Done** (SPEC §10): `./gradlew check` green = compile + unit + ArchUnit + checkstyle. New logic that is testable without MC bootstrap gets a plain JUnit test.
- **Java style:** Java 21, no `var` in public API signatures' surrounding code where it hurts clarity, no `System.out` (use SLF4J logger per class). Match surrounding code.
- **Identifiers:** all registered things use `Identifier` with the owning mod's namespace (`tjkmap:` for core, `tjkmap-radar:` etc. for addons).
- **Commits:** Conventional Commits (`feat(core): …`, `fix(radar): …`, scopes = module names). Reference the PLAN task ID in the body.

## Build & test commands

```bash
./gradlew build          # everything
./gradlew check          # tests + arch tests + checkstyle (CI gate)
./gradlew :core:test     # core unit tests only
./gradlew runClient      # dev client with bundle
./gradlew apiDocs        # regenerate docs/api.md (llms.txt)
./gradlew :bundle:build  # the jar players install
```

(Until Phase S is complete some of these don't exist yet — Phase S tasks create them; keep this list in sync.)

## Repo map

```
core/                 engine + public API (api/* published, internal/* private)
addons/radar/         first-party addon + RadarApi
addons/cavemode/      first-party addon
addons/importer/      post-0.1
bundle/               jar-in-jar player artifact
addon-template/       third-party scaffold (has own AGENTS.md/skills)
docs/                 api.md, format-*.md, decisions.md, kickstart-prompt.md, addon-guide.md
scripts/              sync-skills.* (mirror .claude/ -> .agents/), agent-edit-check.ps1 (hook)
.claude/skills/       repo workflow skills — SOURCE OF TRUTH
.claude/agents/       repo subagents (task-implementer, rules-reviewer, spec-scout) — SOURCE OF TRUTH
.agents/              generated mirror of .claude/skills + .claude/agents — never edit by hand
SPEC.md PLAN.md VISION.md CONTRIBUTING.md
```

## Skills

Repo skills live in `.claude/skills/` (source of truth). `.agents/` is a **generated mirror** — never edit it by hand; after changing anything under `.claude/skills/` or `.claude/agents/`, run `scripts/sync-skills.ps1` (Windows) or `scripts/sync-skills.sh` and commit both. CI (`agents-hygiene.yml`) fails if the mirrors differ.

- `new-api-surface` — checklist for adding/changing public API
- `new-map-layer` — implement + register a MapLayer correctly
- `new-data-format` — versioned format + doc + round-trip test procedure
- `plan-task` — how to pick up, execute, and close a PLAN.md task

Use them; they encode the Definition of Done.

## Subagents

Repo subagents live in `.claude/agents/`:

- `task-implementer` — implements exactly one PLAN.md task (validates deps, spec-first, updates Status)
- `rules-reviewer` — read-only pre-commit check of a diff against the hard rules; run it before every commit while Phase S gates don't exist
- `spec-scout` — read-only "what do the docs say / was this decided" lookups across VISION/SPEC/PLAN/decisions.md

## Decision log

`docs/decisions.md` records settled implementation decisions (spike outcomes, tech choices). Before proposing an approach, grep it — don't relitigate. When you close a spike task, add a row.

## Pitfalls

- Loom/Fabric dev runs need `--refresh-dependencies` after MC version bumps.
- Windows dev environment: paths with spaces (this repo's folder has one) — quote paths in scripts.
- Region files under `<gamedir>/tjkmap/` are user data — never write migration code that deletes on unknown version; fail soft to rescan (SPEC §3.2).
- Freezable registries throw after addon init — register during `onInitialize` only.
