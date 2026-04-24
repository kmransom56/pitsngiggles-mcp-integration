#Requires -Version 5.1
# Creates a Windows desktop shortcut to launch launch_race_center.ps1
param(
    [string]$ShortcutName = "Pits n Giggles - Race Center.lnk"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$launch = Join-Path $root "launch_race_center.ps1"
if (-not (Test-Path -LiteralPath $launch)) {
    throw "Not found: $launch"
}
$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop $ShortcutName
$Wsh = New-Object -ComObject WScript.Shell
$sc = $Wsh.CreateShortcut($lnkPath)
$sc.TargetPath = (Get-Command powershell.exe).Source
$sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launch`""
$sc.WorkingDirectory = $root
$sc.Description = "Pits n Giggles Race Strategy Center (telemetry + voice + Nginx)"
$sc.WindowStyle = 1
# Optional: set IconLocation to the game executable if present
$pngExe = Join-Path $root "pits_n_giggles_3.2.2.exe"
if (Test-Path -LiteralPath $pngExe) {
    $sc.IconLocation = $pngExe
}
$sc.Save()
Write-Host "Created: $lnkPath" -ForegroundColor Green
