# Pits N' Giggles MCP Integration - Project Onboarding

## Overview
This project integrates the "Pits N' Giggles" F1 telemetry application with the Model Context Protocol (MCP). It includes a Race Strategy Center dashboard served via Nginx.

## Architecture
- **Nginx (WSL)**: Acts as a reverse proxy, handling SSL (port 8443) and proxying requests to the telemetry app running on Windows.
- **Pits N' Giggles (Windows)**: A FastAPI/Uvicorn application (`pits_n_giggles_3.2.1.exe`) that receives F1 game telemetry (port 20777) and serves a web UI + Socket.IO (port 4768).
- **Dashboard**: A static HTML page (`strategy_center.html`) that embeds the telemetry engineering view in an iframe.
- **MCP Integration**: Intended to expose an SSE endpoint at `/mcp` for AI agents.

## Key Files
- `pitsngiggles-mcp.conf`: Nginx configuration.
- `start_mcp.ps1` / `launch_race_center.ps1`: PowerShell scripts to start the environment.
- `engView.js`: Client-side logic for the engineering view.
- `png_config.json`: Telemetry app configuration.

## Issues Identified & Fixed
- **Dashboard Telemetry**: The dashboard was not receiving data because Nginx was not proxying `socket.io` traffic. Fixed by adding the `/socket.io/` location to Nginx config.
- **App Startup**: The app `3.2.1` does not recognize the `--mcp` flag, causing it to fail to start the server when the flag is present. Fixed by removing the flag from startup scripts.

## Unresolved Issues
- **MCP Endpoint (404)**: The `/mcp` endpoint is not served by the current EXE version. Documentation suggests it should be there, but the binary lacks the implementation or the flag to enable it.
