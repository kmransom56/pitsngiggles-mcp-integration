# Pits n' Giggles - Complete Deployment Guide

## 🎯 Overview

This guide covers deploying the full Pits n' Giggles F1 Race Engineer system with MCP integration, AI capabilities, and voice features.

## 🚀 Quick Start (Recommended)

The easiest way to get started:

```bash
git clone https://github.com/kmransom56/pitsngiggles-mcp-integration.git
cd pitsngiggles-mcp-integration
./start-auto.sh
```

Then open http://localhost:4768/strategy-center in your browser!

## 📋 Prerequisites

### Required
- **Python 3.9+** - For backend server
- **F1 23/24/25 Game** - For telemetry data
- **Modern Web Browser** - Chrome, Firefox, or Edge

### Optional (Recommended)
- **Docker** - For containerized MCP server deployment
- **nginx** - For HTTPS reverse proxy
- **uv** - Fast Python package installer (optional, speeds up installation)

## 🛠️ Installation Methods

### Method 1: Automatic (Recommended)

```bash
./start-auto.sh
```

This will:
- ✅ Install all dependencies automatically
- ✅ Start the backend server
- ✅ Serve all web interfaces
- ✅ Display access URLs

### Method 2: Interactive

```bash
./start.sh
```

You'll be prompted to:
- Choose whether to start MCP server
- Configure AI API keys (optional)
- Select Docker or native mode

### Method 3: Docker Compose

```bash
docker-compose -f docker-compose.yml up -d
```

Includes:
- Backend server
- MCP server
- nginx reverse proxy
- SSL certificates

## 🌐 Access Points

After deployment, access these URLs:

| Interface | URL | Description |
|-----------|-----|-------------|
| **Main Dashboard** | http://localhost:4768 | Driver view with real-time telemetry |
| **Engineer View** | http://localhost:4768/eng-view | Detailed engineering telemetry |
| **Strategy Center** | http://localhost:4768/strategy-center | AI chat interface |
| **Voice Strategy** | http://localhost:4768/voice-strategy-center | Voice-enabled AI interface |

## 🎮 F1 Game Configuration

### In-Game Settings

1. Open F1 23/24/25
2. Navigate to: **Settings → Telemetry Settings**
3. Configure:
   - **UDP Telemetry**: ON
   - **UDP Broadcast Mode**: OFF  
   - **UDP Port**: 20777
   - **UDP IP Address**: 127.0.0.1 (localhost)
   - **UDP Send Rate**: 60Hz (recommended)

### Start Racing!

1. Start any session (Practice, Qualifying, Race)
2. The telemetry will automatically stream to Pits n' Giggles
3. Open Strategy Center to interact with the AI Race Engineer

## 🤖 AI Configuration

### Built-in Race Engineer (No API Key Required)

The system includes intelligent telemetry analysis that works without any AI API:

- Automatic tyre temperature analysis
- Wear prediction and pit strategy
- Handling diagnostics (understeer/oversteer)
- Setup recommendations

### Advanced AI Integration (Optional)

For enhanced AI capabilities, configure an API key:

#### Option 1: OpenRouter (Recommended)

```bash
# Edit .env.mcp
LLM_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
LLM_API_KEY=your_openrouter_key_here
```

Get your key: https://openrouter.ai/keys

#### Option 2: OpenAI

```bash
# Edit .env.mcp
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
LLM_API_KEY=sk-your_openai_key_here
```

Get your key: https://platform.openai.com/api-keys

#### Option 3: ChatGPT Desktop (MCP Integration)

The MCP server allows ChatGPT Desktop to directly query telemetry:

1. Open ChatGPT Desktop
2. Go to Settings → Custom Instructions
3. Add the MCP server endpoint
4. ChatGPT can now analyze your F1 telemetry in real-time!

See `docs/AI_CLIENT_SETUP.md` for detailed configuration.

## 🎙️ Voice Features

### Speech-to-Text (STT)

**Browser-based** - Uses Web Speech API (Chrome/Edge recommended)

- **Push-to-Talk**: Press and hold spacebar or click the mic button
- **Works Offline**: All processing happens in your browser
- **Zero Cost**: No API keys needed

### Text-to-Speech (TTS)

**Browser-based** - Uses Web Speech API

- **Automatic**: AI responses are spoken automatically
- **Adjustable**: Control voice, speed, and pitch
- **Privacy**: No data sent to external servers

### Usage

1. Open http://localhost:4768/voice-strategy-center
2. Click microphone icon or press spacebar
3. Speak your question
4. Listen to the AI response

## 🔧 Advanced Configuration

### Custom Port

Edit `png_config.json`:

```json
{
  "Network": {
    "server_port": 4768
  }
}
```

### HTTPS/SSL Setup

For production deployment with real SSL certificates:

```bash
# Generate certificate
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -days 365

# Or use Let's Encrypt
sudo certbot certonly --standalone -d yourdomain.com
```

Update `.env.mcp`:

```bash
SSL_CERT_PATH=/path/to/fullchain.pem
SSL_KEY_PATH=/path/to/privkey.pem
```

### nginx Reverse Proxy

For production with nginx:

```bash
sudo cp nginx/pitsngiggles.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/pitsngiggles.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Access via: https://yourdomain.com

## 🐳 Docker Deployment

### Full Stack with Docker Compose

```bash
docker-compose -f docker-compose.complete.yml up -d
```

This includes:
- Pits n' Giggles backend
- MCP server with AI
- nginx with SSL
- Automatic health checks

### MCP Server Only

```bash
docker-compose -f docker-compose.mcp.yml up -d
```

### Custom Docker Build

```bash
docker build -f Dockerfile.complete -t pitsngiggles:latest .
docker run -p 4768:4768 -p 8765:8765 pitsngiggles:latest
```

## 🔍 Troubleshooting

### Application Won't Start

```bash
# Check Python version
python3 --version  # Should be 3.9+

# Check port availability
lsof -i :4768

# Check logs
tail -f /tmp/startup_log.txt
```

### No Telemetry Data

1. **Check F1 Game Settings**: UDP must be ON, port 20777
2. **Check Firewall**: Allow UDP port 20777
3. **Check Console**: Look for connection messages in browser console

### AI Not Responding

```bash
# Test MCP endpoint
curl http://localhost:4768/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "test", "telemetry": null}'

# Check AI API key (if using external AI)
cat .env.mcp | grep LLM_API_KEY
```

### Voice Not Working

1. **Use Chrome or Edge** - Best Web Speech API support
2. **Grant Microphone Permission** - Check browser permissions
3. **Check HTTPS** - Some browsers require HTTPS for mic access
4. **Test in Console**: `window.speechSynthesis.speak(new SpeechSynthesisUtterance("test"))`

### Permission Errors

```bash
# Fix cache permissions
chmod -R 755 ~/.cache/uv
chmod -R 755 ~/.cache/pip

# Or run with sudo (not recommended)
sudo ./start.sh
```

## 🛑 Stopping the Application

```bash
./stop.sh
```

To also stop nginx:

```bash
sudo systemctl stop nginx
```

To stop Docker containers:

```bash
docker-compose down
```

## 📚 Additional Resources

- **Main README**: `README.md` - Project overview
- **Building Guide**: `docs/BUILDING.md` - Development setup
- **AI Setup**: `docs/AI_CLIENT_SETUP.md` - AI client configuration
- **F1 Agent Guide**: `docs/F1_AI_RACE_ENGINEER.md` - Race engineer details
- **Voice Integration**: `docs/VOICE_INTEGRATION.md` - Voice feature details

## 🎯 What's Next?

After successful deployment:

1. ✅ **Test with Sample Data** - Strategy Center shows sample telemetry
2. ✅ **Start F1 Game** - Configure UDP telemetry (port 20777)
3. ✅ **Try Voice Interface** - Open voice-strategy-center page
4. ✅ **Ask AI Questions** - "Fix my understeer", "When should I pit?"
5. ✅ **Configure External AI** - Add API keys for GPT-4/Claude
6. ✅ **Connect ChatGPT Desktop** - Enable MCP integration

## 💡 Tips

- **Quick Test**: Use Strategy Center even without game running to see the interface
- **Voice Quality**: Chrome has the best Web Speech API support
- **Performance**: Use `./start-auto.sh` for fastest startup
- **AI Modes**: Switch between modes in console: `switchAIMode("mcp_chat")`
- **Update**: Pull latest changes: `git pull origin feature/f1-race-engineer-mcp`

## 🤝 Contributing

Found a bug? Have a feature request?

1. Check existing issues: https://github.com/kmransom56/pitsngiggles-mcp-integration/issues
2. Create new issue with details
3. Submit pull request with fixes

## 📝 License

MIT License - see LICENSE file for details

## 🏁 Happy Racing!

Questions? Open an issue or check the docs folder for more guides.
