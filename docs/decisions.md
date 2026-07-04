# Decision log (ADR-lite)

One line per settled decision: date, decision, reason. Locked *product* decisions live in VISION.md's table; this file records everything else that got decided along the way (spikes, tech choices, format details) so agents can grep "was this already decided?" instead of relitigating.

Add a row when you close a spike task (e.g. C2.4) or make a non-obvious implementation choice. Never delete rows; supersede with a new row referencing the old date.

| Date | Decision | Reason / context |
|---|---|---|
| 2026-07-04 | `.claude/` is the single source of truth for skills & agents; `.agents/` is a generated mirror via `scripts/sync-skills.*` | Two hand-edited copies drift; CI (`agents-hygiene.yml`) enforces identity |
| 2026-07-04 | PLAN.md tracks per-task `Status` column (`todo`/`doing`/`done` + PR link) | Tables had no checkbox; agents need one unambiguous place to tick |
