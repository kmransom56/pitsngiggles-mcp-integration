# 🏁 Pits N Giggles - F1 AI Race Engineer Deployment Guide

## ✅ Deployment Complete

The Pits N Giggles application with integrated F1 AI Race Engineer is now ready for deployment!

## 🚀 Quick Start

### Prerequisites
- **Python 3.12+** 
- **Node.js** (optional, for frontend builds)
- **Docker** (optional, for containerized deployment)

### Start the Application

```bash
./start.sh
```

The startup script will:
1. Check prerequisites (Python, uv, nginx, Docker)
2. Set up Python virtual environment
3. Install dependencies automatically
4. Ask if you want to enable the MCP F1 Race Engineer
5. Start the backend server (port 4768)
6. Optionally start the MCP server (port 8765)

### Access Points

**Main Application:**
- Driver View: `http://localhost:4768/`
- Engineer View: `http://localhost:4768/eng-view`
- **Strategy Center (AI Chat):** `http://localhost:4768/strategy-center`
- **Voice Strategy Center:** `http://localhost:4768/voice-strategy-center`

**MCP Server (if enabled):**
- Chat API: `http://localhost:8765/api/chat`
- WebSocket: `ws://localhost:8765/mcp/ws`
- Health Check: `http://localhost:8765/health`

## 🎤 Voice Features

The Voice Strategy Center includes:
- **Speech-to-Text:** Browser-based (Web Speech API)
- **Text-to-Speech:** Browser-based (SpeechSynthesis API)
- **Push-to-Talk:** Space bar or microphone button
- **Real-time Telemetry Context:** Automatically included with voice queries

### Using Voice Features

1. Open `http://localhost:4768/voice-strategy-center`
2. Click the microphone button or press Space
3. Ask your question (e.g., "How's my tyre wear?")
4. Release to send
5. Listen to the AI engineer's response

## 🤖 F1 Race Engineer Agent

The F1 Race Engineer Agent provides:

### Core Capabilities
- **Setup Analysis:** Diagnose understeer, oversteer, handling balance
- **Telemetry Analysis:** Real-time tyre temps, wear, fuel, brake bias
- **Strategy Advice:** Pit windows, tyre compounds, fuel saving
- **Performance Coaching:** Sector times, braking points, throttle application

### Key Tuning Logic
- **Aero:** Front wing for turn-in grip, rear wing for stability
- **Differential:** On-throttle for exit rotation, off-throttle for entry
- **Suspension:** Rear ARB for oversteer, front ARB for understeer
- **Brake Bias:** Forward for braking oversteer, rearward for understeer

### Example Queries
- "I have understeer in Turn 3, what should I change?"
- "When should I pit? My tyres are at 65% wear"
- "How can I improve my sector 2 times?"
- "What's the optimal fuel strategy for this race?"

## 🔧 Configuration

### MCP Server Configuration

Edit `.env.mcp` to configure the MCP server:

```bash
# LLM Provider (optional - system works without it)
LLM_API_KEY=your_api_key_here
LLM_ENDPOINT=https://api.openrouter.ai/api/v1/chat/completions

# Server Settings
MCP_HOST=0.0.0.0
MCP_PORT=8765
```

### AI Modes

The Strategy Center supports three modes:

1. **mcp_chat** (Default): Full F1 Race Engineer with telemetry analysis
2. **mcp**: Telemetry data only (no LLM)
3. **openai**: Direct OpenAI API integration

Switch modes in browser console:
```javascript
switchAIMode("mcp_chat")  // Full AI engineer
switchAIMode("mcp")       // Telemetry only
switchAIMode("openai")    // OpenAI direct
```

## 🐋 Docker Deployment

### Option 1: Complete Stack

```bash
docker-compose -f docker-compose.complete.yml up -d
```

Includes:
- Main Pits N Giggles application
- MCP server
- Nginx reverse proxy with SSL
- Health monitoring

### Option 2: MCP Server Only

```bash
docker-compose -f docker-compose.mcp.yml up -d
```

### Access with Docker
- Main App: `http://localhost:4768`
- MCP HTTP: `http://localhost:80`
- MCP HTTPS: `https://localhost:443`

## 📚 Documentation

### User Guides
- **Quick Start:** `docs/QUICKSTART_5MIN.md`
- **Voice Integration:** `docs/VOICE_INTEGRATION.md`
- **Voice Quick Reference:** `docs/VOICE_QUICK_REFERENCE.md`
- **Strategy Center:** `docs/STRATEGY_CENTER.md`

### Technical Documentation
- **Building:** `docs/BUILDING.md`
- **F1 Agent Guide:** `docs/F1_RACE_ENGINEER_AGENT.md`
- **MCP Integration:** `docs/MCP_INTEGRATION.md`
- **Docker Deployment:** `docs/DOCKER_DEPLOYMENT.md`
- **AI Client Setup:** `docs/AI_CLIENT_SETUP.md`

### Architecture
- **System Architecture:** `docs/arch.mmd`
- **Complete Architecture:** `docs/arch-mcp-complete.mmd`
- **Docker Architecture:** `docs/docker-mcp-arch.mmd`

## 🎮 F1 Game Setup

1. Launch F1 23, 24, or 25
2. Go to **Settings → Telemetry**
3. Enable UDP Telemetry
4. Set IP: `127.0.0.1` (localhost)
5. Set Port: `20777`
6. Set Format: `2021` or later
7. Start a session (Practice, Qualifying, or Race)

## 🔍 Troubleshooting

### Backend Won't Start
```bash
# Check if port 4768 is in use
lsof -i :4768

# Kill existing process
pkill -f "python.*apps.backend"

# Restart
./start.sh
```

### MCP Server Issues
```bash
# Check MCP server logs
docker logs pitsngiggles-mcp-server

# Restart MCP server
docker-compose -f docker-compose.mcp.yml restart
```

### Voice Not Working
- Ensure you're using HTTPS or localhost
- Check browser microphone permissions
- Try Chrome/Edge (best support for Web Speech API)
- Firefox may require specific permissions

### No Telemetry Data
- Verify F1 game is running and in a session
- Check UDP settings in game (port 20777)
- Ensure firewall allows UDP on port 20777
- Try restarting the game

## 🛑 Stopping the Application

```bash
# Stop main application
./stop.sh

# Stop Docker services
docker-compose -f docker-compose.mcp.yml down
```

## 🌐 AI Client Integration

The MCP server can be integrated with:
- **ChatGPT Desktop App**
- **Claude Desktop**
- **Cursor IDE**
- **VS Code**
- Any MCP-compatible AI client

See `docs/AI_CLIENT_SETUP.md` for detailed setup instructions.

### Example ChatGPT Desktop Configuration

Add to `~/Library/Application Support/ChatGPT/config.json` (macOS):
```json
{
  "mcpServers": {
    "pitsngiggles": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sse", "https://localhost:9443/telemetry/mcp"]
    }
  }
}
```

## 🚢 GitHub Repository

**Fork:** https://github.com/kmransom56/pitsngiggles-mcp-integration
**Original:** https://github.com/ashwin-nat/pits-n-giggles

### Latest Features (Branch: feature/f1-race-engineer-mcp)
- ✅ Full MCP integration in main codebase
- ✅ F1 Race Engineer AI with telemetry analysis
- ✅ Voice-enabled strategy center
- ✅ Web Speech API integration
- ✅ Docker deployment ready
- ✅ Nginx reverse proxy support
- ✅ Multi-AI client support

## 📝 License

MIT License - See LICENSE file for details

## 🙏 Credits

- **Original Project:** [Ashwin Natarajan](https://github.com/ashwin-nat/pits-n-giggles)
- **MCP Integration:** Keith Ransom
- **F1 Race Engineer Agent:** AI-powered with real F1 23/24/25 telemetry

## 🏎️ Happy Racing!

For questions, issues, or contributions, visit:
https://github.com/kmransom56/pitsngiggles-mcp-integration

---

**Status:** ✅ Ready for Production
**Last Updated:** April 2026
**Version:** 1.0.0
