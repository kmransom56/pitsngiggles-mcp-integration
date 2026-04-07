# Docker Deployment Guide

## MCP + nginx only (`docker-compose.mcp.yml`)

The recommended **AI reverse-proxy stack** is **`docker-compose.mcp.yml`**: it runs **only** `mcp-server` and `nginx`. **Pits N Giggles stays on the host** at **`http://localhost:4768`** (UDP ingest + main UI). Nginx maps:

| Path on nginx | Goes to |
|---------------|---------|
| `/` | Static Strategy Center (`apps/frontend/html`) |
| `/telemetry/` | PNG on host (`host.docker.internal:4768/`) — e.g. `/telemetry/mcp` → PNG’s SSE MCP |
| `/mcp/` | Docker **`mcp_server`** (`mcp_server/server.py`) on port 8765 |
| `/health` | MCP **`GET /health`** |

**Published ports (compose defaults):** `9080→80` (HTTP redirect to HTTPS), `9443→443` (HTTPS), **`8765`** (direct MCP, bypass nginx). Override with `HTTP_PORT` / `HTTPS_PORT` in `.env.mcp` (example file uses `80`/`443`).

**`mcp_server` transport (FastAPI):** **`POST /mcp/chat`**, **`WebSocket /mcp/ws`**, **`GET /mcp/telemetry/history`**, **`POST /mcp/analyze`**. There is **no** `/mcp/sse` in this container — see [MCP surfaces](#mcp-sse-vs-docker-mcp_server) below.

```bash
docker compose -f docker-compose.mcp.yml --env-file .env.mcp up -d
```

Direct MCP (no nginx): `http://localhost:8765/health`, `POST http://localhost:8765/mcp/chat`.

---

## MCP: SSE vs Docker `mcp_server`

| Surface | Where | SSE `GET …/mcp` | Docker FastAPI `/mcp/chat` + `/mcp/ws` |
|---------|--------|-----------------|----------------------------------------|
| **PNG embedded MCP** | Host `:4768` | Yes — `http://localhost:4768/mcp` | PNG routes: `POST /api/chat`, tools under `/mcp/tools` |
| **Via nginx + Docker MCP only** | `https://localhost:<HTTPS_PORT>` | Use **`/telemetry/mcp`** (proxied to PNG) | Use **`/mcp/chat`** and **`/mcp/ws`** (FastAPI in container) |

Docs that mention **`/mcp/sse`** were **out of date**: neither PNG nor `mcp_server` exposes that path.

---

## Quick Start (repo `./start.sh`)

```bash
./start.sh
```

That's it! The script will:
1. Check for Docker and Docker Compose
2. Create `.env` if needed
3. Build and start all services
4. Show you the access URLs

## What's Included

### Services

1. **f1-race-engineer-mcp** (Port 8765)
   - FastAPI MCP server (`mcp_server/server.py`)
   - F1 Race Engineer AI agent
   - HTTP **`/mcp/chat`** and WebSocket **`/mcp/ws`** (not SSE)

2. **f1-nginx-proxy** (host ports from env, defaults **9080** / **9443**)
   - Nginx reverse proxy
   - Serves Strategy Center UI
   - Proxies **`/mcp/*`** to MCP and **`/telemetry/*`** to host PNG `:4768`

### Networks

- `f1-network` - Bridge network connecting all services

### Volumes

- `mcp-data` - Persistent data for MCP server
- `nginx-logs` - Nginx access and error logs
- `ssl-certs` - SSL certificates

## Configuration

### Environment Variables (.env)

```bash
# LLM Configuration (optional)
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-your-api-key

# Or leave empty for built-in fallback responses
LLM_ENDPOINT=
LLM_API_KEY=
```

### Connecting to Pits N Giggles

**Default**: Assumes Pits N Giggles runs on host machine port 4768

**Custom Host/Port**: Edit `nginx/conf.d/default.conf`

```nginx
location /telemetry/ {
    proxy_pass http://YOUR_IP:YOUR_PORT/;
    # ...
}
```

Then restart:
```bash
docker compose -f docker-compose.mcp.yml restart nginx
```

### Custom Ports

Edit **`docker-compose.mcp.yml`** (or set `HTTP_PORT` / `HTTPS_PORT` in `.env.mcp`):

```yaml
services:
  nginx:
    ports:
      - "${HTTP_PORT:-9080}:80"
      - "${HTTPS_PORT:-9443}:443"
```

## Commands

### Start Services

```bash
./start.sh
# MCP + nginx only:
docker compose -f docker-compose.mcp.yml --env-file .env.mcp up -d
```

### Stop Services

```bash
./stop.sh
# Or MCP stack:
docker compose -f docker-compose.mcp.yml down
```

### View Logs

```bash
# All services
docker compose -f docker-compose.mcp.yml logs -f

# Specific service
docker compose -f docker-compose.mcp.yml logs -f mcp-server
docker compose -f docker-compose.mcp.yml logs -f nginx

# Last 100 lines
docker compose -f docker-compose.mcp.yml logs --tail=100 mcp-server
```

### Restart Services

```bash
# All
docker compose -f docker-compose.mcp.yml restart

# Specific
docker compose -f docker-compose.mcp.yml restart mcp-server
docker compose -f docker-compose.mcp.yml restart nginx
```

### Rebuild Services

```bash
docker compose -f docker-compose.mcp.yml up -d --build
docker compose -f docker-compose.mcp.yml up -d --build mcp-server
```

### Enter Container Shell

```bash
docker compose -f docker-compose.mcp.yml exec mcp-server /bin/bash
docker compose -f docker-compose.mcp.yml exec nginx /bin/sh
```

## Health Checks

### Check Service Status

```bash
docker compose -f docker-compose.mcp.yml ps
```

### Test MCP Server

```bash
# Direct (bypass nginx)
curl http://localhost:8765/health

# Via nginx HTTPS (use your HTTPS_PORT, default 9443)
curl https://localhost:9443/health -k
```

### Test API

```bash
curl -X POST https://localhost:9443/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What setup changes reduce understeer?"}' \
  -k
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :8765
lsof -i :9080
lsof -i :9443

# Change ports in docker-compose.mcp.yml or .env.mcp
```

### Can't Connect to Pits N Giggles

```bash
curl http://localhost:4768/

docker compose -f docker-compose.mcp.yml exec nginx curl -sS http://host.docker.internal:4768/ | head
```

### SSL Certificate Warnings

Normal for development with self-signed certs. In browser:
1. Click "Advanced"
2. Click "Proceed to localhost (unsafe)"

Nginx still redirects port **80** inside the container to HTTPS; on the host you typically hit **`https://localhost:9443`** (default).

### Container Won't Start

```bash
docker compose -f docker-compose.mcp.yml logs mcp-server
docker compose -f docker-compose.mcp.yml down
docker compose -f docker-compose.mcp.yml up -d
docker compose -f docker-compose.mcp.yml up -d --build --force-recreate
```

### Clean Everything

```bash
docker compose -f docker-compose.mcp.yml down -v
docker compose -f docker-compose.mcp.yml down -v --rmi all
./start.sh
```

## Production Deployment

### Use Real SSL Certificates

1. Obtain certificates (Let's Encrypt, etc.)

2. Copy to volume:
```bash
docker cp /path/to/fullchain.pem f1-nginx-proxy:/etc/nginx/ssl/
docker cp /path/to/privkey.pem f1-nginx-proxy:/etc/nginx/ssl/
```

3. Update `nginx/conf.d/default.conf`:
```nginx
ssl_certificate /etc/nginx/ssl/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/privkey.pem;
```

4. Restart nginx:
```bash
docker compose -f docker-compose.mcp.yml restart nginx
```

### Secure Configuration

1. Restrict CORS in `mcp_server/server.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    # ...
)
```

2. Use environment variables for secrets:
```bash
# Don't commit .env to git
echo ".env" >> .gitignore
```

3. Enable firewall rules

4. Use Docker secrets for production

### Scaling

The bundled `nginx/conf.d/default.conf` uses a **single** `proxy_pass` to `mcp-server:8765`. Scaling MCP replicas requires an **upstream** block and load-balancing edits; it is not enabled out of the box.

## Updates

### Update Images

```bash
git pull origin main
docker compose -f docker-compose.mcp.yml up -d --build
```

### Backup Data

```bash
# Backup volumes
docker run --rm -v f1-race-engineer-mcp_mcp-data:/data -v $(pwd):/backup alpine tar czf /backup/mcp-data-backup.tar.gz /data
```

### Restore Data

```bash
# Restore volumes
docker run --rm -v f1-race-engineer-mcp_mcp-data:/data -v $(pwd):/backup alpine tar xzf /backup/mcp-data-backup.tar.gz -C /
```
