#!/usr/bin/env bash
# Create a 4096-bit RSA key + PEM CSR for the Nginx vhost
# f1-race-engineer.netintegrate.net (adjust CN/SAN in config if your CA requires it).
# After your CA signs, install full chain + key under /etc/nginx/ssl/.../ per deployment/README.md
#
# Usage: sudo bash deployment/scripts/openssl-server-csr-f1.sh [output_dir]
set -euo pipefail

OUT="${1:-/tmp/f1-race-engineer-csr}"
CN="${CN:-f1-race-engineer.netintegrate.net}"
DAYS_KEY="${DAYS_KEY:-3650}"

mkdir -p "$OUT"
KEY="$OUT/${CN}.key"
CSR="$OUT/${CN}.csr"
CFG="$OUT/${CN}.openssl.cnf"

cat > "$CFG" <<EOF
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
CN = ${CN}

[ req_ext ]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ alt_names ]
DNS.1 = ${CN}
EOF

echo "Writing key + CSR to: $OUT"
openssl genrsa -out "$KEY" 4096
chmod 600 "$KEY"
openssl req -new -key "$KEY" -out "$CSR" -config "$CFG"

echo ""
echo "CSR (PEM) — send this to ca.netintegrate.net per their docs (https://ca.netintegrate.net/docs):"
echo "-------------------------------------------------------------------"
cat "$CSR"
echo "-------------------------------------------------------------------"
echo ""
echo "Files:"
echo "  Private key: $KEY  (back up securely; do not share)"
echo "  CSR:         $CSR"
echo "  OpenSSL cfg: $CFG  (for reference)"
