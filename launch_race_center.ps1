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
$EngineerHost = if ($env:ENGINEER_VOICE_HOST) { $env:ENGINEER_VOICE_HOST } else { "0.0.0.0" }
$ven = Join-Path $root "engineer_voice\.venv"
$req = Join-Path $root "engineer_voice\requirements.txt"
$engineerDir = Join-Path $root "engineer_voice"
$LocalEngineerUrl = "http://127.0.0.1:$EngineerPort/"
$TelemetryPort = 4768
$TelemetryBaseUrl = "http://127.0.0.1:$TelemetryPort"
$TelemetryEngViewUrl = "$TelemetryBaseUrl/eng-view"
$OllamaBaseUrl = if ($env:OLLAMA_BASE) { $env:OLLAMA_BASE.TrimEnd("/") } else { "http://127.0.0.1:11434" }
$DefaultPiperExe = Join-Path $root "tools\piper\piper.exe"
$DefaultPiperModel = Join-Path $root "tools\piper\voices\en_US-ryan-medium.onnx"
$DefaultPiperConfig = Join-Path $root "tools\piper\voices\en_US-ryan-medium.onnx.json"
$ApplyNginxConfigScript = Join-Path $root "deployment\scripts\apply-nginx-config.ps1"

function Test-LocalPort {
    param([int]$Port)
    $c = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    return $c.TcpTestSucceeded
}

function Test-HttpEndpoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$TimeoutSec = 3
    )
    try {
        $params = @{
            Uri = $Url
            UseBasicParsing = $true
            TimeoutSec = $TimeoutSec
            ErrorAction = "Stop"
        }
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $params.SkipHttpErrorCheck = $true
        }
        $response = Invoke-WebRequest @params
        $code = [int]$response.StatusCode
        return ($code -ge 200 -and $code -lt 500)
    } catch {
        return $false
    }
}

function Wait-HttpEndpoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [int]$MaxAttempts = 60,
        [int]$DelaySec = 1
    )
    Write-Host "  ⏳ Waiting for $Label..." -ForegroundColor Yellow
    for ($attempt = 0; $attempt -lt $MaxAttempts; $attempt++) {
        if (Test-HttpEndpoint -Url $Url) {
            Write-Host "  ✅ $Label is ready: $Url" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds $DelaySec
    }
    Write-Host "  ⚠️  $Label did not respond after $($MaxAttempts * $DelaySec)s: $Url" -ForegroundColor DarkYellow
    return $false
}

function Start-OllamaIfNeeded {
    $tagsUrl = "$OllamaBaseUrl/api/tags"
    if (Test-HttpEndpoint -Url $tagsUrl) {
        Write-Host "  ✅ Ollama is ready: $OllamaBaseUrl" -ForegroundColor Green
        return $true
    }

    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollama) {
        Write-Host "  ⚠️  Ollama command not found; install Ollama or set OLLAMA_BASE to a reachable server." -ForegroundColor DarkYellow
        return $false
    }

    $setupRunning = Get-Process -Name "OllamaSetup", "OllamaSetup.tmp" -ErrorAction SilentlyContinue
    if ($setupRunning) {
        Write-Host "  ⚠️  Ollama installer/update is running; wait for it to finish if Ollama does not start." -ForegroundColor DarkYellow
    }

    Write-Host "  🚀 Starting Ollama..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath $ollama.Source -ArgumentList "serve" -WindowStyle Hidden
    } catch {
        Write-Host "  ⚠️  Could not start Ollama: $($_.Exception.Message)" -ForegroundColor DarkYellow
        return $false
    }

    return (Wait-HttpEndpoint -Url $tagsUrl -Label "Ollama API" -MaxAttempts 30)
}

function Set-EngineerVoiceEnv {
    if (-not $env:ENGINEER_VOICE_PORT) { $env:ENGINEER_VOICE_PORT = "$EngineerPort" }
    if (-not $env:OLLAMA_BASE) { $env:OLLAMA_BASE = $OllamaBaseUrl }
    if (-not $env:PNG_BASE) { $env:PNG_BASE = "http://127.0.0.1:4768" }
    if (-not $env:OLLAMA_MODEL) { $env:OLLAMA_MODEL = "llama3.1:8b" }
    if (-not $env:WHISPER_DEVICE) { $env:WHISPER_DEVICE = "cpu" }
    if (-not $env:WHISPER_COMPUTE) { $env:WHISPER_COMPUTE = "int8" }
    if (-not $env:WHISPER_MODEL) { $env:WHISPER_MODEL = "base.en" }
    if (-not $env:WS_STT_CHUNK_S) { $env:WS_STT_CHUNK_S = "0.8" }
    if (-not $env:PIPER_EXE -and (Test-Path -LiteralPath $DefaultPiperExe)) { $env:PIPER_EXE = $DefaultPiperExe }
    if (-not $env:PIPER_MODEL -and (Test-Path -LiteralPath $DefaultPiperModel)) { $env:PIPER_MODEL = $DefaultPiperModel }
    if (-not $env:PIPER_CONFIG -and (Test-Path -LiteralPath $DefaultPiperConfig)) { $env:PIPER_CONFIG = $DefaultPiperConfig }
}

function Invoke-NginxConfigApply {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$RunSmokeChecks
    )

    if (-not (Test-Path -LiteralPath $ApplyNginxConfigScript)) {
        Write-Host "  ⚠️  Nginx apply script not found: $ApplyNginxConfigScript" -ForegroundColor DarkYellow
        return $false
    }

    $args = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $ApplyNginxConfigScript,
        "-RestartOnReloadFailure"
    )
    if (-not $RunSmokeChecks) {
        $args += "-SkipSmoke"
    }

    Write-Host "  🔧 Applying repo-owned Nginx config..." -ForegroundColor Yellow
    & powershell.exe @args
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Nginx config applied from repo" -ForegroundColor Green
        return $true
    }

    Write-Host "  ⚠️  Nginx config apply failed (exit $LASTEXITCODE); continuing with existing live config." -ForegroundColor DarkYellow
    return $false
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
        if (-not (Wait-HttpEndpoint -Url "$($LocalEngineerUrl)health" -Label "LAN Race Engineer health endpoint" -MaxAttempts 10)) {
            Write-Host "  ⚠️  Port $EngineerPort is bound, but $($LocalEngineerUrl)health did not respond." -ForegroundColor DarkYellow
        }
        return
    }
    $py = Join-Path $ven "Scripts\python.exe"
    if ($RunInForeground) {
        Set-Location -LiteralPath $engineerDir
        & $py -m uvicorn server:app --host $EngineerHost --port $EngineerPort
        return
    }
    Start-Process -FilePath $py -ArgumentList "-m", "uvicorn", "server:app", "--host", "$EngineerHost", "--port", "$EngineerPort" `
        -WorkingDirectory $engineerDir -WindowStyle Hidden
    if (-not (Wait-HttpEndpoint -Url "$($LocalEngineerUrl)health" -Label "LAN Race Engineer health endpoint" -MaxAttempts 30)) {
        Write-Host "  ⚠️  LAN Race Engineer did not become healthy on $LocalEngineerUrl" -ForegroundColor DarkYellow
    }
}

if ($EngineerVoiceOnly) {
    Start-OllamaIfNeeded | Out-Null
    Start-EngineerVoiceProcess -RunInForeground $true
    exit
}

# ── PNG executable path
if ($env:PNG_EXE) {
    $PNGExe = $env:PNG_EXE
} else {
    $PNGExe = Get-ChildItem -Path $root -Filter "pits_n_giggles*.exe" | Select-Object -First 1
    if ($PNGExe) { $PNGExe = $PNGExe.FullName }
    else { $PNGExe = Join-Path $root "pits_n_giggles_3.2.2.exe" }
}
# Strategy Center in browser. DNS: A record f1-race-engineer.netintegrate.net → Nginx (port 8443). Override: $env:STRATEGY_CENTER_URL
if ($env:STRATEGY_CENTER_URL) {
    $StrategyURL = $env:STRATEGY_CENTER_URL.TrimEnd("/") + "/"
} else {
    $StrategyURL = "https://f1-race-engineer.netintegrate.net/"
}
# HTTPS + Nginx path to standalone voice app (must match deployment/nginx/pitsngiggles-mcp.conf)
$RaceEngineerAppUrl = $StrategyURL.TrimEnd("/") + "/race-engineer/"
if ($env:RACE_ENGINEER_APP_URL) {
    $RaceEngineerAppUrl = $env:RACE_ENGINEER_APP_URL.TrimEnd("/") + "/"
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   🏎️  Race Strategy Center Launcher      ║" -ForegroundColor Cyan
Write-Host "  ║   Pits N' Giggles + LAN Race Engineer   ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# If we start PNG this run, it may open its own browser tab. This launcher still opens the primary URL after readiness checks.
$weStartedPngThisRun = $false

# ── Step 1: Start Pits N' Giggles if not already running
$pngRunning = Get-Process -Name "pits_n_giggles*" -ErrorAction SilentlyContinue
if ($pngRunning) {
    Write-Host "  ✅ Pits N' Giggles is already running (PID: $($pngRunning.Id))" -ForegroundColor Green
} else {
    Write-Host "  🚀 Starting Pits N' Giggles..." -ForegroundColor Yellow
    if (Test-Path -LiteralPath $PNGExe) {
        try {
            Unblock-File -LiteralPath $PNGExe -ErrorAction SilentlyContinue
            $workDir = Split-Path -Parent $PNGExe
            if (-not $workDir) { $workDir = $root }
            $null = Start-Process -FilePath $PNGExe -WorkingDirectory $workDir -PassThru -ErrorAction Stop
            $weStartedPngThisRun = $true
        } catch {
            Write-Host "  ❌ Could not start Pits N' Giggles EXE: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if (-not $weStartedPngThisRun) {
        Write-Host "  ⚠️  Executable not found or failed to start. Attempting source launch..." -ForegroundColor Yellow
        if (Get-Command uv -ErrorAction SilentlyContinue) {
            Write-Host "  🚀 Starting from source (uv)..." -ForegroundColor Yellow
            Start-Process -FilePath "uv" -ArgumentList "run", "python", "-O", "-m", "apps.launcher" -WorkingDirectory $root
            $weStartedPngThisRun = $true
        } elseif (Test-Path -LiteralPath (Join-Path $root ".venv\Scripts\python.exe")) {
            Write-Host "  🚀 Starting from source (.venv)..." -ForegroundColor Yellow
            Start-Process -FilePath (Join-Path $root ".venv\Scripts\python.exe") -ArgumentList "-O", "-m", "apps.launcher" -WorkingDirectory $root
            $weStartedPngThisRun = $true
        } else {
            Write-Host "  ❌ No executable and no Python environment found. Please follow QUICKSTART.md." -ForegroundColor Red
            exit 1
        }
    }
}
$telemetryReady = Wait-HttpEndpoint -Url $TelemetryEngViewUrl -Label "Pits N' Giggles engineer view" -MaxAttempts 60

# ── Step 2: LAN Race Engineer
# Default: standalone voice app on 11734. Set RACE_ENGINEER_STANDALONE=0 for in-app /race-engineer/ only.
$useStandaloneEngineer = (-not $SkipEngineerVoice) -and ($env:RACE_ENGINEER_STANDALONE -ne "0")
if ($SkipEngineerVoice) {
    Write-Host "  ⏭️  Skipping LAN Race Engineer (-SkipEngineerVoice)" -ForegroundColor DarkGray
} elseif ($useStandaloneEngineer) {
    Start-OllamaIfNeeded | Out-Null
    Write-Host "  🎙️ Starting standalone LAN race engineer (voice) on port $EngineerPort..." -ForegroundColor Yellow
    try {
        Start-EngineerVoiceProcess -RunInForeground $false
    } catch {
        Write-Host "  ⚠️  Could not start LAN Race Engineer: $($_.Exception.Message)" -ForegroundColor DarkYellow
        Write-Host "     Voice UI: http://127.0.0.1:$EngineerPort/" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  🎙️ RACE_ENGINEER_STANDALONE=0 — engineer UI inside Pits n' Giggles: http://127.0.0.1:$TelemetryPort/race-engineer/" -ForegroundColor Green
    if ($telemetryReady -and -not (Test-HttpEndpoint -Url "http://127.0.0.1:$TelemetryPort/race-engineer/")) {
        Write-Host "  ⚠️  This Pits N' Giggles build did not serve /race-engineer/; use standalone mode on $LocalEngineerUrl instead." -ForegroundColor DarkYellow
    }
}

# ── Step 3: Apply repo-owned Nginx config in WSL
$nginxApplied = Invoke-NginxConfigApply -RunSmokeChecks ($telemetryReady -and (-not $SkipEngineerVoice))
if (-not $nginxApplied) {
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
}

# ── Step 4: Optional reachability check (do not block launch)
$openUrl = $StrategyURL
$openLabel = "Strategy Center (Nginx)"
if ($useStandaloneEngineer) {
    $engineerUrl = $LocalEngineerUrl
    $openUrl = $RaceEngineerAppUrl
    $openLabel = "LAN race engineer (voice, FQDN)"
    Write-Host "  🔍 Verifying FQDN voice app ($RaceEngineerAppUrl)..." -ForegroundColor Yellow
    $verifyOk = $false
    $lastErr = $null
    $maxAttempts = 10
    for ($a = 0; $a -lt $maxAttempts; $a++) {
        try {
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $response = Invoke-WebRequest -Uri $RaceEngineerAppUrl -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop -SkipCertificateCheck
            } else {
                if ($RaceEngineerAppUrl -like "https://*") {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                }
                $response = Invoke-WebRequest -Uri $RaceEngineerAppUrl -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
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
        Write-Host "  ⚠️  Could not reach $RaceEngineerAppUrl — falling back to $LocalEngineerUrl" -ForegroundColor DarkYellow
        if ($lastErr) {
            Write-Host "     ($lastErr)" -ForegroundColor DarkGray
        }
        $openUrl = $LocalEngineerUrl
        $openLabel = "LAN race engineer (voice, direct local fallback)"
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
    Write-Host "  ⚠️  Voice backend not listening on $EngineerPort — opening telemetry engineer view instead." -ForegroundColor DarkYellow
    $openUrl = $TelemetryEngViewUrl
    $openLabel = "Pits N' Giggles engineer view [fallback - voice backend down]"
}
if ($useStandaloneEngineer -and -not $telemetryReady) {
    Write-Host "  ⚠️  Telemetry is not ready; the voice page will open, but its embedded engineer view may stay blank until $TelemetryEngViewUrl responds." -ForegroundColor DarkYellow
}
Write-Host ""
Write-Host "  🏁 Opening $openLabel..." -ForegroundColor Cyan
Write-Host "     $openUrl" -ForegroundColor DarkGray
Write-Host ""
Start-Process $openUrl

Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Launcher is ready! 🏁🏎️💨" -ForegroundColor Green
Write-Host "  Primary browser URL:  $openUrl" -ForegroundColor DarkGray
Write-Host "  Telemetry:    $TelemetryBaseUrl" -ForegroundColor DarkGray
Write-Host "  Engineer view: $TelemetryEngViewUrl" -ForegroundColor DarkGray
if (-not $SkipEngineerVoice) {
    if ($useStandaloneEngineer) {
        Write-Host "  Race engineer (direct): $LocalEngineerUrl" -ForegroundColor DarkGray
        Write-Host "  Race engineer (Nginx, optional): $RaceEngineerAppUrl" -ForegroundColor DarkGray
    } else {
        Write-Host "  Race engineer (in-app):  http://127.0.0.1:$TelemetryPort/race-engineer/" -ForegroundColor DarkGray
    }
}
Write-Host "  Strategy Center (Nginx, optional):  $StrategyURL" -ForegroundColor DarkGray
Write-Host "  MCP (SSE, f1-race-engineer-lan):    $($StrategyURL.TrimEnd('/'))/f1-race-engineer-lan  (ChatGPT / Cursor; /mcp still works)" -ForegroundColor DarkGray
    Write-Host "  MCP (Alias, mcp.netintegrate.net):  https://mcp.netintegrate.net:8443/f1-race-engineer-lan" -ForegroundColor DarkGray
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Start-Sleep -Seconds 5
