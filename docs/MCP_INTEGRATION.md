# Model Context Protocol (MCP) Integration

Pits n' Giggles now supports the Model Context Protocol (MCP), allowing AI tools like ChatGPT, Claude, and Cursor to directly access live F1 telemetry data.

**Paths:** the canonical HTTP path is **`/f1-race-engineer-lan`** (and **`/f1-race-engineer-lan/tools`** for POST). The legacy path **`/mcp`** (and **`/mcp/tools`**) remains available. Use the display name **`f1-race-engineer-lan`** in MCP client lists.

## Overview

The MCP server exposes telemetry data through a standardized protocol that AI assistants can use to:
- Monitor live race conditions
- Analyze driver performance
- Compare lap times and strategies
- Provide real-time race engineering insights

## Quick Start

### 1. Start Pits n' Giggles

Run the application normally. The MCP server is automatically available at:
- **Local**: `http://localhost:4768/f1-race-engineer-lan`
- **With HTTPS**: `https://localhost:4768/f1-race-engineer-lan`
- **With Nginx Proxy**: `https://localhost:8443/f1-race-engineer-lan` (see [Nginx Setup](#nginx-reverse-proxy))

### 2. Access the Strategy Center (Optional)

For a built-in AI chat interface, visit:
- `http://localhost:4768/strategy-center`

This provides a split-screen view with telemetry on the left and AI chat on the right. **Note:** You'll need to set your OpenAI API key in browser localStorage:
```javascript
localStorage.setItem('openai_api_key', 'sk-your-key-here')
```

### 3. Connect Your AI Tool

See the [AI Tool Configuration](#ai-tool-configuration) section below for specific setup instructions.

## Nginx Reverse Proxy (Recommended)

For production use with ChatGPT and other external AI tools, use the Nginx reverse proxy to expose the MCP server over HTTPS.

### Setup

```bash
cd deployment/scripts
sudo ./setup-nginx.sh
```

This will:
1. Generate a self-signed SSL certificate
2. Configure Nginx to proxy MCP traffic
3. Enable HTTPS on port 8443

Your MCP endpoint will be available at: `https://localhost:8443/f1-race-engineer-lan`

For remote access, replace `localhost` with your server's IP or domain name.

See `deployment/README.md` for detailed Nginx configuration options.

## Available MCP Tools

The MCP server provides the following tools that AI assistants can invoke:

### 1. `get_race_info`
Get current race status and overall statistics.

**Returns:**
- Session time and type
- Current lap and total laps
- Safety car/VSC status
- Track and air temperatures
- Weather forecast

**Example use:**
> "What are the current race conditions?"

---

### 2. `get_telemetry_data`
Get live telemetry for all drivers.

**Returns:**
- Driver positions and names
- Current lap times
- Tyre compounds and wear
- Fuel levels
- Penalties and pit status

**Example use:**
> "Show me the current race standings"

---

### 3. `get_driver_info`
Get detailed information about a specific driver.

**Parameters:**
- `driver_index` (integer, 0-21): The driver's index in the race

**Returns:**
- Complete lap history
- Tyre wear progression
- Damage status
- ERS deployment
- Stint information
- Sector times

**Example use:**
> "Analyze driver 5's last 3 laps"

---

### 4. `get_stream_overlay_data`
Get broadcasting-optimized data for stream overlays.

**Returns:**
- Player position and status
- Delta to leader/ahead/behind
- Key race information formatted for streaming

**Example use:**
> "What should I show on my stream overlay?"

---

### 5. `analyze_tyre_strategy`
Compare tyre strategies across multiple drivers.

**Parameters:**
- `driver_indices` (array of integers, optional): List of drivers to analyze

**Returns:**
- Current tyre compound and age
- Tyre wear percentages
- Complete stint history
- Compound choices

**Example use:**
> "Compare tyre strategies between drivers 0, 3, and 7"

---

### 6. `get_lap_comparison`
Compare lap times between drivers.

**Parameters:**
- `driver_indices` (array of integers, optional): Drivers to compare
- `lap_number` (integer, optional): Specific lap to analyze

**Returns:**
- Best and last lap times
- Lap-by-lap comparison
- Sector time breakdowns (if lap specified)

**Example use:**
> "Compare lap 15 between all drivers on softs"

## AI Tool Configuration

**🔗 For complete setup instructions for all AI clients, see: [AI Client Setup Guide](AI_CLIENT_SETUP.md)**

This section provides quick setup for the most common tools. For advanced configurations, self-hosted options, and additional clients (Continue.dev, Windsurf, Zed, Open WebUI, LibreChat, etc.), refer to the comprehensive guide above.

### ChatGPT Desktop (Quick Setup)

1. **Enable Developer Mode**
   - Settings → Personalization → Developer Mode (Toggle ON)

2. **Create New App**
   - Apps → Create New App
   - **Name**: `Pits n' Giggles`
   - **App URL**: `https://localhost:8443/f1-race-engineer-lan` (or your server URL)
   - **Transport Type**: `SSE`

3. **Connect**
   - Click **Connect**
   - Tools should automatically populate

4. **Start Using**
   - Ask: *"What are the current race conditions?"*
   - Ask: *"Analyze driver 0's tyre strategy"*

---

### Cursor IDE

1. **Open Settings**
   - Click the Gear icon → **Features** → **MCP**

2. **Add Server**
   - **Name**: `Pits n Giggles Telemetry`
   - **Type**: `SSE`
   - **URL**: `https://localhost:8443/f1-race-engineer-lan`

3. **Use in Chat**
   - The AI agent will automatically have access to telemetry data
   - Ask racing-specific questions during development

---

### Claude Desktop

Edit the configuration file:
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

Add this configuration:

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

Restart Claude Desktop.

---

### Cline (VS Code Extension)

Edit the MCP settings file:
- **Windows**: `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`
- **macOS**: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

Add this configuration:

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

Reload VS Code.

---

## Self-Signed Certificate Trust

If using the Nginx reverse proxy with a self-signed certificate, you'll need to trust it:

### Windows
1. Open `certmgr.msc`
2. Import `/etc/nginx/ssl/pitsngiggles/fullchain.pem` to "Trusted Root Certification Authorities"

### macOS
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /etc/nginx/ssl/pitsngiggles/fullchain.pem
```

### Linux
```bash
sudo cp /etc/nginx/ssl/pitsngiggles/fullchain.pem /usr/local/share/ca-certificates/pitsngiggles.crt
sudo update-ca-certificates
```

### Browser (for testing)
- **Chrome/Edge**: Visit `https://localhost:8443/f1-race-engineer-lan` and click "Advanced" → "Proceed to localhost"
- **Firefox**: Visit URL → Click "Advanced" → "Accept the Risk and Continue"

---

## Example AI Conversations

Here are some example prompts you can use with your AI assistant:

### Race Strategy
> "Compare the tyre strategies of the top 3 drivers"

> "Who has the oldest tyres in the race right now?"

> "Should I pit on this lap based on my current tyre wear?"

### Performance Analysis
> "Analyze my last 5 laps and tell me where I'm losing time"

> "Compare my sector times to the race leader"

> "Which drivers are faster than me on the same tyre compound?"

### Race Monitoring
> "Alert me when anyone pits or when the safety car is deployed"

> "What's the gap to the car behind me?"

> "Give me a summary of the current race situation"

### Engineering Support
> "Based on current fuel consumption, how many more laps can I complete?"

> "What's causing my lap times to drop off?"

> "Compare my ERS deployment to other drivers"

---

## Troubleshooting

### Connection Issues

**"Unable to connect to MCP server"**
- Verify Pits n' Giggles is running
- Check the MCP URL is correct
- Ensure Nginx is running: `sudo systemctl status nginx`
- Check logs: `sudo tail -f /var/log/nginx/pitsngiggles-mcp.error.log`

**"Certificate verification failed"**
- Trust the self-signed certificate (see above)
- Or use HTTP instead: `http://localhost:4768/f1-race-engineer-lan`

**"No tools available"**
- Refresh the connection in your AI tool
- Check browser console for errors
- Verify `/mcp` endpoint returns data: `curl http://localhost:4768/f1-race-engineer-lan`

### Data Issues

**"No race data available"**
- Ensure F1 game is running and sending telemetry
- Check Pits n' Giggles is receiving packets
- Verify you're in an active session (not main menu)

**"Driver index out of range"**
- Use valid driver indices (0-21)
- Check current session has active drivers

**"Stale data"**
- MCP updates in real-time as telemetry arrives
- If data seems old, check game telemetry settings

---

## Development

### Testing the MCP Endpoint

Test the SSE connection:
```bash
curl -N http://localhost:4768/f1-race-engineer-lan
```

Test tool invocation:
```bash
curl -X POST http://localhost:4768/f1-race-engineer-lan/tools \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/list"}'
```

Get race info:
```bash
curl -X POST http://localhost:4768/f1-race-engineer-lan/tools \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/call", "params": {"name": "get_race_info", "arguments": {}}}'
```

### Custom AI Agents

You can build custom AI agents using the MCP protocol. The server follows the standard MCP specification for tool discovery and invocation.

See `lib/mcp_server/server.py` for the implementation details.

---

## Security Considerations

### Local Development
- Self-signed certificates are fine for local use
- Default configuration allows all origins (`Access-Control-Allow-Origin: *`)

### Production Deployment
- Use proper SSL certificates (Let's Encrypt recommended)
- Restrict CORS to known domains
- Consider authentication for public-facing deployments
- Use firewall rules to limit access

### Network Exposure
- The Nginx reverse proxy configuration is designed for local network use
- For internet exposure, add authentication and proper SSL
- Consider VPN or tunneling solutions for remote access (see main docs)

---

## See Also

- [Nginx Deployment Guide](../deployment/README.md)
- [Main Documentation](https://www.pitsngiggles.com/blog)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
