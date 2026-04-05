# F1 Race Engineer MCP - Quick Start Guide

Get up and running with the F1 Race Engineer MCP server in under 5 minutes.

## Prerequisites

- Docker and Docker Compose installed
- Pits N Giggles installed (or running)
- LLM API key (OpenRouter, OpenAI, or Anthropic)

## Quick Start

### 1. Clone and Configure

```bash
cd /path/to/pits-n-giggles
cp .env.mcp.example .env.mcp
```

### 2. Get an API Key

**Option A: OpenRouter (Recommended - access to multiple models)**
1. Visit https://openrouter.ai/keys
2. Create an account and generate an API key
3. Add credits ($5 recommended)

**Option B: OpenAI**
1. Visit https://platform.openai.com/api-keys
2. Generate an API key

**Option C: Anthropic**
1. Visit https://console.anthropic.com/
2. Generate an API key
3. Use via OpenRouter

### 3. Configure `.env.mcp`

Edit `.env.mcp` and add your API key:

```bash
# For OpenRouter (recommended)
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=sk-or-v1-YOUR_KEY_HERE
LLM_MODEL=openai/gpt-4o-mini

# Or for OpenAI direct
# LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
# LLM_API_KEY=sk-YOUR_OPENAI_KEY
# LLM_MODEL=gpt-4o-mini
```

### 4. Start the MCP Server

```bash
./start-mcp.sh
```

This will:
- Generate SSL certificates (self-signed for development)
- Start the MCP server
- Start nginx reverse proxy
- Display access URLs

### 5. Start Pits N Giggles

In a separate terminal:

```bash
./start.sh
```

### 6. Access Strategy Center

Open your browser to:
- **Strategy Center**: http://localhost/eng-view.html
- Or navigate to the Strategy Center tab in the UI

### 7. Test the AI Engineer

Try asking:
- "I have understeer in slow corners, what should I change?"
- "Analyze my tyre degradation"
- "Give me a balanced setup for this track"

## Access Points

| Service | URL | Description |
|---------|-----|-------------|
| Pits N Giggles | http://localhost:4768 | Main telemetry server |
| Strategy Center | http://localhost/strategy-center.html | AI race engineer UI |
| MCP Chat API | http://localhost/api/chat | Chat endpoint |
| MCP Server | http://localhost:8765 | Direct MCP access |
| Health Check | http://localhost/health | Server status |

## AI Client Integration

### ChatGPT Desktop

Add to MCP settings (`~/Library/Application Support/ChatGPT/config.json`):

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse"
    }
  }
}
```

### Claude Desktop

Add to config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse"
    }
  }
}
```

### Cursor IDE

Add to `.cursorrules` in your project:

```
Use the f1-race-engineer MCP server for F1 telemetry analysis.
Endpoint: http://localhost/mcp/sse
```

## Switching AI Modes

The Strategy Center supports three modes:

```javascript
// In browser console:

// Full AI race engineer (default)
switchAIMode("mcp_chat")

// Telemetry data only
switchAIMode("mcp")

// Direct OpenAI integration
switchAIMode("openai")
```

## Troubleshooting

### MCP Server Not Responding

```bash
# Check logs
docker-compose -f docker-compose.mcp.yml logs -f mcp-server

# Restart
./stop-mcp.sh && ./start-mcp.sh
```

### No AI Responses

1. Check your API key is set in `.env.mcp`
2. Verify you have API credits
3. Check MCP server logs for errors

### Telemetry Not Available

1. Ensure Pits N Giggles is running: `./start.sh`
2. Start F1 23/24/25 and begin a session
3. Check telemetry is being received at http://localhost:4768

### Port Conflicts

Edit `.env.mcp` to change ports:

```bash
HTTP_PORT=8080
HTTPS_PORT=8443
MCP_PORT=8765
```

## Stopping the Server

```bash
./stop-mcp.sh
```

## Next Steps

- [Voice Integration](docs/mcp/VOICE_INTEGRATION.md) - Add speech-to-text
- [AI Client Setup](docs/mcp/AI_CLIENT_SETUP.md) - Detailed AI client configuration
- [Docker Toolkit](docs/mcp/DOCKER_MCP_TOOLKIT.md) - Add to Docker's MCP Toolkit

## Cost Estimates

Using OpenRouter with GPT-4o-mini:
- ~$0.01 per 10 questions
- $5 credit = ~5,000 questions
- Recommended for most users

Using GPT-4:
- ~$0.05 per question
- More expensive but higher quality

Using Claude 3.5 Sonnet:
- ~$0.03 per question
- Excellent for race engineering analysis

## Support

- GitHub Issues: https://github.com/kmransom56/pitsngiggles-mcp-integration/issues
- Pits N Giggles Discord: Check main repo
- Documentation: docs/mcp/

---

**Enjoy your AI race engineer! 🏎️**
