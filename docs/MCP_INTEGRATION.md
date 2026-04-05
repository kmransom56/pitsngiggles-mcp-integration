# MCP Integration Guide for Pits N' Giggles

## Overview

Pits N' Giggles includes a Model Context Protocol (MCP) server that exposes F1 telemetry data to AI assistants like ChatGPT, Claude, Cursor, and other AI tools. This enables real-time race engineering analysis powered by AI.

## Architecture

```
┌─────────────────────┐
│   F1 23 Game        │
│   Telemetry Data    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Pits N' Giggles    │
│  Backend Server     │
│  (Port 4768)        │
└──────────┬──────────┘
           │
           ├─── WebSocket ──┐
           │                 │
           ├─── HTTP API     │
           │                 │
           └─── MCP /mcp ────┤
                             │
                             ▼
┌─────────────────────────────────────────┐
│            Nginx Reverse Proxy          │
│         (Port 80/443 + 8443)            │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  /                → Driver View   │  │
│  │  /eng-view        → Eng View      │  │
│  │  /strategy-center → AI Chat UI    │  │
│  │  /mcp             → MCP Endpoint  │  │
│  │  /telemetry/*     → WebSocket     │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
           │
           ├──────┬──────┬──────┐
           ▼      ▼      ▼      ▼
        Claude  ChatGPT Cursor  Web UI
         MCP     MCP     MCP    Chat
```

## Features

### F1 Race Engineer AI Agent

The AI agent provides professional race engineering analysis with the following capabilities:

#### Core Tools

1. **get_race_info** - Session status, weather, track conditions
2. **get_telemetry_data** - Live data for all drivers
3. **get_driver_info** - Detailed driver-specific telemetry
4. **analyze_tyre_strategy** - Tyre wear and strategy analysis
5. **get_lap_comparison** - Performance comparison between drivers
6. **analyze_lap_time_consistency** - Consistency and trends
7. **diagnose_performance_issues** - Automated issue detection
8. **compare_to_leader** - Gap analysis to P1
9. **analyze_sector_performance** - Sector-by-sector breakdown

#### Setup Tuning Expertise

The agent can analyze F1 23 telemetry and provide setup recommendations:

- **Aero Balance**: Front wing vs rear wing adjustments for handling
- **Differential**: On/off-throttle settings for rotation
- **Suspension**: Anti-roll bar settings for understeer/oversteer
- **Brake Bias**: Forward/rear balance optimization
- **Tyre Strategy**: Compound selection and pit window optimization

## Quick Start

### 1. Start Pits N' Giggles

```bash
./start.sh
# or on Windows:
start.bat
```

The server runs on `http://localhost:4768` by default.

### 2. Access the Strategy Center

Navigate to `http://localhost:4768/strategy-center` to access the AI-powered race engineer interface.

### 3. Using the AI Chat

The Strategy Center provides:

- Real-time telemetry visualization
- AI chat interface for race engineering questions
- Quick action buttons for common queries
- Voice input/output (optional)

Example queries:
- "Analyze my last lap performance"
- "What setup changes would reduce understeer?"
- "Predict optimal pit window"
- "Compare my tyre strategy to P1"

## Nginx Reverse Proxy Setup

For production deployments with HTTPS and external access, see `deployment/nginx/README.md`.

## AI Client Integration

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "pitsngiggles": {
      "command": "curl",
      "args": [
        "-N",
        "-H", "Accept: text/event-stream",
        "http://localhost:4768/mcp"
      ]
    }
  }
}
```

For remote servers with HTTPS:

```json
{
  "mcpServers": {
    "pitsngiggles": {
      "command": "curl",
      "args": [
        "-N",
        "-H", "Accept: text/event-stream",
        "https://your-domain.com:8443/mcp"
      ]
    }
  }
}
```

### ChatGPT (via Custom GPT)

See `docs/AI_CLIENT_SETUP.md` for detailed ChatGPT configuration.

### Cursor IDE

Add to your Cursor settings (`.cursor/mcp_config.json`):

```json
{
  "mcpServers": [
    {
      "name": "pitsngiggles",
      "type": "sse",
      "url": "http://localhost:4768/mcp"
    }
  ]
}
```

### Docker MCP Toolkit Integration

See `deployment/docker/MCP_TOOLKIT.md` for Docker integration guide.

## Voice Functionality

The Strategy Center supports voice interaction using the Web Speech API.

### Enabling Voice

In the Strategy Center UI:
1. Click the microphone icon to start voice input
2. Speak your question clearly
3. AI responses can be played back automatically
4. Toggle voice output in settings

## API Reference

### MCP Endpoints

#### GET /mcp
Server-Sent Events stream for real-time tool discovery

```bash
curl -N -H "Accept: text/event-stream" http://localhost:4768/mcp
```

#### POST /mcp/tools
Execute specific MCP tools

```bash
curl -X POST http://localhost:4768/mcp/tools \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "get_race_info",
      "arguments": {}
    }
  }'
```

See `docs/API_REFERENCE.md` for complete API documentation.

## F1 Race Engineer Agent Configuration

See `docs/F1_AGENT_CONFIG.md` for detailed agent configuration and tuning logic.

## Troubleshooting

### MCP Connection Issues

**Problem**: AI client cannot connect to MCP endpoint

**Solution**:
1. Verify Pits N' Giggles is running: `curl http://localhost:4768/mcp`
2. Check firewall settings
3. For remote access, ensure nginx is properly configured
4. Check SSL certificate validity

### No Telemetry Data

**Problem**: MCP tools return empty data

**Solution**:
1. Ensure F1 23 is running and telemetry is enabled
2. Check UDP telemetry settings in F1 23
3. Verify Pits N' Giggles is receiving data
4. Check the driver view at `http://localhost:4768/`

### Voice Not Working

**Problem**: Speech recognition/synthesis not functional

**Solution**:
1. Use Chrome, Edge, or Safari (Firefox has limited support)
2. Grant microphone permissions
3. Check browser console for errors
4. Ensure HTTPS for production (required for some browsers)

## Security Considerations

See `docs/SECURITY.md` for security best practices.

## Contributing

To extend the MCP server with new tools, see `docs/CONTRIBUTING.md`.

## Resources

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Pits N' Giggles Documentation](https://github.com/ashwin-nat/pits-n-giggles)
- [F1 23 UDP Telemetry Specification](https://answers.ea.com/t5/General-Discussion/F1-23-UDP-Specification/td-p/12633159)

## License

MIT License - See LICENSE file for details
