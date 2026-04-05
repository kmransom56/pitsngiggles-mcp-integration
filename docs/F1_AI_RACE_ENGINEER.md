# F1 AI Race Engineer - Complete Integration Guide

## 🎯 Overview

The **F1 AI Race Engineer** is now fully integrated into Pits n' Giggles, providing intelligent race engineering analysis with voice capabilities. This system combines real-time F1 telemetry with AI-powered insights to help you optimize car setup, strategy, and lap times.

## ✨ Features

### 🏎️ Core Capabilities
- **Real-time Telemetry Analysis** - Analyzes live F1 23/24/25 game data
- **Intelligent Setup Recommendations** - Provides specific car setup changes with exact values
- **Tyre Strategy Optimization** - Suggests optimal pit windows and compound choices
- **Lap Time Analysis** - Identifies performance bottlenecks by sector
- **Handling Diagnostics** - Troubleshoots understeer, oversteer, and balance issues

### 🎙️ Voice Features
- **Speech-to-Text (STT)** - Speak your questions naturally
- **Text-to-Speech (TTS)** - Hear AI responses like a real race engineer
- **Push-to-Talk (PTT)** - Button or spacebar activation
- **Zero Cost** - All processing happens in your browser
- **Privacy-First** - No data leaves your computer

### 🤖 AI Integration Options
- **Built-in Race Engineer** - Powered by integrated MCP server (no API keys needed)
- **OpenAI Integration** - Connect your own GPT-4 API key for advanced reasoning
- **Claude Integration** - Use Claude via MCP for detailed analysis
- **Custom AI** - Configure any AI client that supports MCP protocol

## 🚀 Quick Start

### 1. Start the Application

```bash
./start.sh
```

When prompted:
- **Answer "y"** to start the MCP server (enables AI features)
- **Answer "n"** to run without AI (traditional telemetry only)

### 2. Access Strategy Center

Open one of these URLs in your browser:

- **Text Chat Mode:** `http://localhost:4768/strategy-center`
- **Voice Mode:** `http://localhost:4768/voice-strategy-center`

### 3. Start F1 Game

Launch F1 23, F1 24, or F1 25 and start a session. The AI will automatically receive telemetry data.

## 📱 Using the Strategy Center

### Chat Interface

The Strategy Center embeds your telemetry view with an AI chat sidebar:

**Quick Actions (Pre-configured questions):**
- "What are the current race conditions?"
- "I have understeer in slow corners, what should I change?"
- "Analyze my tyre degradation and suggest pit window"
- "Compare my lap times to P1 and tell me where I'm losing time"
- "Give me a balanced setup for this track"

**Or ask anything:**
- "Why am I losing time in Sector 2?"
- "Should I pit now or wait?"
- "How do I fix oversteer on exit?"

### Voice Mode

1. Click **🎙️ Voice Mode** button
2. **Press and hold** microphone button (or spacebar)
3. **Speak** your question
4. **Release** to send
5. **Listen** to the AI response

**Voice Settings:**
- Click ⚙️ to customize voice, speed, and pitch
- Test different voices to find your preferred race engineer

## 🔧 Race Engineer Expertise

### Setup Recommendations

The AI provides specific, actionable setup changes:

**Example - Understeer:**
```
🔧 UNDERSTEER DIAGNOSIS

Recommended Changes:
1. Front Wing: Increase angle by +1 click
2. Front ARB: Reduce stiffness by -2 clicks  
3. Brake Bias: Move forward to 56-57%
4. Off-Throttle Diff: Reduce to 55%

Expected Impact:
Sharper turn-in with reduced push in slow corners.
May slightly increase front tyre degradation.

Validation: Focus on corner entry feel on next run.
```

### Setup Knowledge Base

The AI understands:

**Aerodynamics:**
- Front Wing: Higher = more front grip, better turn-in
- Rear Wing: Higher = more stability, less top speed

**Differential:**
- On-Throttle: 50-60% = rotation, 70-80% = stability
- Off-Throttle: Lower = better turn-in, Higher = entry stability

**Suspension:**
- Front ARB: Stiffer = less understeer (high-speed corners)
- Rear ARB: Stiffer = less oversteer (exit traction)
- Ride Height: Lower front = aero, Lower rear = mechanical grip

**Brakes:**
- Forward Bias (56-58%): Front bite, less oversteer
- Rear Bias (52-54%): Better rotation, more entry oversteer

## 🛠️ Configuration

### AI Mode Selection

Edit `strategy-center.html` or use localStorage:

```javascript
// In browser console:

// Use built-in MCP chat (default, recommended)
localStorage.setItem('ai_mode', 'mcp_chat');

// Use OpenAI API
localStorage.setItem('ai_mode', 'openai');
localStorage.setItem('openai_api_key', 'sk-...');

// Use raw MCP tools (advanced)
localStorage.setItem('ai_mode', 'mcp');
```

### MCP Endpoints

The MCP server exposes these endpoints:

- **Chat API:** `POST /api/chat` - Intelligent race engineer chat
- **MCP Tools:** `POST /mcp/tools` - Raw MCP tool invocation
- **SSE Stream:** `GET /mcp` - Server-Sent Events for AI clients

### Connect External AI Clients

See `docs/AI_CLIENT_SETUP.md` for detailed instructions on connecting:
- ChatGPT Desktop App
- Claude Desktop
- Cursor AI
- Continue.dev
- Cody by Sourcegraph

## 📊 Example Conversations

### Setup Tuning
```
You: I'm getting understeer mid-corner at high speed

AI: 🔧 HIGH-SPEED UNDERSTEER

Diagnosis: Insufficient front-end load in medium-high speed corners
Root Cause: Front aero or front ARB too soft

Recommendations:
1. Front Wing: +2 clicks (increase downforce)
2. Front ARB: +2 clicks (stiffer for high-speed)
3. Front Ride Height: -1mm (improve aero platform)

Expected Impact: Sharper response in fast corners, slightly reduced top speed
Next Steps: Test on high-speed section, monitor front tyre temps
```

### Tyre Strategy
```
You: When should I pit? Currently on mediums, lap 14

AI: 📊 TYRE STRATEGY ANALYSIS

Current: Lap 14, Medium compound
Wear Rate: ~2.5% per lap (estimated)
Optimal Window: Lap 18-22

Recommendations:
- Continue current stint to lap 18 minimum
- Monitor degradation - if >60% wear, pit immediately
- Undercut window: Lap 17-18 if P1 boxes
- Weather: No rain forecast, dry strategy holds

Next Tyre: Hard (0.3s/lap slower but +10 laps life)
```

### Performance Analysis
```
You: Where am I losing time?

AI: ⏱️ SECTOR ANALYSIS

Biggest Time Loss: Sector 2 (-0.45s vs P1)

Focus Areas:
1. Turn 7-8 Complex: Late braking, earlier throttle application
2. Turn 11 Exit: Smooth throttle, maximize exit speed
3. Gear Selection: Consider higher gear through Turn 9

Data:
- Sector 1: -0.05s (competitive)
- Sector 2: -0.45s (major loss)
- Sector 3: -0.10s (minor loss)

Setup consideration: More rear grip for Turn 11 exit traction
```

## 🎯 Advanced Features

### Context-Aware Analysis

The AI receives full telemetry context:
- Current lap and sector
- Tyre temperatures and wear
- Fuel remaining
- Track conditions
- Session type (Practice, Qualifying, Race)
- Your position and gaps

### Intelligent Response Generation

The AI routes questions to specialized handlers:
- Understeer/Oversteer → Setup diagnostics
- Tyre/Tire → Strategy analysis
- Lap/Sector/Time → Performance focus
- Fuel → Consumption management
- Pit/Strategy → Race tactics

### Fallback Responses

If AI connection fails, the system provides intelligent fallback responses based on:
- Telemetry analysis (automated issue detection)
- Common setup solutions (knowledge base)
- Best practices (racing fundamentals)

## 🐳 Docker Deployment

For production or shared environments:

```bash
# Build and run
docker-compose up -d

# Or use complete stack
docker-compose -f docker-compose.complete.yml up -d
```

See `docs/DOCKER_DEPLOYMENT.md` for details.

## 📝 Contributing

Want to improve the F1 AI Race Engineer?

1. **Enhance Setup Knowledge** - Add more setup scenarios in `lib/mcp_server/server.py`
2. **Improve Responses** - Refine response templates for better clarity
3. **Add Features** - Implement new analysis types (brake temps, aero balance, etc.)
4. **Test & Report** - Use it and report issues or suggestions

## 🔗 Related Documentation

- **[MCP Integration](MCP_INTEGRATION.md)** - Technical MCP protocol details
- **[AI Client Setup](AI_CLIENT_SETUP.md)** - Connect external AI tools
- **[Voice Integration](VOICE_INTEGRATION.md)** - Voice feature details
- **[Strategy Center](STRATEGY_CENTER.md)** - UI and features guide
- **[F1 Agent Prompt](F1_RACE_ENGINEER_AGENT.md)** - AI system prompt

## 💡 Tips & Best Practices

### Getting the Best Answers

✅ **Do:**
- Be specific: "understeer in Turn 3 entry"
- Provide context: "on lap 15, medium tyres, 40% wear"
- Ask for explanations: "why does front wing affect turn-in?"

❌ **Don't:**
- Be vague: "car feels bad"
- Ask multiple unrelated questions at once
- Expect telepathy without telemetry data

### Voice Mode Optimization

- Use a **quiet environment** for better speech recognition
- Speak **clearly and naturally** - no need to be robotic
- **Short questions** work best: "How do I fix oversteer?"
- Use **Push-to-Talk** to avoid background noise

### Performance Tips

- Keep **one Strategy Center tab** open (multiple tabs = multiple connections)
- Use **built-in MCP chat** for best performance (no API latency)
- **Voice mode** uses more browser resources - disable if not needed

## 🆘 Troubleshooting

**AI Not Responding:**
1. Check MCP server is running (green dot in Strategy Center)
2. Verify F1 game is sending telemetry
3. Look at browser console for errors (F12)
4. Restart MCP server: `./stop.sh && ./start.sh`

**Voice Not Working:**
1. Grant microphone permissions in browser
2. Check browser supports Web Speech API (Chrome/Edge recommended)
3. Test with system microphone settings
4. Try different voice in settings (some voices fail to load)

**Setup Not Improving Lap Times:**
1. Make one change at a time
2. Test for 2-3 laps minimum
3. Check track conditions haven't changed
4. Validate the AI understood your issue correctly
5. Some changes trade performance for consistency

## 📈 Roadmap

Future enhancements planned:
- [ ] Multi-language support (Spanish, Portuguese, Italian, French)
- [ ] Advanced telemetry visualization in chat
- [ ] Setup presets library by track
- [ ] Race strategy simulator
- [ ] Session summary reports
- [ ] Integration with OpenF1 live timing data

---

## 🏁 Ready to Race!

You now have a professional F1 race engineer at your fingertips. Whether you're chasing pole position, managing a race stint, or learning car setup, the AI is here to help you go faster.

**Quick access:**
- Text Chat: http://localhost:4768/strategy-center
- Voice Mode: http://localhost:4768/voice-strategy-center

Good luck on track! 🏆
