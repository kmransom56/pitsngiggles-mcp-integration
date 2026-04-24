# Pits n' Giggles - Nginx Reverse Proxy Deployment

This directory contains the Nginx reverse proxy configuration for exposing the Pits n' Giggles MCP server over HTTPS.

## Quick Setup

Run the automated setup script:

```bash
cd deployment/scripts
./setup-nginx.sh
```

This will:
1. Generate a self-signed SSL certificate
2. Install the Nginx configuration
3. Enable and reload Nginx

## Manual Setup

### 1. SSL certificates

`setup-nginx.sh` creates two self-signed cert pairs:

- `/etc/nginx/ssl/pitsngiggles/` — `server_name` **localhost** / **mcp.local**
- `/etc/nginx/ssl/f1-race-engineer.netintegrate.net/` — **f1-race-engineer.netintegrate.net** (A record to this Nginx host)

To generate manually:

```bash
./scripts/generate-self-signed-cert.sh /etc/nginx/ssl/pitsngiggles localhost
./scripts/generate-self-signed-cert.sh /etc/nginx/ssl/f1-race-engineer.netintegrate.net f1-race-engineer.netintegrate.net
```

Replace with CA-issued certificates (below) or point `ssl_certificate` / `ssl_certificate_key` in `nginx/pitsngiggles-mcp.conf` to your PEM paths.

### ca.netintegrate.net — server certificates (recommended for LAN)

Use your org’s CA instead of long-lived self-signed certs so browsers and MCP clients trust **f1-race-engineer.netintegrate.net** without per-site exceptions.

1. **Documentation:** open **[https://ca.netintegrate.net/docs](https://ca.netintegrate.net/docs)** on a machine on your LAN (external networks often time out). Capture the signing/submit API from there, then see **[CA_API_CERT.md](docs/CA_API_CERT.md)** in this repo for key + CSR generation and Nginx file placement.
2. **Name to request:** issue a **server** (TLS) certificate for **`f1-race-engineer.netintegrate.net`** (SAN should include that FQDN if your CA lists multiple names).
3. **Install on the Nginx host** (paths must match the FQDN `server` block in `nginx/pitsngiggles-mcp.conf`):
   - `ssl_certificate` → typically a **full chain** file (e.g. `fullchain.pem`: server + intermediates)
   - `ssl_certificate_key` → private key (e.g. `privkey.pem`) readable only by the user Nginx runs as
   - Default directories in this repo:  
     `/etc/nginx/ssl/f1-race-engineer.netintegrate.net/fullchain.pem`  
     `/etc/nginx/ssl/f1-race-engineer.netintegrate.net/privkey.pem`
4. **Automated install (Cert-Manager on the LAN):** on the Nginx host, after `setup-nginx.sh` (or with the vhost and paths already in place):

   **Linux (or WSL as root):**

   ```bash
   cd /path/to/pitsngiggles-mcp-integration/deployment/scripts
   sudo chmod +x install-f1-tls-from-ca.sh
   sudo ./install-f1-tls-from-ca.sh
   ```

   **Windows + WSL** (same box as `launch_race_center.ps1`; Nginx runs inside WSL):

   ```powershell
   cd deployment\scripts
   .\Install-F1TlsFromCa.ps1
   ```

   Optional (requires **Administrator** PowerShell): `.\Install-F1TlsFromCa.ps1 -ImportRootCa` imports the org root into **Local Machine** so Schannel/Edge trust the site without per-site bypasses.

   The script fetches the **full chain** (`?type=chain`) and **private key** (`?type=key`) from the CA, writes them with **`0644` / `0600`**, **root:root**, **`0750`** on the directory, then **`nginx -t`** and reloads Nginx (`systemctl`, `service`, or `nginx -s reload` as available). Override **`CA_BASE`** or **`DOMAIN`** via `env` on Linux or `-CaBase` / `-Domain` on Windows.

5. **Permissions (if installing by hand):** e.g. `chmod 600` on the key, `chmod 644` on the cert chain; do not leave copies of the key in `/tmp` or world-readable locations.
6. **Test and reload (if you skipped the script):** `sudo nginx -t && sudo systemctl reload nginx`
7. **Trust on clients (Windows / other machines):** import your organization’s **root** (or issuing) CA from **ca.netintegrate.net** into the system trust store (e.g. Windows *Local Computer* → *Trusted Root Certification Authorities*) so `curl` and Edge verify without `-k`. See the main [README.md](../README.md) TLS troubleshooting on your LAN.

You can still use the self-sign script for **`localhost`** / **`mcp.local`** while using a CA-issued cert only for the **`f1-race-engineer.netintegrate.net`** vhost.

### 2. Install Nginx Configuration

```bash
sudo cp nginx/pitsngiggles-mcp.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/pitsngiggles-mcp.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## MCP / Strategy Center URLs

After install, Nginx answers on **:8443** for:

- `https://localhost/…` and `https://mcp.local/…` (local dev, self-signed in `pitsngiggles/`)
- `https://f1-race-engineer.netintegrate.net/…` when the **A** record points to this host (certs in `f1-race-engineer.netintegrate.net/` or your CA paths)

MCP (SSE) path: `/f1-race-engineer-lan` (legacy: `/mcp`).

- **HTTP** on port 80 redirects both name sets to **HTTPS 8443**.

## Connecting AI Tools

### ChatGPT Desktop
1. Enable Developer Mode in Settings
2. Create New App:
   - Name: `Pits n' Giggles`
   - URL: `https://localhost:8443/f1-race-engineer-lan`
   - Transport: `SSE`

### Cursor IDE
1. Settings → Features → MCP
2. Add Server:
   - Name: `Telemetry`
   - Type: `SSE`
   - URL: `https://localhost:8443/f1-race-engineer-lan`

### Claude Desktop
Edit `%APPDATA%\Claude\claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "pitsngiggles": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://localhost:8443/f1-race-engineer-lan"]
    }
  }
}
```

## Troubleshooting

### Check Nginx Status
```bash
sudo systemctl status nginx
```

### View Logs
```bash
sudo tail -f /var/log/nginx/pitsngiggles-mcp.error.log
sudo tail -f /var/log/nginx/pitsngiggles-mcp.access.log
```

### Test Certificate
```bash
openssl s_client -connect localhost:8443 -servername localhost
```

### SSL Certificate Warnings
The self-signed certificate will show warnings in browsers and AI tools. You need to:
- **Browser**: Accept the certificate exception
- **ChatGPT/AI Tools**: May need to add certificate to system trust store

## Production / LAN with DNS

1. **TLS:** Prefer certificates from **[ca.netintegrate.net](https://ca.netintegrate.net/docs)** for `f1-race-engineer.netintegrate.net` (see above). Public **Let’s Encrypt** is an option only if the hostname is resolvable and reachable from the public internet the way you run ACME.
2. **DNS:** **A** record for `f1-race-engineer.netintegrate.net` → Nginx host (already assumed in this config).
3. **Firewall:** allow **TCP 80** and **8443** to the Nginx host from clients that use the dashboard or MCP.
4. **Config:** `server_name` and paths in `pitsngiggles-mcp.conf` are already set for the FQDN vhost; adjust only if you use different file locations.

## Files

- `nginx/pitsngiggles-mcp.conf` - Nginx configuration
- `docs/CA_API_CERT.md` - LAN CA: CSR + Nginx install (works with [ca.netintegrate.net/docs](https://ca.netintegrate.net/docs))
- `scripts/openssl-server-csr-f1.sh` - key + CSR for `f1-race-engineer.netintegrate.net` (bash)
- `scripts/New-F1RaceEngineerCsr.ps1` - same, Windows (requires `openssl` in PATH)
- `scripts/generate-self-signed-cert.sh` - self-signed dev certs
- `scripts/setup-nginx.sh` - Automated setup script
