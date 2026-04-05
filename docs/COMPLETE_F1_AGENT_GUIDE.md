# Complete F1 Race Engineer Agent Guide

## 🎯 Overview

This guide covers the complete F1 Race Engineer AI Agent integration with Pits N Giggles, including:
- MCP (Model Context Protocol) server setup
- Voice-enabled Strategy Center
- Docker deployment
- AI client integration (ChatGPT, Claude, etc.)
- nginx reverse proxy configuration

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
                         │      Nginx Reverse Proxy           │
                         │      :80 (HTTP) :443 (HTTPS)       │
                         └─────────────────────────────────────┘
                                │                   │
                    ┌───────────┴─────┬─────────────┘
                    ▼                 ▼
          ┌─────────────────┐  ┌─────────────────┐
          │ Strategy Center │  │   MCP Server    │
          │  Voice UI       │  │   :8765         │
          │  (Browser)      │  │ F1 AI Engineer  │
          └─────────────────┘  └─────────────────┘
```

## 🚀 Quick Start Options

### Option 1: One-Command Start (Recommended)

```bash
cd /path/to/pits-n-giggles
./start.sh
```

The script will:
1. ✅ Check prerequisites (Python, nginx, Node.js, Docker)
2. ✅ Set up Python virtual environment
3. ✅ Install dependencies
4. ✅ Configure MCP server (interactive)
5. ✅ Start all services

### Option 2: Docker-Only Deployment

```bash
# If Pits N Giggles is already running on host
docker-compose -f docker-compose.mcp.yml up -d

# To include Pits N Giggles in Docker
# Edit docker-compose.mcp.yml and uncomment pits-n-giggles service
docker-compose -f docker-compose.mcp.yml up -d
```

### Option 3: Manual Setup

See [BUILDING.md](BUILDING.md) for detailed manual installation steps.

## 🎙️ F1 Race Engineer Agent

### Purpose

The F1 Race Engineer is an AI agent specialized in:
- Analyzing F1 23/24 telemetry data in real-time
- Providing professional car setup and tuning advice
- Troubleshooting handling issues (understeer/oversteer)
- Recommending pit strategies and fuel management
- Improving lap times through data-driven insights

### Activation Triggers

The agent responds to:
- Car handling issues (Understeer/Oversteer)
- Setup lookup or tuning recommendations
- Telemetry analysis requests
- Pits N Giggles telemetry data
- Voice commands in Voice Strategy Center

### Key Skills & Tuning Logic

#### Aerodynamics
- **Increase front wing** → Better turn-in grip (fixes understeer)
- **Increase rear wing** → More stability (fixes oversteer)
- **Balance**: Match front/rear downforce for neutral handling

#### Differential
- **Lower on-throttle diff** → More rotation on corner exit
- **Lower off-throttle diff** → More rotation on corner entry
- **Higher settings** → More stability but less agility

#### Suspension
- **Stiffen rear ARB** → Reduce oversteer
- **Stiffen front ARB** → Reduce understeer
- **Spring rates**: Softer for bumpy tracks, stiffer for smooth circuits

#### Brake Bias
- **Move forward (55-58%)** → Reduce oversteer under braking
- **Move rear (50-53%)** → Reduce understeer under braking
- **Track-specific**: Monaco needs more front, Monza more rear

#### Telemetry Analysis
The agent maps corner phases to mechanical adjustments:
- **Entry**: Off-throttle diff, brake bias, front ARB
- **Apex**: Roll bars, ride height, tyre pressures
- **Exit**: On-throttle diff, rear wing, traction control

## 🎯 Access Points

After starting services:

### Main Application
- **Driver View**: `http://localhost:4768/`
- **Engineer View**: `http://localhost:4768/eng-view`

### AI Strategy Centers
- **Strategy Center** (Text): `http://localhost:4768/strategy-center`
- **Voice Strategy Center**: `http://localhost:4768/voice-strategy-center`

### MCP Server Endpoints
- **HTTP API**: `http://localhost:80/api/chat`
- **WebSocket**: `ws://localhost:80/api/ws`
- **SSE (AI Clients)**: `http://localhost:80/mcp/sse`
- **Health Check**: `http://localhost:80/health`

If using Docker mode:
- **HTTPS**: `https://localhost:443`

## 🎙️ Voice Features

### Quick Start

1. **Open Voice Strategy Center**:
   ```
   http://localhost:4768/voice-strategy-center
   ```

2. **Enable Voice Mode**: Click the "🎙️ Voice Mode" toggle

3. **Push-to-Talk**:
   - Press & hold microphone button OR Space key
   - Speak your question: *"Analyze my last lap"*
   - Release to send

4. **Hear Response**: AI responds with text + voice automatically

### Voice Controls

**Push-to-Talk (PTT)**:
- **Microphone Button**: Click and hold
- **Space Key**: Press and hold (hands-free racing!)
- **Release**: Stops recording and sends

**Voice Settings**:
- **Voice Selection**: Choose from available browser voices
- **Speech Rate**: 0.5x - 2.0x speed
- **Pitch**: Adjust voice tone
- **Auto-speak**: Toggle automatic TTS responses

### Voice Technology

- 🎙️ **Speech-to-Text**: Browser's Web Speech API (no API keys!)
- 🔊 **Text-to-Speech**: Browser's Speech Synthesis API
- 🏎️ **Zero Latency**: Local browser processing
- 💰 **Zero Cost**: No external services
- 🔒 **Privacy-First**: No data sent to third parties

## 🔧 Configuration

### LLM Configuration (.env.mcp)

```bash
# OpenRouter (Recommended - Access to multiple models)
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-...
LLM_MODEL=openai/gpt-4o-mini

# OpenAI Direct
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-...
LLM_MODEL=gpt-4o-mini

# Anthropic Claude via OpenRouter
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-...
LLM_MODEL=anthropic/claude-3-5-sonnet
```

### Port Configuration

```bash
HTTP_PORT=80          # nginx HTTP
HTTPS_PORT=443        # nginx HTTPS
MCP_PORT=8765         # MCP server
TELEMETRY_HOST=host.docker.internal  # Pits N Giggles host
TELEMETRY_PORT=4768   # Pits N Giggles port
```

## 🤖 AI Client Integration

### ChatGPT Desktop

Add to ChatGPT configuration:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "command": "npx",
      "args": [
        "-y",
        "sse-mcp-client",
        "http://localhost:80/mcp/sse"
      ]
    }
  }
}
```

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost:80/mcp/sse",
      "transport": "sse"
    }
  }
}
```

### Other AI Clients

Any MCP-compatible client can connect via:
- **SSE Endpoint**: `http://localhost:80/mcp/sse`
- **WebSocket**: `ws://localhost:80/api/ws`
- **HTTP REST**: `http://localhost:80/api/chat`

## 🐳 Docker Deployment

### Architecture

```
┌─────────────────────────────────────────┐
│         Docker Host                     │
│  ┌──────────────┐   ┌──────────────┐  │
│  │ MCP Server   │   │   Nginx      │  │
│  │  :8765       │◀─▶│  :80, :443   │  │
│  └──────────────┘   └──────────────┘  │
│         ▲                   ▲          │
└─────────┼───────────────────┼──────────┘
          │                   │
          │                   ▼
          │           Browser (Strategy Center)
          │
          ▼
   Pits N Giggles (Host :4768)
```

### Services

**MCP Server Container**:
- Image: Custom build from `Dockerfile.mcp`
- Port: 8765
- Health check: `/health` endpoint
- Volumes: `mcp-data` for persistence

**Nginx Container**:
- Image: Custom build from `Dockerfile.nginx`
- Ports: 80 (HTTP), 443 (HTTPS)
- Serves: Strategy Center UI, reverse proxy to MCP
- Volumes: SSL certs, logs, static HTML

### Commands

```bash
# Start all services
docker-compose -f docker-compose.mcp.yml up -d

# View logs
docker-compose -f docker-compose.mcp.yml logs -f

# Stop services
docker-compose -f docker-compose.mcp.yml down

# Rebuild after code changes
docker-compose -f docker-compose.mcp.yml up -d --build

# Check health
curl http://localhost:80/health
```

## 🔒 SSL/TLS Configuration

### Development (Self-Signed)

Generated automatically by `start.sh`:

```bash
mkdir -p ssl
openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -days 365 \
    -subj "/C=US/ST=State/L=City/O=PitsNGiggles/CN=localhost"
```

### Production

Replace with real certificates:

```bash
# Using Let's Encrypt
certbot certonly --standalone -d your-domain.com

# Copy to ssl directory
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem

# Restart nginx
docker-compose -f docker-compose.mcp.yml restart nginx
```

## 📊 Agent Response Capabilities

### Real-Time Analysis

The agent provides:
- **Handling Issues**: Identifies understeer/oversteer from telemetry
- **Setup Changes**: Specific click adjustments for aero, diff, ARB
- **Tyre Management**: Wear rates, temperature balance, compound strategy
- **Fuel Strategy**: Consumption tracking, saving opportunities
- **Lap Time**: Sector analysis, corner-by-corner optimization

### Example Interactions

**Voice Command**: *"Why am I getting understeer in Turn 1?"*

**Agent Response**:
```
Based on your telemetry, the front wing is set too low for Turn 1's entry speed. 
I recommend:

1. Increase front wing by 2 clicks
2. Reduce front ARB stiffness by 1 click
3. Check front tyre pressure - increase by 0.2 PSI if below 23.0

This should give you better front-end grip on entry while maintaining 
balance through the apex.
```

**Voice Command**: *"When should I pit?"*

**Agent Response**:
```
Your current tyre wear is at 48% on lap 12. Degradation rate suggests:

Optimal pit window: Laps 15-17
- Wear will reach 65% by lap 17
- Track position: You'll lose 2 positions but gain 1 back
- Compound: Switch to mediums for 18-lap final stint

Alternative: Extend to lap 19 if you can manage tyre temps below 95°C.
```

## 🧪 Testing the Integration

### 1. Test Pits N Giggles Backend

```bash
curl http://localhost:4768/health
# Expected: {"status": "ok"}
```

### 2. Test MCP Server

```bash
curl http://localhost:80/health
# Expected: {"status": "healthy"}
```

### 3. Test Strategy Center

Open in browser: `http://localhost:4768/strategy-center`

### 4. Test Voice Integration

Open in browser: `http://localhost:4768/voice-strategy-center`

### 5. Test AI Agent

In Strategy Center, send:
```
"Analyze my current setup"
```

Should receive AI-generated response with telemetry analysis.

## 🛠️ Troubleshooting

### MCP Server Won't Start

```bash
# Check logs
docker-compose -f docker-compose.mcp.yml logs mcp-server

# Verify port availability
lsof -i :8765

# Check .env.mcp configuration
cat .env.mcp
```

### Voice Not Working

1. **Check browser support**: Chrome/Edge recommended
2. **Grant microphone permission**: Browser will prompt
3. **Test microphone**: Check browser settings
4. **HTTPS required**: Some browsers require HTTPS for voice

### AI Not Responding

1. **Check LLM_API_KEY** in `.env.mcp`
2. **Verify API endpoint**: Test with curl
3. **Check logs**: `docker-compose -f docker-compose.mcp.yml logs`
4. **Fallback mode**: Agent works without API key (limited responses)

### nginx Connection Issues

```bash
# Check nginx status
docker-compose -f docker-compose.mcp.yml ps nginx

# View nginx logs
docker-compose -f docker-compose.mcp.yml logs nginx

# Test configuration
docker-compose -f docker-compose.mcp.yml exec nginx nginx -t
```

## 📚 Additional Documentation

- **Building**: [docs/BUILDING.md](BUILDING.md)
- **Voice Guide**: [docs/VOICE_INTEGRATION.md](VOICE_INTEGRATION.md)
- **Docker Quickstart**: [docs/DOCKER_QUICKSTART.md](DOCKER_QUICKSTART.md)
- **AI Client Setup**: [docs/AI_CLIENT_SETUP.md](AI_CLIENT_SETUP.md)
- **Strategy Center**: [docs/STRATEGY_CENTER.md](STRATEGY_CENTER.md)
- **Testing**: [docs/TESTING.md](TESTING.md)

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](../LICENSE) for details.

## 🏁 Next Steps

1. ✅ **Test deployment** - Run `./start.sh` and verify
2. ✅ **Configure AI** - Add your LLM API key
3. ✅ **Try voice** - Open Voice Strategy Center
4. ⏭️ **Production SSL** - Replace self-signed cert
5. ⏭️ **Share feedback** - Contribute to the community
6. ⏭️ **Docker Hub** - Consider publishing images

---

**Happy Racing! 🏎️💨**
