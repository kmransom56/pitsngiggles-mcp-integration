# Submitting to Docker's MCP Toolkit

This guide explains how to submit the F1 Race Engineer MCP Server to Docker's MCP Toolkit for wider community access.

---

## About Docker's MCP Toolkit

Docker's MCP (Model Context Protocol) Toolkit is a curated collection of MCP servers that can be easily discovered and deployed through Docker Desktop. By submitting to the toolkit, users can:

- Discover the F1 Race Engineer through Docker Desktop's GUI
- Deploy with one click
- Benefit from standardized Docker best practices
- Access community-maintained MCP servers

**Repository:** https://github.com/docker/mcp-toolkit

---

## Prerequisites

Before submitting, ensure:

1. ✅ **Working Docker images** - Tested and verified
2. ✅ **Public Docker Hub registry** - Images published
3. ✅ **Complete documentation** - README with clear instructions
4. ✅ **Health checks implemented** - Container health monitoring
5. ✅ **Example configurations** - Sample `.env` files
6. ✅ **License compliance** - Open source compatible

---

## Preparation Steps

### 1. Publish Docker Images to Docker Hub

```bash
# Login to Docker Hub
docker login

# Tag images
docker tag f1-race-engineer-mcp:latest yourusername/f1-race-engineer-mcp:latest
docker tag f1-race-engineer-mcp:latest yourusername/f1-race-engineer-mcp:v1.0.0

# Push to Docker Hub
docker push yourusername/f1-race-engineer-mcp:latest
docker push yourusername/f1-race-engineer-mcp:v1.0.0
```

### 2. Create MCP Toolkit Manifest

Create `mcp-toolkit.json`:

```json
{
  "name": "f1-race-engineer",
  "version": "1.0.0",
  "displayName": "F1 Race Engineer",
  "description": "AI-powered race engineering analysis for F1 telemetry data. Provides setup recommendations, performance analysis, and strategic advice.",
  "author": {
    "name": "Pits N Giggles Contributors",
    "url": "https://github.com/ashwin-nat/pits-n-giggles"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/ashwin-nat/pits-n-giggles"
  },
  "license": "MIT",
  "category": "sports",
  "tags": [
    "f1",
    "formula-1",
    "racing",
    "telemetry",
    "ai",
    "race-engineer",
    "setup-optimization",
    "motorsport"
  ],
  "docker": {
    "image": "yourusername/f1-race-engineer-mcp",
    "tag": "latest",
    "ports": {
      "8765": "MCP Server API",
      "80": "Web Interface (via Nginx)",
      "443": "HTTPS Interface (via Nginx)"
    },
    "environment": {
      "LLM_ENDPOINT": {
        "description": "LLM API endpoint (OpenRouter, OpenAI, etc.)",
        "default": "https://openrouter.ai/api/v1/chat/completions",
        "required": false
      },
      "LLM_API_KEY": {
        "description": "API key for LLM service",
        "required": false,
        "secret": true
      },
      "LLM_MODEL": {
        "description": "LLM model to use",
        "default": "openai/gpt-4o-mini",
        "required": false
      },
      "MCP_PORT": {
        "description": "MCP server port",
        "default": "8765",
        "required": false
      },
      "HTTP_PORT": {
        "description": "HTTP port for web interface",
        "default": "80",
        "required": false
      },
      "HTTPS_PORT": {
        "description": "HTTPS port for web interface",
        "default": "443",
        "required": false
      }
    },
    "volumes": {
      "/app/data": "Persistent data storage for telemetry history"
    },
    "healthCheck": {
      "test": "curl -f http://localhost:8765/health || exit 1",
      "interval": "30s",
      "timeout": "10s",
      "retries": 3
    }
  },
  "capabilities": {
    "mcp": {
      "protocol": "sse",
      "endpoint": "/telemetry/mcp",
      "endpoint_note": "SSE is served by Pits N Giggles at GET /mcp on host :4768; nginx maps https://host:9443/telemetry/ to PNG. Docker mcp_server uses HTTP+WS only (POST /mcp/chat, WS /mcp/ws on :8765).",
      "tools": [
        {
          "name": "get_telemetry_data",
          "description": "Get live race telemetry and standings"
        },
        {
          "name": "get_race_info",
          "description": "Get session information and weather conditions"
        },
        {
          "name": "get_driver_info",
          "description": "Get detailed driver information"
        },
        {
          "name": "get_lap_comparison",
          "description": "Compare lap times between drivers"
        },
        {
          "name": "analyze_tyre_strategy",
          "description": "Analyze tire degradation and strategy"
        },
        {
          "name": "diagnose_performance_issues",
          "description": "Diagnose car setup and performance issues"
        },
        {
          "name": "analyze_sector_performance",
          "description": "Analyze sector-by-sector performance"
        },
        {
          "name": "compare_to_leader",
          "description": "Compare performance to race leader"
        },
        {
          "name": "get_stream_overlay_data",
          "description": "Get data for streaming overlays"
        },
        {
          "name": "analyze_lap_time_consistency",
          "description": "Analyze lap time consistency"
        }
      ]
    },
    "web": {
      "enabled": true,
      "interfaces": [
        {
          "name": "Strategy Center",
          "path": "/strategy-center",
          "description": "AI-powered race strategy chat interface"
        },
        {
          "name": "Voice Strategy Center",
          "path": "/voice-strategy-center",
          "description": "Voice-enabled race strategy interface"
        },
        {
          "name": "Engineer Dashboard",
          "path": "/eng-view",
          "description": "Classic telemetry dashboard"
        }
      ]
    }
  },
  "requirements": {
    "external": [
      {
        "name": "F1 23/24/25 Game",
        "description": "F1 game with UDP telemetry enabled",
        "required": true
      },
      {
        "name": "Pits N Giggles",
        "description": "Telemetry server running on host (port 4768)",
        "required": true,
        "url": "https://github.com/ashwin-nat/pits-n-giggles"
      }
    ],
    "optional": [
      {
        "name": "LLM API Key",
        "description": "OpenRouter, OpenAI, or compatible API key for AI responses",
        "url": "https://openrouter.ai/keys"
      }
    ]
  },
  "documentation": {
    "readme": "https://github.com/ashwin-nat/pits-n-giggles/blob/main/README.md",
    "quickstart": "https://github.com/ashwin-nat/pits-n-giggles/blob/main/docs/DOCKER_QUICKSTART.md",
    "mcp": "https://github.com/ashwin-nat/pits-n-giggles/blob/main/docs/MCP_INTEGRATION.md",
    "voice": "https://github.com/ashwin-nat/pits-n-giggles/blob/main/docs/VOICE_INTEGRATION.md"
  }
}
```

### 3. Update Documentation

Ensure all documentation is current and references Docker Hub images:

```markdown
# Quick Start with Docker

```bash
docker pull yourusername/f1-race-engineer-mcp:latest
docker-compose up -d
```

Access at: http://localhost/strategy-center
```

### 4. Create Detailed README for Docker Hub

Create `DOCKER_README.md`:

```markdown
# F1 Race Engineer MCP Server

AI-powered race engineering analysis for F1 telemetry. Professional setup recommendations, performance analysis, and strategic advice.

## Quick Start

```bash
docker run -d \
  -p 8765:8765 \
  -e LLM_API_KEY=your_key_here \
  yourusername/f1-race-engineer-mcp:latest
```

## Features

- 🏎️ **10 Specialized MCP Tools** - Telemetry analysis
- 🤖 **AI Race Engineer** - Setup and strategy advice
- 🎙️ **Voice Interface** - Speech-to-text/text-to-speech
- 📊 **Web Dashboard** - Real-time telemetry views
- 🔌 **AI Client Integration** - ChatGPT, Claude, Cursor

## Full Documentation

https://github.com/ashwin-nat/pits-n-giggles
```

---

## Submission Process

### 1. Fork Docker MCP Toolkit Repository

```bash
git clone https://github.com/docker/mcp-toolkit.git
cd mcp-toolkit
git checkout -b add-f1-race-engineer
```

### 2. Add Your MCP Server

```bash
mkdir -p servers/f1-race-engineer
cp mcp-toolkit.json servers/f1-race-engineer/
cp -r docs/ servers/f1-race-engineer/docs/
cp docker-compose.mcp.yml servers/f1-race-engineer/docker-compose.yml
```

### 3. Create Pull Request

```bash
git add servers/f1-race-engineer/
git commit -m "Add F1 Race Engineer MCP Server

Professional F1 telemetry analysis and race engineering AI.

Features:
- 10 specialized MCP tools
- AI-powered setup recommendations  
- Voice interface support
- Real-time telemetry integration
- Multi-LLM support (OpenRouter, OpenAI, Claude)
"

git push origin add-f1-race-engineer
```

### 4. Submit PR on GitHub

1. Go to https://github.com/docker/mcp-toolkit
2. Create Pull Request from your fork
3. Fill out PR template
4. Wait for review

---

## PR Template Content

```markdown
## MCP Server Name
F1 Race Engineer

## Description
AI-powered race engineering analysis for F1 telemetry data. Provides professional setup recommendations, performance analysis, and strategic advice based on live game data.

## Category
Sports / Gaming / AI

## Key Features
- 10 specialized MCP tools for telemetry analysis
- AI race engineer with setup optimization
- Voice interface (speech-to-text/text-to-speech)
- Real-time telemetry integration
- Multi-LLM support (OpenRouter, OpenAI, Anthropic)
- Web dashboard and strategy center
- Integration with F1 23/24/25 games

## Docker Images
- `yourusername/f1-race-engineer-mcp:latest`
- `yourusername/f1-race-engineer-nginx:latest`

## Documentation
- Main README: https://github.com/ashwin-nat/pits-n-giggles
- Docker Quick Start: https://github.com/ashwin-nat/pits-n-giggles/blob/main/docs/DOCKER_QUICKSTART.md
- MCP Integration: https://github.com/ashwin-nat/pits-n-giggles/blob/main/docs/MCP_INTEGRATION.md

## Testing
- ✅ Docker Compose deployment tested
- ✅ Health checks working
- ✅ MCP SSE endpoint verified
- ✅ All 10 tools functional
- ✅ Voice interface tested (Chrome/Edge)
- ✅ AI client integration verified (ChatGPT, Claude)

## External Requirements
- F1 23/24/25 game with UDP telemetry enabled
- Pits N Giggles telemetry server (included or host-based)
- Optional: LLM API key for AI responses

## License
MIT (same as Pits N Giggles)

## Maintainer
@ashwin-nat (Pits N Giggles maintainer)
```

---

## Review Checklist

Before submitting, verify:

- [ ] Docker images published to Docker Hub
- [ ] Images are multi-arch (amd64, arm64) if possible
- [ ] Health checks return 200 OK
- [ ] All environment variables documented
- [ ] Volume mounts documented
- [ ] Port mappings clear
- [ ] README includes quick start
- [ ] Screenshots/demos included
- [ ] License file present
- [ ] Security best practices followed
- [ ] No hardcoded secrets
- [ ] Logs go to stdout/stderr
- [ ] Graceful shutdown on SIGTERM
- [ ] Resource limits reasonable
- [ ] Documentation links valid

---

## Publishing Multi-Architecture Images

For better compatibility, build for multiple architectures:

```bash
# Enable buildx
docker buildx create --use

# Build and push multi-arch
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t yourusername/f1-race-engineer-mcp:latest \
  -t yourusername/f1-race-engineer-mcp:v1.0.0 \
  --push \
  -f Dockerfile.mcp .
```

---

## Post-Submission

### Monitor PR Review

- Respond to reviewer comments promptly
- Make requested changes
- Test suggested improvements
- Update documentation as needed

### After Merge

- Update your README with Docker Toolkit badge
- Announce on social media / community
- Monitor Docker Hub stats
- Respond to issues on GitHub
- Keep images updated

### Maintenance

- Regular security updates
- Dependency updates
- Bug fixes
- Feature enhancements
- Documentation improvements

---

## Docker Hub Registry Setup

### Create Repository

1. Go to https://hub.docker.com
2. Create new repository: `f1-race-engineer-mcp`
3. Set to **Public**
4. Add description
5. Link to GitHub repository

### Repository Description

```
F1 Race Engineer MCP Server - AI-powered telemetry analysis and race engineering for F1 games.

Features:
- 10 specialized MCP tools
- AI setup recommendations
- Voice interface
- Real-time telemetry
- ChatGPT/Claude integration

Docs: https://github.com/ashwin-nat/pits-n-giggles
```

### Add README to Docker Hub

Use the `DOCKER_README.md` content on Docker Hub's Overview tab.

---

## Alternative: GitHub Container Registry

Instead of Docker Hub, you can use GitHub Container Registry:

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Tag and push
docker tag f1-race-engineer-mcp:latest ghcr.io/ashwin-nat/f1-race-engineer-mcp:latest
docker push ghcr.io/ashwin-nat/f1-race-engineer-mcp:latest
```

Update `mcp-toolkit.json`:
```json
{
  "docker": {
    "image": "ghcr.io/ashwin-nat/f1-race-engineer-mcp",
    "tag": "latest"
  }
}
```

---

## Best Practices

### Image Size Optimization

```dockerfile
# Use multi-stage builds
FROM python:3.11-slim as builder
RUN pip install --user ...

FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Security

- Don't include API keys in image
- Use non-root user
- Scan for vulnerabilities
- Keep dependencies updated
- Use official base images

### Documentation

- Clear quick start
- Environment variable docs
- Volume explanations
- Port documentation
- Troubleshooting section
- Examples and use cases

---

## Community Promotion

After acceptance into MCP Toolkit:

1. **Blog Post** - Write about the integration
2. **Reddit** - Share on r/formula1, r/simracing
3. **Twitter/X** - Announce with demo video
4. **Discord** - F1 gaming communities
5. **YouTube** - Tutorial video
6. **Dev.to** - Technical write-up

---

## Resources

- **Docker MCP Toolkit**: https://github.com/docker/mcp-toolkit
- **MCP Specification**: https://modelcontextprotocol.io
- **Docker Hub**: https://hub.docker.com
- **Pits N Giggles**: https://github.com/ashwin-nat/pits-n-giggles

---

## Support

For questions about submission:
- Docker MCP Toolkit Issues: https://github.com/docker/mcp-toolkit/issues
- Pits N Giggles Discussions: https://github.com/ashwin-nat/pits-n-giggles/discussions

**Good luck with your submission! 🏎️🐳**
