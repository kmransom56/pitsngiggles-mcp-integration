# Opens the LAN race engineer UI (same process as Pits n' Giggles HTTP).
# Standalone dev server on 11734:  $env:RACE_ENGINEER_STANDALONE = "1"; .\start_engineer_voice.ps1
# If py launcher fails: see comments in launch_race_center.ps1 / docs/PYTHON_ENVIRONMENT.md
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if ($env:RACE_ENGINEER_STANDALONE -eq "1") {
    & (Join-Path $root "launch_race_center.ps1") -EngineerVoiceOnly
    exit
}
$port = if ($env:PNG_HTTP_PORT) { $env:PNG_HTTP_PORT } else { 4768 }
$url = "http://127.0.0.1:$port/race-engineer/"
Write-Host "Opening LAN Race Engineer (requires Pits n' Giggles running on port $port): $url" -ForegroundColor Cyan
Start-Process $url
