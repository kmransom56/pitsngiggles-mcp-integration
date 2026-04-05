# 🏎️ Pits N Giggles F1 AI Race Engineer - Quick Reference

## 🚀 Start Application
```bash
./start-auto.sh    # Automated (recommended)
./start.sh         # Interactive with options
```

## 📍 URLs
| Page | URL |
|------|-----|
| **Voice Engineer** | `http://localhost:4768/voice-strategy-center` |
| Strategy Center | `http://localhost:4768/strategy-center` |
| Engineer View | `http://localhost:4768/eng-view` |
| Driver View | `http://localhost:4768/` |

## 🎙️ Voice Commands
Press **Space** → Speak → Release

### Example Questions
- *"Why am I getting understeer?"*
- *"When should I pit?"*
- *"How can I improve my lap time?"*
- *"What's my tyre wear?"*
- *"Should I change my setup?"*

## 🔧 F1 Setup Cheat Sheet

### Understeer (Car won't turn)
```
✅ Front Wing:    +1 click
✅ Front ARB:     -2 clicks (softer)
✅ Brake Bias:    56-57% (forward)
✅ Off-Throttle Diff: -5% (lower)
```

### Oversteer (Rear slides out)
```
✅ Rear Wing:     +1 click
✅ Rear ARB:      +1 click (stiffer)
✅ Brake Bias:    54-55% (rearward)
✅ On-Throttle Diff: -5% (lower)
```

### Tyre Temperature Issues
```
Front too hot:   Reduce front wing
Rear too hot:    Increase rear ARB
Uneven temps:    Adjust camber/toe
All too hot:     Reduce ride height
```

## 🎮 F1 Game Setup
```
Settings → Telemetry Settings:
  UDP Telemetry:  ON
  IP Address:     127.0.0.1
  Port:          20777
  Format:        2021 or later
```

## 🛑 Stop Application
```bash
./stop.sh
# OR
pkill -f "python.*apps.backend"
```

## 🔍 Troubleshooting

### No telemetry data?
1. Check F1 game UDP settings
2. Verify game is in active session
3. Restart game if needed

### Backend won't start?
```bash
pkill -f "python.*apps.backend"
./start-auto.sh
```

### Voice not working?
- Use Chrome/Edge browser
- Allow microphone permissions
- Use HTTPS or localhost only

## 💡 Tips

### Switch AI Mode
Open browser console (F12):
```javascript
switchAIMode("mcp_chat")  // Full AI engineer
switchAIMode("mcp")       // Telemetry only
switchAIMode("openai")    // OpenAI direct
```

### Quick Queries
- Type `setup` for full setup analysis
- Type `tyres` for tyre strategy
- Type `fuel` for consumption analysis
- Type `fastest` for lap time breakdown

## 📊 AI Response Times
- **Telemetry Query:** < 100ms
- **Setup Analysis:** < 500ms
- **With LLM:** 1-3 seconds
- **Voice Round-trip:** < 2 seconds

## 🐋 Docker Quick Start
```bash
# Complete stack
docker-compose -f docker-compose.complete.yml up -d

# Stop
docker-compose -f docker-compose.complete.yml down
```

## 📚 Documentation
- Full Guide: `DEPLOYMENT_FINAL.md`
- Voice Setup: `docs/VOICE_INTEGRATION.md`
- F1 Agent: `docs/F1_RACE_ENGINEER_AGENT.md`
- 5-Min Guide: `docs/QUICKSTART_5MIN.md`

## 🔗 Links
- **GitHub:** https://github.com/kmransom56/pitsngiggles-mcp-integration
- **Original:** https://github.com/ashwin-nat/pits-n-giggles
- **Blog:** https://www.pitsngiggles.com/blog/

---

**Status:** ✅ Production Ready | **Version:** 1.0.0 | **Updated:** April 2026
