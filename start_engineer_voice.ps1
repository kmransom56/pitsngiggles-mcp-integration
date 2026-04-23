# Lan race engineer only (foreground uvicorn). Full stack: launch_race_center.ps1
# If you see "No suitable Python runtime" from py: set full path, e.g.
#   $env:ENGINEER_PYTHON = 'C:\Users\you\AppData\Local\Programs\Python\Python313\python.exe'
# Or: py -0   (list runtimes)   /   winget install astral.uv   then   uv python install 3.13
$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "launch_race_center.ps1") -EngineerVoiceOnly
