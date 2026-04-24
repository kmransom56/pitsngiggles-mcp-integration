#!/usr/bin/env bash
# Download CA-issued full chain + private key from ca.netintegrate.net, install under
# /etc/nginx/ssl/f1-race-engineer.netintegrate.net/, set ownership and modes, then
# validate and reload Nginx. Run on the Nginx host (Debian/Ubuntu-style paths).
#
# Environment (optional):
#   DOMAIN   — default: f1-race-engineer.netintegrate.net
#   CA_BASE  — default: https://ca.netintegrate.net
#   CURL_INSECURE — default: 1 (pass -k to curl for internal TLS / not-yet-trusted CAs; set 0 when CA is in trust store)
#
# Usage: sudo -E env CA_BASE=... ./install-f1-tls-from-ca.sh
# Or:   sudo ./install-f1-tls-from-ca.sh
#
set -euo pipefail

DOMAIN="${DOMAIN:-f1-race-engineer.netintegrate.net}"
CA_BASE="${CA_BASE:-https://ca.netintegrate.net}"
CURL_INSECURE="${CURL_INSECURE:-1}"
SSL_DIR="/etc/nginx/ssl/${DOMAIN}"
CHAIN_URL="${CA_BASE}/api/download-cert/${DOMAIN}?type=chain"
KEY_URL="${CA_BASE}/api/download-cert/${DOMAIN}?type=key"

if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "Run as root (e.g. sudo $0)" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl_get() {
  if [[ "$CURL_INSECURE" == "1" ]]; then
    curl -sS -fL -k "$1" -o "$2"
  else
    curl -sS -fL "$1" -o "$2"
  fi
}

echo "==> Downloading full chain: $CHAIN_URL"
curl_get "$CHAIN_URL" "$tmp/fullchain.pem"

echo "==> Downloading private key:  $KEY_URL"
curl_get "$KEY_URL" "$tmp/privkey.pem"

echo "==> Verifying PEM material"
if ! openssl x509 -in "$tmp/fullchain.pem" -noout -subject 2>/dev/null; then
  echo "fullchain.pem does not look like a valid certificate chain" >&2
  exit 1
fi
if ! openssl pkey -in "$tmp/privkey.pem" -noout 2>/dev/null; then
  echo "privkey.pem is not a valid private key" >&2
  exit 1
fi

echo "==> Installing to $SSL_DIR (root:root, 644 chain / 600 key, 0750 directory)"
install -d -m 0750 -o root -g root "$SSL_DIR"
install -m 0644 -o root -g root "$tmp/fullchain.pem" "$SSL_DIR/fullchain.pem"
install -m 0600 -o root -g root "$tmp/privkey.pem" "$SSL_DIR/privkey.pem"
chmod 0750 "$SSL_DIR"

echo "==> Testing and reloading Nginx"
nginx -t
if command -v systemctl &>/dev/null && systemctl is-active --quiet nginx 2>/dev/null; then
  systemctl reload nginx
elif command -v service &>/dev/null; then
  service nginx reload
else
  nginx -s reload
fi
echo "==> Done. $DOMAIN TLS is active (paths match nginx/pitsngiggles-mcp.conf)."
