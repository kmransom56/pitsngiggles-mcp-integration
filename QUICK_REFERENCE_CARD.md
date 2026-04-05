# F1 AI Race Engineer - Quick Reference Card

## 🚀 Start Application

```bash
./start.sh  # Answer 'y' to enable MCP server
```

## 🌐 Access Points

| Feature | URL |
|---------|-----|
| Voice Strategy Center | http://localhost:4768/voice-strategy-center |
| Text Chat Center | http://localhost:4768/strategy-center |
| Engineering View | http://localhost:4768/eng-view |
| Driver View | http://localhost:4768/ |

## 🎙️ Voice Commands

**Activation:** Press & hold **Space** or microphone button

**Example Questions:**
- *"I have understeer in Turn 3, what should I change?"*
- *"When should I pit?"*
- *"Why am I losing time in Sector 2?"*
- *"Give me a balanced setup for this track"*
- *"How do I fix oversteer on exit?"*

## 🔧 Common Setup Fixes

### Understeer (Front pushes wide)
```
Front Wing: +1-2 clicks
Front ARB: -2 clicks  
Brake Bias: +1-2% forward
Off-Throttle Diff: -5%
```

### Oversteer (Rear slides out)
```
Rear Wing: +1-2 clicks
On-Throttle Diff: +5-10%
Rear ARB: -2 clicks
Rear Suspension: +1 click
```

### No Rotation (Can't turn in)
```
Front Wing: +1 click
Rear ARB: -2 clicks
Brake Bias: +2% forward
Off-Throttle Diff: -10%
```

### Unstable on Power
```
On-Throttle Diff: +10%
Rear Wing: +2 clicks
Rear Suspension: +1 click
Rear Tyre Pressure: -0.1 PSI
```

## 🛞 Tyre Strategy

### Compound Characteristics
| Compound | Life | Delta to Soft | Usage |
|----------|------|---------------|-------|
| Soft | 8-12 laps | 0.0s | Qualifying, Sprint |
| Medium | 15-20 laps | +0.5-0.8s | Race balance |
| Hard | 25+ laps | +0.8-1.2s | Long stints |

### Pit Windows
- **Undercut:** Pit 1-2 laps before competitor
- **Optimal:** When wear >60% or temps unstable
- **Emergency:** When wear >85% or significant time loss

## ⛽ Fuel Management

**Target Buffer:** 0.3-0.5 laps at race end
**Consumption:** ~1.6-1.8 kg/lap
**Fuel Saving:** Lift & coast in Sector 3 = ~0.1 kg/lap saved

## 📊 Key Metrics

### Tyre Temperature (Optimal: 85-95°C)
- Too Cold (<80°C): Reduce tyre pressure 0.1-0.2 PSI
- Too Hot (>100°C): Increase pressure 0.1-0.2 PSI

### Tyre Wear
- <30%: Fresh, full performance
- 30-50%: Slight deg, manageable
- 50-70%: Notable deg, consider pit
- >70%: Significant loss, pit ASAP

### Brake Temperature
- Optimal: 500-700°C
- Too Hot: Reduce brake pressure, earlier braking
- Too Cold: Increase brake pressure, later braking

## 🎯 Lap Time Analysis

### Focus Areas (Priority Order)
1. **Corner Exit Speed** - Biggest impact on next straight
2. **Braking Points** - Gain 0.1-0.3s per heavy zone
3. **Apex Speed** - Minimum speed in corner
4. **Racing Line** - Optimize geometric line

### Sector Consistency
- **±0.3s:** Excellent consistency
- **±0.5s:** Good consistency
- **>1.0s:** Work on consistency first, then speed

## 🤖 AI Integration

### Chat Modes

**Built-in MCP (Default - Recommended):**
```javascript
localStorage.setItem('ai_mode', 'mcp_chat');
```

**OpenAI API:**
```javascript
localStorage.setItem('ai_mode', 'openai');
localStorage.setItem('openai_api_key', 'sk-...');
```

**Raw MCP Tools (Advanced):**
```javascript
localStorage.setItem('ai_mode', 'mcp');
```

### External AI Clients

**Connect ChatGPT/Claude:**
1. MCP Endpoint: `http://localhost:4768/mcp`
2. Use system prompt from `docs/F1_RACE_ENGINEER_AGENT.md`
3. Enable MCP in AI client settings

## 🔍 Troubleshooting

### AI Not Responding
```bash
# Restart MCP server
./stop.sh && ./start.sh
```

### Voice Not Working
1. Grant microphone permission in browser
2. Use Chrome/Edge (best compatibility)
3. Check system microphone settings
4. Try different voice in ⚙️ settings

### Telemetry Not Updating
1. Verify F1 game settings: UDP 20777, IP 127.0.0.1
2. Start a session in F1 game
3. Check browser console (F12) for errors
4. Restart application if needed

### Performance Issues
- Close other browser tabs
- Disable voice mode if not needed
- Check CPU usage (F1 game + app)

## 📚 Documentation

| Topic | File |
|-------|------|
| Complete Guide | docs/F1_AI_RACE_ENGINEER.md |
| Voice Features | docs/VOICE_INTEGRATION.md |
| AI Client Setup | docs/AI_CLIENT_SETUP.md |
| MCP Integration | docs/MCP_INTEGRATION.md |
| Docker Deployment | docs/DOCKER_DEPLOYMENT.md |

## 💡 Pro Tips

### Getting Best Results
- ✅ Be specific: "understeer in Turn 3 entry"  
- ✅ Provide context: "lap 15, medium tyres, 40% wear"
- ✅ One change at a time (test 2-3 laps)
- ✅ Keep notes on what works

### Voice Optimization
- 🎤 Quiet environment
- 🎤 Clear, natural speech
- 🎤 Short questions work best
- 🎤 Use Push-to-Talk mode

### Setup Philosophy
1. Start with baseline
2. Identify main issue
3. Make small change (1-2 clicks)
4. Test for 2-3 laps
5. Validate improvement
6. Repeat if needed

## 🏁 Common Scenarios

### Qualifying Setup
```
Focus: Peak downforce, maximum grip
Aero: High front + high rear
Fuel: Minimum (1-2 laps)
Tyres: Soft compound, optimal temp
```

### Race Setup  
```
Focus: Consistency, tyre life
Aero: Balanced (slightly lower rear)
Fuel: Full race distance + buffer
Tyres: Medium/Hard compounds
```

### Wet Weather
```
Focus: Stability, avoid aquaplaning
Aero: Higher values for downforce
Brake Bias: Rearward (52-53%)
Diff: Higher values for stability
```

---

## 🆘 Emergency Contacts

**GitHub:** https://github.com/kmransom56/pitsngiggles-mcp-integration
**Issues:** https://github.com/kmransom56/pitsngiggles-mcp-integration/issues
**Original Project:** https://github.com/ashwin-nat/pits-n-giggles

---

*Keep this card handy during race sessions for quick reference!* 🏆
