#!/bin/bash
# Pits n' Giggles Unified Startup Script
# Starts both the main application and optional MCP server

set -e

# Colors and symbols
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
CHECK="✓"
CROSS="✗"
ARROW="→"

# Banner
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Pits n' Giggles - F1 Race Engineer Starting...           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="Windows"
else
    OS="Unknown"
fi

echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo -e "${GREEN}${CHECK} Python 3 found${NC} (${PYTHON_VERSION})"
else
    echo -e "${RED}${CROSS} Python 3 not found${NC}"
    echo "Please install Python 3.9 or higher"
    exit 1
fi

# Check uv package manager (optional but faster)
if command -v uv &> /dev/null; then
    echo -e "${GREEN}${CHECK} uv package manager found${NC} (fast mode)"
    USE_UV=true
else
    echo -e "${YELLOW}${ARROW} uv not found, using pip${NC} (slower)"
    USE_UV=false
fi

# Check nginx (for MCP)
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}${CHECK} nginx found${NC}"
    NGINX_AVAILABLE=true
else
    echo -e "${YELLOW}${ARROW} nginx not found${NC} (MCP HTTPS will be unavailable)"
    NGINX_AVAILABLE=false
fi

# Check Node.js (for frontend builds)
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>&1)
    echo -e "${GREEN}${CHECK} Node.js found${NC} (${NODE_VERSION})"
else
    echo -e "${YELLOW}${ARROW} Node.js not found${NC} (optional)"
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}${CHECK} Docker found${NC}"
    DOCKER_AVAILABLE=true
else
    echo -e "${YELLOW}${ARROW} Docker not found${NC} (MCP Docker mode unavailable)"
    DOCKER_AVAILABLE=false
fi

echo ""
echo -e "${BLUE}[2/5] Setting up Python environment...${NC}"

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
if [ "$USE_UV" = true ]; then
    # Fix uv cache permissions if needed
    UVCACHE="$HOME/.cache/uv"
    if [ -d "$UVCACHE" ]; then
        chmod -R 755 "$UVCACHE" 2>/dev/null || true
    else
        mkdir -p "$UVCACHE" 2>/dev/null || true
    fi
    
    # Install using uv with better error handling
    echo "Installing with uv (fast mode)..."
    if [ -f "requirements.txt" ]; then
        uv pip install -r requirements.txt 2>/dev/null || .venv/bin/pip install -q -r requirements.txt || true
    fi
    
    # Install main dependencies
    uv pip install jinja2 python-socketio quart gevent psutil pydantic uvicorn msgpack pyzmq requests aiohttp websocket-client markdown orjson 2>/dev/null || .venv/bin/pip install -q jinja2 python-socketio quart gevent psutil pydantic uvicorn msgpack pyzmq requests aiohttp websocket-client markdown orjson 2>/dev/null || echo "Main dependencies already installed"
    
    # Install MCP server dependencies
    if [ -f "mcp_server/requirements.txt" ]; then
        uv pip install -r mcp_server/requirements.txt 2>/dev/null || .venv/bin/pip install -q -r mcp_server/requirements.txt 2>/dev/null || echo "MCP dependencies already installed"
    fi
else
    # Fallback to pip
    echo "Installing with pip..."
    if [ -f "requirements.txt" ]; then
        .venv/bin/pip install -q -r requirements.txt 2>/dev/null || true
    fi
    .venv/bin/pip install -q jinja2 python-socketio quart gevent psutil pydantic uvicorn msgpack pyzmq requests aiohttp websocket-client markdown orjson 2>/dev/null || echo "Main dependencies already installed"
    if [ -f "mcp_server/requirements.txt" ]; then
        .venv/bin/pip install -q -r mcp_server/requirements.txt 2>/dev/null || echo "MCP dependencies already installed"
    fi
fi

echo -e "${GREEN}${CHECK} Dependencies installed${NC}"

echo ""
echo -e "${BLUE}[3/5] Checking MCP configuration...${NC}"

# Ask about MCP server
echo ""
echo "Do you want to start the MCP server (F1 AI Race Engineer)?"
echo "  - Enables AI chat in Strategy Center"
echo "  - Allows ChatGPT/Claude to analyze telemetry"
echo "  - Includes voice features (speech-to-text, text-to-speech)"
echo ""
read -p "Start MCP server? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    START_MCP=true
    
    # Check if .env.mcp exists
    if [ ! -f .env.mcp ]; then
        echo -e "${YELLOW}Creating .env.mcp from example...${NC}"
        cp .env.mcp.example .env.mcp
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}MCP Server Configuration Needed${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "For full AI functionality, you need an LLM API key."
        echo ""
        echo "Options:"
        echo "  1. OpenRouter (recommended) - https://openrouter.ai/keys"
        echo "     - Access to multiple models (GPT-4, Claude, etc.)"
        echo "     - Free tier available"
        echo ""
        echo "  2. OpenAI - https://platform.openai.com/api-keys"
        echo "     - Direct GPT-4 access"
        echo "     - Pay-per-use"
        echo ""
        echo "  3. Skip for now - Basic telemetry analysis only"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Do you have an API key to configure now? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            read -p "Enter your API key: " API_KEY
            
            # Update .env.mcp with the API key
            sed -i "s/LLM_API_KEY=your_api_key_here/LLM_API_KEY=${API_KEY}/" .env.mcp
            
            echo -e "${GREEN}${CHECK} API key configured${NC}"
        else
            echo -e "${YELLOW}${ARROW} Skipping API key configuration${NC}"
            echo "   MCP server will run with telemetry analysis only"
            echo "   Edit .env.mcp later to add your API key"
        fi
    fi
    
    # Choose Docker or native mode
    if [ "$DOCKER_AVAILABLE" = true ]; then
        echo ""
        read -p "Run MCP in Docker? (recommended) (Y/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            MCP_MODE="docker"
        else
            MCP_MODE="native"
        fi
    else
        MCP_MODE="native"
    fi
else
    START_MCP=false
fi

echo ""
echo -e "${BLUE}[4/5] Starting services...${NC}"

# Start main Pits n' Giggles application
echo "Starting Pits n' Giggles backend..."
PYTHONPATH="${PWD}:${PYTHONPATH}" .venv/bin/python -m apps.backend &
BACKEND_PID=$!
echo -e "${GREEN}${CHECK} Backend started (PID: ${BACKEND_PID})${NC}"

# Wait a moment for backend to initialize
sleep 2

# Start MCP server if requested
if [ "$START_MCP" = true ]; then
    echo ""
    echo "Starting MCP server (${MCP_MODE} mode)..."
    
    if [ "$MCP_MODE" = "docker" ]; then
        # Generate SSL certificate if needed
        if [ ! -f ssl/cert.pem ]; then
            echo "Generating self-signed SSL certificate..."
            mkdir -p ssl
            openssl req -x509 -newkey rsa:4096 -nodes \
                -keyout ssl/key.pem \
                -out ssl/cert.pem \
                -days 365 \
                -subj "/C=US/ST=State/L=City/O=PitsNGiggles/CN=localhost" 2>/dev/null
        fi
        
        # Start with Docker Compose
        docker-compose -f docker-compose.mcp.yml --env-file .env.mcp up -d
        echo -e "${GREEN}${CHECK} MCP server started (Docker)${NC}"
    else
        # Start MCP server natively
        source .env.mcp 2>/dev/null || true
        cd mcp_server && ../.venv/bin/python server.py &
        MCP_PID=$!
        cd ..
        echo -e "${GREEN}${CHECK} MCP server started (PID: ${MCP_PID})${NC}"
    fi
fi

echo ""
echo -e "${BLUE}[5/5] Initialization complete!${NC}"

# Display access information
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                     🏎️  Ready to Race!                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Main Application:${NC}"
echo "  ${ARROW} Web UI: http://localhost:4768"
echo "  ${ARROW} Driver View: http://localhost:4768/"
echo "  ${ARROW} Engineer View: http://localhost:4768/eng-view"
echo ""

if [ "$START_MCP" = true ]; then
    echo -e "${GREEN}Strategy Center (AI):${NC}"
    echo "  ${ARROW} Strategy Center: http://localhost:4768/strategy-center"
    echo "  ${ARROW} Voice Strategy: http://localhost:4768/voice-strategy-center"
    echo ""
    
    if [ "$MCP_MODE" = "docker" ]; then
        echo -e "${GREEN}MCP Server:${NC}"
        echo "  ${ARROW} MCP API: http://localhost:80/api/chat"
        echo "  ${ARROW} MCP WebSocket: ws://localhost:80/api/ws"
        echo "  ${ARROW} MCP SSE (AI Clients): http://localhost:80/mcp/sse"
        echo "  ${ARROW} Health Check: http://localhost:80/health"
        if [ "$NGINX_AVAILABLE" = true ]; then
            echo "  ${ARROW} HTTPS: https://localhost:443"
        fi
    else
        echo -e "${GREEN}MCP Server:${NC}"
        echo "  ${ARROW} MCP API: http://localhost:8765/api/chat"
        echo "  ${ARROW} MCP WebSocket: ws://localhost:8765/api/ws"
        echo "  ${ARROW} Health Check: http://localhost:8765/health"
    fi
    echo ""
fi

echo -e "${YELLOW}Voice Features:${NC}"
echo "  🎙️  Speech-to-Text: Built-in (browser-based)"
echo "  🔊 Text-to-Speech: Built-in (browser-based)"
echo "  ⚙️  Push-to-Talk: Space key or microphone button"
echo "  ${ARROW} Open Voice Strategy Center to use voice features"
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Launch F1 23/24/25 and start a session"
echo "  2. Configure UDP telemetry to localhost:20777"
echo "  3. Open http://localhost:4768/voice-strategy-center"
echo "  4. Talk to your AI race engineer!"
echo ""

if [ "$START_MCP" = true ]; then
    echo -e "${CYAN}AI Client Setup:${NC}"
    echo "  ${ARROW} ChatGPT Desktop: See docs/AI_CLIENT_SETUP.md"
    echo "  ${ARROW} Claude Desktop: See docs/AI_CLIENT_SETUP.md"
    echo "  ${ARROW} API Endpoint: http://localhost/mcp/sse"
    echo ""
fi

echo -e "${YELLOW}Documentation:${NC}"
echo "  ${ARROW} Building: docs/BUILDING.md"
echo "  ${ARROW} Voice Guide: docs/VOICE_INTEGRATION.md"
echo "  ${ARROW} F1 Agent: docs/F1_RACE_ENGINEER_AGENT.md"
if [ "$MCP_MODE" = "docker" ]; then
    echo "  ${ARROW} Docker Quick Start: docs/DOCKER_QUICKSTART.md"
fi
echo ""

echo -e "${RED}To Stop:${NC}"
if [ "$START_MCP" = true ] && [ "$MCP_MODE" = "docker" ]; then
    echo "  ./stop.sh && docker-compose -f docker-compose.mcp.yml down"
else
    echo "  ./stop.sh"
fi
echo ""

# Save PIDs for cleanup
echo $BACKEND_PID > .backend.pid
if [ "$START_MCP" = true ] && [ "$MCP_MODE" = "native" ]; then
    echo $MCP_PID > .mcp.pid
fi

echo -e "${GREEN}All systems operational. Happy racing! 🏁${NC}"
echo ""
