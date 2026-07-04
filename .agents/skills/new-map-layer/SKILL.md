---
name: new-map-layer
description: Implement and register a MapLayer (drawing on minimap and/or world map) correctly. Use for any feature that draws dots, icons, overlays, or highlights on map surfaces.
---

# Implementing a MapLayer

`MapLayer` (`api.map`) is THE way to draw on map surfaces. Never mixin into `internal.render` for this.

## Contract

- Register during addon `onInitialize` via `TjkMapApi` map registry with: `Identifier` id, z-index, surface flags (minimap / worldmap / both).
- Layer stack order (SPEC §3.3): `tiles → grid/overlays → addon MapLayers (by z) → waypoints → entity layers → frame/mask`. Pick z relative to that; don't fight waypoints for the top.
- Render callback gives you a transform context (world↔screen mapping, zoom, rotation). **Draw through the provided `GuiGraphics`; never assume north-up** — minimap may be rotating.
- Colors: theme keys via `ThemeApi.color(...)`, never literals (checkstyle blocks it). Register default values for your keys so unthemed setups work.
- Perf: render runs every frame. Precompute per-tick or on data-change events; the render body should be draw calls only. Minimap frame budget is 0.3 ms total (SPEC §6) — you get a slice of that.
- Per-column data needed? Contribute a channel via `ColumnDataProvider` (see `new-data-format` if it persists) instead of scanning the world yourself.
- Capability-gated feature (reveals entities/terrain info)? Register a capability id and check `CapabilityApi.isAllowed` in the layer — servers must be able to turn you off (AGENTS.md rule 8).

## Checklist

1. [ ] Registered with id, z, surface flags in `onInitialize`.
2. [ ] Theme keys registered + used; zero color literals.
3. [ ] No per-frame allocation-heavy work; data prep is event/tick driven.
4. [ ] Rotation handled (test with minimap rotate mode ON).
5. [ ] Capability check if the layer reveals gameplay-relevant info.
6. [ ] Config toggle via config schema API if user-facing.
7. [ ] `./gradlew check` + visual verify in `runClient` (both surfaces, both rotate modes, zoomed in/out).
