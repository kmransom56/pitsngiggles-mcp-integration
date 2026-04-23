# Wrapper so you can run from this directory; full script is at repo root
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $root "start_engineer_voice.ps1") @args
