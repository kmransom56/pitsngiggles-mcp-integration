# Adding F1 Race Engineer to Docker's MCP Toolkit

This guide shows how to integrate the F1 Race Engineer MCP server with Docker's MCP Toolkit for easy deployment and discovery.

## What is Docker's MCP Toolkit?

The Docker MCP Toolkit is a curated collection of MCP (Model Context Protocol) servers that can be easily deployed via Docker Compose. Adding your MCP server makes it discoverable and easy to use for the Docker community.

## Prerequisites

- Docker Hub account
- Tested MCP server
- Documentation
- Example usage

## Step 1: Prepare Docker Images

### Build and Tag Images

```bash
# Build MCP server image
docker build -f Dockerfile.mcp -t pitsngiggles/f1-race-engineer-mcp:latest .

# Build nginx proxy image
docker build -f Dockerfile.nginx -t pitsngiggles/f1-nginx-proxy:latest .

# Tag for versioning
docker tag pitsngiggles/f1-race-engineer-mcp:latest pitsngiggles/f1-race-engineer-mcp:1.0.0
docker tag pitsngiggles/f1-nginx-proxy:latest pitsngiggles/f1-nginx-proxy:1.0.0
```

### Test Images Locally

```bash
docker-compose -f docker-compose.mcp.yml up -d
docker-compose -f docker-compose.mcp.yml logs -f
```

### Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Push images
docker push pitsngiggles/f1-race-engineer-mcp:latest
docker push pitsngiggles/f1-race-engineer-mcp:1.0.0
docker push pitsngiggles/f1-nginx-proxy:latest
docker push pitsngiggles/f1-nginx-proxy:1.0.0
```

## Step 2: Create MCP Toolkit Configuration

### Create `mcp-toolkit.yml`

```yaml
name: f1-race-engineer
version: 1.0.0
description: AI-powered race engineering for F1 23/24/25 via Pits N Giggles
author: kmransom56
repository: https://github.com/kmransom56/pitsngiggles-mcp-integration
documentation: https://github.com/kmransom56/pitsngiggles-mcp-integration/blob/main/README.md

tags:
  - f1
  - racing
  - telemetry
  - ai-assistant
  - race-engineer
  - sim-racing

category: gaming

services:
  - name: mcp-server
    image: pitsngiggles/f1-race-engineer-mcp:1.0.0
    description: F1 Race Engineer AI service
    
  - name: nginx
    image: pitsngiggles/f1-nginx-proxy:1.0.0
    description: Reverse proxy for MCP and Pits N Giggles

endpoints:
  - name: Chat API
    url: http://localhost/api/chat
    method: POST
    description: Send chat messages with telemetry context
    
  - name: WebSocket
    url: ws://localhost/api/ws
    description: Real-time communication
    
  - name: MCP SSE
    url: http://localhost/mcp/sse
    description: Server-Sent Events for AI clients (ChatGPT, Claude)
    
  - name: Health Check
    url: http://localhost/health
    method: GET
    description: Check server status

environment:
  required:
    - name: LLM_API_KEY
      description: API key for LLM service (OpenRouter, OpenAI, Anthropic)
      example: sk-or-v1-...
      
  optional:
    - name: LLM_ENDPOINT
      description: LLM API endpoint
      default: https://openrouter.ai/api/v1/chat/completions
      
    - name: LLM_MODEL
      description: Model to use
      default: openai/gpt-4o-mini
      
    - name: HTTP_PORT
      description: HTTP port
      default: 80
      
    - name: HTTPS_PORT
      description: HTTPS port
      default: 443
      
    - name: MCP_PORT
      description: MCP server port
      default: 8765

volumes:
  - name: mcp-data
    description: MCP server data and logs
    
  - name: nginx-logs
    description: Nginx access and error logs

networks:
  - name: f1-network
    description: Internal network for F1 services

ports:
  - port: 80
    description: HTTP traffic
    
  - port: 443
    description: HTTPS traffic (with self-signed cert)
    
  - port: 8765
    description: Direct MCP server access

quickstart: |
  1. Get an LLM API key from OpenRouter (https://openrouter.ai/keys)
  2. Copy .env.mcp.example to .env.mcp and add your API key
  3. Run: ./start-mcp.sh
  4. Start Pits N Giggles: ./start.sh
  5. Access: http://localhost/strategy-center.html
  
  For detailed instructions: https://github.com/kmransom56/pitsngiggles-mcp-integration/blob/main/docs/mcp/MCP_QUICKSTART.md

usage_examples:
  - title: Basic Chat Request
    language: bash
    code: |
      curl -X POST http://localhost/api/chat \
        -H "Content-Type: application/json" \
        -d '{
          "message": "I have understeer in slow corners",
          "telemetry": {
            "lap": 5,
            "speed": 120.5,
            "tyre_temps": {"FL": 85, "FR": 82, "RL": 78, "RR": 80},
            "tyre_wear": {"FL": 15, "FR": 14, "RL": 12, "RR": 13}
          }
        }'
  
  - title: WebSocket Connection
    language: javascript
    code: |
      const ws = new WebSocket('ws://localhost/api/ws');
      
      ws.onopen = () => {
        ws.send(JSON.stringify({
          type: 'chat',
          message: 'What is my optimal pit window?',
          telemetry: { lap: 12, fuel: 8.5 }
        }));
      };
      
      ws.onmessage = (event) => {
        const response = JSON.parse(event.data);
        console.log('AI Response:', response.data.response);
      };
  
  - title: ChatGPT Desktop Integration
    language: json
    code: |
      {
        "mcpServers": {
          "f1-race-engineer": {
            "url": "http://localhost/mcp/sse",
            "description": "F1 Race Engineering AI"
          }
        }
      }

dependencies:
  - name: pits-n-giggles
    description: F1 telemetry server (optional - can run on host)
    url: https://github.com/ashwin-nat/pits-n-giggles
    required: true
    
  - name: f1-game
    description: F1 23, F1 24, or F1 25
    required: true

compatibility:
  ai_clients:
    - ChatGPT Desktop
    - Claude Desktop
    - Cursor IDE
    - Continue.dev
    - Any MCP-compatible client
    
  platforms:
    - linux
    - macos
    - windows
    
  games:
    - F1 23
    - F1 24
    - F1 25

troubleshooting:
  - issue: MCP server not responding
    solution: Check logs with `docker-compose -f docker-compose.mcp.yml logs -f mcp-server`
    
  - issue: No AI responses
    solution: Verify LLM_API_KEY is set in .env.mcp and has credits
    
  - issue: Telemetry not available
    solution: Ensure Pits N Giggles is running on host or in Docker

support:
  documentation: https://github.com/kmransom56/pitsngiggles-mcp-integration/blob/main/README.md
  issues: https://github.com/kmransom56/pitsngiggles-mcp-integration/issues
  discussions: https://github.com/kmransom56/pitsngiggles-mcp-integration/discussions
```

## Step 3: Create Standalone Docker Compose

Create a simplified compose file for Docker Toolkit users:

```yaml
# docker-compose.toolkit.yml
version: '3.8'

services:
  mcp-server:
    image: pitsngiggles/f1-race-engineer-mcp:1.0.0
    container_name: f1-race-engineer-mcp
    environment:
      - LLM_ENDPOINT=${LLM_ENDPOINT:-https://openrouter.ai/api/v1/chat/completions}
      - LLM_API_KEY=${LLM_API_KEY:?Please set LLM_API_KEY in .env file}
      - LLM_MODEL=${LLM_MODEL:-openai/gpt-4o-mini}
      - MCP_PORT=8765
    ports:
      - "${MCP_PORT:-8765}:8765"
    networks:
      - f1-network
    restart: unless-stopped
    volumes:
      - mcp-data:/app/data

  nginx:
    image: pitsngiggles/f1-nginx-proxy:1.0.0
    container_name: f1-nginx-proxy
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
    networks:
      - f1-network
    depends_on:
      - mcp-server
    restart: unless-stopped
    volumes:
      - nginx-logs:/var/log/nginx
    extra_hosts:
      - "host.docker.internal:host-gateway"

networks:
  f1-network:
    driver: bridge

volumes:
  mcp-data:
  nginx-logs:
```

## Step 4: Submit to Docker MCP Toolkit

### Fork the MCP Toolkit Repository

```bash
git clone https://github.com/docker/mcp-toolkit
cd mcp-toolkit
git checkout -b add-f1-race-engineer
```

### Add Your Configuration

```bash
mkdir -p servers/f1-race-engineer
cp mcp-toolkit.yml servers/f1-race-engineer/
cp docker-compose.toolkit.yml servers/f1-race-engineer/docker-compose.yml
cp README.md servers/f1-race-engineer/
cp docs/mcp/MCP_QUICKSTART.md servers/f1-race-engineer/QUICKSTART.md
```

### Create Pull Request

```bash
git add servers/f1-race-engineer/
git commit -m "Add F1 Race Engineer MCP server"
git push origin add-f1-race-engineer
```

Then create a PR at: https://github.com/docker/mcp-toolkit/pulls

## Step 5: Create Docker Hub README

### Repository Description

```
F1 Race Engineer MCP Server - AI-powered race engineering for F1 23/24/25 via Pits N Giggles. Provides expert car setup advice, telemetry analysis, and race strategy recommendations.
```

### README.md for Docker Hub

```markdown
# F1 Race Engineer MCP Server

AI-powered race engineering for F1 23/24/25 games. Integrates with Pits N Giggles telemetry to provide professional car setup and strategy advice.

## Quick Start

```bash
# Create .env file
echo "LLM_API_KEY=your-api-key-here" > .env

# Start services
docker-compose up -d
```

## Features

- 🏎️ Real-time F1 telemetry analysis
- 🤖 AI-powered race engineering advice
- 🔧 Car setup recommendations
- 📊 Tyre strategy optimization
- 🎯 Performance gap analysis

## Configuration

Required environment variables:
- `LLM_API_KEY` - API key from OpenRouter, OpenAI, or Anthropic

Optional:
- `LLM_ENDPOINT` - Default: OpenRouter
- `LLM_MODEL` - Default: gpt-4o-mini
- `HTTP_PORT` - Default: 80
- `HTTPS_PORT` - Default: 443

## Endpoints

- Chat API: `POST /api/chat`
- WebSocket: `ws://localhost/api/ws`
- MCP SSE: `GET /mcp/sse`
- Health: `GET /health`

## AI Client Integration

Compatible with:
- ChatGPT Desktop
- Claude Desktop
- Cursor IDE
- Continue.dev

## Documentation

Full documentation: https://github.com/kmransom56/pitsngiggles-mcp-integration

## License

MIT License - See repository for details
```

## Step 6: Publish and Promote

### Docker Hub

1. Go to https://hub.docker.com/
2. Create repository: `f1-race-engineer-mcp`
3. Add README and description
4. Add tags: `f1`, `racing`, `mcp`, `ai`, `telemetry`

### GitHub Release

Create a GitHub release with:
- Version: v1.0.0
- Release notes
- Docker installation instructions
- Link to Docker Hub

### Community

Share on:
- Reddit: /r/simracing, /r/F1Game
- Discord: Pits N Giggles community, MCP servers
- Twitter: Tag @Docker, @OpenAI, sim racing community

## Testing Checklist

Before submitting to Docker Toolkit:

- [ ] Images build successfully
- [ ] Images run without errors
- [ ] Health check passes
- [ ] Chat API responds correctly
- [ ] WebSocket connection works
- [ ] MCP SSE endpoint available
- [ ] Documentation is complete
- [ ] Examples work as documented
- [ ] Environment variables validated
- [ ] Error messages are helpful
- [ ] Logs are informative

## Maintenance

### Version Updates

```bash
# Update version in code
# Build and tag
docker build -f Dockerfile.mcp -t pitsngiggles/f1-race-engineer-mcp:1.1.0 .
docker tag pitsngiggles/f1-race-engineer-mcp:1.1.0 pitsngiggles/f1-race-engineer-mcp:latest

# Push
docker push pitsngiggles/f1-race-engineer-mcp:1.1.0
docker push pitsngiggles/f1-race-engineer-mcp:latest

# Update mcp-toolkit.yml version
# Submit new PR
```

### Security Updates

Monitor for:
- Base image updates (python:3.11-slim, nginx:alpine)
- Dependency vulnerabilities
- Security advisories

## Benefits of Docker Toolkit Integration

1. **Discoverability**: Users can find your MCP server easily
2. **Easy Installation**: One-command deployment
3. **Community**: Join ecosystem of MCP servers
4. **Trust**: Docker verification
5. **Documentation**: Centralized docs
6. **Updates**: Automated update notifications

## Example Docker Toolkit Usage

Once integrated, users can:

```bash
# Install from Docker Toolkit
docker mcp install f1-race-engineer

# Start
docker mcp start f1-race-engineer

# Stop
docker mcp stop f1-race-engineer

# Update
docker mcp update f1-race-engineer
```

---

**Make your F1 Race Engineer accessible to the Docker community! 🐳🏎️**
