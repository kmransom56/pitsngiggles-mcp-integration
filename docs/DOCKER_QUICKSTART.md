# Docker Quick Start - F1 Race Engineer with Pits N Giggles

**Get the complete F1 Race Engineer AI + Telemetry system running in under 5 minutes with Docker!**

---

## Prerequisites

- Docker Desktop installed ([Get Docker](https://www.docker.com/get-started))
- F1 23/24/25 game
- **Optional:** OpenRouter or OpenAI API key for AI responses (free tier available)

---

## Quick Start (3 Steps)

### 1. Clone the Repository

```bash
git clone https://github.com/ashwin-nat/pits-n-giggles.git
cd pits-n-giggles
```

### 2. Start the Services

```bash
# Linux/macOS
./start-mcp.sh

# Windows
start-mcp.bat
```

**Note:** First run will automatically:
- Create `.env.mcp` configuration file
- Generate self-signed SSL certificates
- Pull/build Docker images
- Start all services

### 3. Configure Your AI (Optional but Recommended)

Edit `.env.mcp` and add your API key:

```bash
# Get a FREE API key from OpenRouter
# Visit: https://openrouter.ai/keys
LLM_API_KEY=sk-or-v1-your-key-here
```

**Restart services:**
```bash
./stop-mcp.sh && ./start-mcp.sh
```

---

## Access the System

### Strategy Center (Built-in AI Chat)
```
http://localhost/strategy-center
```
- Chat with F1 Race Engineer
- View live telemetry
- Get setup recommendations

### Voice Strategy Center (Speech Enabled)
```
http://localhost/voice-strategy-center
```
- Talk to your AI engineer
- Push-to-talk with Space key
- Hear responses via text-to-speech

### Classic Dashboards
```
http://localhost/driver-view        # Driver telemetry view
http://localhost/eng-view            # Engineer dashboard
http://localhost                      # Main telemetry hub
```

---

## Connect F1 Game

1. **Start F1 23/24/25**
2. **Enable UDP Telemetry:**
   - Settings → Telemetry Settings
   - UDP Telemetry: **On**
   - UDP Broadcast Mode: **On**
   - UDP IP Address: **127.0.0.1** (or your Docker host IP)
   - UDP Port: **20777**
   - UDP Send Rate: **60Hz** (recommended)
   - UDP Format: **2023** or **2024**

3. **Start a session** (Practice, Qualifying, or Race)

Telemetry should start flowing immediately!

---

## Connect AI Clients (ChatGPT, Claude, Cursor)

### ChatGPT Desktop

**Edit:** `~/Library/Application Support/ChatGPT/mcp_config.json` (macOS)

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse",
      "name": "F1 Race Engineer",
      "description": "Live F1 telemetry analysis and race engineering"
    }
  }
}
```

**Restart ChatGPT** → The F1 icon appears in the chat!

### Claude Desktop

**Edit:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "command": "curl",
      "args": ["-N", "http://localhost/mcp/sse"]
    }
  }
}
```

### Cursor IDE

**Settings** → **Features** → **MCP Servers** → **Add Server**

```
Name: F1 Race Engineer
URL: http://localhost/mcp/sse
```

---

## How It Works

### Architecture Overview

```
F1 Game (UDP) → Pits N Giggles (host:4768) → Docker Services
                                                   ↓
                                        ┌──────────────────┐
                                        │  Nginx (80/443)  │
                                        └────────┬─────────┘
                                                 │
                         ┌───────────────────────┼───────────────────┐
                         ↓                       ↓                   ↓
                  Web Frontend           MCP Server (8765)    AI Clients
              (Strategy Center)         (F1 Race Engineer)   (ChatGPT/Claude)
                         │                       │
                         └───────────────────────┘
                            Live Telemetry + AI Analysis
```

### Components

1. **Pits N Giggles** (Runs on host at `localhost:4768`)
   - Receives UDP telemetry from F1 game
   - Processes and computes race data
   - Exposes REST API and Socket.IO

2. **Nginx Reverse Proxy** (Docker, port 80/443)
   - Routes requests to appropriate services
   - Handles SSL/TLS
   - Serves frontend HTML pages
   - Proxies telemetry from host

3. **MCP Server** (Docker, port 8765)
   - F1 Race Engineer AI agent
   - 10 specialized MCP tools
   - Connects to LLM (OpenRouter/OpenAI)
   - Analyzes telemetry data

4. **Web Frontend** (Served by Nginx)
   - Strategy Center (chat interface)
   - Voice Strategy Center (speech-enabled)
   - Classic telemetry dashboards

---

## Usage Examples

### Example 1: Setup Advice

**In Strategy Center:**
```
You: "I have oversteer on corner exit"

AI Engineer: "Based on current telemetry analysis:

**Diagnosis:** Oversteer on corner exit indicates excessive rear 
rotation when applying throttle.

**Root Cause:** Rear of the car is losing grip before the front 
during throttle application phase.

**Recommendations:**
1. Increase rear anti-roll bar by 1-2 clicks (current: too soft)
2. Raise differential on-throttle setting to 65-70% 
3. Consider +1 click rear wing for additional stability

**Expected Impact:** More rear grip on exit, smoother throttle 
application, potentially 0.1-0.2s faster per lap."
```

### Example 2: Voice Control

**In Voice Strategy Center:**
```
[Press & hold SPACE]
You: "Analyze my last lap"
[Release SPACE]

AI Engineer: [Spoken response]
"Your last lap was 1:32.456, approximately 0.3 seconds off optimal 
pace. Sector 2 showed the most time loss with inconsistent 
braking points. I recommend focusing on trail-braking 
consistency into Turn 8..."
```

### Example 3: ChatGPT Integration

**In ChatGPT:**
```
You: "What tools do you have access to for F1 telemetry?"

ChatGPT: "I can access 10 F1 Race Engineer tools:
- get_telemetry_data - Live race positions
- get_race_info - Session and weather data
- get_driver_info - Specific driver details
- analyze_tyre_strategy - Tire degradation analysis
- get_lap_comparison - Compare lap times
- diagnose_performance_issues - Setup analysis
- analyze_sector_performance - Sector-by-sector breakdown
- compare_to_leader - Gap analysis
- get_stream_overlay_data - Streaming data
- analyze_lap_time_consistency - Consistency tracking

What would you like to analyze?"
```

---

## Voice Features

### Push-to-Talk

- **Button:** Click & hold the microphone button
- **Keyboard:** Press & hold **SPACE** key
- Speak your question
- Release when done
- Auto-sends to AI

### Voice Settings

Click **⚙️ Settings** to customize:
- **Voice Selection** - Choose system voice
- **Speed** - 0.5x to 2.0x (default: 1.0x)
- **Pitch** - 0.5 to 2.0 (default: 1.0)
- **Auto-Speak** - Automatic response vocalization

### Browser Support

- ✅ Chrome (Best)
- ✅ Edge (Excellent)
- ✅ Safari (Good)
- ⚠️ Firefox (Limited)

---

## Available MCP Tools

The F1 Race Engineer provides 10 specialized tools:

| Tool | Purpose | Example Use |
|------|---------|-------------|
| `get_telemetry_data` | Live race standings | "What's the current race order?" |
| `get_race_info` | Session and weather | "What's the weather looking like?" |
| `get_driver_info` | Specific driver data | "How's Hamilton doing?" |
| `get_lap_comparison` | Compare lap times | "Compare my laps to P1" |
| `analyze_tyre_strategy` | Tire degradation | "When should I pit?" |
| `diagnose_performance_issues` | Setup problems | "Why am I slow in sector 2?" |
| `analyze_sector_performance` | Sector analysis | "Where am I losing time?" |
| `compare_to_leader` | Gap analysis | "What's my gap to the leader?" |
| `get_stream_overlay_data` | Streaming info | "Get overlay data" |
| `analyze_lap_time_consistency` | Consistency tracking | "Am I consistent?" |

---

## AI Modes

The Strategy Center supports 3 AI modes (switch via UI toggle):

### 1. MCP F1 Engineer (Recommended)
- Full AI-powered race engineering
- Uses LLM (OpenRouter/OpenAI)
- Context-aware responses
- Requires API key
- **Best for:** Detailed analysis and advice

### 2. MCP Tools Only
- Direct tool responses
- No AI interpretation
- Instant results
- No API key needed
- **Best for:** Raw data queries

### 3. OpenAI Direct
- OpenAI GPT-4 with telemetry context
- Requires OpenAI API key
- General-purpose AI
- **Best for:** Custom setups

---

## Configuration Files

### `.env.mcp` - Main Configuration

```bash
# LLM Provider
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=your_api_key_here
LLM_MODEL=openai/gpt-4o-mini

# Ports
HTTP_PORT=80
HTTPS_PORT=443
MCP_PORT=8765

# Pits N Giggles (running on host)
TELEMETRY_HOST=host.docker.internal
TELEMETRY_PORT=4768
```

### Supported LLM Models

**Via OpenRouter (Recommended):**
- `openai/gpt-4o-mini` (Fast, cheap, good)
- `openai/gpt-4o` (Best quality)
- `anthropic/claude-3.5-sonnet` (Excellent)
- `google/gemini-pro-1.5` (Fast alternative)
- `meta-llama/llama-3.1-70b-instruct` (Open source)

**Direct OpenAI:**
```bash
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-...
LLM_MODEL=gpt-4o-mini
```

---

## Troubleshooting

### "No telemetry data"
1. Verify F1 game UDP settings
2. Check Pits N Giggles is running on host: `http://localhost:4768`
3. Ensure game session is active (not menu)

### "AI not responding"
1. Check `.env.mcp` has valid `LLM_API_KEY`
2. Verify API key has credits (OpenRouter dashboard)
3. Check MCP server logs: `docker-compose -f docker-compose.mcp.yml logs mcp-server`

### "Voice not working"
1. Use Chrome or Edge browser
2. Grant microphone permissions
3. Check system TTS voices installed
4. Fallback to text input if needed

### "Port already in use"
```bash
# Change ports in .env.mcp
HTTP_PORT=8080
HTTPS_PORT=8443

# Restart services
./stop-mcp.sh && ./start-mcp.sh
```

### "SSL certificate warning"
- Self-signed certificates show browser warnings
- Click "Advanced" → "Proceed" (safe for local dev)
- For production, replace with real certificates

---

## Management Commands

### Start Services
```bash
./start-mcp.sh
```

### Stop Services
```bash
./stop-mcp.sh
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.mcp.yml logs -f

# MCP server only
docker-compose -f docker-compose.mcp.yml logs -f mcp-server

# Nginx only
docker-compose -f docker-compose.mcp.yml logs -f nginx
```

### Restart Services
```bash
docker-compose -f docker-compose.mcp.yml restart
```

### Rebuild Containers
```bash
docker-compose -f docker-compose.mcp.yml build
docker-compose -f docker-compose.mcp.yml up -d
```

### Health Check
```bash
curl http://localhost/health
```

---

## Advanced Configuration

### Running Pits N Giggles in Docker

**Uncomment in `docker-compose.mcp.yml`:**
```yaml
pits-n-giggles:
  build:
    context: .
    dockerfile: Dockerfile
  container_name: pits-n-giggles
  ports:
    - "4768:4768"
  networks:
    - f1-network
```

**Update `.env.mcp`:**
```bash
TELEMETRY_HOST=pits-n-giggles
TELEMETRY_PORT=4768
```

### Custom Nginx Configuration

Edit `deployment/nginx/pitsngiggles-mcp.conf` and restart nginx:
```bash
docker-compose -f docker-compose.mcp.yml restart nginx
```

### Production SSL

Replace self-signed certificates with real ones:
```bash
# Place certificates
cp /path/to/fullchain.pem ssl/fullchain.pem
cp /path/to/privkey.pem ssl/privkey.pem

# Update nginx config
# Edit: deployment/nginx/pitsngiggles-mcp.conf

# Restart nginx
docker-compose -f docker-compose.mcp.yml restart nginx
```

---

## Performance

### System Requirements
- **CPU:** 2+ cores recommended
- **RAM:** 4 GB minimum, 8 GB recommended
- **Network:** LAN or localhost (low latency)
- **Storage:** 2 GB for Docker images

### Resource Usage
- **Pits N Giggles:** ~200 MB RAM, 5-10% CPU
- **MCP Server:** ~300 MB RAM, 10-20% CPU (when processing)
- **Nginx:** ~50 MB RAM, <5% CPU
- **Total:** ~600 MB RAM, 15-30% CPU

### Latency
- **Telemetry Update:** 60 Hz (16.67ms)
- **AI Response:** 1-3 seconds (LLM dependent)
- **Voice Recognition:** 500-2000ms
- **Voice Synthesis:** 100-500ms

---

## Next Steps

### Share with Community
1. Test thoroughly with your racing setup
2. Report issues on GitHub
3. Share your experience
4. Contribute improvements

### Enhance Your Setup
- [ ] Configure production SSL certificates
- [ ] Explore all 10 MCP tools
- [ ] Try voice control while racing
- [ ] Connect ChatGPT for deeper analysis
- [ ] Create custom AI prompts
- [ ] Set up OBS streaming overlays

### Contribute
- [ ] Add support for more LLM providers
- [ ] Create track-specific setup guides
- [ ] Improve voice recognition
- [ ] Build custom MCP tools
- [ ] Enhance telemetry analysis

---

## API Reference

### MCP Endpoints

```bash
# Chat API (JSON)
POST http://localhost/api/chat
Content-Type: application/json

{
  "message": "I have understeer in slow corners",
  "telemetry": { ... }
}

# WebSocket
ws://localhost/api/ws

# MCP SSE (for AI clients)
GET http://localhost/mcp/sse

# Health Check
GET http://localhost/health
```

### Telemetry Endpoints (Proxied from Pits N Giggles)

```bash
# Live telemetry
GET http://localhost/telemetry-info

# Race info
GET http://localhost/race-info

# Driver details
GET http://localhost/driver-info?driver=0

# All endpoints from Pits N Giggles available via proxy
```

---

## Support

### Documentation
- [Main README](../README.md)
- [Building Guide](BUILDING.md)
- [MCP Integration](MCP_INTEGRATION.md)
- [Voice Integration](VOICE_INTEGRATION.md)
- [AI Client Setup](AI_CLIENT_SETUP.md)
- [F1 Agent Configuration](F1_AGENT_CONFIG.md)

### Community
- GitHub Issues: [Report bugs](https://github.com/ashwin-nat/pits-n-giggles/issues)
- GitHub Discussions: [Get help](https://github.com/ashwin-nat/pits-n-giggles/discussions)

### Quick Reference
- [MCP Quick Start](../MCP_README.md)
- [Voice Quick Reference](VOICE_QUICK_REFERENCE.md)
- [F1 Quick Setup](F1_RACE_ENGINEER_QUICK_SETUP.md)

---

## License

Pits n' Giggles is open source. See [LICENSE](../LICENSE) for details.

The F1 Race Engineer MCP integration is part of the same project and follows the same license.

---

**Ready to race smarter? Start your engines! 🏎️💨**
