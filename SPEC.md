# TJK's Minimap — Specification

> Companion to [VISION.md](VISION.md) (the *why*) and [PLAN.md](PLAN.md) (the *when/how*). This document is the *what*: every module, its responsibilities, its boundaries, and its contracts.
>
> Status: **draft for v0.1**. API is 0.x — breaks freely, documented loudly.

---

## 1. System overview

TJK's Minimap (`tjkmap`) is a client-only Fabric mod structured as a **map engine (core)** plus **addons**. Core owns data acquisition, storage, rendering pipeline, and extension points. All features beyond the base minimap/world-map — radar, cave mode, importers — are addons consuming the same public API third parties get.

```
┌─────────────────────────────────────────────────────────┐
│  bundle jar (what players install)                      │
│  ┌───────────────┐  ┌────────┐ ┌──────────┐ ┌────────┐  │
│  │ core          │  │ radar  │ │ cavemode │ │importer│  │
│  │ engine + API  │←─┤ addon  │ │ addon    │ │ addon  │  │
│  └───────────────┘  └────────┘ └──────────┘ └────────┘  │
└─────────────────────────────────────────────────────────┘
        ↑ published separately to Maven for third-party devs
```

Gradle modules: `core`, `addons/radar`, `addons/cavemode`, `addons/importer`, `bundle`, `addon-template`.

**Hard rule (dogfooding):** addon modules depend on core's **published API artifact only** (`dev.tjk.tjkmap:tjkmap-core`). Build fails if an addon references an `internal` package — enforced by package structure + an architecture test (see §12).

## 2. Package layout (core)

```
dev.tjk.tjkmap.api.*        # public, semver-governed (after 1.0)
  api.map                   # layers, tile access, renderers
  api.waypoint              # waypoint store, categories, events
  api.hud                   # HUD components, layout slots
  api.theme                 # theme values, theme registry
  api.event                 # event bus / callback interfaces
  api.capability            # capability registration + queries
  api.config                # addon config registration
dev.tjk.tjkmap.internal.*   # engine — never referenced by addons
  internal.scan             # chunk scanning
  internal.tile             # tile compositor, region files, cache
  internal.render           # GPU textures, draw pipeline
  internal.hud              # HUD layout engine, minimap widget
  internal.worldmap         # fullscreen map screen
  internal.waypoint         # waypoint store impl + persistence
  internal.theme            # theme loading, defaults
  internal.config           # config format, screens
  internal.addon            # addon discovery + lifecycle
  internal.net              # capability handshake
```

## 3. Module specs

### 3.1 Chunk scanner (`internal.scan`)

Turns loaded world chunks into map data.

- **Input:** chunk load/unload events, block-change events, light-level changes.
- **Output:** `ScannedChunk` — per-column: top block state id, height, water depth, biome id, block light, plus a configurable set of **surface strata** for cave-aware consumers.
- **Threading:** scanning off-thread on a dedicated worker pool; reads use chunk snapshots captured on the client thread. Never touch world objects off-thread.
- **Scheduling:** priority queue keyed by distance-to-player; dirty-chunk rescans debounced (default 250 ms).
- **Cave awareness:** scanner records the surface *and* the first air-gap column slice below the player's Y (data only — presentation is the cavemode addon's job).
- **Extension point:** `api.map.ColumnDataProvider` — addons contribute extra per-column data channels (e.g. slime-chunk flag), stored alongside core channels and versioned independently.

### 3.2 Tile engine (`internal.tile`)

Converts scanned chunks into colored tiles and persists them.

- **Tile:** 512×512 px region texture = 32×32 chunks (matches region file granularity). Zoom levels are mipmapped from level 0.
- **Coloring:** block state → color via a data-driven color map (JSON in resources, override-able per theme, biome-tinted for grass/foliage/water). Height shading (slope-based) and water depth darkening applied in the compositor.
- **Persistence:** custom binary region format, one file per region per dimension, under `<gamedir>/tjkmap/worlds/<world-id>/<dimension>/`. Format is **versioned and documented** (`docs/format-tiles.md`): magic, version, per-chunk offsets table, zlib-compressed chunk payloads. Forward-incompatible reads fail soft (rescan).
- **Cache:** LRU of decoded tiles in RAM (configurable MB budget) + GPU texture cache; eviction never blocks render thread.
- **World identity:** singleplayer = save folder name; multiplayer = server address (normalized) — with a per-world override in config for proxied servers.
- **Extension point:** `api.map.TileColorProvider` (replace/augment coloring), `api.map.MapLayer` (draw above/below tiles, ordered by registered z-index).

### 3.3 Render pipeline (`internal.render`)

- Minimap renders to an offscreen framebuffer, then composited into HUD with shape mask (square/circle), rotation, zoom.
- World map renders visible tiles directly with pan/zoom transform.
- All drawing through vanilla `GuiGraphics`/render layers — no custom shaders in v0.1 (keeps compat surface tiny).
- Layer stack (both minimap and world map): `tiles → grid/overlays → MapLayer addons (by z) → waypoints → entity layers (addon) → frame/mask`.
- Budget: minimap composite ≤ 0.3 ms/frame target on mid hardware; tile texture uploads amortized (≤ 2 uploads/frame).

### 3.4 Waypoints (`internal.waypoint`, `api.waypoint`)

- **Model:** `Waypoint { id (UUID), name, pos (BlockPos), dimension, color, icon-id, visible, meta (string map for addons) }`, grouped into **sets**; one implicit default set in v0.1 (multi-set post-0.1).
- **Persistence:** versioned JSON per world (`tjkmap/worlds/<world-id>/waypoints.json`), schema documented in `docs/format-waypoints.md`. Atomic writes (write-temp-rename).
- **Death waypoints:** auto-created on death, auto-styled, capped history (default 3, configurable), removable.
- **API:** full CRUD, query by dimension/radius, change events (`WaypointEvents.ADDED/REMOVED/UPDATED`). Addons store custom data in `meta` — never extra files with their own formats unless they own them.
- **Rendering:** on-map icons + optional in-world beacons deferred (beacons post-0.1); distance labels on HUD edge when off-map.

### 3.5 HUD system (`internal.hud`, `api.hud`)

- **Slots:** anchor-based layout (9 anchors × offset), minimap is just a HUD component in a slot.
- **Components:** `api.hud.HudComponent` — measure + render + optional config screen section. Core ships: minimap, coords line, biome line, time/day line.
- **Layout config:** per-profile JSON, editable in a drag-arrange screen (v0.1: drag minimap + toggle info lines; full freeform arrange post-0.1).
- **Extension point:** addons register `HudComponent`s; they appear in the layout screen automatically.

### 3.6 Theme system (`internal.theme`, `api.theme`)

- Theme = JSON document: palette (named colors), minimap frame/mask textures (resource ids), font-ish choices (scale), waypoint default colors, map color-map overrides.
- Loaded from resources (built-in themes) + `tjkmap/themes/*.json` (user themes). Hot-reloadable via config screen button.
- Every core/addon UI reads colors through `ThemeApi.color(key)` — **no hardcoded colors in render code** (checkstyle rule, see §12).
- Themes are shareable single files by design.

### 3.7 Config (`internal.config`, `api.config`)

- Own format + own screens (locked decision — no Cloth Config).
- Format: JSON5-ish lenient JSON, one file per module: `tjkmap/config/core.json`, `tjkmap/config/<addon-id>.json`.
- **API:** addons declare a config schema (builder: bool/int-range/enum/color/string/keybind), get parsing, defaults, save, and an auto-generated settings section for free.
- Config screen: category tree (core + one node per addon), search box deferred post-0.1.
- All config values live-apply where feasible; ones that can't are flagged `requiresRestart`.

### 3.8 Addon loading (`internal.addon`, `api`)

- Discovery via Fabric entrypoint `"tjkmap"` → `TjkMapAddon` interface: `onInitialize(TjkMapApi api)`.
- `TjkMapApi` is the root handle: accessors for map/waypoint/hud/theme/capability/config registries. Passed in, never statically grabbed (testability; but a static `TjkMap.api()` convenience exists and is documented as second-choice).
- Lifecycle: core init → addons init (registration phase) → registries freeze where freezable → world join/leave callbacks.
- **Disable mechanism:** `core.json` lists `disabledAddons: []`; disabled bundled addons are not initialized (jar still present). Third-party addons: users remove the jar, same as any mod.

### 3.9 Capability handshake (`internal.net`, `api.capability`)

- Addons register features as **capabilities** (`radar.players`, `radar.mobs`, `cavemode`, …) with a default policy.
- Server may send custom payload packet `tjkmap:capabilities` (documented in `docs/format-capabilities.md`) listing forced-off capability ids. Core stores server verdicts and answers `CapabilityApi.isAllowed(id)`.
- **Non-bypassable by design:** capability-gated addons must route feature activation through `isAllowed`; core re-checks on every world join; no API to override a server verdict.
- No server-side component shipped — packet spec is public so any server plugin/mod can implement the sender.

### 3.10 World map screen (`internal.worldmap`)

- Fullscreen screen: pan (drag/keys), zoom (scroll, pinch-steps), waypoint interaction (click → edit popup, right-click → new waypoint), dimension switcher for visited dimensions, follow-player toggle.
- Shares tile cache & layer stack with minimap (layers can opt out of either surface via flags).
- Keybind: `M` default (conflict-safe registration).

### 3.11 First-party addons

**Radar (`addons/radar`)** — entity dots on minimap + world map.
- Entity scanning (players/hostiles/passives/items toggles), dot rendering as a `MapLayer`, per-category colors via theme keys, capability-gated per category.
- Publishes its own artifact + `RadarApi` v0: register custom entity categorizers/icons (deep-addon pattern proof).

**Cave mode (`addons/cavemode`)** — underground presentation.
- Activation heuristics (player below surface stratum / low sky light), renders cave slice channel from core scanner data, manual toggle keybind, capability-gated.

**Importer (`addons/importer`)** — post-0.1, spec'd early because format decisions constrain it. Reads Xaero's & JourneyMap region + waypoint data, converts into tjkmap formats. CLI entry (runnable jar) + in-game import screen.

### 3.12 Bundle (`bundle`)

- Jar-in-jar of core + bundled addons via Fabric's `include`. Its `fabric.mod.json` is the player-facing identity ("TJK's Minimap").
- Version = marketing version; core/addons keep independent versions inside.

## 4. Public API principles

- Interfaces in `api.*` only; implementations internal. No `internal.*` type ever appears in an `api.*` signature (arch-test enforced).
- Registration APIs take ids as `Identifier` (`namespace:path`); addon namespace = its mod id.
- Events: small dedicated callback interfaces (Fabric-style `Event<T>`), never a monolithic listener.
- Everything registered is inspectable/replaceable: registries expose `get/getAll/replace` where safe.
- Each API package has package-info javadoc; `docs/api.md` (single-file reference, doubles as `llms.txt`) is regenerated from source each release by a Gradle task.
- 0.x: breaking changes allowed, each one logged in `docs/api-changes.md`.

## 5. Data formats (all documented in `docs/format-*.md`)

| Format | File | Notes |
|---|---|---|
| Tile regions | `worlds/<w>/<dim>/r.<x>.<z>.tjkr` | binary, versioned, zlib chunks |
| Waypoints | `worlds/<w>/waypoints.json` | versioned JSON schema |
| Config | `config/*.json` | lenient JSON, schema per module |
| Themes | `themes/*.json` | shareable single file |
| HUD layout | `config/hud-layout.json` | per-profile |
| Capability packet | `tjkmap:capabilities` | custom payload, spec public |

## 6. Performance targets (v0.1)

- Scanning: no measurable TPS/FPS hit at 32 render distance while moving (workers ≤ 2 by default).
- Minimap render ≤ 0.3 ms/frame steady state; world map 60 fps while panning on cached tiles.
- RAM: tile cache default 128 MB budget, hard-capped.
- Disk: region writes batched, flushed on world leave + every 30 s.

## 7. Compatibility & constraints

- Fabric only; Fabric API is the sole dependency. MC 26.2+ major releases (locked).
- Java 21 toolchain (or whatever the target MC mandates — pin in `gradle/libs.versions.toml`).
- Client-only: `"environment": "client"` in every `fabric.mod.json`; no classes loaded server-side.
- MIT license, headers not required per-file (LICENSE at root suffices).

## 8. Non-goals (v0.1)

No Forge/NeoForge. No shaders. No web map. No addon browser. No in-world waypoint beacons. No multi-waypoint-sets UI. No snapshot MC support. No config search. No server-side jar.

## 9. Testing strategy

- **Unit:** format encode/decode round-trips, color math, scheduler priority, config schema parsing — plain JUnit, no MC bootstrap where avoidable.
- **Architecture tests:** ArchUnit — `api` never depends on `internal`; addons never import `internal`; no hardcoded colors in render classes.
- **Game tests:** Fabric client gametest for smoke (mod loads, registries populated, minimap renders one frame without throwing).
- **Manual matrix:** per release — SP, MP (vanilla server), dimension switch, death waypoint, theme switch, addon disable.

## 10. Definition of Done (every task in PLAN.md)

1. Compiles, `./gradlew check` green (unit + arch tests + checkstyle).
2. New public API has javadoc + entry regenerated into `docs/api.md`.
3. New data format or format change → format doc updated + version bumped.
4. Addon-visible behavior → dogfooded (used or at least exercised by a first-party addon or test).
5. No `internal` leak into `api` signatures.

## 11. Open questions (resolve before touching related tasks)

- Exact MC target version at dev start (pin in versions.toml, task S1.2).
- Biome tint source: precomputed table vs runtime biome color resolution (perf spike, task C2.4).
- Region file locking strategy for multiple MC instances on one save (task C3.6 decides; likely lock file + read-only fallback).

## 12. Enforcement tooling

- **ArchUnit** test module rules (see §9).
- **Checkstyle/custom lint:** no `new Color(`/hex literals in `internal.render`/`internal.hud` (theme rule), no `System.out`.
- **Gradle:** addons compile against `core-api` artifact (an `apiElements`-filtered jar exposing only `api.*` — built by a `apiJar` task), not the full core jar. Compile-time enforcement of the dogfooding rule.
