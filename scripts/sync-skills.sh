#!/usr/bin/env bash
# Mirrors .claude/skills and .claude/agents into .agents/ (single source of truth: .claude/).
# Run after any change under .claude/skills or .claude/agents. CI verifies the dirs are identical.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"

for dir in skills agents; do
  src="$root/.claude/$dir"
  dst="$root/.agents/$dir"
  [ -d "$src" ] || continue
  rm -rf "$dst"
  mkdir -p "$dst"
  cp -r "$src/." "$dst/"
  echo "synced .claude/$dir -> .agents/$dir"
done
