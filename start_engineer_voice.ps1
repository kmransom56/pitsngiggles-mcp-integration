# Starts the LAN race engineer: Ollama + telemetry + browser UI (http://127.0.0.1:11734)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$ven = Join-Path $root "engineer_voice\.venv"
$req = Join-Path $root "engineer_voice\requirements.txt"

if (-not (Test-Path $ven)) {
    py -3.12 -m venv $ven
    if ($LASTEXITCODE -ne 0) { py -3 -m venv $ven }
}
& (Join-Path $ven "Scripts\python.exe") -m pip install -q -r $req
$opt = Join-Path $root "engineer_voice\requirements-optional-stt.txt"
if (Test-Path $opt) {
    & (Join-Path $ven "Scripts\pip.exe") install -q -r $opt 2>$null
}

$env:ENGINEER_VOICE_PORT = "11734"
$env:OLLAMA_BASE = if ($env:OLLAMA_BASE) { $env:OLLAMA_BASE } else { "http://127.0.0.1:11434" }
$env:PNG_BASE = if ($env:PNG_BASE) { $env:PNG_BASE } else { "http://127.0.0.1:4768" }
$env:OLLAMA_MODEL = if ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { "llama3.1" }

Set-Location (Join-Path $root "engineer_voice")
& (Join-Path $ven "Scripts\python.exe") -m uvicorn server:app --host 127.0.0.1 --port 11734
