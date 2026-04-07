# F1 Race Engineer MCP Integration for Pits N Giggles

AI-powered Race Engineering for F1 23/24/25 using Model Context Protocol (MCP)

## 🏎️ Features

- **Real-time Telemetry Analysis** - Live data from Pits N Giggles
- **AI Race Engineer** - Professional setup and strategy recommendations
- **Voice Integration** - Speak to your race engineer, hear responses
- **Setup Diagnostics** - Identify understeer, oversteer, and balance issues
- **Tyre Strategy** - Optimal pit windows and compound analysis
- **Fuel Management** - Consumption tracking and saving strategies
- **AI Client Support** - ChatGPT, Claude, Cursor integration via MCP
- **Docker-Based Deployment** - One-command setup for any platform

## 🚀 Quick Start (5 Minutes)

### Prerequisites

- F1 23, F1 24, or F1 25 game
- Docker + Docker Compose (OR Python 3.12+)

### Fastest Path

```bash
# 1. Clone repository
git clone https://github.com/ashwin-nat/pits-n-giggles.git
cd pits-n-giggles

# 2. Start everything
./start.sh
# OR with Docker
docker-compose -f docker-compose.complete.yml up -d

# 3. Configure F1 game
# Settings → Telemetry → UDP Port: 20777, IP: 127.0.0.1

# 4. Open Voice Strategy Center
open http://localhost:4768/voice-strategy-center
```

**📖 Detailed Guide**: [5-Minute Quickstart](docs/QUICKSTART_5MIN.md)

## 🎙️ Voice-Enabled Race Engineer

Hold **Space**, speak your question, release. Your AI engineer responds with voice!

**Example Commands:**
- *"Why am I getting understeer in Turn 3?"*
- *"When should I pit?"*
- *"Analyze my last lap"*
- *"Compare my sector times"*

**Zero Cost** - Uses browser's built-in speech APIs. No external services needed!

## 📋 What Gets Deployed

### Complete Stack

1. **Pits N Giggles Backend** (Port 4768)
   - F1 telemetry receiver (UDP 20777)
   - Real-time data processing
   - Web UI server

2. **MCP Server** (Port 8765)
   - F1 Race Engineer AI
   - WebSocket and HTTP APIs
   - Telemetry analysis engine
   - LLM integration (optional)

3. **Nginx Reverse Proxy** (Ports 80/443)
   - Serves Strategy Center UIs
   - Proxies to backend services
   - SSL/TLS with self-signed cert (dev)

4. **Strategy Centers**
   - Text-based AI chat
   - Voice-enabled AI chat
   - Real-time telemetry display

## 🎯 Access Points

### Main Application
- **Driver View**: `http://localhost:4768/`
- **Engineer View**: `http://localhost:4768/eng-view`

### AI Strategy Centers
- **Strategy Center** (Text): `http://localhost:4768/strategy-center`
- **Voice Strategy Center**: `http://localhost:4768/voice-strategy-center` ⭐

### MCP Stack (`docker-compose.mcp.yml`: **mcp-server + nginx** only)

**Docker MCP** (`mcp_server`, no SSE):

- **Direct**: `POST http://localhost:8765/mcp/chat`, `WebSocket ws://localhost:8765/mcp/ws`, `GET http://localhost:8765/health`
- **Via nginx** (default compose ports): `http://localhost:9080/...`, `https://localhost:9443/...` under `/mcp/`

**PNG on the host** (`:4768`) — **SSE** for MCP-style clients is here: `GET http://localhost:4768/mcp`. Through nginx: **`https://localhost:9443/telemetry/mcp`**.

## 🤖 AI Client Integration

Connect ChatGPT, Claude, or other AI assistants to your telemetry!

### ChatGPT Desktop

Use the **PNG SSE** URL (not the Docker MCP container — it does not implement SSE). With default nginx TLS and self-signed cert, your client must allow insecure TLS or use HTTP to PNG directly.

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "command": "npx",
      "args": ["-y", "sse-mcp-client", "https://localhost:9443/telemetry/mcp"]
    }
  }
}
```

### Claude Desktop

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "https://localhost:9443/telemetry/mcp",
      "transport": "sse"
    }
  }
}
```

For **HTTP straight to PNG** (no nginx): use `http://localhost:4768/mcp`.

**📖 Full Setup**: [AI Client Setup Guide](docs/mcp/AI_CLIENT_SETUP.md)


## 🏗️ Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   F1 23/24/25   │      │  Pits N Giggles │      │   AI Clients    │
│   Telemetry     │─────▶│   Backend       │◀─────│ (ChatGPT/Claude)│
│  UDP :20777     │      │   :4768         │      │   via SSE       │
└─────────────────┘      └─────────────────┘      └─────────────────┘
                                │                           │
                                ▼                           ▼
                         ┌─────────────────────────────────────┐
                         │      nginx Reverse Proxy           │
                         │      :80 (HTTP) :443 (HTTPS)       │
                         └─────────────────────────────────────┘
                                │                   │
                    ┌───────────┴─────┬─────────────┘
                    ▼                 ▼
          ┌─────────────────┐  ┌─────────────────┐
          │ Strategy Centers│  │   MCP Server    │
          │  (Voice + Text) │  │   :8765         │
          │  (Browser)      │  │ F1 AI Engineer  │
          └─────────────────┘  └─────────────────┘
                    ▲                   ▼
                    │             ┌─────────────┐
                    └─────────────│  LLM APIs   │
                                 │(OpenRouter) │
                                 └─────────────┘
```

## 📚 Documentation

### Quick Start
- **⭐ [5-Minute Quickstart](docs/QUICKSTART_5MIN.md)** - Fastest way to get started
- **[Complete F1 Agent Guide](docs/COMPLETE_F1_AGENT_GUIDE.md)** - Comprehensive reference
- **[Building from Source](docs/BUILDING.md)** - Manual installation

### Features
- **[Voice Integration](docs/VOICE_INTEGRATION.md)** - Speech-to-text, text-to-speech setup
- **[F1 Race Engineer Agent](docs/F1_RACE_ENGINEER_AGENT.md)** - Agent capabilities & behavior
- **[Strategy Center](docs/STRATEGY_CENTER.md)** - Using the AI chat interface

### Deployment
- **[Docker Quickstart](docs/DOCKER_QUICKSTART.md)** - Docker-specific guide
- **[Docker MCP Toolkit](docs/DOCKER_MCP_TOOLKIT_SUBMISSION.md)** - Docker Hub submission

### Integration
- **[AI Client Setup](docs/AI_CLIENT_SETUP.md)** - ChatGPT, Claude, Cursor configuration
- **[MCP Integration](docs/MCP_INTEGRATION.md)** - Technical MCP details

## 🔧 Configuration

### Optional: LLM API Key

For enhanced AI responses, add your API key to `.env.mcp`:

```bash
# Get free key from https://openrouter.ai/keys
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-your-key-here
LLM_MODEL=openai/gpt-4o-mini
```

**Without API key**: Agent works with intelligent fallback responses based on telemetry analysis.

## 🧪 Testing

Run the integration test suite:

```bash
./test-integration.sh
```

Tests verify:
- ✅ Pits N Giggles backend
- ✅ MCP server health
- ✅ Web UIs accessible
- ✅ Docker containers running

## 🎓 F1 Race Engineer Capabilities

### What the Agent Knows

**Aerodynamics**
- Increase front wing → Better turn-in grip (fixes understeer)
- Increase rear wing → More stability (fixes oversteer)

**Differential**
- Lower on-throttle → More rotation on exit
- Lower off-throttle → More rotation on entry

**Suspension**
- Stiffen rear ARB → Reduce oversteer
- Stiffen front ARB → Reduce understeer

**Brake Bias**
- Forward (55-58%) → Reduce oversteer under braking
- Rear (50-53%) → Reduce understeer under braking

### Example Interactions

**You**: *"I'm getting massive understeer in slow corners"*

**Engineer**: 
```
Based on your telemetry, I see front tyre temps are 15°C cooler than rears.
Recommendations:
1. Increase front wing by 2 clicks
2. Reduce front ARB stiffness by 1 click  
3. Front tyre pressure: +0.2 PSI
This will improve front-end grip while maintaining balance.
```

## 🆘 Troubleshooting

### No Telemetry Data

```bash
# Check F1 game UDP settings
# Must be: Port 20777, IP 127.0.0.1

# Test backend
curl http://localhost:4768/health
```

### MCP Server Issues

```bash
# Check logs
docker-compose -f docker-compose.mcp.yml logs mcp-server

# Verify port
lsof -i :8765

# Check configuration
cat .env.mcp
```

### Voice Not Working

- **Browser**: Use Chrome or Edge (best support)
- **Permissions**: Allow microphone access
- **HTTPS**: Some browsers require HTTPS for voice

### Quick Reset

```bash
# Stop all services
./stop.sh
docker-compose -f docker-compose.mcp.yml down

# Remove volumes
docker-compose -f docker-compose.mcp.yml down -v

# Start fresh
./start.sh
```

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🙏 Credits

- **Pits N Giggles**: Original platform by Ashwin Natarajan
- **MCP Integration**: F1 Race Engineer AI
- **Voice Features**: Browser-based STT/TTS
- **Community**: All contributors and testers

## 💬 Support

- **Issues**: https://github.com/ashwin-nat/pits-n-giggles/issues
- **Discussions**: https://github.com/ashwin-nat/pits-n-giggles/discussions
- **Documentation**: [docs/](docs/)

---

**🏁 Happy Racing! 🏎️💨**

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
