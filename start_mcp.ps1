$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
if ($env:PNG_EXE) {
    $PNGExe = $env:PNG_EXE
} else {
    $PNGExe = Get-ChildItem -Path $root -Filter "pits_n_giggles*.exe" | Select-Object -First 1
    if ($PNGExe) { $PNGExe = $PNGExe.FullName }
    else { $PNGExe = Join-Path $root "pits_n_giggles_3.2.2.exe" }
}
$TelemetryPort = 4768

$pngRunning = Get-Process -Name "pits_n_giggles*" -ErrorAction SilentlyContinue
if ($pngRunning) {
    Write-Host "Pits N' Giggles is already running. Stopping it first..."
    $pngRunning | Stop-Process -Force
    Start-Sleep -Seconds 2
}

$weStartedPngThisRun = $false
if (Test-Path -LiteralPath $PNGExe) {
    Write-Host "Starting Pits N' Giggles EXE: $PNGExe"
    try {
        Unblock-File -LiteralPath $PNGExe -ErrorAction SilentlyContinue
        $workDir = Split-Path -Parent $PNGExe
        if (-not $workDir) { $workDir = $root }
        $null = Start-Process -FilePath $PNGExe -WorkingDirectory $workDir -PassThru -ErrorAction Stop
        $weStartedPngThisRun = $true
    } catch {
        Write-Host "Could not start Pits N' Giggles EXE: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $weStartedPngThisRun) {
    Write-Host "Executable not found or failed to start. Attempting source launch..." -ForegroundColor Yellow
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "Starting from source (uv)..." -ForegroundColor Yellow
        Start-Process -FilePath "uv" -ArgumentList "run", "python", "-O", "-m", "apps.launcher" -WorkingDirectory $root
        $weStartedPngThisRun = $true
    } elseif (Test-Path -LiteralPath (Join-Path $root ".venv\Scripts\python.exe")) {
        Write-Host "Starting from source (.venv)..." -ForegroundColor Yellow
        Start-Process -FilePath (Join-Path $root ".venv\Scripts\python.exe") -ArgumentList "-O", "-m", "apps.launcher" -WorkingDirectory $root
        $weStartedPngThisRun = $true
    } else {
        Write-Host "No executable and no Python environment found. Please follow QUICKSTART.md." -ForegroundColor Red
        exit 1
    }
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
