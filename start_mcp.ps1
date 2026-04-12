$PNGExe = "c:\pitsngiggles-mcp-integration\pits_n_giggles_3.2.1.exe"
$TelemetryPort = 4768

$pngRunning = Get-Process -Name "pits_n_giggles*" -ErrorAction SilentlyContinue
if ($pngRunning) {
    Write-Host "Pits N' Giggles is already running. Stopping it first..."
    $pngRunning | Stop-Process -Force
    Start-Sleep -Seconds 2
}

Write-Host "Starting Pits N' Giggles..."
Start-Process -FilePath $PNGExe -WorkingDirectory (Split-Path $PNGExe)

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
