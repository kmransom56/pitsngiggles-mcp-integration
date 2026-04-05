#!/usr/bin/env bash
# Generate self-signed SSL certificate for local MCP server

set -euo pipefail

CERT_DIR="${1:-/etc/nginx/ssl/pitsngiggles}"
DOMAIN="${2:-localhost}"

echo "Creating SSL certificate directory: $CERT_DIR"
sudo mkdir -p "$CERT_DIR"

# Generate OpenSSL config
cat > /tmp/pitsngiggles-ssl.cnf <<EOF
[ req ]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext
x509_extensions = v3_ca

[ dn ]
C = US
ST = State
L = City
O = Pits n Giggles
OU = Telemetry
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
subjectAltName = @alt_names
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = mcp.local
DNS.3 = localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

echo "Generating private key and self-signed certificate..."
sudo openssl req -x509 -nodes -days 365 \
    -newkey rsa:4096 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -config /tmp/pitsngiggles-ssl.cnf

sudo chmod 600 "$CERT_DIR/privkey.pem"
sudo chmod 644 "$CERT_DIR/fullchain.pem"

rm -f /tmp/pitsngiggles-ssl.cnf

echo "✓ Certificate generated successfully!"
echo "  Certificate: $CERT_DIR/fullchain.pem"
echo "  Private Key: $CERT_DIR/privkey.pem"
echo ""
echo "To trust this certificate in your browser:"
echo "  Chrome/Edge: Import $CERT_DIR/fullchain.pem to 'Trusted Root Certification Authorities'"
echo "  Firefox: Settings > Privacy & Security > Certificates > View Certificates > Import"
