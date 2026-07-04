# Mirrors .claude/skills and .claude/agents into .agents/ (single source of truth: .claude/).
# Run after any change under .claude/skills or .claude/agents. CI verifies the dirs are identical.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

foreach ($dir in 'skills', 'agents') {
    $src = Join-Path $root ".claude\$dir"
    $dst = Join-Path $root ".agents\$dir"
    if (-not (Test-Path $src)) { continue }
    robocopy $src $dst /MIR /NJH /NJS /NDL /NC /NS | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $dir (exit $LASTEXITCODE)" }
    Write-Host "synced .claude/$dir -> .agents/$dir"
}
exit 0
