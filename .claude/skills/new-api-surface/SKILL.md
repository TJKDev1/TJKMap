---
name: new-api-surface
description: Checklist for adding or changing public API (anything under dev.tjk.tjkmap.api). Use for new interfaces, methods, events, registries, or any signature change in api packages.
---

# Adding / changing public API

The API is the product. Every surface here is a promise to addon devs (soft in 0.x, hard after 1.0).

## Design rules

- Interfaces in `api.*`; implementation in `internal.*`. **No `internal.*` type may appear in any api signature, field, or supertype** (ArchUnit enforces).
- Registration takes `Identifier` (namespace = caller's mod id). Registries expose `get/getAll/replace` where safe, and freeze after addon init.
- Events: small dedicated callback interfaces (Fabric `Event<T>` style). No monolithic listeners.
- Accessors hang off `TjkMapApi` (the handle passed to addons) — avoid new statics; `TjkMap.api()` is the only sanctioned static.
- Ask: could the radar or cavemode addon use this? If yes, wire one of them to it (dogfooding proof). If no first-party consumer and no test exercises it, question whether it belongs in v0.x.

## Checklist

1. [ ] Javadoc on every public type/method — written for an addon dev who has only `docs/api.md`, not our source.
2. [ ] Package has `package-info.java` (create if new package).
3. [ ] Breaking change (signature/behavior)? → entry in `docs/api-changes.md` with migration hint.
4. [ ] `./gradlew apiDocs` regenerated `docs/api.md`.
5. [ ] Unit or gametest exercises the new surface.
6. [ ] `./gradlew check` green (ArchUnit will catch internal leaks).
7. [ ] If this API exists because someone mixin'd into that spot: note it — mixin hotspots are promotion signals (VISION principle 5).
