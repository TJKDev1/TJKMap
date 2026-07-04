# Claude Code PostToolUse hook: cheap grep-based checks after Edit/Write.
# Exit 2 + stderr feeds the message back to the agent so it can self-correct immediately,
# before the Gradle/checkstyle/ArchUnit gates (which may not exist yet — Phase S).
$ErrorActionPreference = 'SilentlyContinue'
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$path = $payload.tool_input.file_path
if (-not $path -or -not (Test-Path $path)) { exit 0 }
$rel = $path -replace '\\', '/'
$msgs = @()

if ($rel -match '/addons/.*\.java$') {
    if (Select-String -Path $path -Pattern 'dev\.tjk\.tjkmap\.internal' -Quiet) {
        $msgs += 'HARD RULE 1 VIOLATION: addon code references dev.tjk.tjkmap.internal.* — addons may use dev.tjk.tjkmap.api.* ONLY. Remove the internal reference; if the API is missing something, that is an API task, not a reason to reach into internal.'
    }
}
if ($rel -match '\.java$') {
    if ($rel -match '(render|hud|map|layer|screen|widget|theme)' -and
        (Select-String -Path $path -Pattern '0x[0-9A-Fa-f]{6,8}\b|new Color\s*\(' -Quiet)) {
        $msgs += 'HARD RULE 5 WARNING: possible hardcoded color in render/HUD code. Use ThemeApi.color(key). If this hit is a false positive (bitmask etc.), continue.'
    }
    if (Select-String -Path $path -Pattern 'System\.(out|err)\.print' -Quiet) {
        $msgs += 'STYLE VIOLATION: System.out/err - use an SLF4J logger per class (AGENTS.md working conventions).'
    }
}
if ($rel -match '/\.claude/(skills|agents)/') {
    $msgs += 'REMINDER: you edited .claude/ content that is mirrored in .agents/. Run scripts/sync-skills.ps1 (or .sh) before committing - CI fails if the mirrors differ.'
}

if ($msgs.Count -gt 0) {
    [Console]::Error.WriteLine(($msgs -join "`n"))
    exit 2
}
exit 0
