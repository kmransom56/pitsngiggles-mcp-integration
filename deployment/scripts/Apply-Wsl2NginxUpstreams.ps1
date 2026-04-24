#Requires -Version 5.1
# Regenerate WSL2 upstream snippet and reload Nginx. Run from Windows after
# start.sh / PNG / engineer voice are on the Windows host (fixes 502 from Nginx in WSL).
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$sh = Join-Path $root "deployment\scripts\apply-wsl2-nginx-upstreams.sh"
if (-not (Test-Path -LiteralPath $sh)) { throw "Not found: $sh" }
$wslSh = (wsl.exe wslpath -a $sh 2>$null)
if ([string]::IsNullOrWhiteSpace($wslSh)) {
    $p = (Resolve-Path -LiteralPath $sh).Path
    if ($p -notmatch "^([A-Za-z]):\\(.*)$") { throw "Cannot map to WSL path: $p" }
    $drive = $Matches[1].ToLower()
    $rest = $Matches[2] -replace "\\", "/"
    $wslSh = "/mnt/$drive/$rest"
}
& wsl.exe -u root bash $wslSh.Trim()
if ($LASTEXITCODE -ne 0) { throw "apply-wsl2-nginx-upstreams.sh failed with exit $LASTEXITCODE" }
& wsl.exe -u root nginx -s reload
Write-Host "Nginx reloaded. Retest the site in the browser." -ForegroundColor Green
