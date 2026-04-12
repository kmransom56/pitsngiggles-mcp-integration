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
