# ═══════════════════════════════════════════════════════════
# 🏎️ Pits N' Giggles — Race Strategy Center + LAN Race Engineer
# ═══════════════════════════════════════════════════════════
# Starts Pits n' Giggles (telemetry). Default: standalone voice on 11734 and
# open http://127.0.0.1:11734/ in the browser. RACE_ENGINEER_STANDALONE=0 uses
# in-app /race-engineer/ on 4768 only (no 11734). Nginx in WSL for MCP/HTTPS.
#
#   Full stack (default):     .\launch_race_center.ps1
#   Engineer voice only:      .\launch_race_center.ps1 -EngineerVoiceOnly
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
# Strategy Center in browser. DNS: A record f1-race-engineer.netintegrate.net → Nginx (port 8443). Override: $env:STRATEGY_CENTER_URL
if ($env:STRATEGY_CENTER_URL) {
    $StrategyURL = $env:STRATEGY_CENTER_URL.TrimEnd("/") + "/"
} else {
    $StrategyURL = "https://f1-race-engineer.netintegrate.net:8443/"
}
# HTTPS + Nginx path to standalone voice app (must match deployment/nginx/pitsngiggles-mcp.conf)
$RaceEngineerAppUrl = $StrategyURL.TrimEnd("/") + "/race-engineer/"
if ($env:RACE_ENGINEER_APP_URL) {
    $RaceEngineerAppUrl = $env:RACE_ENGINEER_APP_URL.TrimEnd("/") + "/"
}
$TelemetryPort = 4768

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   🏎️  Race Strategy Center Launcher      ║" -ForegroundColor Cyan
Write-Host "  ║   Pits N' Giggles + LAN Race Engineer   ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# If we start PNG this run, its HTTP server opens /race-engineer/ (or /) in a browser — do not open a second tab for the same URL in Step 2.
$weStartedPngThisRun = $false

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
        $weStartedPngThisRun = $true
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

# ── Step 2: LAN Race Engineer
# Default: standalone voice app on 11734. Set RACE_ENGINEER_STANDALONE=0 for in-app /race-engineer/ only.
$useStandaloneEngineer = (-not $SkipEngineerVoice) -and ($env:RACE_ENGINEER_STANDALONE -ne "0")
if ($SkipEngineerVoice) {
    Write-Host "  ⏭️  Skipping LAN Race Engineer (-SkipEngineerVoice)" -ForegroundColor DarkGray
} elseif ($useStandaloneEngineer) {
    Write-Host "  🎙️ Starting standalone LAN race engineer (voice) on port $EngineerPort..." -ForegroundColor Yellow
    try {
        Start-EngineerVoiceProcess -RunInForeground $false
    } catch {
        Write-Host "  ⚠️  Could not start LAN Race Engineer: $($_.Exception.Message)" -ForegroundColor DarkYellow
        Write-Host "     Voice UI: http://127.0.0.1:$EngineerPort/" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  🎙️ RACE_ENGINEER_STANDALONE=0 — engineer UI inside Pits n' Giggles: http://127.0.0.1:$TelemetryPort/race-engineer/" -ForegroundColor Green
    if (Test-LocalPort -Port $TelemetryPort) {
        if (-not $weStartedPngThisRun) {
            Start-Process "http://127.0.0.1:$TelemetryPort/race-engineer/"
        } else {
            Write-Host "  (Pits n' Giggles opened that URL on startup — skipping a duplicate tab.)" -ForegroundColor DarkGray
        }
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

# ── Step 4: Optional reachability check (do not block launch)
$openUrl = $StrategyURL
$openLabel = "Strategy Center (Nginx)"
if ($useStandaloneEngineer) {
    $engineerUrl = $RaceEngineerAppUrl
    $openUrl = $RaceEngineerAppUrl
    $openLabel = "LAN race engineer (voice) at FQDN"
    Write-Host "  🔍 Verifying voice app via Nginx ($RaceEngineerAppUrl)..." -ForegroundColor Yellow
    $verifyOk = $false
    $lastErr = $null
    $maxAttempts = 10
    for ($a = 0; $a -lt $maxAttempts; $a++) {
        try {
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $response = Invoke-WebRequest -Uri $engineerUrl -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop -SkipCertificateCheck
            } else {
                if ($engineerUrl -like "https://*") {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                }
                $response = Invoke-WebRequest -Uri $engineerUrl -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
            }
            $code = [int]$response.StatusCode
            Write-Host "  ✅ Voice app responded (HTTP $code)" -ForegroundColor Green
            $verifyOk = $true
            break
        } catch {
            $lastErr = $_.Exception.Message
        }
        if ($a -lt ($maxAttempts - 1)) {
            Start-Sleep -Seconds 1
        }
    }
    if (-not $verifyOk) {
        Write-Host "  ⚠️  Could not reach $engineerUrl — opening browser anyway" -ForegroundColor DarkYellow
        if ($lastErr) {
            Write-Host "     ($lastErr)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  🔍 Verifying Strategy Center endpoint..." -ForegroundColor Yellow
    $verifyOk = $false
    $lastErr = $null
    $maxAttempts = 10
    for ($a = 0; $a -lt $maxAttempts; $a++) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        try {
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $response = Invoke-WebRequest -Uri $StrategyURL -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop -SkipHttpErrorCheck
            } else {
                $response = Invoke-WebRequest -Uri $StrategyURL -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            }
            $code = [int]$response.StatusCode
            Write-Host "  ✅ Strategy Center responded (HTTP $code)" -ForegroundColor Green
            $verifyOk = $true
            break
        } catch {
            $ex = $_.Exception
            $lastErr = $ex.Message
            try {
                $resp = $ex.Response
                if ($null -ne $resp -and $null -ne $resp.StatusCode) {
                    $code = [int]$resp.StatusCode
                    Write-Host "  ✅ Strategy Center reached the server (HTTP $code) — may need login or a path fix" -ForegroundColor Green
                    $verifyOk = $true
                    break
                }
            } catch {
            }
        }
        if ($a -lt ($maxAttempts - 1)) {
            Start-Sleep -Seconds 1
        }
    }
    if (-not $verifyOk) {
        Write-Host "  ⚠️  Could not reach $StrategyURL from this PC (firewall, DNS, VPN, or host down) — opening browser anyway" -ForegroundColor DarkYellow
        if ($lastErr) {
            Write-Host "     ($lastErr)" -ForegroundColor DarkGray
        }
    }
}

# ── Step 5: Open the primary app in the default browser
if ($useStandaloneEngineer -and -not (Test-LocalPort -Port $EngineerPort)) {
    Write-Host "  ⚠️  Voice backend not listening on $EngineerPort — Nginx cannot proxy /race-engineer/. Opening Strategy Center root instead." -ForegroundColor DarkYellow
    $openUrl = $StrategyURL
    $openLabel = "Strategy Center (Nginx) [fallback - voice backend down]"
}
Write-Host ""
Write-Host "  🏁 Opening $openLabel..." -ForegroundColor Cyan
Write-Host "     $openUrl" -ForegroundColor DarkGray
Write-Host ""
Start-Process $openUrl

Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Launcher is ready! 🏁🏎️💨" -ForegroundColor Green
Write-Host "  Primary browser URL:  $openUrl" -ForegroundColor DarkGray
Write-Host "  Telemetry:    http://localhost:$TelemetryPort" -ForegroundColor DarkGray
if (-not $SkipEngineerVoice) {
    if ($useStandaloneEngineer) {
        Write-Host "  Race engineer (HTTPS): $RaceEngineerAppUrl" -ForegroundColor DarkGray
        Write-Host "  Voice backend (direct):  http://127.0.0.1:$EngineerPort/" -ForegroundColor DarkGray
    } else {
        Write-Host "  Race engineer (in-app):  http://127.0.0.1:$TelemetryPort/race-engineer/" -ForegroundColor DarkGray
    }
}
Write-Host "  Strategy Center (Nginx, optional):  $StrategyURL" -ForegroundColor DarkGray
Write-Host "  MCP (SSE, f1-race-engineer-lan):    $($StrategyURL.TrimEnd('/'))/f1-race-engineer-lan  (ChatGPT / Cursor; /mcp still works)" -ForegroundColor DarkGray
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Start-Sleep -Seconds 5
