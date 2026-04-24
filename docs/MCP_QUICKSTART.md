# MCP Quick Start Guide

Get AI-powered race engineering in 5 minutes!

## Prerequisites

- Pits n' Giggles installed and running
- Nginx installed (`sudo apt install nginx` on Linux)
- ChatGPT Desktop, Claude, or Cursor IDE

## Step 1: Deploy Nginx Reverse Proxy

```bash
cd pits-n-giggles/deployment/scripts
sudo ./setup-nginx.sh
```

This creates an HTTPS endpoint for AI tools at: `https://localhost:8443/f1-race-engineer-lan` (legacy path `/mcp` is still supported).

## Step 2: Start Pits n' Giggles

Run the application normally. The MCP server starts automatically on port 4768.

## Step 3: Connect Your AI Tool

### ChatGPT Desktop (Recommended)

1. Open ChatGPT Desktop
2. Settings → Personalization → **Enable Developer Mode**
3. Apps → **Create New App**
   - Name: `Pits n' Giggles`
   - URL: `https://localhost:8443/f1-race-engineer-lan`
   - Transport: `SSE`
4. Click **Connect**

### Claude Desktop

Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer-lan": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://localhost:8443/f1-race-engineer-lan"]
    }
  }
}
```

### Cursor IDE

1. Settings → Features → MCP
2. Add Server:
   - Name: `f1-race-engineer-lan`
   - Type: `SSE`
   - URL: `https://localhost:8443/f1-race-engineer-lan`

## Step 4: Start Racing!

### Example Prompts

Once connected, try these:

**Race Status:**
> "What are the current race conditions?"

**Strategy Analysis:**
> "Compare tyre strategies of the top 3 drivers"

**Performance Coaching:**
> "Analyze my last 3 laps and tell me where I'm losing time"

**Live Monitoring:**
> "What's my gap to P1 and who's behind me?"

**Tyre Management:**
> "Should I pit now based on my tyre wear?"

**Fuel Strategy:**
> "How many more laps can I do with current fuel?"

## Troubleshooting

**Certificate Error?**
- Accept the self-signed certificate in your browser first
- Visit `https://localhost:8443/f1-race-engineer-lan` and click "Advanced" → "Proceed"

**No Connection?**
- Verify Nginx is running: `sudo systemctl status nginx`
- Check Pits n' Giggles is running on port 4768
- View logs: `sudo tail -f /var/log/nginx/pitsngiggles-mcp.error.log`

**No Data?**
- Ensure F1 game is running and sending telemetry
- Check you're in an active session (not main menu)

## Next Steps

- Read the full [MCP Integration Guide](MCP_INTEGRATION.md)
- Explore all available [MCP Tools](MCP_INTEGRATION.md#available-mcp-tools)
- Set up [Remote Access](MCP_INTEGRATION.md#production-deployment)

## Need Help?

- [GitHub Issues](https://github.com/ashwin-nat/pits-n-giggles/issues)
- [Discord Community](https://discord.gg/RK5Z76h6dX)
- [Full Documentation](https://www.pitsngiggles.com/blog)
