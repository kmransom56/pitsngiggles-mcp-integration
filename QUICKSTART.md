# 🚀 Quick Start - Pits n' Giggles with F1 Race Engineer

Get up and running with AI-powered race engineering in **under 2 minutes**!

---

## One-Command Startup

### Linux/macOS

```bash
./start.sh
```

That's it! The script will:
1. ✅ Check prerequisites (Python, nginx, Node.js)
2. ✅ Create virtual environment
3. ✅ Install dependencies
4. ✅ Configure nginx reverse proxy (HTTPS)
5. ✅ Start backend with MCP server
6. ✅ Verify all services

### Windows

```cmd
start.bat
```

Double-click `start.bat` or run from command prompt.

---

## What Gets Started

```
╔═════════════════════════════════════════════════╗
║  Service                    │  URL              ║
╠═════════════════════════════╪═══════════════════╣
║  Telemetry Dashboard        │  :4768            ║
║  Engineer View              │  :4768/eng-view   ║
║  F1 Race Engineer (AI)      │  :4768/strategy   ║
║  MCP Server (HTTP)          │  :4768/mcp        ║
║  MCP Server (HTTPS)         │  :8443/mcp        ║
╚═════════════════════════════╧═══════════════════╝
```

---

## First Time Setup (5 minutes)

### Option 1: Built-in Strategy Center (Easiest)

**No external tools needed!**

1. **Start the game**
   ```
   F1 23, F1 24, or F1 25
   Enable UDP telemetry in settings
   ```

2. **Open Strategy Center**
   ```
   http://localhost:4768/strategy-center
   ```

3. **Start asking questions!**
   ```
   "Analyze my current performance"
   "Why am I losing time in sector 2?"
   "Compare my pace to P1"
   ```

**That's it!** The built-in AI uses MCP tools automatically.

---

### Option 2: ChatGPT Desktop (Best Experience)

**For more advanced conversations and context memory.**

1. **Enable Developer Mode**
   - ChatGPT Settings → Personalization
   - Toggle **Developer Mode** ON

2. **Create F1 Race Engineer App**
   - Apps → Create New App
   - **Name:** `F1 Race Engineer`
   - **URL:** `https://localhost:8443/mcp` (or `http://localhost:4768/mcp`)
   - **Transport:** `SSE`

3. **Connect**
   - Click **Connect**
   - Wait for tools to populate (10 tools)

4. **Start Racing!**
   ```
   "What are the current race conditions?"
   "Diagnose why I'm getting slower"
   "Analyze my lap time consistency"
   ```

---

### Option 3: Claude Desktop (Deep Analysis)

**For longest context and best reasoning.**

1. **Edit Config File**
   - **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
   - **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Linux:** `~/.config/Claude/claude_desktop_config.json`

2. **Add MCP Server**
   ```json
   {
     "mcpServers": {
       "pitsngiggles": {
         "command": "npx",
         "args": ["-y", "mcp-remote", "https://localhost:8443/mcp"]
       }
     }
   }
   ```

3. **Restart Claude Desktop**

4. **Verify**
   - Ask: *"List available MCP tools"*
   - Should see 10 Pits n' Giggles tools

---

## Test Your Setup

### 1. Check Services Running

**Linux/macOS:**
```bash
# Check backend
curl http://localhost:4768/race-info

# Check MCP
curl -N http://localhost:4768/mcp
```

**Windows:**
```cmd
REM Open in browser
start http://localhost:4768/race-info
start http://localhost:4768/strategy-center
```

### 2. Test F1 Agent (Built-in)

1. Open: `http://localhost:4768/strategy-center`
2. Click **"Race Status"** quick button
3. Should see: *"F1 Race Engineer online..."*

### 3. Test External AI (ChatGPT/Claude)

Ask any of these:
- *"What are the current race conditions?"*
- *"Analyze my last 5 laps for consistency"*
- *"Compare my pace to the race leader"*
- *"Which sector am I losing the most time?"*

---

## Available F1 Race Engineer Tools

The AI automatically uses these tools based on your questions:

**Basic Telemetry:**
1. `get_race_info` - Session status, weather, track temps
2. `get_telemetry_data` - All drivers data
3. `get_driver_info` - Detailed driver analysis

**Strategy:**
4. `analyze_tyre_strategy` - Compound comparison
5. `get_lap_comparison` - Lap time comparison

**Advanced Analysis:** ⭐
6. `analyze_lap_time_consistency` - Statistical consistency
7. `diagnose_performance_issues` - Detect tyre deg, damage
8. `compare_to_leader` - P1 comparison with deltas
9. `analyze_sector_performance` - Sector breakdown

**Streaming:**
10. `get_stream_overlay_data` - Broadcast data

---

## Example AI Conversations

### Setup Advice

**You:** *"I have understeer in slow corners"*

**F1 Agent:**
```
🔧 SLOW CORNER UNDERSTEER

Diagnosis: Front-end limitation in low-speed corners

Recommendations:
1. Front Wing: +1 - Adds front downforce
2. Front ARB: -2 clicks - More front compliance  
3. Brake Bias: +2% forward - Improves rotation

Expected Impact:
- Sharper turn-in in hairpins
- Better front-end feel through chicanes

Next Steps:
- Run 3 laps, monitor front tyre temps
- Report if high-speed corners feel unstable
```

### Performance Analysis

**You:** *"Why am I losing time?"*

**F1 Agent:**
```
📊 PERFORMANCE ANALYSIS

Lap Consistency: 387ms std deviation (Fair)
Tyre Degradation: 95ms/lap over last 5 laps (High)
Sector 2 Loss: -0.534s vs P1 (67% of total gap)

Root Cause:
Tyre deg is primary issue. Sector 2 (high-speed)
affected most due to reduced mechanical grip.

Recommendations:
1. Pit within next 2 laps
2. If staying out: Reduce brake pressure -2%
3. Lift earlier in S2 fast corners

Expected: Stabilize lap times now, gain 0.5s/lap
after pit stop with fresh tyres.
```

### Strategy Comparison

**You:** *"Compare my tyre strategy to P1"*

**F1 Agent:**
```
🏁 LEADER COMPARISON

Your Position: P5
Gap to P1: +8.234s

Pace Comparison:
• Your best lap: 1:24.567
• P1 best lap: 1:23.956
• Delta: +0.611s

Current Pace:
• Your last lap: 1:25.123
• P1 last lap: 1:24.456
• Delta: +0.667s (degrading)

Tyre Strategy:
• You: Soft, 8 laps old, 18% wear
• P1: Medium, 3 laps old, 8% wear

Analysis: P1 on fresher, harder tyres with better
deg profile. You need to pit soon or accept
increasing pace deficit.
```

---

## Troubleshooting

### "Connection refused" Error

**Problem:** Can't connect to MCP server

**Solutions:**
```bash
# Check if backend is running
curl http://localhost:4768/race-info

# Check logs
tail -f pits-n-giggles.log  # Linux/macOS
type pits-n-giggles.log     # Windows

# Restart
./stop.sh && ./start.sh     # Linux/macOS
stop.bat && start.bat       # Windows
```

### "No tools available" in ChatGPT/Claude

**Problem:** AI client doesn't see MCP tools

**Solutions:**
1. **Verify MCP endpoint works:**
   ```bash
   curl -N http://localhost:4768/mcp
   ```

2. **Check URL in AI client:**
   - ChatGPT: `https://localhost:8443/mcp` or `http://localhost:4768/mcp`
   - Claude: Must use `https://localhost:8443/mcp` with `mcp-remote`

3. **Restart AI client** after configuration

### "SSL Certificate Error"

**Problem:** Browser/AI doesn't trust self-signed cert

**Solutions:**

**Linux/macOS:**
```bash
# Trust the certificate
sudo cp /etc/nginx/ssl/nginx-selfsigned.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**Windows:**
- Double-click certificate file
- Install to "Trusted Root Certification Authorities"

**Or just use HTTP:**
- `http://localhost:4768/mcp` (works without SSL)

### "Port already in use"

**Problem:** Port 4768 or 8443 already taken

**Solutions:**
```bash
# Find what's using the port
lsof -i :4768    # Linux/macOS
netstat -ano | findstr :4768  # Windows

# Kill the process
kill <PID>       # Linux/macOS
taskkill /F /PID <PID>  # Windows
```

---

## Stopping the Server

### Linux/macOS
```bash
./stop.sh
```

### Windows
```cmd
stop.bat
```

Or press **Ctrl+C** in the terminal where it's running.

---

## Configuration Options

### Change Port

Edit `apps/backend/intf_layer/telemetry_web_server.py`:
```python
self.port = 4768  # Change to your preferred port
```

### Enable/Disable MCP Server

In `apps/launcher.py`:
```python
mcp_enabled = True  # Set to False to disable
```

### AI Mode in Strategy Center

In browser console:
```javascript
// Switch to MCP mode (free, no API key)
switchAIMode('mcp')

// Switch to OpenAI mode (requires key)
localStorage.setItem('openai_api_key', 'sk-...')
switchAIMode('openai')
```

---

## Performance Tips

### For Best AI Response Times

1. **Use MCP mode** in Strategy Center (fastest)
2. **Use ChatGPT Desktop** for external tools (good balance)
3. **Use Claude Desktop** for deep analysis (slower but smarter)

### For Lower Resource Usage

1. **Disable nginx** if you don't need HTTPS:
   ```bash
   sudo systemctl stop nginx
   ```
   Use HTTP endpoint: `http://localhost:4768/mcp`

2. **Use only built-in Strategy Center** (no external AI)

### For Multiple Sessions

The MCP server handles multiple AI clients simultaneously:
- ChatGPT Desktop + Strategy Center ✓
- Claude + Cursor IDE ✓
- Multiple browser tabs ✓

---

## What's Next?

### Explore More Features

- **Post-Race Analysis:** Detailed session review tools
- **Custom Overlays:** Streaming integration
- **Replay System:** Review past sessions
- **Setup Database:** Save and compare setups

### Customize Your Agent

See:
- `docs/F1_RACE_ENGINEER_AGENT.md` - Full agent spec
- `docs/F1_RACE_ENGINEER_QUICK_SETUP.md` - AI client configs
- `docs/AI_CLIENT_SETUP.md` - 10+ AI clients supported

### Join the Community

- **Issues:** Report bugs or request features
- **Discussions:** Share setups and strategies
- **Wiki:** Community-contributed guides

---

## Quick Reference Card

**Start:** `./start.sh` (Linux/macOS) or `start.bat` (Windows)

**URLs:**
- Dashboard: `http://localhost:4768`
- Engineer View: `http://localhost:4768/eng-view`
- **Strategy Center: `http://localhost:4768/strategy-center`** ⭐
- MCP (HTTP): `http://localhost:4768/mcp`
- MCP (HTTPS): `https://localhost:8443/mcp`

**Stop:** `./stop.sh` or `stop.bat`

**Logs:** `tail -f pits-n-giggles.log` or `type pits-n-giggles.log`

**Docs:** `docs/README.md`

---

**Need Help?**
- Check `docs/` for detailed guides
- Open an issue on GitHub
- Review the logs for error messages

**Happy Racing! 🏎️💨**
