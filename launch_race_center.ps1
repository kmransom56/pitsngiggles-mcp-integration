# ═══════════════════════════════════════════════════════════
# 🏎️ Pits N' Giggles — Race Strategy Center + LAN Race Engineer
# ═══════════════════════════════════════════════════════════
# Starts Pits N' Giggles (telemetry + LAN race engineer at /race-engineer/ on
# the same HTTP port). Optional standalone engineer on 11734: set
# RACE_ENGINEER_STANDALONE=1. Ensures Nginx in WSL, opens Strategy Center.
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

function Get-EngineerPythonExe {
    if ($env:ENGINEER_PYTHON) {
        $ep = $env:ENGINEER_PYTHON
        if (Test-Path -LiteralPath $ep) { return (Resolve-Path -LiteralPath $ep).Path }
        Write-Host "  ⚠️  ENGINEER_PYTHON is set but file not found: $ep" -ForegroundColor DarkYellow
    }
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        $u = & uv python find 2>$null
        if ($LASTEXITCODE -eq 0 -and $u) {
            $p = $u | Select-Object -First 1
            if (Test-Path -LiteralPath $p) { return $p.Trim() }
        }
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $tryVers = @("3.14", "3.13", "3.12", "3.11", "3.10")
        foreach ($tv in $tryVers) {
            $o = & py "-$tv" -c "import sys; print(sys.executable)" 2>&1
            if ($LASTEXITCODE -eq 0 -and $o -and ($o -notmatch "Error|not found|suitable")) {
                $line = if ($o -is [array]) { $o[-1] } else { $o }
                $cand = $line.ToString().Trim()
                if (Test-Path -LiteralPath $cand) { return $cand }
            }
        }
        $tryTags = @(
            "-V:Astral/CPython3.13.11",
            "-V:Astral/CPython3.12.12"
        )
        if ($env:ENGINEER_PY_TAG) {
            $tryTags = @($env:ENGINEER_PY_TAG) + $tryTags
        }
        foreach ($tag in $tryTags) {
            if (-not $tag) { continue }
            $o = & py $tag -c "import sys; print(sys.executable)" 2>&1
            if ($LASTEXITCODE -eq 0 -and $o -and ($o -notmatch "Error|not found|suitable")) {
                $line = if ($o -is [array]) { $o[-1] } else { $o }
                $cand = $line.ToString().Trim()
                if (Test-Path -LiteralPath $cand) { return $cand }
            }
        }
        $o3 = & py -3 -c "import sys; print(sys.executable)" 2>&1
        if ($LASTEXITCODE -eq 0 -and $o3 -and ($o3 -notmatch "Error|not found|suitable")) {
            $line = if ($o3 -is [array]) { $o3[-1] } else { $o3 }
            $cand = $line.ToString().Trim()
            if (Test-Path -LiteralPath $cand) { return $cand }
        }
    }
    $w = @()
    try { $w = & where.exe python 2>$null } catch { }
    foreach ($cand in $w) {
        $cand = $cand.Trim()
        if (-not $cand) { continue }
        if ($cand -match "WindowsApps") { continue }
        if (-not (Test-Path -LiteralPath $cand)) { continue }
        $vv = & $cand -c "import sys; v=sys.version_info; assert v>=(3,10); print(sys.executable)" 2>&1
        if ($LASTEXITCODE -eq 0) { return $cand }
    }
    return $null
}

function New-EngineerVenv {
    if (Test-Path -LiteralPath (Join-Path $ven "Scripts\python.exe")) { return }
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "  … Creating venv with uv…" -ForegroundColor DarkGray
        $x = & uv venv $ven 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $ven "Scripts\python.exe"))) { return }
    }
    $base = Get-EngineerPythonExe
    if ($base) {
        Write-Host "  … Creating venv with: $base" -ForegroundColor DarkGray
        & $base -m venv $ven
        if ($LASTEXITCODE -ne 0) { throw "python -m venv failed (exit $LASTEXITCODE): $base" }
        if (-not (Test-Path (Join-Path $ven "Scripts\python.exe"))) { throw "venv missing Scripts\python.exe after -m venv" }
        return
    }
    throw @"
No Python found for engineer_voice. The Windows 'py' launcher has no 3.10+ install, and 'python' was not usable.

  Fix (pick one):
  • Install Python 3.12+ from https://www.python.org/downloads/  (check **Install launcher** and **Add to PATH**).
  • Or install Astral uv and a runtime:  winget install astral.uv  then:  uv python install 3.13
  • Or set the full path to python.exe, then re-run:
      `$env:ENGINEER_PYTHON = 'C:\Path\to\python.exe'`

  To see what the launcher can run:  py -0
"@
}

function Install-EngineerVoiceDeps {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    try {
        if (-not (Test-Path -LiteralPath $req)) {
            throw "Missing $req"
        }
        if (-not (Test-Path -LiteralPath $ven) -or -not (Test-Path (Join-Path $ven "Scripts\python.exe"))) {
            if (Test-Path -LiteralPath $ven) {
                Write-Host "  … Removing broken engineer_voice venv" -ForegroundColor DarkYellow
                Remove-Item -LiteralPath $ven -Recurse -Force -ErrorAction SilentlyContinue
            }
            New-EngineerVenv
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

# ── Step 2: LAN Race Engineer (built into Pits n' Giggles HTTP on /race-engineer/)
if ($SkipEngineerVoice) {
    Write-Host "  ⏭️  Skipping LAN Race Engineer (-SkipEngineerVoice)" -ForegroundColor DarkGray
} elseif ($env:RACE_ENGINEER_STANDALONE -eq "1") {
    Write-Host "  🎙️ RACE_ENGINEER_STANDALONE=1 — starting separate engineer on port $EngineerPort..." -ForegroundColor Yellow
    try {
        Start-EngineerVoiceProcess -RunInForeground $false
    } catch {
        Write-Host "  ⚠️  Could not start LAN Race Engineer: $($_.Exception.Message)" -ForegroundColor DarkYellow
        Write-Host "     Voice UI: http://127.0.0.1:$EngineerPort/" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  🎙️ LAN Race Engineer is inside Pits n' Giggles: http://127.0.0.1:$TelemetryPort/race-engineer/" -ForegroundColor Green
    if (Test-LocalPort -Port $TelemetryPort) {
        Start-Process "http://127.0.0.1:$TelemetryPort/race-engineer/"
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
    if ($env:RACE_ENGINEER_STANDALONE -eq "1") {
        Write-Host "  Race engineer (standalone): http://127.0.0.1:$EngineerPort/" -ForegroundColor DarkGray
    } else {
        Write-Host "  Race engineer (same app):    http://127.0.0.1:$TelemetryPort/race-engineer/" -ForegroundColor DarkGray
    }
}
Write-Host "  Dashboard:    $StrategyURL" -ForegroundColor DarkGray
Write-Host "  MCP (SSE):    $($StrategyURL.TrimEnd('/'))/mcp  (ChatGPT / Cursor)" -ForegroundColor DarkGray
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Start-Sleep -Seconds 5
