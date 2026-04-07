# Complete Setup Guide - Pits n' Giggles with F1 Race Engineer

## 🎯 Quick Start (5 minutes)

### Prerequisites
- Docker Desktop installed
- F1 23/24/25 game
- (Optional) LLM API key for AI features

### One-Command Start
```bash
git clone https://github.com/kmransom56/pitsngiggles-mcp-integration.git
cd pitsngiggles-mcp-integration
./start.sh
```

That's it! The script will:
1. ✅ Check all prerequisites
2. ✅ Set up Python environment
3. ✅ Configure MCP server (optionally)
4. ✅ Start all services
5. ✅ Display access URLs

---

## 🏗️ What Gets Started

### Core Application
- **Backend**: FastAPI server receiving F1 telemetry
- **Web UI**: Real-time dashboards and overlays
- **WebSocket**: Live telemetry streaming

### MCP Server (Optional)
- **AI Race Engineer**: Analyzes telemetry and provides setup advice
- **API Endpoints**: REST and WebSocket interfaces
- **Voice Features**: Speech-to-text and text-to-speech

### Reverse Proxy (Docker mode)
- **nginx**: HTTPS termination and routing
- **SSL**: Self-signed certificate (auto-generated)

---

## 🎙️ Voice Features

### Accessing Voice Mode
1. Start the application: `./start.sh`
2. Open: http://localhost:4768/voice-strategy-center
3. Click "🎙️ Voice Mode" toggle

### Using Voice
- **Push-to-Talk**: Hold Space key or microphone button
- **Speak**: "Analyze my last lap"
- **Listen**: AI responds with voice + text

### Voice Technology
- **Speech-to-Text**: Browser Web Speech API (no API key needed)
- **Text-to-Speech**: Browser Web Speech API (no API key needed)
- **Zero Cost**: Completely free, runs in your browser
- **Privacy**: All processing happens locally

### Supported Browsers
- ✅ Chrome (best experience)
- ✅ Edge (excellent)
- ✅ Safari (good)
- ⚠️ Firefox (limited)

---

## 🤖 AI Race Engineer

### What It Does
The F1 Race Engineer is a specialized AI agent that:

1. **Analyzes Telemetry** - Tire temps, wear, fuel, speed, inputs
2. **Diagnoses Issues** - Understeer, oversteer, balance problems
3. **Recommends Setups** - Specific wing, diff, ARB, brake bias changes
4. **Provides Strategy** - Pit windows, tire management, pace advice
5. **Answers Questions** - Natural language queries about performance

### Agent Behavior

#### Understeer Example
```
Driver: "I have understeer in slow corners"

Engineer: 
**Diagnosis:** Front-end grip deficiency in low-speed corners

**Root Cause:** Insufficient front mechanical grip; possible front ARB too stiff

**Recommendations:**
1. Reduce front ARB by 1-2 clicks (softer)
2. Increase front wing by 1 click
3. Move brake bias 1% forward (to 56%)

**Expected Impact:** Better turn-in rotation and mid-corner grip in hairpins and chicanes

**Validation:** Monitor front tire temperatures - should increase 5-10°C
```

#### Oversteer Example
```
Driver: "Oversteer on corner exit"

Engineer:
**Diagnosis:** Rear instability on throttle application

**Root Cause:** Rear mechanical imbalance; diff may be too open

**Recommendations:**
1. Increase differential on-throttle to 65% (from 55%)
2. Reduce rear ARB by 1 click (softer)
3. Consider increasing rear wing 1 click for more stability

**Expected Impact:** More progressive power application; reduced snap on exit

**Validation:** Check rear tire temperatures and slip ratio data
```

### AI Modes

#### Mode 1: MCP Chat (Full AI)
- Uses external LLM (GPT-4, Claude, etc.)
- Intelligent, context-aware responses
- Requires API key
- Best experience

#### Mode 2: MCP (Telemetry Only)
- Automated telemetry analysis
- Rule-based recommendations
- No API key needed
- Good for basic diagnostics

#### Mode 3: OpenAI Direct
- Direct OpenAI API integration
- Fast responses
- Requires OpenAI API key
- Alternative to OpenRouter

**Switch modes in browser console:**
```javascript
switchAIMode("mcp_chat")  // Full AI with LLM
switchAIMode("mcp")       // Telemetry only
switchAIMode("openai")    // Direct OpenAI
```

---

## 🔧 Configuration

### LLM API Keys

#### Option 1: OpenRouter (Recommended)
1. Sign up: https://openrouter.ai
2. Create API key: https://openrouter.ai/keys
3. Edit `.env.mcp`:
   ```bash
   LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
   LLM_API_KEY=sk-or-v1-...
   LLM_MODEL=openai/gpt-4o-mini
   ```

**Why OpenRouter?**
- Access to 100+ models (GPT-4, Claude, Gemini, etc.)
- Free tier available
- Pay-per-use pricing
- Model fallback support

#### Option 2: OpenAI Direct
1. Sign up: https://platform.openai.com
2. Create API key: https://platform.openai.com/api-keys
3. Edit `.env.mcp`:
   ```bash
   LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
   LLM_API_KEY=sk-...
   LLM_MODEL=gpt-4o-mini
   ```

#### Option 3: Anthropic Claude
1. Use via OpenRouter (easiest)
2. Edit `.env.mcp`:
   ```bash
   LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
   LLM_API_KEY=sk-or-v1-...
   LLM_MODEL=anthropic/claude-3.5-sonnet
   ```

### Port Configuration

Default ports in `.env.mcp`:
```bash
HTTP_PORT=80          # Main HTTP access
HTTPS_PORT=443        # HTTPS access (Docker only)
MCP_PORT=8765         # MCP server port
```

Change if you have conflicts:
```bash
HTTP_PORT=8080
HTTPS_PORT=8443
MCP_PORT=9000
```

---

## 🐳 Docker vs Native

### Docker Mode (Recommended)
**Pros:**
- ✅ Isolated environment
- ✅ nginx reverse proxy with HTTPS
- ✅ Easy to start/stop
- ✅ Consistent across systems
- ✅ Production-ready

**Cons:**
- Requires Docker Desktop
- Slightly more resource usage

**Start:**
```bash
./start.sh  # Select Docker when prompted
```

**Stop:**
```bash
docker compose -f docker-compose.mcp.yml down
```

### Native Mode
**Pros:**
- ✅ Faster startup
- ✅ Direct process access
- ✅ Easier debugging
- ✅ Lower resource usage

**Cons:**
- No nginx/HTTPS
- Manual dependency management
- Direct port exposure

**Start:**
```bash
./start.sh  # Select Native when prompted
```

**Stop:**
```bash
./stop.sh
```

---

## 📡 Connecting AI Clients

### ChatGPT Desktop

1. Install: https://openai.com/chatgpt/desktop/
2. Open Settings → Integrations
3. Add MCP Server:
   ```json
   {
     "mcpServers": {
       "f1-race-engineer": {
         "url": "https://localhost:9443/telemetry/mcp",
         "name": "F1 Race Engineer",
         "description": "F1 23/24/25 telemetry analysis and setup advice"
       }
     }
   }
   ```
4. Restart ChatGPT
5. Look for "F1 Race Engineer" in available tools

### Claude Desktop

1. Install: https://claude.ai/download
2. Edit config: `~/.config/claude/config.json` (Linux/Mac) or `%APPDATA%\Claude\config.json` (Windows)
3. Add:
   ```json
   {
     "mcpServers": {
       "f1-race-engineer": {
         "url": "https://localhost:9443/telemetry/mcp",
         "name": "F1 Race Engineer"
       }
     }
   }
   ```
4. Restart Claude

### Cursor IDE

1. Open Cursor Settings
2. Go to MCP Servers
3. Add new server:
   - URL: `https://localhost:9443/telemetry/mcp` (SSE from PNG via `/telemetry/`; Docker `mcp_server` uses `POST /mcp/chat` on `:8765`, not SSE)
   - Name: F1 Race Engineer
4. Save and reload

---

## 🎮 F1 Game Configuration

### UDP Telemetry Setup

1. Launch F1 23/24/25
2. Go to **Settings** → **Telemetry Settings**
3. Configure:
   - **UDP Telemetry**: On
   - **UDP Broadcast Mode**: On
   - **UDP IP Address**: 127.0.0.1
   - **UDP Port**: 20777
   - **UDP Format**: 2023/2024/2025
4. Save and start a session

### Network Firewall

If telemetry isn't working:
1. Allow Python through firewall
2. Check port 20777 isn't blocked
3. Verify localhost connectivity

---

## 🔍 Troubleshooting

### MCP Server Won't Start

**Symptom:** `./start-mcp.sh` fails

**Solutions:**
1. Check Docker is running: `docker ps`
2. Check port conflicts: `lsof -i :9080 -i :9443 -i :8765`
3. Review logs: `docker compose -f docker-compose.mcp.yml logs`
4. Try native mode: `./start.sh` and select "Native"

### Voice Not Working

**Symptom:** Microphone button greyed out

**Solutions:**
1. Use Chrome or Edge browser
2. Grant microphone permission
3. Check browser console for errors
4. Verify HTTPS (voice requires secure context)
5. Test with http://localhost (not 127.0.0.1)

### AI Responses Are Generic

**Symptom:** AI doesn't use telemetry data

**Solutions:**
1. Check MCP server is running: `curl -sk https://localhost:9443/health`
2. Verify LLM API key in `.env.mcp`
3. Check API key balance/quota
4. Review MCP logs: `docker compose -f docker-compose.mcp.yml logs mcp-server`
5. Try switching to `mcp_chat` mode

### No Telemetry Data

**Symptom:** Dashboard shows "No data"

**Solutions:**
1. Verify F1 game is running with UDP enabled
2. Check UDP port: 20777
3. Test with: `nc -u -l 20777` (should see data)
4. Restart backend: `./stop.sh && ./start.sh`
5. Check firewall settings

---

## 📊 Architecture

```
┌─────────────────┐
│  F1 23/24/25    │  UDP Telemetry (60 Hz)
│     Game        │────────────────────────┐
└─────────────────┘                        │
                                           ▼
┌──────────────────────────────────────────────────────────┐
│              Pits n' Giggles Backend                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ UDP Receiver │→ │ State Engine │→ │  WebSocket   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                           │                              │
│                           ▼                              │
│                    ┌──────────────┐                      │
│                    │  MCP Server  │                      │
│                    │  (FastAPI)   │                      │
│                    └──────────────┘                      │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │    nginx (Docker)      │
              │  Reverse Proxy + SSL   │
              └────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Strategy   │  │   ChatGPT    │  │    Claude    │
│    Center    │  │   Desktop    │  │   Desktop    │
│  (Browser)   │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
      │
      ▼
┌──────────────┐
│ Voice Layer  │
│  STT + TTS   │
│  (Browser)   │
└──────────────┘
```

### Data Flow

1. **F1 Game** → UDP packets at 60 Hz
2. **Backend** → Receives, parses, computes state
3. **WebSocket** → Broadcasts to all connected clients
4. **MCP Server** → Exposes telemetry via API
5. **Strategy Center** → Displays telemetry + AI chat
6. **Voice Layer** → Converts speech ↔ text (browser)
7. **AI Clients** → Analyze via MCP SSE endpoint

---

## 🚀 Advanced Usage

### Multiple AI Clients

Run multiple AI clients simultaneously:
1. ChatGPT analyzing race strategy
2. Claude providing setup advice
3. Strategy Center for quick questions
4. Voice mode for hands-free racing

All clients see the same telemetry data in real-time.

### Custom Voice Settings

Edit `voice-strategy-center.html`:
```javascript
const voiceSettings = {
    voice: "Google UK English Male",  // Voice name
    rate: 0.95,                        // Speed (0.5-2.0)
    pitch: 0.9,                        // Pitch (0.5-2.0)
    volume: 1.0                        // Volume (0-1)
};
```

### Production Deployment

For production use:

1. **Get real SSL certificate** (Let's Encrypt)
2. **Use production LLM keys** (with rate limits)
3. **Configure nginx** for your domain
4. **Set up monitoring** (healthchecks)
5. **Enable authentication** (if exposing publicly)

---

## 📚 Documentation

- **Building**: `docs/BUILDING.md`
- **Voice Integration**: `docs/VOICE_INTEGRATION.md`
- **F1 Agent Config**: `docs/F1_RACE_ENGINEER_AGENT.md`
- **AI Client Setup**: `docs/AI_CLIENT_SETUP.md`
- **Docker Quick Start**: `docs/DOCKER_QUICKSTART.md`
- **MCP Integration**: `docs/MCP_INTEGRATION.md`

---

## 🐛 Getting Help

### Logs

**Docker mode:**
```bash
docker compose -f docker-compose.mcp.yml logs -f
```

**Native mode:**
```bash
tail -f mcp_server.log
tail -f backend.log
```

### Health Checks

```bash
# Backend
curl http://localhost:4768/race-info

# MCP Server (Docker)
curl -sk https://localhost:9443/health

# MCP Server (Native)
curl http://localhost:8765/health
```

### Debug Mode

Set in `.env.mcp`:
```bash
LOG_LEVEL=DEBUG
```

Restart services to see detailed logs.

### Community

- **GitHub Issues**: Report bugs or request features
- **Discussions**: Ask questions and share setups
- **Discord**: Join the Pits n' Giggles community

---

## 🏁 Quick Reference

### Starting
```bash
./start.sh
```

### Stopping
```bash
./stop.sh
docker compose -f docker-compose.mcp.yml down
```

### URLs
- Main UI: http://localhost:4768
- Voice Strategy: http://localhost:4768/voice-strategy-center
- Docker MCP chat: `POST https://localhost:9443/mcp/chat` or `POST http://localhost:8765/mcp/chat`
- MCP health: `https://localhost:9443/health` (or `:8765/health` direct)

### Voice Controls
- **Push-to-Talk**: Space key
- **Stop Speaking**: ESC key
- **Settings**: ⚙️ button

### AI Modes
```javascript
switchAIMode("mcp_chat")  // Full AI
switchAIMode("mcp")       // Telemetry only
switchAIMode("openai")    // Direct OpenAI
```

---

**Happy Racing! 🏎️💨**
