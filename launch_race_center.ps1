# ═══════════════════════════════════════════════════════════
# 🏎️ Pits N' Giggles — Race Strategy Center + LAN Race Engineer
# ═══════════════════════════════════════════════════════════
# Starts Pits N' Giggles (telemetry), the LAN race engineer
# (Ollama + voice UI on 11734), ensures Nginx in WSL, opens Strategy Center.
#
#   Full stack (default):     .\launch_race_center.ps1
#   Engineer voice only:      .\launch_race_center.ps1 -EngineerVoiceOnly
#                             (same as start_engineer_voice.ps1)
#   Skip LAN engineer:        .\launch_race_center.ps1 -SkipEngineerVoice
# ═══════════════════════════════════════════════════════════

param(
    [switch]$EngineerVoiceOnly,
    [switch]$SkipEngineerVoice
)

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
$EngineerPort = 11734
$ven = Join-Path $root "engineer_voice\.venv"
$req = Join-Path $root "engineer_voice\requirements.txt"
$engineerDir = Join-Path $root "engineer_voice"

function Test-LocalPort {
    param([int]$Port)
    $c = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    return $c.TcpTestSucceeded
}

function Set-EngineerVoiceEnv {
    if (-not $env:ENGINEER_VOICE_PORT) { $env:ENGINEER_VOICE_PORT = "$EngineerPort" }
    if (-not $env:OLLAMA_BASE) { $env:OLLAMA_BASE = "http://127.0.0.1:11434" }
    if (-not $env:PNG_BASE) { $env:PNG_BASE = "http://127.0.0.1:4768" }
    if (-not $env:OLLAMA_MODEL) { $env:OLLAMA_MODEL = "llama3.1:8b" }
}

function Install-EngineerVoiceDeps {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    try {
        if (-not (Test-Path -LiteralPath $req)) {
            throw "Missing $req"
        }
        if (-not (Test-Path -LiteralPath $ven)) {
            $created = $false
            try {
                & py -3.12 -m venv $ven
                if ($LASTEXITCODE -eq 0) { $created = $true }
            } catch { }
            if (-not $created) {
                try {
                    & py -3 -m venv $ven
                    if ($LASTEXITCODE -eq 0) { $created = $true }
                } catch { }
            }
            if (-not $created) {
                & python -m venv $ven
            }
        }
        $py = Join-Path $ven "Scripts\python.exe"
        if (-not (Test-Path -LiteralPath $py)) {
            throw "Python venv not found at $py"
        }
        & $py -m pip install -q -r $req
        if ($LASTEXITCODE -ne 0) { throw "pip install failed" }
        $opt = Join-Path $root "engineer_voice\requirements-optional-stt.txt"
        if (Test-Path -LiteralPath $opt) {
            $pip = Join-Path $ven "Scripts\pip.exe"
            & $pip install -q -r $opt 2>$null
        }
    } finally {
        $ErrorActionPreference = $oldEap
    }
}

function Start-EngineerVoiceProcess {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$RunInForeground
    )
    Set-EngineerVoiceEnv
    Install-EngineerVoiceDeps
    if (Test-LocalPort -Port $EngineerPort) {
        Write-Host "  ✅ LAN Race Engineer already listening on port $EngineerPort" -ForegroundColor Green
        return
    }
    $py = Join-Path $ven "Scripts\python.exe"
    if ($RunInForeground) {
        Set-Location -LiteralPath $engineerDir
        & $py -m uvicorn server:app --host 127.0.0.1 --port $EngineerPort
        return
    }
    Start-Process -FilePath $py -ArgumentList "-m", "uvicorn", "server:app", "--host", "127.0.0.1", "--port", "$EngineerPort" `
        -WorkingDirectory $engineerDir -WindowStyle Hidden
    Write-Host "  ⏳ Waiting for LAN Race Engineer on port $EngineerPort..." -ForegroundColor Yellow
    $attempts = 0
    $maxAttempts = 30
    while ($attempts -lt $maxAttempts) {
        if (Test-LocalPort -Port $EngineerPort) {
            Write-Host "  ✅ LAN Race Engineer is up: http://127.0.0.1:$EngineerPort/" -ForegroundColor Green
            return
        }
        Start-Sleep -Seconds 1
        $attempts++
    }
    Write-Host "  ⚠️  LAN Race Engineer did not open port $EngineerPort within ${maxAttempts}s (is Ollama running?)" -ForegroundColor DarkYellow
}

if ($EngineerVoiceOnly) {
    Start-EngineerVoiceProcess -RunInForeground $true
    exit
}

# ── PNG executable path
if ($env:PNG_EXE) {
    $PNGExe = $env:PNG_EXE
} else {
    $PNGExe = Join-Path $root "pits_n_giggles_3.2.2.exe"
}
if ($env:STRATEGY_CENTER_URL) {
    $StrategyURL = $env:STRATEGY_CENTER_URL.TrimEnd("/") + "/"
} else {
    $StrategyURL = "https://mcp.netintegrate.net:8443/"
}
$TelemetryPort = 4768

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   🏎️  Race Strategy Center Launcher      ║" -ForegroundColor Cyan
Write-Host "  ║   Pits N' Giggles + LAN Race Engineer   ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Start Pits N' Giggles if not already running
$pngRunning = Get-Process -Name "pits_n_giggles*" -ErrorAction SilentlyContinue
if ($pngRunning) {
    Write-Host "  ✅ Pits N' Giggles is already running (PID: $($pngRunning.Id))" -ForegroundColor Green
} else {
    Write-Host "  🚀 Starting Pits N' Giggles..." -ForegroundColor Yellow
    if (-not (Test-Path -LiteralPath $PNGExe)) {
        Write-Host "  ❌ Executable not found: $PNGExe" -ForegroundColor Red
        Write-Host "  Install or copy pits_n_giggles_3.2.2.exe next to this script, or set env var PNG_EXE to the full path." -ForegroundColor Yellow
        exit 1
    }
    try {
        Unblock-File -LiteralPath $PNGExe -ErrorAction SilentlyContinue
    } catch {
    }
    try {
        $workDir = Split-Path -Parent $PNGExe
        if (-not $workDir) {
            $workDir = $root
        }
        $null = Start-Process -FilePath $PNGExe -WorkingDirectory $workDir -PassThru -ErrorAction Stop
    } catch {
        Write-Host "  ❌ Could not start Pits N' Giggles: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Message -match "canceled|cancelled") {
            Write-Host "  If you saw 'Windows protected your PC' (SmartScreen), click More info, then Run anyway, or:" -ForegroundColor Yellow
            Write-Host "  Right-click the .exe → Properties → check Unblock → OK, then run this script again." -ForegroundColor Yellow
        }
        exit 1
    }
    Write-Host "  ⏳ Waiting for telemetry server to start on port $TelemetryPort..." -ForegroundColor Yellow
    $attempts = 0
    $maxAttempts = 30
    while ($attempts -lt $maxAttempts) {
        if (Test-LocalPort -Port $TelemetryPort) {
            Write-Host "  ✅ Telemetry server is up on port $TelemetryPort" -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 1
        $attempts++
    }
    if ($attempts -eq $maxAttempts) {
        Write-Host "  ⚠️  Telemetry server did not start within ${maxAttempts}s — continuing anyway" -ForegroundColor DarkYellow
    }
}

# ── Step 2: LAN Race Engineer (Ollama + voice UI)
if ($SkipEngineerVoice) {
    Write-Host "  ⏭️  Skipping LAN Race Engineer (-SkipEngineerVoice)" -ForegroundColor DarkGray
} else {
    Write-Host "  🎙️ Starting LAN Race Engineer (background)..." -ForegroundColor Yellow
    try {
        Start-EngineerVoiceProcess -RunInForeground $false
    } catch {
        Write-Host "  ⚠️  Could not start LAN Race Engineer: $($_.Exception.Message)" -ForegroundColor DarkYellow
        Write-Host "     Voice UI: http://127.0.0.1:$EngineerPort/ — fix deps or use -SkipEngineerVoice" -ForegroundColor DarkGray
    }
}

# ── Step 3: Ensure Nginx is running in WSL
Write-Host "  🔧 Checking Nginx reverse proxy in WSL..." -ForegroundColor Yellow
$nginxStatus = wsl -u root bash -c "service nginx status 2>&1" 2>$null
if ($nginxStatus -match "running|active") {
    Write-Host "  ✅ Nginx is already running" -ForegroundColor Green
} else {
    Write-Host "  🚀 Starting Nginx in WSL..." -ForegroundColor Yellow
    wsl -u root bash -c "service nginx start" 2>$null
    Start-Sleep -Seconds 1
    Write-Host "  ✅ Nginx started" -ForegroundColor Green
}

# ── Step 4: Verify HTTPS endpoint is reachable
Write-Host "  🔍 Verifying Strategy Center endpoint..." -ForegroundColor Yellow
$attempts = 0
$maxAttempts = 10
while ($attempts -lt $maxAttempts) {
    try {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        $response = Invoke-WebRequest -Uri $StrategyURL -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ Strategy Center is responding (HTTP 200)" -ForegroundColor Green
            break
        }
    } catch {
        Start-Sleep -Seconds 1
        $attempts++
    }
}
if ($attempts -eq $maxAttempts) {
    Write-Host "  ⚠️  Could not verify endpoint — opening browser anyway" -ForegroundColor DarkYellow
}

# ── Step 5: Open the Strategy Center in default browser
Write-Host ""
Write-Host "  🏁 Opening Race Strategy Center..." -ForegroundColor Cyan
Write-Host "     $StrategyURL" -ForegroundColor DarkGray
Write-Host ""
Start-Process $StrategyURL

Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Race Strategy Center is ready! 🏁🏎️💨" -ForegroundColor Green
Write-Host "  Telemetry:    http://localhost:$TelemetryPort" -ForegroundColor DarkGray
if (-not $SkipEngineerVoice) {
    Write-Host "  Race engineer: http://127.0.0.1:$EngineerPort/  (Ollama + voice)" -ForegroundColor DarkGray
}
Write-Host "  Dashboard:    $StrategyURL" -ForegroundColor DarkGray
Write-Host "  MCP (SSE):    $($StrategyURL.TrimEnd('/'))/mcp  (ChatGPT / Cursor)" -ForegroundColor DarkGray
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Start-Sleep -Seconds 5
