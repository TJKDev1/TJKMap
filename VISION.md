# TJK's Minimap — Vision

> **"There are many map mods, but this one is yours."**

Open-source minimap & world map mod for Minecraft, built as a **framework first, feature mod second**. Competitor to Xaero's Minimap — but where Xaero is a closed monolith, TJK's Minimap is an open map engine whose own features are addons, proving an API anyone can build on.

## Positioning

- **For players:** fast, polished minimap + world map with extreme customizability — themes, HUD layout, shareable configs. One jar, works out of the box.
- **For addon devs:** the friendliest map platform in modded Minecraft. Stable API, real docs, first-party addons as living examples, AI-assisted development embraced.
- **The differentiator Xaero can't copy:** architecture. Core = map engine + API. Our features (radar, cave mode, …) consume the same public API third parties get. If we can build it, so can you.

## Core principles

1. **Framework core.** Core = chunk scanning, tile render pipeline, waypoint store, HUD layout, theme system, capability/networking hooks, addon loading. Everything else is an addon.
2. **Dogfooded API.** First-party addons use only the public API — no backdoors into core internals. Enforced by build structure (addons depend on the published API artifact).
3. **Minimal hardcoding.** Data-driven registries and events everywhere: renderers, layers, themes, providers are all swappable/replaceable without touching original code.
4. **Open data.** Versioned JSON waypoints. Documented binary region format for map tiles. Converter CLI + Xaero/JourneyMap importer (early first-party addon — kills switching cost).
5. **Layered extensibility.** Every first-party addon publishes its own maven artifact and its own extension points (e.g. `RadarApi`). Deep "Xaero Plus"-style addons are a supported pattern, not a hack. Mixins into our open MIT code are the escape hatch — and a signal to promote that spot to real API.
6. **Addons are replaceable.** Bundled addons ship as separate jars inside the bundle; core config can disable any of them. Don't like our radar? Ship your own.
7. **AI-native ecosystem.** AI-assisted addon dev is embraced and tooled for, not shamed. Shipped artifacts:
   - **`AGENTS.md`** (cross-agent standard) + **`CLAUDE.md`** in core repo and addon-template — build commands, conventions, API pointers, pitfalls.
   - **Skills** (`.claude/skills/`) in the addon-template: e.g. `create-addon` (scaffold + register), `add-map-layer`, `debug-addon` — small, focused, agent-runnable.
   - **Kickstart prompt** (`docs/kickstart-prompt.md`): one self-contained paste for any chatbot — condensed API surface, minimal working addon source, build setup, hard rules. Output: an addon that compiles and runs. Not great, but works — the "hello world in one paste" for the ecosystem.
   - **Single-file API reference** (`docs/api.md`, also served as `llms.txt`): whole public API in one markdown, regenerated each release, made for context windows.
8. **Server respect via capabilities.** Core is client-only (no server component), but ships a small capability handshake: servers can send a packet disabling registered capabilities (e.g. radar); core enforces it. Addons register their features as capabilities. Full power on singleplayer/own servers; real, non-bypassable-by-design control for server owners.

## Scope decisions (locked)

| Decision | Choice |
|---|---|
| Loader | Fabric only (for now) |
| MC versions | 26.2+, major releases only, no snapshots; aim to cover 26.x |
| Language | Java (addon-dev & AI-codegen friendly) |
| License | MIT |
| Core vs addon line | World map = core (too entangled with tile engine). Radar, cave mode presentation = first-party addons |
| Networking | Core client-only + capability handshake; server interaction beyond that = addon territory |
| Addon browser | Not core; an addon could build one. Theme system in core, theme sharing possible |
| Distribution | One bundled jar for players (jar-in-jar); core published separately to Maven/Modrinth for devs |
| Mod ID | `tjkmap` (entrypoint `tjkmap`, data folders `tjkmap/`, maven group `dev.tjk.tjkmap`) |
| Dependencies | Fabric API only — no third-party libs; own config screens/format (fits theming + zero addon-dev friction) |
| API stability | 0.x breaks freely (documented loudly); 1.0 freezes API → semver + deprecation cycles |
| Hosting | GitHub personal repo (org later if it grows); distribute on Modrinth + CurseForge |

## Repository structure

Monorepo, Gradle multi-module:

```
tjks-minimap/
  core/            # engine + public API → published maven artifact
  addons/
    radar/         # first-party addon, doubles as example
    cavemode/
    importer/      # Xaero/JourneyMap data importer
  bundle/          # jar-in-jar packaging → the jar players install
  docs/            # api.md (single-file API ref / llms.txt), kickstart-prompt.md, addon guide
  addon-template/  # scaffold for third-party devs, incl. AGENTS.md, CLAUDE.md, .claude/skills/
  AGENTS.md        # + CLAUDE.md at repo root for contributors' agents
```

Third-party addons live in their own repos, built from the template: depend on the core artifact, declare a `tjks-minimap` entrypoint, register against the API. Normal Fabric mod — drop in mods folder.

## v0.1 scope

**Core:** minimap render (rotate/north-lock, zoom) · world map (pan, zoom) · waypoints (+ death waypoints) · dimension support · tile persistence · theme + HUD layout foundations · addon loading + API v0.

**First-party addons:** radar (entity dots) · cave mode.

**Post-0.1 (ROADMAP.md):** importer addon, slime chunks, waypoint sets/sharing, capability handshake, biome colors, nether/cave world-map modes, performance passes, API stabilization → 1.0 = feature parity with Xaero + frozen API v1.
