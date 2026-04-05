# Docker Deployment Guide

## Quick Start

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
   - FastAPI MCP server
   - F1 Race Engineer AI agent
   - WebSocket and HTTP APIs

2. **f1-nginx-proxy** (Ports 80, 443)
   - Nginx reverse proxy
   - Serves Strategy Center UI
   - Proxies to MCP server and Pits N Giggles

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
docker-compose restart nginx
```

### Custom Ports

Edit `docker-compose.yml`:

```yaml
services:
  nginx:
    ports:
      - "8080:80"    # HTTP
      - "8443:443"   # HTTPS
```

## Commands

### Start Services

```bash
./start.sh
# Or manually:
docker-compose up -d
```

### Stop Services

```bash
./stop.sh
# Or manually:
docker-compose down
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mcp-server
docker-compose logs -f nginx

# Last 100 lines
docker-compose logs --tail=100 mcp-server
```

### Restart Services

```bash
# All
docker-compose restart

# Specific
docker-compose restart mcp-server
docker-compose restart nginx
```

### Rebuild Services

```bash
# After code changes
docker-compose up -d --build

# Specific service
docker-compose up -d --build mcp-server
```

### Enter Container Shell

```bash
# MCP server
docker-compose exec mcp-server /bin/bash

# Nginx
docker-compose exec nginx /bin/sh
```

## Health Checks

### Check Service Status

```bash
docker-compose ps
```

### Test MCP Server

```bash
# Direct
curl http://localhost:8765/health

# Via nginx
curl https://localhost/health -k
```

### Test API

```bash
curl -X POST https://localhost/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What setup changes reduce understeer?"}' \
  -k
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :8765
lsof -i :80
lsof -i :443

# Change ports in docker-compose.yml
```

### Can't Connect to Pits N Giggles

```bash
# Check Pits N Giggles is running
curl http://localhost:4768/

# Test from inside nginx container
docker-compose exec nginx curl http://host.docker.internal:4768/
```

### SSL Certificate Warnings

Normal for development with self-signed certs. In browser:
1. Click "Advanced"
2. Click "Proceed to localhost (unsafe)"

Or use HTTP: `http://localhost`

### Container Won't Start

```bash
# Check logs
docker-compose logs mcp-server

# Remove and recreate
docker-compose down
docker-compose up -d

# Force rebuild
docker-compose up -d --build --force-recreate
```

### Clean Everything

```bash
# Stop and remove containers, networks, volumes
docker-compose down -v

# Remove images too
docker-compose down -v --rmi all

# Start fresh
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
docker-compose restart nginx
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

```bash
# Run multiple MCP server instances
docker-compose up -d --scale mcp-server=3

# Nginx will load balance automatically
```

## Updates

### Update Images

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose up -d --build
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
