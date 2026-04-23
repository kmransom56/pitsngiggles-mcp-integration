# Lan race engineer only (foreground uvicorn). Full stack: launch_race_center.ps1
$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "launch_race_center.ps1") -EngineerVoiceOnly
