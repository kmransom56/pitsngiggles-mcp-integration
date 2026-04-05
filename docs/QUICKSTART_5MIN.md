# 🚀 F1 Race Engineer - 5 Minute Quickstart

Get your AI Race Engineer running in 5 minutes!

## Prerequisites

- F1 23, F1 24, or F1 25 game
- Docker + Docker Compose (OR Python 3.12+)

## Option 1: Docker (Easiest) ⭐

```bash
# 1. Clone repository
git clone https://github.com/ashwin-nat/pits-n-giggles.git
cd pits-n-giggles

# 2. Start everything
docker-compose -f docker-compose.complete.yml up -d

# 3. Open your browser
open http://localhost:4768/voice-strategy-center
```

**That's it!** The AI Race Engineer is running.

## Option 2: Quick Start Script

```bash
# 1. Clone repository  
git clone https://github.com/ashwin-nat/pits-n-giggles.git
cd pits-n-giggles

# 2. Run start script
./start.sh

# 3. Follow prompts
# - Press 'y' to start MCP server
# - Skip API key for now (optional)
# - Choose Docker or native mode
```

## 🎮 F1 Game Setup

1. **Launch F1 23/24/25**

2. **Enable UDP Telemetry**:
   - Go to: Settings → Telemetry Settings
   - UDP Telemetry: **ON**
   - UDP Port: **20777**
   - UDP IP Address: **127.0.0.1** (localhost)

3. **Start a Session** (Practice, Qualifying, or Race)

## 🎯 Using Your AI Race Engineer

### Text Chat

1. Open: `http://localhost:4768/strategy-center`
2. Type questions like:
   - *"Why am I getting understeer?"*
   - *"When should I pit?"*
   - *"Analyze my last lap"*

### Voice Chat (Recommended!)

1. Open: `http://localhost:4768/voice-strategy-center`
2. Click **"🎙️ Voice Mode"** toggle
3. **Hold Space key** and speak: *"Analyze my lap times"*
4. Release Space to send
5. **Hear AI response** automatically!

## 🤖 Advanced: AI Client Integration

### ChatGPT Desktop

Add to ChatGPT config:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "command": "npx",
      "args": ["-y", "sse-mcp-client", "http://localhost:80/mcp/sse"]
    }
  }
}
```

Then ask ChatGPT: *"Analyze my F1 telemetry"*

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

## 🎙️ Voice Commands Examples

- *"What's my current lap time?"*
- *"Compare my last two laps"*
- *"Why am I slower in sector 2?"*
- *"Recommend setup changes for understeer"*
- *"Show me tire degradation"*
- *"When should I box?"*
- *"Analyze my braking points"*
- *"Give me fuel saving tips"*

## 🔧 Add Your AI API Key (Optional)

For smarter AI responses:

1. Get API key from [OpenRouter](https://openrouter.ai/keys) (free tier available)

2. Edit `.env.mcp`:
   ```bash
   LLM_API_KEY=sk-or-v1-your-key-here
   ```

3. Restart:
   ```bash
   docker-compose -f docker-compose.complete.yml restart
   # OR
   ./stop.sh && ./start.sh
   ```

## 📊 What You Get

### Without API Key (Free Forever)
- ✅ Real-time telemetry display
- ✅ Basic setup recommendations
- ✅ Handling diagnostics (understeer/oversteer)
- ✅ Tyre & fuel analysis
- ✅ Voice input/output
- ✅ Canned expert responses

### With API Key (Enhanced)
- ✅ **Everything above, PLUS:**
- ✅ Conversational AI responses
- ✅ Context-aware recommendations
- ✅ Multi-lap strategy analysis
- ✅ Personalized coaching
- ✅ Natural language understanding

## 🆘 Troubleshooting

### No Telemetry Data?
```bash
# Check F1 game UDP settings (must be 20777)
# Verify game is running and in-session
curl http://localhost:4768/race-info
```

### MCP Server Not Starting?
```bash
# Check if port 8765 is in use
lsof -i :8765

# View logs
docker-compose -f docker-compose.complete.yml logs mcp-server
```

### Voice Not Working?
- **Use Chrome or Edge** (best voice support)
- **Allow microphone access** when prompted
- **Use HTTPS** for production (some browsers require it)

### Quick Reset
```bash
# Stop everything
docker-compose -f docker-compose.complete.yml down

# Remove volumes
docker-compose -f docker-compose.complete.yml down -v

# Start fresh
docker-compose -f docker-compose.complete.yml up -d
```

## 📚 Next Steps

- **Read**: [Complete F1 Agent Guide](COMPLETE_F1_AGENT_GUIDE.md)
- **Configure**: [Voice Integration](VOICE_INTEGRATION.md)
- **Learn**: [F1 Race Engineer Agent](F1_RACE_ENGINEER_AGENT.md)
- **Customize**: [AI Client Setup](AI_CLIENT_SETUP.md)

## 💬 Support

- **Issues**: https://github.com/ashwin-nat/pits-n-giggles/issues
- **Discussions**: https://github.com/ashwin-nat/pits-n-giggles/discussions

---

**🏁 Happy Racing!**
