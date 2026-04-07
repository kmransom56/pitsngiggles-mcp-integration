# F1 Race Engineer MCP - Quick Reference Card

## 🚀 Quick Start (5 Minutes)

```bash
# 1. Configure
cp .env.mcp.example .env.mcp
nano .env.mcp  # Add LLM_API_KEY

# 2. Start
./start-mcp.sh

# 3. Access (nginx HTTPS default host port 9443)
https://localhost:9443/
```
(Trust or `-k` self-signed cert in dev.)

## 🔑 Get API Key

**OpenRouter (Recommended):**
1. Visit: https://openrouter.ai/keys
2. Sign up and add $5 credit
3. Copy API key to .env.mcp

## 📡 Endpoints

**Docker `mcp_server` (HTTP + WebSocket only — no SSE):**

| Path | Purpose | Method |
|------|---------|--------|
| `http://localhost:8765/mcp/chat` | Chat | POST |
| `ws://localhost:8765/mcp/ws` | WebSocket | WS |
| `http://localhost:8765/health` | Status | GET |

**Via nginx** (`HTTPS_PORT` default **9443**): `https://localhost:9443/mcp/chat`, `wss://localhost:9443/mcp/ws`, `https://localhost:9443/health`.

**PNG on host `:4768`** (SSE for MCP-style streams): `GET http://localhost:4768/mcp`  
**Through nginx telemetry prefix:** `GET https://localhost:9443/telemetry/mcp`

There is **no** `/mcp/sse` on either stack.

## 🎯 Example Questions

```
"I have understeer in slow corners"
"Analyze my tyre degradation"
"What's my optimal pit window?"
"Give me a balanced setup for this track"
"Where am I losing time to P1?"
```

## 🤖 AI Client Config

### ChatGPT Desktop (SSE → PNG through nginx)
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

## 🔧 Commands

```bash
# Start
./start-mcp.sh

# Stop  
./stop-mcp.sh

# Logs
docker compose -f docker-compose.mcp.yml logs -f

# Restart
./stop-mcp.sh && ./start-mcp.sh

# Status
curl -sk https://localhost:9443/health
```

## 🐛 Troubleshooting

### MCP Not Responding
```bash
docker compose -f docker-compose.mcp.yml logs -f mcp-server
```

### No AI Responses
1. Check `.env.mcp` has `LLM_API_KEY`
2. Verify API credits
3. Check server logs

### No Telemetry
1. Start Pits N Giggles: `./start.sh`
2. Start F1 game
3. Test: `curl http://localhost:4768/race-info`

## 💰 Costs

| Model | Cost/Question | $5 Gets You |
|-------|---------------|-------------|
| GPT-4o-mini | $0.001 | ~5,000 questions |
| Claude 3.5 | $0.03 | ~166 questions |
| GPT-4 | $0.05 | ~100 questions |

## 🎤 Voice Mode (Optional)

```javascript
// In browser console
switchAIMode("mcp_chat")
```

Then use 🎤 button for push-to-talk.

## 📊 AI Modes

```javascript
// Full AI Engineer (default)
switchAIMode("mcp_chat")

// Telemetry only
switchAIMode("mcp")

// Direct OpenAI
switchAIMode("openai")
```

## 🏁 Setup Knowledge Reference

### Understeer (Front-Limited)
- Front Wing: +1 to +2
- Front ARB: -2
- Brake Bias: +1-2%
- Off-throttle Diff: -5%

### Oversteer (Rear-Limited)  
- Rear Wing: +1 to +2
- Rear ARB: -2
- On-throttle Diff: +5-10%
- Rear Suspension: +1

### Lack of Rotation
- Rear ARB: -2
- Off-throttle Diff: -10%
- Brake Bias: +2%
- Front Wing: +1

### Unstable on Power
- On-throttle Diff: +10%
- Rear Wing: +2
- Rear Suspension: +1

## 📚 Documentation

- **Quick Start**: `docs/mcp/MCP_QUICKSTART.md`
- **Voice**: `docs/mcp/VOICE_INTEGRATION.md`
- **AI Clients**: `docs/mcp/AI_CLIENT_SETUP.md`
- **Docker**: `docs/mcp/DOCKER_MCP_TOOLKIT.md`
- **Full README**: `MCP_README.md`

## 🔗 Links

- Issues: https://github.com/kmransom56/pitsngiggles-mcp-integration/issues
- Docs: `docs/mcp/`
- Main Repo: https://github.com/ashwin-nat/pits-n-giggles

## ⚙️ Environment Variables

```bash
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-YOUR_KEY_HERE
LLM_MODEL=openai/gpt-4o-mini
HTTP_PORT=9080
HTTPS_PORT=9443
MCP_PORT=8765
```

## 🧪 Test Connection

```bash
curl -sk https://localhost:9443/health

curl -sk -X POST https://localhost:9443/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my lap time?"}'
```

## 📞 Support

- Check logs first: `docker compose -f docker-compose.mcp.yml logs -f`
- GitHub Issues for bugs
- Documentation in `docs/mcp/`
- Quick Start guide for common issues

---

**Keep this card handy while racing! 🏎️**
