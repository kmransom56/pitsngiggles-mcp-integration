# 🤖 AI Client Configuration Guide

Complete guide for connecting various AI tools to the Pits n' Giggles MCP server.

**MCP endpoint (canonical):** `https://localhost:8443/f1-race-engineer-lan` — the shorter **`/mcp`** path is still supported for old configs. Use server name **`f1-race-engineer-lan`** in client lists. Your server URL may differ if not local.

---

## 📋 Quick Reference Table

| AI Tool | Setup Difficulty | Transport | API Key Needed | Best For |
|---------|-----------------|-----------|----------------|----------|
| ChatGPT Desktop | Easy | SSE | No | General analysis |
| Claude Desktop | Medium | mcp-remote | No | Deep reasoning |
| Cursor IDE | Easy | SSE | No | Development |
| Cline (VS Code) | Easy | SSE | No | Code + telemetry |
| Continue.dev | Easy | SSE | No | VS Code alternative |
| Windsurf Editor | Easy | SSE | No | Code + AI pair programming |
| Zed Editor | Medium | SSE | No | Fast lightweight IDE |
| Open WebUI | Medium | Custom | Optional | Self-hosted chat |
| LibreChat | Medium | Custom | Optional | Open source ChatGPT |
| Strategy Center | Easy | Direct | Optional | Built-in browser UI |

---

## 🏎️ 1. ChatGPT Desktop (Recommended)

**Platform:** Windows, macOS  
**Transport:** SSE (Server-Sent Events)  
**Setup Time:** 2 minutes

### Setup Steps

1. **Enable Developer Mode**
   - Open ChatGPT Desktop
   - Settings → Personalization
   - Toggle **Developer Mode** ON

2. **Create MCP App**
   - Go to **Apps** → **Create New App**
   - Fill in:
     - **Name:** `Pits n' Giggles Race Engineer`
     - **App URL:** `https://localhost:8443/f1-race-engineer-lan`
     - **Transport Type:** `SSE`

3. **Connect**
   - Click **Connect**
   - Wait for tool discovery
   - You should see 6 tools populate

4. **Verify**
   - Ask: *"What are the current race conditions?"*
   - Should receive live telemetry data

### Tips
- ChatGPT automatically retries on connection errors
- Works best for natural language strategy advice
- Maintains conversation context across multiple queries

---

## 💻 2. Cursor IDE

**Platform:** Windows, macOS, Linux  
**Transport:** SSE  
**Setup Time:** 1 minute

### Setup Steps

1. **Open MCP Settings**
   - Click Gear icon (⚙️)
   - Navigate to **Features** → **MCP**

2. **Add Server**
   - Click **Add Server**
   - Configure:
     - **Name:** `Pits n' Giggles Telemetry`
     - **Type:** `SSE`
     - **URL:** `https://localhost:8443/f1-race-engineer-lan`

3. **Activate**
   - Toggle server to **Active**
   - Green indicator confirms connection

### Usage
- AI composer has direct access to telemetry
- Use `@Pits n' Giggles Telemetry` to reference explicitly
- Great for analyzing telemetry data while coding

### Example Prompts
```
"Show me the current race standings @Pits n' Giggles Telemetry"
"Compare tyre strategies using telemetry data"
"Generate a lap time analysis script based on current session"
```

---

## 🧠 3. Claude Desktop

**Platform:** Windows, macOS  
**Transport:** mcp-remote (npx wrapper)  
**Setup Time:** 3 minutes

### Setup Steps

1. **Locate Config File**
   - **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
   - **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Linux:** `~/.config/Claude/claude_desktop_config.json`

2. **Edit Configuration**
   Create or edit the file with:

   ```json
   {
     "mcpServers": {
       "pitsngiggles": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://localhost:8443/f1-race-engineer-lan"
         ]
       }
     }
   }
   ```

3. **Restart Claude**
   - Close Claude Desktop completely
   - Reopen the application
   - Check for MCP tools in settings

4. **Verify**
   - Look for 🔌 icon indicating MCP connection
   - Ask: *"List available MCP tools"*

### Notes
- Claude requires Node.js installed for `npx`
- Uses `mcp-remote` package to bridge SSE to Claude's protocol
- Best for complex multi-step reasoning about race strategy

---

## 🛠️ 4. Cline (VS Code Extension)

**Platform:** VS Code (all platforms)  
**Transport:** SSE  
**Setup Time:** 2 minutes

### Setup Steps

1. **Install Extension**
   - Open VS Code
   - Install "Cline" extension from marketplace

2. **Locate Config File**
   - **Windows:** `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`
   - **macOS:** `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
   - **Linux:** `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

3. **Add MCP Server**
   ```json
   {
     "mcpServers": {
       "Pits_N_Giggles": {
         "type": "sse",
         "url": "https://localhost:8443/f1-race-engineer-lan"
       }
     }
   }
   ```

4. **Reload VS Code**
   - Restart VS Code
   - Open Cline panel
   - Verify connection

### Usage
- Cline can analyze code + telemetry simultaneously
- Great for building telemetry analysis tools
- Can modify code based on live race data

---

## 🔄 5. Continue.dev (VS Code/JetBrains)

**Platform:** VS Code, IntelliJ, PyCharm, etc.  
**Transport:** SSE  
**Setup Time:** 2 minutes

### Setup Steps

1. **Install Extension**
   - Install Continue.dev from marketplace

2. **Open Config**
   - Open Continue sidebar
   - Click gear icon → **Edit config.json**

3. **Add MCP Server**
   ```json
   {
     "contextProviders": [
       {
         "name": "f1-race-engineer-lan",
         "params": {
           "serverUrl": "https://localhost:8443/f1-race-engineer-lan",
           "transport": "sse"
         }
       }
     ]
   }
   ```

4. **Use @ Mentions**
   - Type `@mcp` in Continue chat
   - Ask telemetry questions

---

## 🌊 6. Windsurf Editor (Codeium)

**Platform:** Windows, macOS, Linux  
**Transport:** SSE  
**Setup Time:** 2 minutes

### Setup Steps

1. **Open Settings**
   - File → Preferences → Settings
   - Search for "MCP"

2. **Add Server**
   - Click **Add MCP Server**
   - Configure:
     ```json
     {
       "name": "Pits n' Giggles",
       "url": "https://localhost:8443/f1-race-engineer-lan",
       "type": "sse"
     }
     ```

3. **Use Cascade AI**
   - Open Cascade panel
   - MCP tools available automatically
   - Ask telemetry questions while coding

### Features
- Agentic AI with MCP context
- Multi-file editing with telemetry awareness
- Terminal integration

---

## ⚡ 7. Zed Editor

**Platform:** macOS, Linux (Windows coming)  
**Transport:** SSE  
**Setup Time:** 3 minutes

### Setup Steps

1. **Open Zed Config**
   - `Cmd+,` (macOS) or `Ctrl+,` (Linux)
   - Navigate to settings

2. **Edit settings.json**
   ```json
   {
     "assistant": {
       "mcp_servers": {
         "pitsngiggles": {
           "url": "https://localhost:8443/f1-race-engineer-lan",
           "transport": "sse"
         }
       }
     }
   }
   ```

3. **Restart Zed**
   - Close and reopen
   - MCP tools available in assistant

---

## 🌐 8. Open WebUI (Self-Hosted)

**Platform:** Docker, any OS  
**Transport:** Custom adapter  
**Setup Time:** 10 minutes

### Setup Steps

1. **Install Open WebUI**
   ```bash
   docker run -d -p 3000:8080 \
     -v open-webui:/app/backend/data \
     --name open-webui \
     ghcr.io/open-webui/open-webui:main
   ```

2. **Create MCP Adapter**
   Create `mcp_adapter.py`:
   ```python
   import requests
   
   def get_race_info():
       response = requests.post(
           'https://localhost:8443/f1-race-engineer-lan/tools',
           json={'method': 'tools/call', 'params': {
               'name': 'get_race_info', 'arguments': {}
           }},
           verify=False
       )
       return response.json()
   ```

3. **Register as Tool**
   - Go to Open WebUI admin
   - Tools → Add Custom Tool
   - Upload adapter script

### Use Cases
- Self-hosted alternative to ChatGPT
- Full privacy control
- Can use any LLM backend (Ollama, etc.)

---

## 💬 9. LibreChat

**Platform:** Docker, any OS  
**Transport:** Custom plugin  
**Setup Time:** 15 minutes

### Setup Steps

1. **Install LibreChat**
   ```bash
   git clone https://github.com/danny-avila/LibreChat.git
   cd LibreChat
   docker compose up -d
   ```

2. **Create MCP Plugin**
   In `api/app/clients/tools/`:
   ```javascript
   const axios = require('axios');
   
   module.exports = {
     name: 'get_race_info',
     description: 'Get F1 telemetry race info',
     execute: async () => {
       const { data } = await axios.post(
         'https://localhost:8443/f1-race-engineer-lan/tools',
         {
           method: 'tools/call',
           params: { name: 'get_race_info', arguments: {} }
         }
       );
       return data;
     }
   };
   ```

3. **Register Plugin**
   - Restart LibreChat
   - Enable plugin in settings

---

## 🖥️ 10. Strategy Center (Built-in)

**Platform:** Any browser  
**Transport:** Direct HTTP  
**Setup Time:** 0 minutes (already included!)

### Access

Simply visit: `http://localhost:4768/strategy-center`

### Features
- Split-screen telemetry + AI chat
- Dual mode: MCP (free) or OpenAI
- No installation needed
- See [Strategy Center Guide](STRATEGY_CENTER.md)

### Quick Setup

**MCP Mode (Default):**
```javascript
// No setup needed! Just use it
```

**OpenAI Mode:**
```javascript
localStorage.setItem('openai_api_key', 'sk-...')
switchAIMode('openai')
```

---

## 🔧 Advanced Configurations

### Using with Ollama (Local LLM)

If you have Ollama running locally, you can use it with Continue.dev or Open WebUI:

```json
{
  "models": [{
    "title": "Llama 3.1 + Telemetry",
    "provider": "ollama",
    "model": "llama3.1",
    "contextProviders": ["mcp"]
  }]
}
```

### Using with LM Studio

LM Studio can integrate via OpenAI-compatible API:

```javascript
// In Strategy Center, set custom endpoint:
const AI_ENDPOINT = 'http://localhost:1234/v1/chat/completions';
const AI_KEY = 'not-needed';
```

### Custom API Integration

For any tool not listed, use the MCP endpoints directly:

```javascript
// List tools
POST https://localhost:8443/f1-race-engineer-lan/tools
{
  "method": "tools/list"
}

// Call tool
POST https://localhost:8443/f1-race-engineer-lan/tools
{
  "method": "tools/call",
  "params": {
    "name": "get_race_info",
    "arguments": {}
  }
}
```

---

## 🎯 Recommended Setup by Use Case

### For Racing (Real-time)
**Best:** Strategy Center (MCP mode)
- Zero latency
- Free
- Integrated UI

### For Strategy Analysis (Post-race)
**Best:** ChatGPT Desktop
- Best reasoning
- Natural language
- Conversation context

### For Development (Building tools)
**Best:** Cursor or Windsurf
- Code + telemetry context
- Multi-file awareness
- Agentic capabilities

### For Privacy (Self-hosted)
**Best:** Open WebUI + Ollama
- Fully local
- No API costs
- Complete control

### For Research (Deep analysis)
**Best:** Claude Desktop
- Longest context window
- Best reasoning for complex queries
- Document analysis

---

## 📊 Feature Comparison

| Feature | ChatGPT | Claude | Cursor | Continue | Strategy Center |
|---------|---------|---------|--------|----------|-----------------|
| Real-time Data | ✅ | ✅ | ✅ | ✅ | ✅ |
| Free | ✅* | ✅* | ✅* | ✅ | ✅ |
| Code Integration | ❌ | ❌ | ✅ | ✅ | ❌ |
| Natural Language | ✅✅ | ✅✅ | ✅ | ✅ | ✅ |
| Context Memory | ✅✅ | ✅✅✅ | ✅ | ✅ | ❌ |
| Offline Mode | ❌ | ❌ | ❌ | ✅** | ✅*** |

\* May require subscription for full features  
\*\* With local LLM  
\*\*\* MCP mode only

---

## 🐛 Troubleshooting

### "Connection refused"
- Ensure Nginx is running: `sudo systemctl status nginx`
- Check Pits n' Giggles is running
- Verify endpoint: `curl -N https://localhost:8443/f1-race-engineer-lan`

### "Certificate error"
- Trust self-signed cert (see [MCP Integration](MCP_INTEGRATION.md#self-signed-certificate-trust))
- Or use HTTP: `http://localhost:4768/f1-race-engineer-lan`

### "No tools available"
- Check `/mcp/tools` endpoint works
- Restart AI client
- Check AI client MCP logs

### "Tool call failed"
- Verify backend is running
- Check telemetry is active (game running)
- View browser console for errors

---

## 🏁 Quick Test

Test your MCP setup with any AI client:

1. **Ask:** "What are the current race conditions?"
2. **Expected:** Live race status with lap, temps, weather
3. **If error:** Check troubleshooting section above

**Test Prompts:**
- "Compare tyre strategies of top 3 drivers"
- "Analyze driver 0's last 3 laps"
- "What's the optimal pit window?"
- "Show me current standings"

---

## 📚 See Also

- [MCP Integration Guide](MCP_INTEGRATION.md) - Complete MCP setup
- [Strategy Center Guide](STRATEGY_CENTER.md) - Built-in browser UI
- [MCP Quick Start](MCP_QUICKSTART.md) - 5-minute setup
- [Nginx Deployment](../deployment/README.md) - Production setup
