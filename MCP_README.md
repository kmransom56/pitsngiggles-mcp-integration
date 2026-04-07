# F1 Race Engineer MCP Integration

AI-powered race engineering for F1 23/24/25 integrated with Pits N Giggles telemetry.

## 🏎️ What is This?

This is a complete MCP (Model Context Protocol) server that transforms Pits N Giggles telemetry into an intelligent F1 Race Engineer AI assistant. It analyzes your driving data in real-time and provides professional car setup advice, strategy recommendations, and performance analysis.

## ✨ Features

- **🤖 AI Race Engineer**: Professional car setup and tuning advice using LLMs (GPT-4, Claude, etc.)
- **📊 Telemetry Analysis**: Real-time analysis of tyre temps, wear, fuel, and performance
- **🔧 Setup Recommendations**: Specific, actionable setup changes (aero, diff, suspension, brakes)
- **💬 Chat Interface**: Ask questions in natural language about your car and strategy
- **🎤 Voice Support**: Hands-free operation with speech-to-text and text-to-speech
- **🔌 AI Client Integration**: Works with ChatGPT Desktop, Claude, Cursor, and more
- **🐳 Docker Deployment**: One-command setup with Docker Compose
- **🔒 Nginx Reverse Proxy**: Secure HTTPS access with SSL/TLS

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Pits N Giggles installed
- LLM API key (OpenRouter recommended)
- F1 23, 24, or 25 game

### Installation

```bash
# 1. Clone repository (or use existing Pits N Giggles)
cd /path/to/pits-n-giggles

# 2. Configure environment
cp .env.mcp.example .env.mcp
nano .env.mcp  # Add your LLM_API_KEY

# 3. Start MCP server
./start-mcp.sh

# 4. Start Pits N Giggles (in separate terminal)
./start.sh

# 5. Start F1 game and begin a session

# 6. Open Strategy Center
# http://localhost/strategy-center.html
```

That's it! 🎉

## 📖 Detailed Guides

- **[Quick Start Guide](docs/mcp/MCP_QUICKSTART.md)** - Get running in 5 minutes
- **[Voice Integration](docs/mcp/VOICE_INTEGRATION.md)** - Add speech-to-text/text-to-speech
- **[AI Client Setup](docs/mcp/AI_CLIENT_SETUP.md)** - Configure ChatGPT, Claude, Cursor
- **[Docker Toolkit](docs/mcp/DOCKER_MCP_TOOLKIT.md)** - Add to Docker's MCP Toolkit
- **[Architecture](docs/mcp/architecture.mmd)** - System architecture diagram

## 🎯 Use Cases

### During Practice

```
You: "I have understeer in turns 3 and 7, what should I change?"

AI: "Based on your telemetry showing higher front tyre temps and slow corner issues:

**Diagnosis:** Front-limited understeer in slow corners
**Root Cause:** Insufficient front-end bite and rotation

**Recommendations:**
1. Front Wing: +1 click - Increase front downforce
2. Front ARB: -2 clicks - Add mechanical compliance
3. Brake Bias: +1% to 57% - Improve front bite
4. Off-throttle Diff: -5% to 60% - Help rotation on entry

**Expected Impact:** Better turn-in response, improved rotation in slow corners. May need to monitor front tyre wear."
```

### During Qualifying

```
You: "Analyze my last lap and where I'm losing time to P1"

AI: "Sector comparison shows you're losing 0.3s in Sector 2:
- Turn 4 entry: Too much brake, late turn-in
- Turn 5-6 complex: Carrying 8 km/h less mid-corner speed
- Suggested: Brake 10m later, smoother steering input, use more kerb on exit"
```

### During Race

```
You: "What's my optimal pit window based on tyre degradation?"

AI: "Current tyre wear analysis:
- Front Left: 68% (critical)
- Front Right: 64%
- Rears: 52-54% (good)

**Optimal Pit Window:** Laps 18-20
**Current Lap:** 15
**Recommendation:** Box on lap 18-19 to avoid cliff edge
**Alternative:** Extend to lap 21 if Safety Car deployed"
```

## 🛠️ Configuration

### LLM Options

#### OpenRouter (Recommended)

- Access to multiple models (GPT-4, Claude, Llama, etc.)
- Pay-as-you-go pricing
- No separate subscriptions needed

```bash
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-YOUR_KEY
LLM_MODEL=openai/gpt-4o-mini  # or anthropic/claude-3.5-sonnet
```

#### OpenAI Direct

```bash
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-YOUR_KEY
LLM_MODEL=gpt-4o-mini
```

#### Anthropic via OpenRouter

```bash
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-YOUR_KEY
LLM_MODEL=anthropic/claude-3.5-sonnet
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LLM_ENDPOINT` | LLM API endpoint | OpenRouter |
| `LLM_API_KEY` | API key (required) | - |
| `LLM_MODEL` | Model to use | gpt-4o-mini |
| `HTTP_PORT` | HTTP port | 80 |
| `HTTPS_PORT` | HTTPS port | 443 |
| `MCP_PORT` | MCP server port | 8765 |

## 📡 API Endpoints

### Chat API

```bash
POST /api/chat
Content-Type: application/json

{
  "message": "I have oversteer on corner exit",
  "telemetry": {
    "lap": 5,
    "speed": 145.2,
    "tyre_temps": {"FL": 82, "FR": 85, "RL": 88, "RR": 90},
    "tyre_wear": {"FL": 15, "FR": 16, "RL": 20, "RR": 22}
  }
}
```

### WebSocket

```javascript
const ws = new WebSocket('ws://localhost/api/ws');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'chat',
    message: 'Analyze my tyre degradation',
    telemetry: { /* ... */ }
  }));
};

ws.onmessage = (event) => {
  const { response, analysis, recommendations } = JSON.parse(event.data);
};
```

### MCP SSE (for AI Clients)

Served by **Pits N Giggles** (PNG) on the host, not by Docker `mcp_server`:

```
GET /mcp
```

Examples: `http://localhost:4768/mcp` or, via nginx from `docker-compose.mcp.yml`, `https://localhost:9443/telemetry/mcp` (maps to PNG `GET /mcp`).

Docker MCP exposes **`POST /mcp/chat`** and **`WebSocket /mcp/ws`** only (e.g. `http://localhost:8765`).

## 🎤 Voice Commands

Enable voice mode in Strategy Center:

```javascript
// Browser console
switchAIMode("mcp_chat")
```

Then use push-to-talk:
1. Click and hold 🎤 microphone button
2. Speak your question
3. Release button
4. Hear AI response (if TTS enabled)

## 🤖 AI Client Integration

### ChatGPT Desktop

Add to `~/Library/Application Support/ChatGPT/config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "https://localhost:9443/telemetry/mcp"
    }
  }
}
```

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "https://localhost:9443/telemetry/mcp"
    }
  }
}
```

### Cursor IDE

Add to `.cursorrules`:

```
Use f1-race-engineer MCP server for F1 telemetry analysis.
SSE (PNG): https://localhost:9443/telemetry/mcp — MCP HTTP/WS: http://localhost:8765/mcp/
```

## 🏗️ Architecture

```
┌─────────────┐
│ F1 23/24/25 │
│    Game     │
└──────┬──────┘
       │ UDP Telemetry
       ▼
┌─────────────────┐
│ Pits N Giggles  │
│  Telemetry      │◄─────────┐
└────────┬────────┘          │
         │ Socket.IO         │
         ▼                   │
    ┌────────┐               │
    │ nginx  │               │
    │ Proxy  │               │
    └───┬─┬──┘               │
        │ │                  │
    ┌───┘ └─────┐            │
    ▼           ▼            │
Frontend    MCP Server       │
┌──────┐   ┌────────────┐   │
│ Chat │   │ F1 Race    │   │
│  UI  │   │ Engineer   │   │
└──┬───┘   │   Agent    │   │
   │       └─────┬──────┘   │
   │             │          │
   │    ┌────────▼──────┐   │
   └───►│ LLM Service   │   │
        │ (OpenRouter/  │   │
        │  OpenAI/etc)  │   │
        └───────────────┘   │
                            │
┌─────────────────────────┐ │
│ AI Clients              │ │
│ (ChatGPT/Claude/Cursor) ├─┘
└─────────────────────────┘
```

## 🧪 Testing

### Manual Testing

```bash
# Check health
curl http://localhost/health

# Test chat API
curl -X POST http://localhost/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my lap time?"}'

# Check logs
docker-compose -f docker-compose.mcp.yml logs -f
```

### Automated Testing

```bash
# Run integration tests
pytest tests/mcp/

# Test with mock telemetry
python scripts/test_mcp_integration.py
```

## 🐛 Troubleshooting

### MCP Server Not Responding

```bash
# Check if running
docker ps | grep mcp

# View logs
docker-compose -f docker-compose.mcp.yml logs -f mcp-server

# Restart
./stop-mcp.sh && ./start-mcp.sh
```

### No AI Responses

1. Check API key is set: `cat .env.mcp | grep LLM_API_KEY`
2. Verify API credits/quota
3. Check model name is correct
4. View server logs for errors

### Telemetry Not Available

1. Ensure Pits N Giggles is running: `ps aux | grep python`
2. Check F1 game telemetry is enabled
3. Verify UDP port 4768 is open
4. Test telemetry endpoint: `curl http://localhost:4768/race-info`

## 💰 Cost Estimates

### OpenRouter with GPT-4o-mini
- ~$0.001 per question
- $5 = ~5,000 questions
- Recommended for daily use

### OpenRouter with GPT-4
- ~$0.05 per question  
- $5 = ~100 questions
- Best quality, higher cost

### OpenRouter with Claude 3.5 Sonnet
- ~$0.03 per question
- $5 = ~166 questions
- Great for detailed analysis

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file

## 🙏 Credits

- **Pits N Giggles**: [ashwin-nat/pits-n-giggles](https://github.com/ashwin-nat/pits-n-giggles)
- **MCP Protocol**: [Anthropic Model Context Protocol](https://modelcontextprotocol.io)
- **F1 Race Engineer**: [kmransom56](https://github.com/kmransom56)

## 🔗 Links

- **Documentation**: [docs/mcp/](docs/mcp/)
- **Issues**: [GitHub Issues](https://github.com/kmransom56/pitsngiggles-mcp-integration/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kmransom56/pitsngiggles-mcp-integration/discussions)
- **Docker Hub**: [pitsngiggles/f1-race-engineer-mcp](https://hub.docker.com/r/pitsngiggles/f1-race-engineer-mcp)

---

**Made with ❤️ for the sim racing community. Happy racing! 🏎️**
