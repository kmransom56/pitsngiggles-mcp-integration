# AI Client Setup Guide

Configure ChatGPT, Claude, Cursor, and other AI clients to access the F1 Race Engineer MCP server.

## Overview

The MCP (Model Context Protocol) allows AI clients to connect to external tools and data sources. By connecting to the F1 Race Engineer MCP server, AI clients can access live F1 telemetry and provide race engineering advice.

## Supported AI Clients

- ✅ ChatGPT Desktop (Mac/Windows)
- ✅ Claude Desktop (Mac/Windows)
- ✅ Cursor IDE
- ✅ Continue.dev
- ✅ Cline (VS Code extension)
- ✅ Any MCP-compatible client

## ChatGPT Desktop Setup

### Prerequisites

- ChatGPT Desktop app installed
- F1 Race Engineer MCP server running (`./start-mcp.sh`)

### Configuration

**Mac/Linux:**

Edit `~/Library/Application Support/ChatGPT/config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse",
      "description": "F1 Race Engineering with live telemetry",
      "capabilities": ["chat", "telemetry", "analysis"]
    }
  }
}
```

**Windows:**

Edit `%APPDATA%\ChatGPT\config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse",
      "description": "F1 Race Engineering with live telemetry"
    }
  }
}
```

### Custom Instructions

Add to ChatGPT custom instructions:

**"What would you like ChatGPT to know about you?"**

```
I race F1 games (F1 23/24/25) and use Pits n' Giggles for telemetry. 
I need professional race engineering advice on car setup, handling 
balance, and performance optimization. I prefer concise, technical 
responses with specific setup values (not ranges).
```

**"How would you like ChatGPT to respond?"**

```
Act as a professional F1 race engineer. When discussing car setup or 
handling, use the f1-race-engineer MCP tool to access live telemetry. 
Provide specific recommendations with exact setup values:

Response format:
1. Diagnosis: What's the issue
2. Root Cause: Why it's happening  
3. Recommendations: 2-3 specific changes with values
4. Expected Impact: What should improve

Be direct, technical, and actionable. Always cite telemetry data.
```

### Usage

1. Start F1 game and Pits N Giggles
2. Ensure MCP server is running
3. Open ChatGPT Desktop
4. Ask: "What does my telemetry show?" or "I have understeer in turn 3"
5. ChatGPT will use the MCP tool to fetch live data and provide advice

## Claude Desktop Setup

### Prerequisites

- Claude Desktop app installed
- MCP server running

### Configuration

**Mac:**

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "command": "curl",
      "args": [
        "-N",
        "-H", "Accept: text/event-stream",
        "http://localhost/mcp/sse"
      ]
    }
  }
}
```

**Windows:**

Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "f1-race-engineer": {
      "command": "curl.exe",
      "args": [
        "-N",
        "-H", "Accept: text/event-stream",
        "http://localhost/mcp/sse"
      ]
    }
  }
}
```

### Project Instructions

Create a Claude Project for "F1 Racing" with custom instructions:

```
You are an F1 race engineer analyzing telemetry from Pits n' Giggles. 
When setup or handling issues are mentioned, use the f1-race-engineer 
MCP tool to get live telemetry data.

Available MCP Tools:
- get_race_info: Session and track conditions
- get_driver_info: Detailed driver telemetry
- analyze_tyre_strategy: Tyre degradation analysis
- get_lap_comparison: Sector time comparison

Response format:
**Diagnosis:** [Issue]
**Root Cause:** [Explanation]
**Recommendations:**
1. [Component]: [Change] - [Reasoning]
2. [Component]: [Change] - [Reasoning]
**Expected Impact:** [Results]
**Next Steps:** [What to monitor]

Be concise, technical, and provide specific values.
```

### Usage

1. Start MCP server and Pits N Giggles
2. Open Claude Desktop
3. Select your "F1 Racing" project
4. Ask questions about telemetry, setup, or strategy
5. Claude will fetch live data via MCP

## Cursor IDE Setup

### Prerequisites

- Cursor IDE installed
- MCP server running
- Project open in Cursor

### Configuration

Create `.cursorrules` in your project root:

```
# F1 Race Engineer MCP Integration

When discussing F1 telemetry, car setup, or race strategy, use the 
f1-race-engineer MCP server to access live data.

## MCP Server
Endpoint: http://localhost/mcp/sse
Description: Live F1 telemetry and race engineering AI

## Usage Guidelines
- Always cite telemetry data in responses
- Provide specific setup changes with values
- Explain the physics/reasoning behind recommendations
- Format responses clearly with sections

## Response Template
**Diagnosis:** [Issue identified]
**Analysis:** [Telemetry insights]  
**Recommendations:**
1. [Component]: [From X to Y] - [Why]
2. [Component]: [From X to Y] - [Why]
**Expected Impact:** [What improves]

## Setup Knowledge
- Aero: Front wing (grip) | Rear wing (stability)
- Diff: On-throttle (exit) | Off-throttle (entry)
- ARB: Front (understeer) | Rear (oversteer)
- Brakes: Forward (bite) | Rear (rotation)
```

### Cursor Settings

Add to Cursor settings (`.cursor/settings.json`):

```json
{
  "mcp.servers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse",
      "enabled": true
    }
  }
}
```

### Usage

1. Open F1-related code or notes in Cursor
2. Use Cmd+K (Mac) or Ctrl+K (Windows) to chat
3. Ask: "Check my current telemetry" or "Analyze my last lap"
4. Cursor will use MCP to fetch live data

## Continue.dev Setup

### Prerequisites

- Continue.dev extension installed (VS Code/JetBrains)
- MCP server running

### Configuration

Edit Continue config (`~/.continue/config.json`):

```json
{
  "mcpServers": [
    {
      "name": "f1-race-engineer",
      "url": "http://localhost/mcp/sse",
      "description": "F1 telemetry and race engineering"
    }
  ],
  "systemMessage": "You are an F1 race engineer. Use the f1-race-engineer MCP tool to access live telemetry when discussing car setup or strategy."
}
```

### Usage

1. Open Continue panel (Cmd+L or Ctrl+L)
2. Ask F1-related questions
3. Continue will use MCP for telemetry access

## Cline (VS Code) Setup

### Prerequisites

- Cline extension installed in VS Code
- MCP server running

### Configuration

Add to VS Code settings (`.vscode/settings.json`):

```json
{
  "cline.mcpServers": {
    "f1-race-engineer": {
      "url": "http://localhost/mcp/sse",
      "autoConnect": true
    }
  },
  "cline.instructions": "Use f1-race-engineer MCP for F1 telemetry analysis. Provide specific setup recommendations with values."
}
```

## Generic MCP Client Setup

For any MCP-compatible client:

```json
{
  "server": {
    "url": "http://localhost/mcp/sse",
    "protocol": "sse",
    "capabilities": [
      "tools/call",
      "resources/read",
      "prompts/get"
    ]
  }
}
```

## Available MCP Tools

Once connected, AI clients can call these tools:

| Tool | Description | Parameters |
|------|-------------|------------|
| `get_race_info` | Get current race/session status | - |
| `get_driver_info` | Get detailed driver telemetry | `driver_index` |
| `get_telemetry_data` | Get all drivers' data | - |
| `analyze_tyre_strategy` | Analyze tyre degradation | `driver_indices[]` |
| `get_lap_comparison` | Compare sector times | - |

## Testing Connection

### Test with curl

```bash
# Test SSE connection
curl -N -H "Accept: text/event-stream" http://localhost/mcp/sse

# Should output:
# data: {"type":"ping","timestamp":"..."}
```

### Test in AI Client

Ask: "What MCP tools are available?"

Expected response should list f1-race-engineer tools.

## Example Conversations

### ChatGPT Example

```
You: "I have understeer in slow corners at Spa, what should I change?"

ChatGPT: [Uses f1-race-engineer tool to fetch telemetry]

"Based on your current telemetry showing front tyre temps of 78°C 
(below optimal 82-88°C) and slow corner speeds:

**Diagnosis:** Cold front tyres causing understeer in low-speed sections

**Recommendations:**
1. Front Wing: +2 clicks (from 6 to 8) - Increase front downforce
2. Front ARB: -2 clicks (from 5 to 3) - Add mechanical compliance
3. Brake Bias: +1% (from 56% to 57%) - More front brake heat
4. Tire Pressure: -0.2 PSI front - Increase contact patch

**Expected Impact:** Better front grip in Turns 1, 5, 18. 
May need to monitor front brake temps."
```

### Claude Example

```
You: "Analyze my tyre degradation and suggest pit window"

Claude: [Fetches data via MCP]

"Current tyre analysis (Lap 12/28):

**Front Left:** 72% wear, 91°C (critical)
**Front Right:** 68% wear, 88°C  
**Rear Left:** 54% wear, 84°C
**Rear Right:** 52% wear, 82°C

**Pit Window:** Laps 14-16 (2-4 laps from now)
**Reasoning:** FL approaching cliff edge at 75%+ wear
**Strategy:** Box lap 15, switch to Mediums
**Alternative:** If Safety Car on lap 13-14, box immediately"
```

## Troubleshooting

### Connection Failed

```bash
# Check MCP server is running
curl http://localhost/health

# Check SSE endpoint
curl -N http://localhost/mcp/sse

# Restart MCP server
./stop-mcp.sh && ./start-mcp.sh
```

### Tools Not Showing

1. Check AI client MCP configuration
2. Restart AI client after config changes
3. Verify JSON syntax in config files
4. Check AI client logs for errors

### No Telemetry Data

1. Ensure Pits N Giggles is running
2. Start F1 game and begin session
3. Check telemetry at http://localhost:4768
4. Verify MCP can reach telemetry server

## Best Practices

1. **Clear Questions**: Be specific about the issue
2. **Include Context**: Mention track, session type, lap number
3. **One Issue at a Time**: Don't ask about multiple problems
4. **Follow Up**: Ask for clarification if needed
5. **Test Changes**: Apply one setup change at a time

## Advanced: Custom Tools

You can extend the MCP server with custom tools by modifying `mcp_server/server.py`:

```python
@app.post("/mcp/tools/custom_analysis")
async def custom_analysis(params: dict):
    # Your custom analysis logic
    return {
        "result": "Custom analysis data"
    }
```

Then register in MCP manifest.

## Support

- **Documentation**: [docs/mcp/](docs/mcp/)
- **Issues**: [GitHub Issues](https://github.com/kmransom56/pitsngiggles-mcp-integration/issues)
- **Community**: Discord/Forums

---

**Happy racing with AI assistance! 🏎️🤖**
