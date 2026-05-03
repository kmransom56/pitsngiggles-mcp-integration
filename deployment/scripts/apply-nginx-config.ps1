#Requires -Version 5.1
<#
.SYNOPSIS
  Apply the repo-owned Nginx reverse proxy config to WSL and verify the F1 Race Engineer route.

.DESCRIPTION
  This script is the single normal path for Nginx runtime configuration. It copies
  deployment/nginx/pitsngiggles-mcp.conf into WSL, regenerates the WSL2 upstream
  snippet, ensures the local FQDN certificate exists and is trusted, validates
  Nginx, reloads it, and runs smoke checks.
#>
param(
    [string]$Fqdn = "f1-race-engineer.netintegrate.net",
    [switch]$SkipSmoke,
    [switch]$RestartOnReloadFailure
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$repoNginxConfig = Join-Path $root "deployment\nginx\pitsngiggles-mcp.conf"
$upstreamScript = Join-Path $root "deployment\scripts\apply-wsl2-nginx-upstreams.sh"
$localCertDir = Join-Path $root "deployment\nginx\local-cert"
$localCert = Join-Path $localCertDir "f1-race-engineer.selfsigned.crt"
$localKey = Join-Path $localCertDir "f1-race-engineer.selfsigned.key"
$liveConfig = "/etc/nginx/sites-available/pitsngiggles-mcp.conf"
$liveEnabled = "/etc/nginx/sites-enabled/pitsngiggles-mcp.conf"
$liveCertDir = "/etc/nginx/ssl/$Fqdn"
$liveCert = "$liveCertDir/fullchain.pem"
$liveKey = "$liveCertDir/privkey.pem"

function ConvertTo-WslPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($resolved -notmatch "^([A-Za-z]):\\(.*)$") {
        throw "Cannot map to WSL path: $resolved"
    }
    $drive = $Matches[1].ToLower()
    $rest = $Matches[2] -replace "\\", "/"
    return "/mnt/$drive/$rest"
}

function ConvertTo-BashLiteral {
    param([Parameter(Mandatory = $true)][string]$Value)

    return "'" + $Value.Replace("'", "'\''") + "'"
}

function Invoke-WslRoot {
    param([Parameter(Mandatory = $true)][string]$Command)

    & wsl.exe -u root bash -lc $Command
    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed with exit $LASTEXITCODE`: $Command"
    }
}

function Test-UrlStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int[]]$AllowedStatus = @(200),
        [int]$TimeoutSec = 12
    )

    $status = & curl.exe -sS --max-time $TimeoutSec -o NUL -w "%{http_code}" $Url 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }
    return ($AllowedStatus -contains [int]$status)
}

function Test-WebSocketOpen {
    param([Parameter(Mandatory = $true)][string]$Url)

    try {
        $ws = [System.Net.WebSockets.ClientWebSocket]::new()
        $cts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(8))
        $ws.ConnectAsync([Uri]$Url, $cts.Token).GetAwaiter().GetResult()
        return ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open)
    } catch {
        return $false
    } finally {
        if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"type":"close"}')
                $segment = [ArraySegment[byte]]::new($bytes)
                $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
            } catch {
            }
        }
        if ($ws) { $ws.Dispose() }
        if ($cts) { $cts.Dispose() }
    }
}

function Ensure-LocalCertificate {
    New-Item -ItemType Directory -Force -Path $localCertDir | Out-Null
    if ((Test-Path -LiteralPath $localCert) -and (Test-Path -LiteralPath $localKey)) {
        Write-Host "  OK local certificate exists: $localCert" -ForegroundColor Green
    } else {
        Write-Host "  Generating local HTTPS certificate for $Fqdn..." -ForegroundColor Yellow
        $certDirWsl = ConvertTo-WslPath $localCertDir
        $cmd = @"
set -e
cd $(ConvertTo-BashLiteral $certDirWsl)
openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 1095 \
  -keyout f1-race-engineer.selfsigned.key \
  -out f1-race-engineer.selfsigned.crt \
  -subj "/CN=$Fqdn" \
  -addext "subjectAltName=DNS:$Fqdn" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" >/dev/null 2>&1
"@
        Invoke-WslRoot $cmd
    }

    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($localCert)
    $trusted = Get-ChildItem Cert:\CurrentUser\Root | Where-Object { $_.Thumbprint -eq $certificate.Thumbprint }
    if ($trusted) {
        Write-Host "  OK certificate trusted for current user: $($certificate.Thumbprint)" -ForegroundColor Green
    } else {
        Write-Host "  Trusting local certificate for current user..." -ForegroundColor Yellow
        & certutil.exe -user -addstore Root $localCert | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "certutil failed to trust $localCert"
        }
    }
}

if (-not (Test-Path -LiteralPath $repoNginxConfig)) {
    throw "Missing repo Nginx config: $repoNginxConfig"
}
if (-not (Test-Path -LiteralPath $upstreamScript)) {
    throw "Missing upstream script: $upstreamScript"
}

Write-Host "Applying repo-owned Nginx config..." -ForegroundColor Cyan
Ensure-LocalCertificate

$repoNginxConfigWsl = ConvertTo-WslPath $repoNginxConfig
$upstreamScriptWsl = ConvertTo-WslPath $upstreamScript
$localCertWsl = ConvertTo-WslPath $localCert
$localKeyWsl = ConvertTo-WslPath $localKey
$backupStamp = Get-Date -Format "yyyyMMddHHmmss"

Write-Host "  Regenerating WSL upstream snippet..." -ForegroundColor Yellow
Invoke-WslRoot "$(ConvertTo-BashLiteral $upstreamScriptWsl)"

Write-Host "  Installing Nginx site config..." -ForegroundColor Yellow
Invoke-WslRoot @"
set -e
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
if [ -f $(ConvertTo-BashLiteral $liveConfig) ] && ! cmp -s $(ConvertTo-BashLiteral $repoNginxConfigWsl) $(ConvertTo-BashLiteral $liveConfig); then
  cp $(ConvertTo-BashLiteral $liveConfig) $(ConvertTo-BashLiteral "$liveConfig.bak.$backupStamp")
fi
install -D -m 644 $(ConvertTo-BashLiteral $repoNginxConfigWsl) $(ConvertTo-BashLiteral $liveConfig)
ln -sfn $(ConvertTo-BashLiteral $liveConfig) $(ConvertTo-BashLiteral $liveEnabled)
"@

Write-Host "  Installing HTTPS certificate..." -ForegroundColor Yellow
Invoke-WslRoot @"
set -e
mkdir -p $(ConvertTo-BashLiteral $liveCertDir)
if [ -f $(ConvertTo-BashLiteral $liveCert) ] && ! cmp -s $(ConvertTo-BashLiteral $localCertWsl) $(ConvertTo-BashLiteral $liveCert); then
  cp $(ConvertTo-BashLiteral $liveCert) $(ConvertTo-BashLiteral "$liveCert.bak.$backupStamp")
fi
if [ -f $(ConvertTo-BashLiteral $liveKey) ] && ! cmp -s $(ConvertTo-BashLiteral $localKeyWsl) $(ConvertTo-BashLiteral $liveKey); then
  cp $(ConvertTo-BashLiteral $liveKey) $(ConvertTo-BashLiteral "$liveKey.bak.$backupStamp")
fi
install -m 644 $(ConvertTo-BashLiteral $localCertWsl) $(ConvertTo-BashLiteral $liveCert)
install -m 600 $(ConvertTo-BashLiteral $localKeyWsl) $(ConvertTo-BashLiteral $liveKey)
"@

Write-Host "  Validating Nginx..." -ForegroundColor Yellow
Invoke-WslRoot "nginx -t"

Write-Host "  Restarting Nginx cleanly..." -ForegroundColor Yellow
Invoke-WslRoot @"
set -e
if pgrep nginx >/dev/null 2>&1; then
  nginx -s quit >/dev/null 2>&1 || true
  for _ in 1 2 3 4 5; do
    pgrep nginx >/dev/null 2>&1 || break
    sleep 1
  done
fi
if pgrep nginx >/dev/null 2>&1; then
  pkill -TERM nginx || true
  for _ in 1 2 3 4 5; do
    pgrep nginx >/dev/null 2>&1 || break
    sleep 1
  done
fi
if pgrep nginx >/dev/null 2>&1; then
  pkill -KILL nginx || true
fi
nginx
"@

if (-not $SkipSmoke) {
    Write-Host "  Running smoke checks..." -ForegroundColor Yellow
    $checks = @(
        @{ Label = "Pits N' Giggles engineer view"; Ok = (Test-UrlStatus "http://127.0.0.1:4768/eng-view") },
        @{ Label = "LAN Race Engineer health"; Ok = (Test-UrlStatus "http://127.0.0.1:11734/health") },
        @{ Label = "FQDN Race Engineer"; Ok = (Test-UrlStatus "https://$Fqdn/race-engineer/") },
        @{ Label = "FQDN STT WebSocket"; Ok = (Test-WebSocketOpen "wss://$Fqdn/race-engineer/ws/stt") }
    )
    $failed = @($checks | Where-Object { -not $_.Ok })
    foreach ($check in $checks) {
        if ($check.Ok) {
            Write-Host "    OK $($check.Label)" -ForegroundColor Green
        } else {
            Write-Host "    FAIL $($check.Label)" -ForegroundColor Red
        }
    }
    if ($failed.Count -gt 0) {
        throw "Smoke checks failed: $($failed.Label -join ', ')"
    }
}

Write-Host "Nginx config is applied and verified." -ForegroundColor Green
