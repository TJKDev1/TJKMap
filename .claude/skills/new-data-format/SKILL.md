---
name: new-data-format
description: Procedure for creating or changing any persisted data format (tile regions, waypoints JSON, config, themes, HUD layout, network packets). Formats are public contracts — spec first, version always.
---

# Data formats: spec first, version always

Open data is a core promise (VISION principle 4). Third parties parse these files.

## Procedure

1. **Doc before code.** Write/update `docs/format-<name>.md`: layout (field table for binary, JSON schema-by-example for JSON), version number, endianness/encoding, evolution rules. For packets: payload id + when sent.
2. **Version field is mandatory** — first thing written, first thing read.
3. **Reader rules:**
   - Older version than current → migrate or read-compat path. Never silently drop user data.
   - Newer/unknown version → **fail soft**: for tiles, discard-and-rescan; for waypoints/config, back the file up untouched (`.bak-v<N>`) and start fresh — never delete or overwrite unknown data (AGENTS.md pitfall).
   - Corrupt data → log warning with file path, recover per above; never crash the game for a bad map file.
4. **Writer rules:** atomic writes only (temp file + rename). Batched writers must flush on world leave.
5. **Changing an existing format:** bump the version, keep the old reader, add a migration test with a fixture file of the old version committed under test resources.

## Checklist

1. [ ] `docs/format-*.md` updated in the same change.
2. [ ] Version bump if layout changed.
3. [ ] Round-trip unit test (write → read → equals).
4. [ ] Unknown-version + corrupt-input tests (fail soft, no data loss).
5. [ ] Old-version fixture + migration test when evolving a format.
6. [ ] Atomic write verified (no direct `FileOutputStream` to the live file).
