$ErrorActionPreference = "Continue"
if ($env:PNG_EXE) {
    $PNGExe = $env:PNG_EXE
} else {
    $PNGExe = Join-Path $PSScriptRoot "pits_n_giggles_3.2.2.exe"
}
$TelemetryPort = 4768

$pngRunning = Get-Process -Name "pits_n_giggles*" -ErrorAction SilentlyContinue
if ($pngRunning) {
    Write-Host "Pits N' Giggles is already running. Stopping it first..."
    $pngRunning | Stop-Process -Force
    Start-Sleep -Seconds 2
}

if (-not (Test-Path -LiteralPath $PNGExe)) {
    Write-Host "Executable not found: $PNGExe" -ForegroundColor Red
    Write-Host "Install or copy pits_n_giggles_3.2.2.exe next to this script, or set env var PNG_EXE to the full path." -ForegroundColor Yellow
    exit 1
}
try {
    Unblock-File -LiteralPath $PNGExe -ErrorAction SilentlyContinue
} catch {
}

Write-Host "Starting Pits N' Giggles..."
try {
    $workDir = Split-Path -Parent $PNGExe
    if (-not $workDir) {
        $workDir = $PSScriptRoot
    }
    $null = Start-Process -FilePath $PNGExe -WorkingDirectory $workDir -PassThru -ErrorAction Stop
} catch {
    Write-Host "Could not start Pits N' Giggles: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -match "canceled|cancelled") {
        Write-Host "If you saw 'Windows protected your PC' (SmartScreen), click More info, then Run anyway, or:" -ForegroundColor Yellow
        Write-Host "Right-click the .exe, Properties, check Unblock, OK, then run this script again." -ForegroundColor Yellow
    }
    exit 1
}

Write-Host "Waiting for telemetry server on port $TelemetryPort..."
$attempts = 0
while ($attempts -lt 20) {
    $conn = Test-NetConnection -ComputerName 127.0.0.1 -Port $TelemetryPort -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($conn.TcpTestSucceeded) {
        Write-Host "Telemetry server is up!"
        break
    }
    Start-Sleep -Seconds 1
    $attempts++
}
