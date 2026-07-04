# TJK's Minimap — Implementation Plan

> Execution order for [SPEC.md](SPEC.md). Fine-grained, dependency-ordered, one task ≈ one PR (or less).
>
> **Complexity:** `XS` < 1 h · `S` ≈ half day · `M` ≈ 1–2 days · `L` ≈ 3–5 days · `XL` = must be split before starting.
> **Status:** every row has a `Status` cell: `todo` → `doing` → `done` (append PR link, e.g. `done [#12](…)`). Update it when you start and when you finish. Tasks list hard deps by ID; anything not listed as a dep can be parallelized.
>
> **Rules for agents:**
> - Before starting a task, derive 3–5 acceptance-criteria bullets from the relevant SPEC.md section and put them in the PR/commit body. No criteria = you haven't read the spec.
> - `L` tasks must be split into `S`/`M` subtasks in this file before an agent starts them (same rule as `XL`).

## Phase S — Project setup

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| S1.1 | Gradle multi-module skeleton: root + `core`, `addons/radar`, `addons/cavemode`, `bundle`, `addon-template`; Loom applied; empty mods compile | M | — | todo |
| S1.2 | Pin toolchain: `libs.versions.toml` (MC version, loader, Fabric API, Java 21), `gradle.properties` conventions | S | S1.1 | todo |
| S1.3 | `fabric.mod.json` for every module: client-only env, `tjkmap` mod id in core, addon ids (`tjkmap-radar` etc.), entrypoint declarations | S | S1.1 | todo |
| S1.4 | `apiJar` task in core: filtered artifact exposing only `dev.tjk.tjkmap.api.*`; addons depend on it (dogfood enforcement) | M | S1.1 | todo |
| S1.5 | Bundle module: jar-in-jar `include` of core + addons; verify one jar loads in dev client | S | S1.3 | todo |
| S1.6 | Test infra: JUnit 5 wiring, ArchUnit module + first rule (`api` ↛ `internal`), checkstyle w/ no-hardcoded-color + no-`System.out` rules | M | S1.1 | todo |
| S1.7 | CI (GitHub Actions): build + `check` on PR, artifact upload; cache Gradle | S | S1.6 | todo |
| S1.8 | Publishing setup: maven-publish for core (+`-api`) and each addon to GitHub Packages (Modrinth/CF deferred to R-phase) | S | S1.4 | todo |
| S1.9 | Client gametest smoke harness: mod loads, one frame renders | M | S1.5 | todo |
| S1.10 | `docs/api-changes.md` + `docs/format-*.md` stubs; docs conventions section in CONTRIBUTING | XS | — | todo |

## Phase C1 — Core: API skeleton & addon loading

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C1.1 | `TjkMapAddon` entrypoint interface + `TjkMapApi` root handle (empty sub-APIs); static `TjkMap.api()` convenience | S | S1.3 | todo |
| C1.2 | Addon discovery + lifecycle: entrypoint scan, init ordering, registration-phase → freeze, world join/leave callbacks | M | C1.1 | todo |
| C1.3 | `disabledAddons` config gate in loader | S | C1.2, C5.2 | todo |
| C1.4 | Event plumbing: `Event<T>` pattern adoption, `api.event` package, lifecycle events published | S | C1.2 | todo |
| C1.5 | Registry base class: id-keyed, freezable, `get/getAll/replace`, inspection API | S | C1.1 | todo |
| C1.6 | ArchUnit rule: addon modules ↛ `internal.*` (compile-enforced by S1.4, test double-checks) | XS | S1.6, C1.2 | todo |

## Phase C2 — Core: chunk scanning & coloring

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C2.1 | `ScannedChunk` model + column data channel abstraction (`ColumnDataProvider` API) | M | C1.5 | todo |
| C2.2 | Chunk snapshot capture on client thread (blocks, biomes, light) — safe handoff object | M | C2.1 | todo |
| C2.3 | Worker pool + priority queue (distance-keyed) + dirty-chunk debounce | M | C2.2 | todo |
| C2.4 | **Spike:** biome tint strategy (precomputed table vs runtime) — decide, document in SPEC §11 | S | C2.2 | todo |
| C2.5 | Surface scan pass: top block, height, water depth, biome, light per column | M | C2.3 | todo |
| C2.6 | Cave strata pass: first air-gap slice below player Y, stored as extra channel | M | C2.5 | todo |
| C2.7 | Block→color map: JSON resource format, loader, vanilla block coverage generator (data-gen or script) | L | C2.4 | todo |
| C2.8 | Height-slope shading + water-depth darkening math (+ unit tests) | S | C2.7 | todo |
| C2.9 | Block-change/light-change event hooks → dirty marking | S | C2.3 | todo |
| C2.10 | Unit tests: scheduler priority, debounce, channel round-trip | S | C2.5 | todo |

## Phase C3 — Core: tile engine & persistence

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C3.1 | Tile model: 512² region texture, chunk→tile compositor writing colored pixels | M | C2.8 | todo |
| C3.2 | Zoom mipmap chain from level-0 tiles | S | C3.1 | todo |
| C3.3 | Binary region format v1: writer + reader + version header (spec first in `docs/format-tiles.md`) | L | C3.1 | todo |
| C3.4 | Forward-incompat soft-fail: unknown version → rescan path | S | C3.3 | todo |
| C3.5 | World identity resolution (SP save name / normalized server address / config override) | S | C3.3 | todo |
| C3.6 | Region file locking decision + impl (lock file, read-only fallback) | S | C3.3 | todo |
| C3.7 | RAM LRU cache w/ MB budget + GPU texture cache + non-blocking eviction | M | C3.1 | todo |
| C3.8 | Write batching: 30 s flush + world-leave flush, atomic writes | S | C3.3 | todo |
| C3.9 | Dimension support: per-dimension storage + active-dimension switch | S | C3.5 | todo |
| C3.10 | Unit tests: format round-trip, corrupt-file recovery, cache eviction | M | C3.3, C3.7 | todo |

## Phase C4 — Core: rendering, HUD, world map

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C4.1 | `MapLayer` API: registration, z-order, minimap/worldmap opt-out flags | S | C1.5 | todo |
| C4.2 | Minimap offscreen framebuffer + composite (mask square/circle, rotation, zoom) | L | C3.7 | todo |
| C4.3 | Tile upload amortization (≤2/frame) + perf counters | S | C4.2 | todo |
| C4.4 | North-lock vs rotate modes, zoom steps + keybinds | S | C4.2 | todo |
| C4.5 | `HudComponent` API + anchor/offset layout engine | M | C1.5 | todo |
| C4.6 | Core HUD components: minimap widget, coords, biome, time lines | S | C4.5, C4.2 | todo |
| C4.7 | HUD layout persistence (`hud-layout.json`) + drag-arrange screen (v0.1 scope: drag minimap, toggle lines) | M | C4.6, C5.2 | todo |
| C4.8 | World map screen: pan/zoom over cached tiles, follow-player toggle | L | C3.7, C4.1 | todo |
| C4.9 | World map dimension switcher (visited dims) | S | C4.8, C3.9 | todo |
| C4.10 | Keybind registration (`M` map, zoom, cave toggle passthrough) | XS | C4.8 | todo |
| C4.11 | Layer stack integration on both surfaces (order per SPEC §3.3) | S | C4.2, C4.8 | todo |
| C4.12 | Perf validation vs SPEC §6 budgets; fix or file follow-ups | M | C4.11 | todo |

## Phase C5 — Core: config & themes

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C5.1 | Lenient JSON reader/writer + atomic save util (+ tests) | S | — | todo |
| C5.2 | Config schema builder API (bool/int-range/enum/color/string/keybind), defaults, load/save per module | M | C5.1, C1.5 | todo |
| C5.3 | Auto-generated config screen from schema: category tree, live-apply, `requiresRestart` flag | L | C5.2 | todo |
| C5.4 | Theme JSON format + loader (built-in + `themes/` dir) + `ThemeApi.color(key)` | M | C5.1, C1.5 | todo |
| C5.5 | Default theme + one alternate (proves theming works) | S | C5.4 | todo |
| C5.6 | Theme hot-reload button + theme picker in config screen | S | C5.3, C5.4 | todo |
| C5.7 | Sweep: all render code reads via ThemeApi (checkstyle already blocks new violations) | S | C5.4, C4.6 | todo |

## Phase C6 — Core: waypoints

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C6.1 | Waypoint model + store + change events + `meta` map (API per SPEC §3.4) | M | C1.5 | todo |
| C6.2 | JSON persistence v1 (schema doc first: `docs/format-waypoints.md`), atomic writes | S | C6.1, C5.1 | todo |
| C6.3 | Map rendering: icons on minimap + world map, off-map edge labels w/ distance | M | C6.1, C4.11 | todo |
| C6.4 | Waypoint CRUD UI: list screen, edit popup, world-map right-click create | M | C6.3, C5.3 | todo |
| C6.5 | Death waypoints: auto-create, style, capped history, config | S | C6.1, C5.2 | todo |
| C6.6 | Query API: by dimension/radius + tests | S | C6.1 | todo |

## Phase C7 — Core: capability handshake

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| C7.1 | `CapabilityApi`: registration, default policy, `isAllowed(id)` | S | C1.5 | todo |
| C7.2 | Packet spec `tjkmap:capabilities` written (`docs/format-capabilities.md`) before impl | S | C7.1 | todo |
| C7.3 | Client receiver: apply verdicts, persist per server, re-check on world join | M | C7.2 | todo |
| C7.4 | Reference sender snippet (server-side plugin/mod example in docs, not shipped) | S | C7.2 | todo |

## Phase A — First-party addons

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| A1.1 | Radar addon skeleton: entrypoint, config section, capability registrations (`radar.players/mobs/...`) | S | C1.2, C5.2, C7.1 | todo |
| A1.2 | Entity scanning (categories: players/hostiles/passives/items) client-thread cheap-pass | M | A1.1 | todo |
| A1.3 | Dot rendering as `MapLayer`, theme-keyed colors, both surfaces | M | A1.2, C4.11 | todo |
| A1.4 | `RadarApi` v0: custom categorizers + icons; publish artifact | M | A1.3, S1.8 | todo |
| A1.5 | Cavemode addon skeleton: entrypoint, config, capability, keybind toggle | S | C1.2, C5.2, C7.1 | todo |
| A1.6 | Activation heuristic (below surface stratum / low sky light) + manual override | M | A1.5, C2.6 | todo |
| A1.7 | Cave slice rendering: recolor pipeline consuming cave channel | L | A1.6, C3.1 | todo |
| A1.8 | Dogfood audit: confirm both addons touch zero `internal.*` (arch test green by construction) | XS | A1.4, A1.7 | todo |

## Phase D — Docs & ecosystem artifacts

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| D1.1 | `apiDocs` Gradle task: regenerate `docs/api.md` (= `llms.txt`) from `api.*` sources | M | C1.1 | todo |
| D1.2 | `docs/kickstart-prompt.md`: condensed API + minimal addon source + build setup, verified to produce compiling addon | M | D1.1, A1.4 | todo |
| D1.3 | Addon guide (`docs/addon-guide.md`): walkthrough from template to published jar | M | D1.2 | todo |
| D1.4 | addon-template: working scaffold repo content (build, entrypoint, example layer, AGENTS.md, CLAUDE.md, `.claude/skills/` create-addon/add-map-layer/debug-addon) | L | A1.4 | todo |
| D1.5 | Format docs finalized: tiles, waypoints, capabilities, themes, config | S | C3.3, C6.2, C7.2 | todo |
| D1.6 | README.md: player-facing + dev-facing sections, badges, screenshots | S | R1.1 | todo |

## Phase R — Release 0.1

| ID | Task | Cx | Deps | Status |
|---|---|---|---|---|
| R1.1 | Manual test matrix run (SP, MP, dimensions, death, themes, addon disable) — file bugs | M | A1.8, C4.12 | todo |
| R1.2 | Bug-fix budget for R1.1 findings | L | R1.1 | todo |
| R1.3 | Version stamping, changelog, `api-changes.md` review | S | R1.2 | todo |
| R1.4 | Modrinth + CurseForge listings, bundle upload; core to Maven | M | R1.3 | todo |
| R1.5 | ROADMAP.md: post-0.1 items (importer, slime chunks, waypoint sets/sharing, biome colors, nether world-map, perf, API 1.0) | S | R1.3 | todo |

## Dependency graph (phase level)

```
S ──→ C1 ──→ C2 ──→ C3 ──→ C4 ──┐
       │              ┌────────┤
       ├──→ C5 ───────┤        ├──→ A ──→ D ──→ R
       ├──→ C6 (needs C4.11) ──┤
       └──→ C7 ────────────────┘
```

Parallel lanes once C1 lands: {C2→C3→C4} · {C5} · {C7}. C6 needs C4.11 for rendering but C6.1/C6.2/C6.6 can start after C1+C5.1.

## Counting

~70 tasks. Rough load: XS×4, S×30, M×24, L×7, XL×0. Nothing bigger than L by design — if a task grows, split it and update this file.
