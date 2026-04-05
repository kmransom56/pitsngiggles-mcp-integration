# 🏎️ F1 Race Engineer - Quick Reference Card

## ⚡ Quick Start

```bash
./start.sh                                    # Start everything
open http://localhost:4768/voice-strategy-center    # Open voice UI
```

## 🎙️ Voice Commands

**Hold Space** and say:
- *"Why am I getting understeer?"*
- *"When should I pit?"*
- *"Analyze my last lap"*
- *"Compare my sector times"*
- *"Recommend setup changes"*

## 🔧 Setup Recommendations Cheat Sheet

### Understeer (Front losing grip)
- ✅ Increase front wing (+1-2 clicks)
- ✅ Reduce front ARB (-1 click)
- ✅ Increase front tyre pressure (+0.2 PSI)
- ✅ Move brake bias forward (+2%)

### Oversteer (Rear losing grip)
- ✅ Increase rear wing (+1-2 clicks)
- ✅ Reduce rear ARB (-1 click)
- ✅ Reduce rear tyre pressure (-0.2 PSI)
- ✅ Move brake bias rearward (-2%)

### More Entry Rotation
- ✅ Lower off-throttle differential (-5%)
- ✅ Move brake bias forward (+2%)

### More Exit Traction
- ✅ Lower on-throttle differential (-5%)
- ✅ Reduce rear wing (-1 click)

## 📍 Access Points

| Service | URL |
|---------|-----|
| Voice Strategy | `http://localhost:4768/voice-strategy-center` ⭐ |
| Text Strategy | `http://localhost:4768/strategy-center` |
| Engineer View | `http://localhost:4768/eng-view` |
| Driver View | `http://localhost:4768/` |
| MCP API | `http://localhost:80/api/chat` |
| Health Check | `http://localhost:80/health` |

## 🐳 Docker Commands

```bash
# Start all services
docker-compose -f docker-compose.complete.yml up -d

# View logs
docker-compose -f docker-compose.complete.yml logs -f

# Stop services
docker-compose -f docker-compose.complete.yml down

# Restart services
docker-compose -f docker-compose.complete.yml restart

# Check status
docker-compose -f docker-compose.complete.yml ps
```

## 🧪 Testing

```bash
./test-integration.sh                   # Run all tests
curl http://localhost:4768/health       # Test backend
curl http://localhost:80/health         # Test MCP
```

## 🔑 Configuration

Edit `.env.mcp`:
```bash
LLM_API_KEY=sk-or-v1-your-key-here     # Get from openrouter.ai
LLM_MODEL=openai/gpt-4o-mini           # Change model
LOG_LEVEL=INFO                          # DEBUG for verbose
```

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| No telemetry | Check F1 UDP settings: 127.0.0.1:20777 |
| MCP won't start | Check port 8765: `lsof -i :8765` |
| Voice not working | Use Chrome/Edge, allow microphone |
| Docker issues | `docker-compose down && docker-compose up -d` |

## 📚 Documentation

| Guide | Location |
|-------|----------|
| Quick Start | `docs/QUICKSTART_5MIN.md` |
| Complete Guide | `docs/COMPLETE_F1_AGENT_GUIDE.md` |
| Voice Features | `docs/VOICE_INTEGRATION.md` |
| AI Clients | `docs/AI_CLIENT_SETUP.md` |

## 🎮 F1 Game Setup

1. Settings → Telemetry Settings
2. UDP Telemetry: **ON**
3. UDP Port: **20777**
4. UDP IP: **127.0.0.1**

## 🤖 AI Client Setup

### ChatGPT Desktop
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

### Claude Desktop
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

## 📊 Typical AI Conversation

**You**: *"I'm 0.5 seconds slower in Sector 2"*

**Engineer**: 
```
Looking at your Sector 2 telemetry:
- Tyre temps: Front 12°C cooler than rear
- Apex speed: 3 km/h slower than optimal

Recommendations:
1. Increase front wing +2 clicks
2. Reduce front ARB -1 click  
3. Trail brake deeper into Turn 5

This should gain you 0.3s in Sector 2.
```

## 💡 Pro Tips

1. **Start with Voice**: It's the most natural interface
2. **No API Key OK**: Agent works great without it
3. **Ask Specific**: "Turn 3 understeer" > "My car is slow"
4. **Use Real-Time**: Ask during practice, apply in qualifying
5. **Test Changes**: Make one adjustment at a time

## 🎯 Common Questions

**Q: Do I need an API key?**  
A: No! Agent works with intelligent fallback responses.

**Q: Which browser?**  
A: Chrome or Edge for best voice support.

**Q: Does it work offline?**  
A: Yes, without LLM. With LLM needs internet.

**Q: Can I customize responses?**  
A: Yes! Edit `mcp_server/server.py`

**Q: Production ready?**  
A: Yes! Just add real SSL certificate.

## 🏁 Remember

- **Hold Space** to talk
- **Release** to send
- **Listen** for AI response
- **Apply** recommendations
- **Repeat** until fast!

---

**Happy Racing! 🏎️💨**
