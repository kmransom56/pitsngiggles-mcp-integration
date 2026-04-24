#Requires -Version 5.1
<#
.SYNOPSIS
  On Windows + WSL: install F1 vhost TLS from ca.netintegrate.net into the WSL Nginx
  path (/etc/nginx/ssl/...), then reload Nginx. Same machine that runs launch_race_center.ps1.

.EXAMPLE
  # Admin PowerShell (required only for -ImportRootCa to Local Machine store):
  .\Install-F1TlsFromCa.ps1
  .\Install-F1TlsFromCa.ps1 -ImportRootCa
#>
param(
    [string]$Domain = "f1-race-engineer.netintegrate.net",
    [string]$CaBase = "https://ca.netintegrate.net",
    [switch]$ImportRootCa
)

$ErrorActionPreference = "Stop"

function ConvertTo-WslPath {
    param([string]$WindowsPath)
    $p = (Resolve-Path -LiteralPath $WindowsPath).Path
    if ($p -notmatch "^([A-Za-z]):\\(.*)$") { throw "Cannot map to WSL path: $p" }
    $drive = $Matches[1].ToLower()
    $rest = $Matches[2] -replace "\\", "/"
    return "/mnt/$drive/$rest"
}

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "WSL is required (Nginx for this app runs in WSL on this host)."
}
$null = wsl -l -q 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "WSL is not available or has no default distro. Install/launch WSL once, then re-run."
}

$here = $PSScriptRoot
$sh = Join-Path $here "install-f1-tls-from-ca.sh"
if (-not (Test-Path -LiteralPath $sh)) {
    throw "Missing: $sh"
}
$wslSh = ConvertTo-WslPath $sh

Write-Host "Installing F1 TLS in WSL (root) - $wslSh" -ForegroundColor Cyan
& wsl.exe -u root env "DOMAIN=$Domain" "CA_BASE=$CaBase" "CURL_INSECURE=1" bash $wslSh
if ($LASTEXITCODE -ne 0) {
    throw "install-f1-tls-from-ca.sh failed with exit code $LASTEXITCODE"
}
Write-Host "WSL Nginx TLS install finished." -ForegroundColor Green

if ($ImportRootCa) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw 'Run PowerShell as Administrator to use -ImportRootCa, or import the root CA manually in certlm.msc.'
    }
    $rootUrl = $CaBase.TrimEnd("/") + "/api/download-root-ca"
    $rootPem = Join-Path $env:TEMP "netintegrate-root-ca-$(Get-Date -Format 'yyyyMMdd').pem"
    Write-Host "Downloading root CA to $rootPem" -ForegroundColor Cyan
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Invoke-WebRequest -Uri $rootUrl -OutFile $rootPem -UseBasicParsing -SkipCertificateCheck
    } else {
        $prev = $null
        try { $prev = [System.Net.ServicePointManager]::ServerCertificateValidationCallback; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } } catch { }
        try { Invoke-WebRequest -Uri $rootUrl -OutFile $rootPem -UseBasicParsing } finally {
            if ($null -ne $prev) { [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $prev }
        }
    }
    Import-Certificate -FilePath $rootPem -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
    Write-Host 'Imported root CA to Local Machine / Trusted Root Certification Authorities store.' -ForegroundColor Green
    Remove-Item -LiteralPath $rootPem -Force -ErrorAction SilentlyContinue
}
