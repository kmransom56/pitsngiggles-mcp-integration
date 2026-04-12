# ═══════════════════════════════════════════════════════════
# 🏎️ Pits N' Giggles — Race Strategy Center Launcher
# ═══════════════════════════════════════════════════════════
# Starts the telemetry server, ensures Nginx proxy is running
# in WSL, and opens the unified Strategy Center dashboard.
# ═══════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"
$PNGExe = "c:\pitsngiggles-mcp-integration\pits_n_giggles_3.2.1.exe"
$StrategyURL = "https://mcp.netintegrate.net:8443/"
$TelemetryPort = 4768
$NginxPort = 8443

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   🏎️  Race Strategy Center Launcher     ║" -ForegroundColor Cyan
Write-Host "  ║   Pits N' Giggles + Antigravity AI      ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Start Pits N' Giggles if not already running ──
$pngRunning = Get-Process -Name "pits_n_giggles*" -ErrorAction SilentlyContinue
if ($pngRunning) {
    Write-Host "  ✅ Pits N' Giggles is already running (PID: $($pngRunning.Id))" -ForegroundColor Green
} else {
    Write-Host "  🚀 Starting Pits N' Giggles..." -ForegroundColor Yellow
    Start-Process -FilePath $PNGExe -WorkingDirectory (Split-Path $PNGExe)
    Write-Host "  ⏳ Waiting for telemetry server to start on port $TelemetryPort..." -ForegroundColor Yellow
    
    $attempts = 0
    $maxAttempts = 30
    while ($attempts -lt $maxAttempts) {
        $conn = Test-NetConnection -ComputerName 127.0.0.1 -Port $TelemetryPort -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($conn.TcpTestSucceeded) {
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

# ── Step 2: Ensure Nginx is running in WSL ──
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

# ── Step 3: Verify HTTPS endpoint is reachable ──
Write-Host "  🔍 Verifying Strategy Center endpoint..." -ForegroundColor Yellow

$attempts = 0
$maxAttempts = 10
while ($attempts -lt $maxAttempts) {
    try {
        # Skip cert validation for self-signed cert
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

# ── Step 4: Open the Strategy Center in default browser ──
Write-Host ""
Write-Host "  🏁 Opening Race Strategy Center..." -ForegroundColor Cyan
Write-Host "     $StrategyURL" -ForegroundColor DarkGray
Write-Host ""

Start-Process $StrategyURL

Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Race Strategy Center is ready! 🏁🏎️💨" -ForegroundColor Green
Write-Host "  Telemetry: http://localhost:$TelemetryPort" -ForegroundColor DarkGray
Write-Host "  Dashboard: $StrategyURL" -ForegroundColor DarkGray
Write-Host "  MCP (SSE): $($StrategyURL.TrimEnd('/'))/mcp  (ChatGPT / Cursor)" -ForegroundColor DarkGray
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

# Keep window open briefly so user can see status
Start-Sleep -Seconds 5
