#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  WSL2: forward TCP 80, 443, 8443 from 0.0.0.0 (this Windows host) to the same
  ports on the current default WSL distro, so Nginx in WSL is reachable on the
  LAN. Also adds matching Windows Defender Firewall allow rules.
  Re-run when WSL's eth0 address changes (e.g. after reboot).
#>
$ErrorActionPreference = "Stop"
$wslOut = wsl -u root bash -c "hostname -I" 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "WSL not available: $wslOut"
}
$wslIp = ($wslOut -split "\s+")[0]
if ([string]::IsNullOrWhiteSpace($wslIp) -or $wslIp -notmatch "^\d+\.\d+\.\d+\.\d+$") {
    throw "Could not read WSL IPv4 from hostname -I (got: $wslOut)"
}
Write-Host "WSL IPv4: $wslIp" -ForegroundColor Cyan
$ports = 80, 443, 8443
foreach ($p in $ports) {
    netsh interface portproxy delete v4tov4 listenport=$p listenaddress=0.0.0.0 2>$null
    netsh interface portproxy add v4tov4 listenport=$p listenaddress=0.0.0.0 connectport=$p connectaddress=$wslIp
    Write-Host "  portproxy 0.0.0.0:$p -> $wslIp :$p" -ForegroundColor Green
}
$ruleName = "PitsNG WSL F1 Nginx 80,443,8443"
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existing) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80,443,8443 | Out-Null
    Write-Host "Firewall: added rule for TCP 80,443,8443" -ForegroundColor Green
} else {
    Write-Host "Firewall: rule already present" -ForegroundColor DarkGray
}
Write-Host "Done. Copy nginx config, then: wsl -u root nginx -t && wsl -u root service nginx restart" -ForegroundColor Cyan
