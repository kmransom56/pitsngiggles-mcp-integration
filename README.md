# F1 Race Engineer MCP Integration for Pits N Giggles

AI-powered Race Engineering for F1 23 using Model Context Protocol (MCP)

## 🏎️ Features

- **Real-time Telemetry Analysis** - Live data from Pits N Giggles
- **AI Race Engineer** - Professional setup and strategy recommendations
- **Setup Diagnostics** - Identify understeer, oversteer, and balance issues
- **Tyre Strategy** - Optimal pit windows and compound analysis
- **Fuel Management** - Consumption tracking and saving strategies
- **Voice Integration Ready** - Speech-to-text and text-to-speech support
- **Docker-Based Deployment** - One-command setup for any platform

## 🚀 Quick Start with Docker

### Prerequisites

- Docker and Docker Compose installed
- Pits N Giggles running (or will run in Docker)
- F1 23/24 game running and sending telemetry

### Option 1: Simple Docker Deployment

```bash
# Clone the repository
git clone https://github.com/kmransom56/pitsngiggles-mcp-integration.git
cd pitsngiggles-mcp-integration

# Start all services
docker-compose up -d

# Access the Strategy Center
# Open https://localhost in your browser
```

### Option 2: With Custom LLM (OpenAI, etc.)

```bash
# Create environment file
cat > .env << EOF
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=your-api-key-here
EOF

# Start services
docker-compose up -d
```

## 📋 What Gets Deployed

The Docker Compose stack includes:

1. **MCP Server** (Port 8765)
   - F1 Race Engineer AI
   - WebSocket and HTTP APIs
   - Telemetry analysis engine

2. **Nginx Reverse Proxy** (Ports 80/443)
   - Serves Strategy Center UI
   - Proxies to Pits N Giggles telemetry
   - SSL/TLS with self-signed cert (development)

3. **Volumes**
   - `mcp-data` - Persistent MCP server data
   - `nginx-logs` - Access and error logs
   - `ssl-certs` - SSL certificates

## 🎮 Usage

### Access Points

- **Strategy Center UI**: https://localhost
- **MCP HTTP API**: https://localhost/mcp/
- **MCP WebSocket**: wss://localhost/mcp/ws
- **Health Check**: https://localhost/health

### Connecting Pits N Giggles

The default configuration assumes Pits N Giggles is running on your host machine on port 4768.

**If Pits N Giggles is on a different host/port**, edit `nginx/conf.d/default.conf`:

```nginx
location /telemetry/ {
    proxy_pass http://YOUR_HOST_IP:4768/;
    # ...
}
```

Then restart:
```bash
docker-compose restart nginx
```

## 🤖 AI Configuration

### Using OpenAI or Compatible LLMs

1. Set environment variables in `.env`:
```bash
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-your-key-here
```

2. Restart MCP server:
```bash
docker-compose restart mcp-server
```

### Supported AI Clients

- **OpenAI** (GPT-4, GPT-3.5)
- **Anthropic Claude** (via API)
- **Local LLMs** (Ollama, LM Studio, etc.)
- **Azure OpenAI**
- **Any OpenAI-compatible endpoint**

See `docs/AI_CLIENT_SETUP.md` for detailed configuration.

## 🔧 Advanced Configuration

### Custom Ports

Edit `docker-compose.yml`:

```yaml
services:
  mcp-server:
    ports:
      - "YOUR_PORT:8765"
  
  nginx:
    ports:
      - "YOUR_HTTP_PORT:80"
      - "YOUR_HTTPS_PORT:443"
```

### Production SSL Certificates

Replace self-signed certs with real ones:

```bash
# Copy your certs
cp /path/to/fullchain.pem docker-volumes/ssl-certs/
cp /path/to/privkey.pem docker-volumes/ssl-certs/

# Update nginx config
# Edit nginx/conf.d/default.conf ssl_certificate paths
```

### Running Pits N Giggles in Docker

Uncomment the `pits-n-giggles` service in `docker-compose.yml`:

```yaml
pits-n-giggles:
  image: pitsngiggles:latest
  ports:
    - "4768:4768"
  # ...
```

## 📊 Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mcp-server
docker-compose logs -f nginx

# Nginx access logs
docker exec f1-nginx-proxy tail -f /var/log/nginx/f1-mcp.access.log
```

### Health Checks

```bash
# Check MCP server
curl http://localhost:8765/health

# Check via nginx
curl https://localhost/health
```

## 🛠️ Development

### Local Development (without Docker)

```bash
# Install Python dependencies
pip install -r mcp_server/requirements.txt

# Run MCP server
python mcp_server/server.py

# Serve frontend
cd frontend && python -m http.server 8080
```

### Rebuild After Changes

```bash
# Rebuild specific service
docker-compose build mcp-server

# Rebuild and restart
docker-compose up -d --build mcp-server
```

## 📚 Documentation

- **MCP Integration**: `docs/MCP_INTEGRATION.md`
- **F1 Race Engineer Agent**: `docs/F1_RACE_ENGINEER_AGENT.md`
- **Voice Integration**: `docs/VOICE_INTEGRATION.md`
- **AI Client Setup**: `docs/AI_CLIENT_SETUP.md`
- **Building Guide**: `docs/BUILDING.md`

## 🎯 Quick Action Guide

Ask the AI Race Engineer:

- "Analyze my current handling balance"
- "What setup changes would reduce understeer?"
- "What setup changes would reduce oversteer?"
- "Analyze optimal pit window"
- "Compare tyre compound performance"
- "How can I improve my lap times?"

## 🔒 Security Notes

**For Development:**
- Uses self-signed SSL certificates
- All origins allowed in CORS

**For Production:**
- Replace with real SSL certificates
- Configure specific CORS origins in `mcp_server/server.py`
- Use environment variables for secrets
- Enable firewall rules

## 🐛 Troubleshooting

### MCP Server Won't Start
```bash
# Check logs
docker-compose logs mcp-server

# Verify port not in use
lsof -i :8765
```

### Can't Connect to Pits N Giggles
```bash
# Check Pits N Giggles is running
curl http://localhost:4768/

# Check nginx config
docker-compose exec nginx nginx -t

# Check from inside nginx container
docker-compose exec nginx curl http://host.docker.internal:4768/
```

### SSL Certificate Errors
```bash
# Accept self-signed cert in browser, or
# Add certificate exception, or
# Use HTTP instead (not recommended)
```

## 🤝 Contributing

Contributions welcome! Please see `CONTRIBUTING.md` for guidelines.

## 📝 License

See `LICENSE` file for details.

## 🙏 Credits

- **Pits N Giggles** - ashwin-nat
- **MCP Integration** - kmransom56
- **F1 23 Community**

## 📞 Support

- **Issues**: https://github.com/kmransom56/pitsngiggles-mcp-integration/issues
- **Discussions**: https://github.com/kmransom56/pitsngiggles-mcp-integration/discussions
- **Pits N Giggles**: https://www.pitsngiggles.com

---

**Happy Racing! 🏁**
