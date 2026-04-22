# Pits N' Giggles - Integrated Race Strategy Center

This repository contains the full integration suite to connect the **Pits N' Giggles** telemetry application with the **Model Context Protocol (MCP)** and provide a unified **Race Strategy Dashboard**.

![Race Strategy Center](screenshots/eng-view.png)


## 🚀 Overview

The integration transforms the local telemetry tool into a professional racing suite by:
1.  **Providing a Secure Reverse Proxy**: Using Nginx to terminate TLS via an internal CA, allowing ChatGPT and other AI models to connect via HTTPS.
2.  **Automating SSL Management**: A custom script handles CSR generation and signing through the `ca.netintegrate.net` API.
3.  **Unified AI Strategy Dashboard**: A premium 2-pane web interface where you can view live telemetry alongside a specialized **Antigravity Race Engineer** AI agent.

![High-Tech Dashboard](screenshots/dashboard-mockup.png)


## 📂 Repository Structure

-   `pitsngiggles-mcp.conf`: The Nginx configuration for the secure proxy and dashboard.
-   `strategy_center.html`: The premium integrated dashboard (served at `https://mcp.netintegrate.net:8443/`).
-   `launch_race_center.ps1`: One-click launcher for the entire suite.
-   `start_mcp.ps1`: Simplified telemetry app starter.
-   `docs/AI_CLIENT_SETUP.md`: Guide for connecting Cursor, ChatGPT, etc.

## 🛠️ Quick Setup (WSL / Ubuntu)

### 1. Nginx Deployment
Copy the config to your Nginx sites-available and enable it:
```bash
sudo cp pitsngiggles-mcp.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/pitsngiggles-mcp.conf /etc/nginx/sites-enabled/
```

### 2. Dashboard Deployment
Move the strategy center to the local web root:
```bash
sudo mkdir -p /var/www/html
sudo cp strategy_center.html /var/www/html/index.html
```

## 🌐 DNS for `mcp.netintegrate.net`

In this lab, **`netintegrate.net` is a local zone**, not public registrar DNS. Authoritative resolvers live on the LAN (for example **`192.168.0.252`** and **`192.168.0.253`**).

### Internal DNS (typical for this repo)

1. **Zone on your DNS servers:** define **`mcp.netintegrate.net`** as an **A** record to the **IPv4 LAN address** of the machine where Nginx listens on **80** and **8443**.
2. **Clients must query those resolvers:** every PC, phone, or AI tool host that should open `https://mcp.netintegrate.net:8443/` needs **DHCP-provided DNS** = `192.168.0.252` / `192.168.0.253`, or a manual static DNS entry on that interface. If Windows still uses only your ISP’s DNS, **`mcp.netintegrate.net` will not resolve** (or will NXDOMAIN), and the browser cannot connect.
3. **Trust your internal CA:** browsers and some MCP clients must **trust the certificate** used by Nginx (import your root CA from **ca.netintegrate.net** into the user or machine store, or accept the risk once in the browser).
4. **TLS paths** on the Nginx host must match `pitsngiggles-mcp.conf` (`fullchain.pem` / `privkey.pem` under `mcp.netintegrate.net`). Wrong or missing files often produce **ERR_CONNECTION_RESET** or certificate warnings.
5. **Firewall:** allow **TCP 80** and **TCP 8443** to Nginx on that host from other LAN clients (and from the same host for loopback tests).
6. **Upstream** (`proxy_pass … :4768`): see comments in `pitsngiggles-mcp.conf`—fix **WSL2 → Windows** gateway IP when it changes, or use **`127.0.0.1`** if the telemetry app runs on the same Linux instance as Nginx.
7. **Check:** from a client using your internal DNS: `nslookup mcp.netintegrate.net 192.168.0.252` then `curl -vkI https://mcp.netintegrate.net:8443/`.

### Browser shows `ERR_CONNECTION_RESET` but `curl` works on the server

- **Run the same curl on the PC where the browser fails** (not only on the Nginx box). If curl fails there, it is network/DNS/firewall, not “Edge vs Chrome.”
- **Browser DNS bypass:** Chrome/Edge **Secure DNS / DNS over HTTPS** can ignore Windows DNS (`192.168.0.252` / `192.168.0.253`) and never see your internal zone. Turn off secure DNS for that profile, or choose **“Use your current service provider”**, then retry.
- **Confirm resolution on that PC:** `nslookup mcp.netintegrate.net 192.168.0.252` must return the **LAN IP of the Nginx host** (same address curl uses).
- **Firewall on the Nginx host:** allow inbound **TCP 8443** (and **80** if you use the HTTP→HTTPS redirect) from **other LAN clients**, not only from `127.0.0.1`.
- **While reproducing in the browser**, tail Nginx errors: `sudo tail -f /var/log/nginx/pitsngiggles-mcp.error.log` — if the log stays empty on reset, packets are not reaching Nginx (firewall/router path).

### Edge: `curl` works on the same PC, but Edge shows `ERR_CONNECTION_RESET`

`curl` and Edge both use Windows, but Edge (Chromium) negotiates TLS and **HTTP/3 (QUIC)** differently than `curl`.

1. **Compare trust:** run `curl -vI https://mcp.netintegrate.net:8443/` **without** `-k`. If that fails certificate verification but **with** `-k` it works, install your **internal root CA** into **Local Computer** trusted roots (`certlm.msc` → *Trusted Root Certification Authorities* → *Certificates* → import). Edge may not treat a user-only import the same way `curl -k` does.
2. **Disable QUIC in Edge:** open `edge://flags`, search **Experimental QUIC protocol**, set to **Disabled**, restart Edge. QUIC uses **UDP** to the same host; broken or filtered UDP can produce resets while **TCP 443/8443 + TLS** (what `curl` uses) still works.
3. **Secure DNS:** Settings → **Privacy, search, and services** → **Security** → use **your current service provider** (not a fixed public resolver) so internal names resolve like `nslookup` does.
4. **Try Google Chrome** on the same PC. If Chrome works and Edge does not, keep QUIC disabled or reset Edge (Settings → Reset settings).
5. **Narrow TLS:** on the Nginx host, temporarily set `ssl_protocols TLSv1.2;` (TLS 1.2 only), `nginx -t && reload`, test Edge again. If that fixes it, note your OpenSSL/nginx build and consider a TLS 1.3 cipher profile update; then restore `TLSv1.2 TLSv1.3` once fixed upstream.
6. **Third‑party HTTPS inspection** (some antivirus): pause web/HTTPS scanning for a quick test; these tools often break Edge before they break `curl`.

The repo’s `pitsngiggles-mcp.conf` sets **`ssl_session_tickets off`** on port 8443, which avoids a class of rare Chromium/Edge + OpenSSL ticket issues—reload Nginx after pulling the latest config.

### If you ever publish the same name on the public internet

Use your registrar’s DNS (or split-horizon) with an **A** record to a **routable** public IP, open the same ports on that edge, and use a publicly trusted chain (or pin your CA only on clients you control).

`launch_race_center.ps1` defaults to `https://mcp.netintegrate.net:8443/`. For testing without internal DNS:  
`$env:STRATEGY_CENTER_URL = 'https://localhost:8443/'` (and use an nginx `server_name` that matches, e.g. `deployment/nginx/…`).

## 🏎️ MCP + Pits n' Giggles (same running app)

The desktop app must expose **HTTP + MCP on port 4768** (ensure **Enable MCP HTTP Server** is checked in the app's **MCP Settings**). Nginx then exposes:

| Path | Purpose |
|------|--------|
| `/` | Strategy Center (`strategy_center.html` as `index.html`) |
| `/telemetry/` | Engineering view iframe (same app) |
| `/mcp` | **SSE MCP** for ChatGPT, Cursor, Claude, etc. |

**Flow:** Start the game session → launch the app → enable the MCP HTTP Server in settings → open `https://mcp.netintegrate.net:8443/` → add **`https://mcp.netintegrate.net:8443/mcp`** as the MCP URL in your AI client.

## 🏎️ Connecting AI Tools

SSE MCP URL: `https://mcp.netintegrate.net:8443/mcp`

---
*Created by Antigravity for high-performance race engineering.*
