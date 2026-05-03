#Requires -Version 5.1
<#
.SYNOPSIS
  Report drift between repo-owned config and the live Windows/WSL runtime.

.DESCRIPTION
  This script does not change system state. It compares the canonical Nginx
  config and local certificate files against WSL, checks expected listeners, and
  confirms the launcher still contains the expected runtime defaults.
#>
param(
    [string]$Fqdn = "f1-race-engineer.netintegrate.net"
)

$ErrorActionPreference = "Continue"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$repoNginxConfig = Join-Path $root "deployment\nginx\pitsngiggles-mcp.conf"
$localCert = Join-Path $root "deployment\nginx\local-cert\f1-race-engineer.selfsigned.crt"
$localKey = Join-Path $root "deployment\nginx\local-cert\f1-race-engineer.selfsigned.key"
$launcher = Join-Path $root "launch_race_center.ps1"
$liveConfig = "/etc/nginx/sites-available/pitsngiggles-mcp.conf"
$liveCert = "/etc/nginx/ssl/$Fqdn/fullchain.pem"
$liveKey = "/etc/nginx/ssl/$Fqdn/privkey.pem"
$liveUpstreams = "/etc/nginx/snippets/pitsngiggles-wsl2-upstream.conf"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Detail = ""
    )

    $results.Add([pscustomobject]@{
        Name = $Name
        Status = $Status
        Detail = $Detail
    })
}

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

function Test-WslFilesEqual {
    param(
        [Parameter(Mandatory = $true)][string]$WindowsPath,
        [Parameter(Mandatory = $true)][string]$WslPath
    )

    if (-not (Test-Path -LiteralPath $WindowsPath)) {
        return "missing-repo"
    }
    $repoWslPath = ConvertTo-WslPath $WindowsPath
    & wsl.exe -u root bash -lc "test -f $(ConvertTo-BashLiteral $WslPath) && cmp -s $(ConvertTo-BashLiteral $repoWslPath) $(ConvertTo-BashLiteral $WslPath)"
    if ($LASTEXITCODE -eq 0) {
        return "match"
    }
    & wsl.exe -u root bash -lc "test -f $(ConvertTo-BashLiteral $WslPath)"
    if ($LASTEXITCODE -ne 0) {
        return "missing-live"
    }
    return "drift"
}

function Test-Listener {
    param([int]$Port)

    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $listener)
}

function Add-FileDriftResult {
    param(
        [string]$Name,
        [string]$RepoPath,
        [string]$LivePath
    )

    $state = Test-WslFilesEqual -WindowsPath $RepoPath -WslPath $LivePath
    switch ($state) {
        "match" { Add-Result $Name "OK" "$LivePath matches repo" }
        "missing-repo" { Add-Result $Name "DRIFT" "Missing repo file: $RepoPath" }
        "missing-live" { Add-Result $Name "DRIFT" "Missing live file: $LivePath" }
        default { Add-Result $Name "DRIFT" "$LivePath differs from repo" }
    }
}

Write-Host "Checking config drift..." -ForegroundColor Cyan

Add-FileDriftResult "Nginx site config" $repoNginxConfig $liveConfig
Add-FileDriftResult "FQDN certificate" $localCert $liveCert
Add-FileDriftResult "FQDN private key" $localKey $liveKey

$upstreamText = & wsl.exe -u root bash -lc "test -f $(ConvertTo-BashLiteral $liveUpstreams) && sed -n '/server /p' $(ConvertTo-BashLiteral $liveUpstreams)" 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($upstreamText -join "`n"))) {
    Add-Result "WSL upstream snippet" "DRIFT" "Missing or unreadable: $liveUpstreams"
} elseif (($upstreamText -join "`n") -match ":4768" -and ($upstreamText -join "`n") -match ":11734") {
    Add-Result "WSL upstream snippet" "OK" "Contains upstreams for 4768 and 11734"
} else {
    Add-Result "WSL upstream snippet" "DRIFT" "Does not contain expected upstream ports"
}

foreach ($port in 80, 443, 8443, 4768, 11734) {
    if (Test-Listener -Port $port) {
        Add-Result "Listener TCP $port" "OK" "Port is listening"
    } else {
        Add-Result "Listener TCP $port" "DRIFT" "Port is not listening"
    }
}

$launcherText = if (Test-Path -LiteralPath $launcher) {
    Get-Content -LiteralPath $launcher -Raw
} else {
    ""
}
$expectedDefaults = [ordered]@{
    ENGINEER_VOICE_PORT = "11734"
    OLLAMA_MODEL = "llama3.1:8b"
    WHISPER_DEVICE = "cpu"
    WHISPER_COMPUTE = "int8"
    WHISPER_MODEL = "base.en"
    WS_STT_CHUNK_S = "0.8"
}
foreach ($entry in $expectedDefaults.GetEnumerator()) {
    $literalPattern = [regex]::Escape('$env:' + $entry.Key) + '\s*=\s*"' + [regex]::Escape($entry.Value) + '"'
    $derivedEngineerPortPattern = '\$EngineerPort\s*=\s*' + [regex]::Escape($entry.Value) + '\b'
    $derivedEnvPortPattern = [regex]::Escape('$env:' + $entry.Key) + '\s*=\s*"\$EngineerPort"'
    $matchesExpected = $launcherText -match $literalPattern
    if ($entry.Key -eq "ENGINEER_VOICE_PORT") {
        $matchesExpected = $matchesExpected -or (($launcherText -match $derivedEngineerPortPattern) -and ($launcherText -match $derivedEnvPortPattern))
    }

    if ($matchesExpected) {
        Add-Result "Launcher default $($entry.Key)" "OK" $entry.Value
    } else {
        Add-Result "Launcher default $($entry.Key)" "DRIFT" "Expected default '$($entry.Value)' in $launcher"
    }
}

$results | Format-Table -AutoSize

$drift = @($results | Where-Object { $_.Status -ne "OK" })
if ($drift.Count -gt 0) {
    Write-Host ""
    Write-Host "Drift detected. Run deployment\scripts\apply-nginx-config.ps1 after services are started." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "No config drift detected." -ForegroundColor Green
