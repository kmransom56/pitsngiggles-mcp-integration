---
id: pitsngiggles-2026-04-07-cursor-strategy-mcp
kind: session-note
title: Cursor, Strategy Center MCP warning, and repo sync (session notes)
summary: >
  Cursor was steered into CLAUDE.md doc-reconcile loops; a Cursor rule fixes that.
  Strategy Center showed "MCP not running" because nginx /health targets Docker MCP,
  while in-browser chat uses PNG /api/chat — health check removed from mcp_chat init.
  Fork push and optional upstream PR noted for GitHub sync.
written: 2026-04-07
updated: 2026-04-07
tags:
  - cursor
  - claude-md
  - strategy-center
  - mcp
  - nginx
  - docker-compose.mcp
  - github
components:
  - .cursor/rules/no-claude-md-chat-loops.mdc
  - apps/frontend/html/strategy-center.html
  - docker-compose.mcp.yml
  - nginx/conf.d/default.conf
symptoms:
  - Chat keeps suggesting CLAUDE.md updates or doc reconcile lists
  - Strategy Center warns MCP server not running while Race Engineer or chat still works
---

# Session notes — troubleshooting and updates

Concise record of issues discussed and changes made, for future debugging and doc updates.

## 1. Cursor looping on `CLAUDE.md`

**Symptom:** Chat repeatedly suggests verifying, reconciling, or editing `CLAUDE.md` instead of staying on the coding task.

**Cause:** Large always-on context plus `git status` showing `M CLAUDE.md` encourages “doc reconcile” behavior.

**Mitigation in repo:**

- **`.cursor/rules/no-claude-md-chat-loops.mdc`** (`alwaysApply: true`) — do not read/edit/summarize `CLAUDE.md` unless the user explicitly asks; ignore `CLAUDE.md` in git status for that purpose; no doc-reconcile narration.

**Project rule (already in `CLAUDE.md`):** Cursor should not open/close answers with “update CLAUDE.md” or paste doc-reconcile lists unless the user asked to refresh project memory.

---

## 2. Strategy Center: “MCP server may not be running” / `./start-mcp.sh`

**Symptom:** On load, `mcp_chat` mode showed:  
`⚠️ Warning: MCP server may not be running. Start it with ./start-mcp.sh`  
even when in-browser chat could work.

**Cause:** Init code called **`GET /health`** on the same origin as the page. With **`docker-compose.mcp.yml` + nginx**, `location /health` proxies to the **Docker MCP service** (`mcp-server:8765`), not PNG. In-browser **mcp_chat** actually uses **PNG**: `POST /api/chat` and `POST /mcp/tools`. So a down MCP container produced a misleading warning.

**Fix (in `apps/frontend/html/strategy-center.html`):** Removed the `mcp_chat` startup `fetch('/health')` check; added a short comment explaining nginx vs PNG.

**When `./start-mcp.sh` still matters:**

- External AI clients using Docker MCP: `POST /mcp/chat`, `WS /mcp/ws` (port **8765** or nginx **`/mcp/`**).
- Operators using nginx **`/health`** as the MCP container health endpoint.

**If browser chat fails:** Ensure PNG is running (e.g. **4768**), API keys/env for `/api/chat` are set. If the UI is served only via nginx, confirm **`/api/chat`**, **`/race-info`**, etc. are proxied to PNG (default MCP nginx config mainly proxies **`/telemetry/`** to PNG).

---

## 3. GitHub update (fork)

**Remote:** `fork` → `git@github.com:kmransom56/pitsngiggles-mcp-integration.git`  
**Branch:** `feature/f1-race-engineer-mcp`  
**Example commit:** `d7964a9` — *feat(ui): AI message formatting and Strategy Center MCP init fix*

**That commit included (among others):** strategy/voice HTML, `ai-message-format*.js`, `tests/endpoints_test.py`, `.cursor/rules/no-claude-md-chat-loops.mdc`, `CLAUDE.md` touch-up.

**Upstream:** `origin` → `ashwin-nat/pits-n-giggles` — open a PR from the fork branch when ready.

---

## 4. Follow-ups (optional)

- Add nginx `location` blocks for PNG **`/api/chat`**, **`/mcp/tools`**, **`/race-info`** if Strategy Center must work from the nginx origin without path hacks.
- Re-run **`pytest tests/endpoints_test.py`** with the project’s fixture setup (e.g. conftest `hostname`/`port`) if extending endpoint tests.

---

*Generated from a Cursor working session; edit this file as behavior or URLs change.*
