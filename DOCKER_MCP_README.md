# Pits n' Giggles - F1 Race Engineer MCP Server

**AI-Powered Race Engineering for F1 23/24/25 Games**

An intelligent F1 Race Engineer powered by MCP (Model Context Protocol) that analyzes telemetry data from F1 games and provides professional car setup and strategy advice through AI chat, voice commands, and desktop AI clients.

## 🏎️ What is This?

Pits n' Giggles with MCP integration transforms your F1 gaming experience by adding an AI race engineer that:

- **Analyzes Real-Time Telemetry** - Monitors speed, tyre temps, fuel, lap times from F1 23/24/25
- **Diagnoses Handling Issues** - Identifies understeer, oversteer, balance problems
- **Recommends Setup Changes** - Suggests specific aero, diff, suspension, brake adjustments
- **Voice Commands** - Talk to your engineer using speech-to-text and hear responses
- **Multi-Platform AI** - Works with ChatGPT Desktop, Claude Desktop, Cursor, and custom AI clients

## 🚀 Quick Start (Docker)

### Prerequisites
- Docker and Docker Compose installed
- F1 23, F1 24, or F1 25 game
- (Optional) OpenAI or OpenRouter API key for advanced AI features

### Run with Docker

```bash
# Clone the repository
git clone https://github.com/kmransom56/pitsngiggles-mcp-integration.git
cd pitsngiggles-mcp-integration

# MCP + nginx only (PNG runs on the host :4768)
docker compose -f docker-compose.mcp.yml --env-file .env.mcp up -d

# Access
# Pits N Giggles (host): http://localhost:4768
# Docker MCP direct: http://localhost:8765/mcp/chat, ws://localhost:8765/mcp/ws
# Via nginx: http://localhost:9080/mcp/..., https://localhost:9443/mcp/...
# SSE for AI clients (PNG, not mcp_server): https://localhost:9443/telemetry/mcp or http://localhost:4768/mcp
```

### Configuration

1. **Game Setup**: Configure F1 game UDP telemetry to `localhost:20777`
2. **API Key (Optional)**: For full AI features, add your API key to `.env.mcp`:
   ```bash
   LLM_API_KEY=your_openai_or_openrouter_key
   LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
   ```

## 🎯 Features

### Race Strategy Center
- **Real-time telemetry display** embedded in engineer view
- **AI chat interface** for setup advice and strategy
- **Quick action buttons** for common questions
- **Telemetry-aware responses** with context from current race data

### Voice Strategy Center
- **Push-to-talk** with space bar or microphone button
- **Browser-based speech recognition** (no external services needed)
- **Natural text-to-speech** responses
- **Hands-free operation** during races

### F1 Race Engineer AI
The AI agent is trained on F1 car setup principles:

**Handling Issues:**
- Understeer on entry → Front wing +1, Front ARB -2, Brake bias +1%
- Oversteer on exit → Rear wing +1, Rear ARB -2, On-throttle diff +5%
- Lack of rotation → Off-throttle diff -10%, Brake bias +2%
- Unstable on power → On-throttle diff +10%, Rear wing +2

**Setup Components:**
- **Aero**: Front wing (turn-in), Rear wing (stability)
- **Differential**: On-throttle (50-80%), Off-throttle (50-80%)
- **ARB**: Stiffer front reduces understeer, stiffer rear reduces oversteer
- **Brakes**: Forward bias (56-58%) for front bite, rear bias (52-54%) for rotation

### Desktop AI Integration (MCP Protocol)

The MCP server exposes telemetry tools that ChatGPT, Claude, and other AI clients can use:

- `get_telemetry_data` - Current race state and driver data
- `get_race_info` - Session type, lap count, weather, track conditions
- `analyze_tyre_strategy` - Tyre compounds, wear, degradation analysis
- `get_driver_info` - Specific driver telemetry and performance
- `get_lap_comparison` - Compare lap times across drivers
- `get_stream_overlay_data` - HUD and overlay information

**Setup AI Clients:**

<details>
<summary>ChatGPT Desktop</summary>

Add to `%APPDATA%\com.openai.chat\config.json`:
```json
{
  "mcpServers": {
    "pits-n-giggles": {
      "url": "https://localhost:9443/telemetry/mcp",
      "name": "F1 Race Engineer",
      "description": "F1 23/24/25 telemetry analysis and race engineering"
    }
  }
}
```
</details>

<details>
<summary>Claude Desktop</summary>

Add to `%APPDATA%\Claude\claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "pits-n-giggles": {
      "command": "curl",
      "args": ["-N", "https://localhost:9443/telemetry/mcp"]
    }
  }
}
```
</details>

<details>
<summary>Cursor IDE</summary>

Add to Cursor settings → MCP Servers:
```
https://localhost:9443/telemetry/mcp
```
</details>

## 📊 MCP Tools Available

### `get_telemetry_data`
Returns complete race state including all drivers, positions, lap times, tyre data, and current session information.

### `get_race_info`
Returns session details: type (Practice/Qualifying/Race), lap counts, weather, track/air temps, safety car status.

### `analyze_tyre_strategy`
Analyzes tyre compounds, wear rates, degradation patterns, and optimal pit windows for specified drivers.

### `get_driver_info(driver_index)`
Detailed telemetry for a specific driver: speed, throttle, brake, steering, tyre temps, fuel, lap times.

### `get_lap_comparison`
Compares lap times, sectors, and performance across all drivers or specific subset.

### `get_stream_overlay_data`
Returns HUD overlay data for streaming: current position, lap info, tyre status, fuel remaining.

## 🔊 Voice Features

Voice commands are processed entirely in the browser using Web Speech API:

**Speech-to-Text:**
- Browser-native recognition (Chrome/Edge recommended)
- Push-to-talk with space bar
- Continuous listening mode available
- No external API needed

**Text-to-Speech:**
- Browser-native synthesis
- Multiple voice options
- Adjustable speed and pitch
- Automatic response reading

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│ F1 23/24/25 Game                                                 │
│ UDP Telemetry → localhost:20777                                   │
└────────────────────────┬──────────────────────────────────────────┘
                         │
┌────────────────────────▼──────────────────────────────────────────┐
│ Pits n' Giggles Backend (Python/Quart)                           │
│ • UDP Receiver                                                     │
│ • Packet Parser                                                    │
│ • Telemetry Computation Engine                                    │
│ • WebSocket/Socket.IO Server                                      │
│ • HTTP API (FastAPI)                                              │
└────────────────────────┬──────────────────────────────────────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
┌─────────────▼──┐ ┌────▼────────┐ ┌▼────────────────────┐
│ Web UI         │ │ MCP Server  │ │ Voice Strategy UI   │
│ • Driver View  │ │ (FastAPI)   │ │ • Speech-to-Text    │
│ • Engineer View│ │ • Tools API │ │ • Text-to-Speech    │
│ • Strategy     │ │ • SSE Stream│ │ • Push-to-Talk      │
│   Center       │ │ • Chat API  │ │                     │
└────────────────┘ └─────┬───────┘ └─────────────────────┘
                         │
                   ┌─────▼──────┐
                   │ nginx      │
                   │ HTTPS/HTTP │
                   │ Reverse    │
                   │ Proxy      │
                   └─────┬──────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                 │
┌───────▼────┐  ┌────────▼──────┐  ┌──────▼─────┐
│ ChatGPT    │  │ Claude        │  │ Cursor IDE │
│ Desktop    │  │ Desktop       │  │            │
│            │  │               │  │            │
└────────────┘  └───────────────┘  └────────────┘
```

## 📦 Docker Deployment Options

### Option 1: All-in-One (Recommended)
```bash
docker-compose up -d
```
Starts: Main app, MCP server, and nginx in one command.

### Option 2: MCP Only
```bash
docker-compose -f docker-compose.mcp.yml up -d
```
Just the MCP server and nginx for AI client integration.

### Option 3: Native + Docker MCP
```bash
# Run main app natively
./start.sh

# Run MCP in Docker separately
docker-compose -f docker-compose.mcp.yml up -d
```

## 🛠️ Development

### Local Development Setup
```bash
# Install dependencies
python -m venv .venv
source .venv/bin/activate  # or `.venv\Scripts\activate` on Windows
uv pip install -r mcp_server/requirements.txt

# Start development server
./start.sh
```

### Environment Variables
Create `.env.mcp` file:
```bash
# AI/LLM Configuration
LLM_API_KEY=your_api_key_here
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_MODEL=gpt-4

# MCP Server
MCP_SERVER_HOST=0.0.0.0
MCP_SERVER_PORT=8765

# Nginx
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
```

## 🧪 Testing

### Test MCP Endpoint
```bash
# Health check
curl http://localhost/health

# Test chat endpoint
curl -X POST http://localhost/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What causes understeer in slow corners?"}'

# Test SSE stream (for AI clients)
curl -N https://localhost:9443/telemetry/mcp
```

### Test Voice Features
1. Open http://localhost:4768/voice-strategy-center
2. Click microphone button or press space bar
3. Say: "I have understeer in turn 3"
4. Release button to send
5. Hear AI response

## 📚 Documentation

- **[Building Guide](docs/BUILDING.md)** - Compile from source
- **[Docker Quick Start](docs/DOCKER_QUICKSTART.md)** - Docker deployment
- **[Voice Integration](docs/VOICE_INTEGRATION.md)** - Voice feature setup
- **[F1 Race Engineer Agent](docs/F1_RACE_ENGINEER_AGENT.md)** - AI agent details
- **[AI Client Setup](docs/AI_CLIENT_SETUP.md)** - Configure desktop AI clients
- **[MCP Integration](docs/MCP_INTEGRATION.md)** - MCP protocol details

## 🤝 Contributing

Contributions welcome! Areas of interest:
- Additional telemetry analysis algorithms
- New AI agent behaviors and personas
- Mobile app support
- VR overlay integration
- Additional game support (iRacing, ACC, etc.)

## 📄 License

MIT License - See [LICENSE](LICENSE) file

## 🙏 Credits

- **Original Project**: [Pits n' Giggles](https://github.com/ashwin-nat/pits-n-giggles) by Ashwin Natarajan
- **MCP Integration**: Keith Ransom
- **MCP Protocol**: Anthropic

## 🔗 Links

- **GitHub**: https://github.com/kmransom56/pitsngiggles-mcp-integration
- **Upstream**: https://github.com/ashwin-nat/pits-n-giggles
- **Website**: https://www.pitsngiggles.com
- **MCP Specification**: https://modelcontextprotocol.io

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/kmransom56/pitsngiggles-mcp-integration/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kmransom56/pitsngiggles-mcp-integration/discussions)
- **Discord**: Join the Pits n' Giggles community

---

**Ready to race with AI?** 🏁

```bash
docker-compose up -d
# Open http://localhost:4768/voice-strategy-center
# Start F1, configure UDP telemetry, and race!
```
