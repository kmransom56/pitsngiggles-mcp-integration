#Requires -Version 5.1
# Generate RSA key + CSR for f1-race-engineer.netintegrate.net (Nginx TLS).
# Install OpenSSL: choco install openssl  OR  use Git for Windows `openssl`
# Use the .csr with https://ca.netintegrate.net/docs (LAN) — this machine cannot see your CA API.
param(
    [string]$OutputDir = (Join-Path $env:TEMP "f1-race-engineer-csr"),
    [string]$CommonName = "f1-race-engineer.netintegrate.net"
)

$ErrorActionPreference = "Stop"
$openssl = Get-Command openssl -ErrorAction SilentlyContinue
if (-not $openssl) {
    Write-Error "openssl not found. Install OpenSSL, or run deployment/scripts/openssl-server-csr-f1.sh on Linux/WSL."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$key = Join-Path $OutputDir "$CommonName.key"
$csr = Join-Path $OutputDir "$CommonName.csr"
$cfg = Join-Path $OutputDir "$CommonName.openssl.cnf"

@"

[ req ]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[ dn ]
C  = US
ST = State
L  = City
O  = Netintegrate
OU = Pits n Giggles
CN = $CommonName

[ req_ext ]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ alt_names ]
DNS.1 = $CommonName
"@ | Set-Content -Path $cfg -Encoding ASCII

& openssl genrsa -out $key 4096
& openssl req -new -key $key -out $csr -config $cfg

Write-Host "Private key: $key"
Write-Host "CSR:         $csr"
Write-Host ""
Write-Host "CSR (PEM) for ca.netintegrate.net — next steps in deployment/docs/CA_API_CERT.md"
Get-Content $csr
