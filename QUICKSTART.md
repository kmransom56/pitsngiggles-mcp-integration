# F1 Race Engineer MCP - Quickstart Guide

Get up and running with the F1 Race Engineer MCP in under 5 minutes!

## Prerequisites

✅ **Docker Desktop** installed ([Get Docker](https://docs.docker.com/get-docker/))  
✅ **F1 23 or F1 24** game  
✅ **Pits N Giggles** running ([Get Pits N Giggles](https://github.com/ashwin-nat/pits-n-giggles))

## Step 1: Clone Repository

```bash
git clone https://github.com/kmransom56/pitsngiggles-mcp-integration.git
cd pitsngiggles-mcp-integration
```

## Step 2: Start Services

```bash
./start.sh
```

That's it! The script will:
- ✅ Check Docker is installed
- ✅ Build the MCP server container
- ✅ Build the Nginx reverse proxy
- ✅ Start all services
- ✅ Show you the access URLs

## Step 3: Access Strategy Center

Open in your browser:

**https://localhost**

Accept the SSL certificate warning (it's self-signed for development).

## Step 4: Start Racing!

1. **Launch F1 23/24** and start a session
2. **Make sure Pits N Giggles** is running and receiving telemetry
3. **Open Strategy Center** (https://localhost)
4. **Ask the AI Engineer** questions like:
   - "What setup changes would reduce understeer?"
   - "Analyze my tyre degradation"
   - "When should I pit?"

## That's It!

You now have:
- ✅ AI-powered Race Engineer analyzing your telemetry
- ✅ Real-time setup recommendations
- ✅ Strategy guidance
- ✅ WebSocket connection for instant responses

## Optional: Add LLM (GPT-4, Claude, etc.)

For enhanced AI responses, add your API key:

```bash
# Create .env file
cat > .env << EOF
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-your-api-key-here
EOF

# Restart services
docker-compose restart mcp-server
```

The system works without an external LLM using built-in racing knowledge!

## Quick Commands

```bash
# View logs
docker-compose logs -f

# Stop services
./stop.sh

# Restart services
docker-compose restart

# Clean everything
docker-compose down -v
```

## Troubleshooting

### "Can't connect to MCP"

Check MCP server is running:
```bash
docker-compose ps
curl http://localhost:8765/health
```

### "No telemetry data"

1. Check F1 game is running and sending UDP telemetry
2. Check Pits N Giggles is running:
   ```bash
   curl http://localhost:4768/
   ```
3. Check nginx proxy:
   ```bash
   docker-compose logs nginx
   ```

### "Port already in use"

Change ports in `docker-compose.yml`:
```yaml
nginx:
  ports:
    - "8080:80"   # Use 8080 instead of 80
    - "8443:443"  # Use 8443 instead of 443
```

## What's Next?

- **Voice Control**: See `docs/VOICE_INTEGRATION.md`
- **Custom LLMs**: See `docs/AI_CLIENT_SETUP.md`
- **Production Deploy**: See `docs/DOCKER_DEPLOYMENT.md`
- **Build from Source**: See `docs/BUILDING.md`

## Architecture Overview

```
F1 Game → UDP :20777 → Pits N Giggles :4768
                             ↓
                       Nginx Proxy :443
                             ↓
         ┌───────────────────┴───────────────────┐
         ↓                                       ↓
  Strategy Center UI                    MCP Server :8765
  (Web Browser)                         (F1 Race Engineer AI)
         ↓                                       ↑
    WebSocket /mcp/ws ←─────────────────────────┘
```

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Strategy Center** | https://localhost | Main UI with AI chat |
| **Engineer View** | https://localhost/telemetry/eng-view | Telemetry dashboard |
| **MCP API** | https://localhost/mcp/ | MCP HTTP endpoint |
| **MCP WebSocket** | wss://localhost/mcp/ws | Real-time chat |
| **Health Check** | https://localhost/health | Service status |

## Key Features

🏎️ **Real-time Analysis**
- Live telemetry from F1 game
- Instant AI feedback
- Setup diagnostics

🔧 **Setup Recommendations**
- Aero balance
- Differential settings
- Suspension tuning
- Brake bias

📊 **Strategy Guidance**
- Tyre degradation tracking
- Optimal pit windows
- Fuel management
- Weather strategy

🎤 **Voice Ready**
- Speech-to-text input
- Text-to-speech responses
- Hands-free operation

## Example Conversations

**You:** "I'm getting understeer in sector 2"

**AI Engineer:** 
```
To reduce understeer in sector 2:

1. Front Wing: +1 click (increases front downforce)
2. Front ARB: -2 clicks (softer for more mechanical grip)
3. Brake Bias: +1% forward (54-55% range)

Expected Impact: Better turn-in response, reduced push
Trade-off: Slightly less stability on kerbs
Next Steps: Test in practice, monitor front tyre temps
```

**You:** "When should I pit?"

**AI Engineer:**
```
Current tyre wear at 58% on lap 12/25.

Optimal pit window: Laps 14-16

Reasoning:
- Current degradation rate: 4.8% per lap
- Target 10% tyre life at pit entry
- Weather forecast shows no changes
- Traffic considerations favor lap 15

Recommendation: Pit lap 15, switch to mediums
```

## Support

- **Documentation**: `/docs` folder
- **Issues**: GitHub Issues
- **Community**: Pits N Giggles Discord

---

**Happy Racing! 🏁**

Get instant AI-powered race engineering advice while you drive!
