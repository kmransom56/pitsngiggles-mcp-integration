# TLS certificate via **ca.netintegrate.net** (API)

The CA runs on your **LAN**; build agents and cloud tools often **cannot** open `https://ca.netintegrate.net/docs`. Read the live API on a machine that resolves internal DNS, then use the flow below.

## 1. API surface (ca.netintegrate.net — Cert-Manager)

Open **[https://ca.netintegrate.net/docs](https://ca.netintegrate.net/docs)** or **`/openapi.json`**. The LAN CA exposes (among others):

- **`POST /api/generate-cert`** — JSON body; can return PEM in the response when `includeContent` is true
- **`POST /api/sign-csr`** — `multipart/form-data` with a **`csr`** file (`.csr` / `.pem`)
- **`GET /api/download-cert/{domain}`** — download issued files after generation (e.g. `?type=...` if your build supports it)
- **`GET /api/download-root-ca`** — root CA for client trust stores

Add **auth headers** or TLS client rules only if your deployment requires them (the public schema may not list every constraint).

## 2. Create a private key and CSR

**Linux / WSL / macOS (bash):**

```bash
cd /path/to/pitsngiggles-mcp-integration
bash deployment/scripts/openssl-server-csr-f1.sh /tmp/f1-csr
```

**Windows (OpenSSL in PATH):**

```powershell
.\deployment\scripts\New-F1RaceEngineerCsr.ps1 -OutputDir "$env:TEMP\f1-csr"
```

This produces `*.key` (secret) and `*.csr` (send to the CA). **Never** commit the key.

## 3. Issue or sign (pick one)

### 3a. Generate on the CA (`POST /api/generate-cert`)

Returns certificate material in the JSON when **`includeContent`** is true (use the response fields your OpenAPI documents — often PEM or paths).

```bash
curl -sS -k -X POST "https://ca.netintegrate.net/api/generate-cert" \
  -H "Content-Type: application/json" \
  -d '{"serverName":"f1-race-engineer.netintegrate.net","certificateType":"server","includeContent":true}'
```

Adjust **`certificateType`**, **`validityDays`**, **`serverIp`**, etc. per `/docs`.

### 3b. Sign a CSR you created locally (`POST /api/sign-csr`)

```bash
curl -sS -k -X POST "https://ca.netintegrate.net/api/sign-csr" \
  -F "csr=@/tmp/f1-csr/f1-race-engineer.netintegrate.net.csr" \
  -F "caName=intermediate" \
  -F "validityDays=365"
```

### 3c. Download after issuance (`GET /api/download-cert/{domain}`)

- **`?type=chain`** — PEM full chain (server + intermediates) for Nginx `ssl_certificate` / `fullchain.pem`
- **`?type=key`** — private key for `ssl_certificate_key` / `privkey.pem` (treat as secret)

```bash
curl -sS -k "https://ca.netintegrate.net/api/download-cert/f1-race-engineer.netintegrate.net?type=chain" -o fullchain.pem
curl -sS -k "https://ca.netintegrate.net/api/download-cert/f1-race-engineer.netintegrate.net?type=key"   -o privkey.pem
```

On the Nginx host, use **`deployment/scripts/install-f1-tls-from-ca.sh`** to fetch, set permissions, and reload Nginx (see [deployment README](../README.md#manual-setup)).

If the API returns a **PEM full chain** and you already have the **private key** from step 2 (for path 3b), or a separate key from the generate response (for 3a — follow your CA’s layout):

- Save the chain to  
  `sudo install -D -m 644 fullchain.pem /etc/nginx/ssl/f1-race-engineer.netintegrate.net/fullchain.pem`
- Install the key (same path as in `nginx/pitsngiggles-mcp.conf`):  
  `privkey.pem` from step 2 → `/etc/nginx/ssl/f1-race-engineer.netintegrate.net/privkey.pem`  
  `sudo chmod 600 .../privkey.pem`
- `sudo nginx -t && sudo systemctl reload nginx`

## 4. Trust on clients

```bash
curl -sS -k -o root-ca.pem "https://ca.netintegrate.net/api/download-root-ca"
```

Import that **root** (or your org’s published issuing chain) so browsers and `curl` verify without `-k`. See the main [README.md](../../README.md) TLS section for Windows / Edge.

## 5. Operator note (PATH / subprocess env)

If **`sign-csr`** returns **`400` “Could not parse CSR”** while the PEM is valid, or **`generate-cert`** fails with **`openssl` / `mkdir` / `cat` not found** inside the API’s logs, the worker process may be running with a **venv-only `PATH`** and no system paths. The CA service should **merge the caller environment with `os.environ` and ensure `/usr/bin` and `/bin` (or the OS equivalents) are on `PATH`** for any shell/`openssl` subprocess. That class of misconfiguration made OpenSSL’s CSR check look like an “invalid” CSR and broke `generate_server_cert.sh`.

## 6. If the web UI is easier

Use the **dashboard** from the docs to paste a CSR or request a cert, then still place files in the paths in the [deployment README — Manual setup](../README.md#manual-setup).
