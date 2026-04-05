#!/bin/bash
# Pits n' Giggles Non-Interactive Startup Script
# For automated deployments and CI/CD

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "🏁 Pits N Giggles - Automated Deployment"
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.12+"
    exit 1
fi

# Create venv if needed
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Install dependencies
echo "Installing dependencies..."
.venv/bin/pip install --quiet --upgrade pip setuptools wheel
.venv/bin/pip install --quiet jinja2 python-socketio quart gevent psutil pydantic \
    uvicorn msgpack pyzmq requests aiohttp websocket-client markdown orjson

# Install MCP server dependencies
if [ -f "mcp_server/requirements.txt" ]; then
    .venv/bin/pip install --quiet -r mcp_server/requirements.txt
fi

# Start backend
echo "Starting Pits N Giggles backend..."
PYTHONPATH="${PWD}:${PYTHONPATH}" .venv/bin/python -m apps.backend &
BACKEND_PID=$!
echo $BACKEND_PID > .backend.pid

# Wait for backend to initialize
sleep 3

echo ""
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "📍 Access Points:"
echo "   • Main App:         http://localhost:4768"
echo "   • Driver View:      http://localhost:4768/"
echo "   • Engineer View:    http://localhost:4768/eng-view"
echo "   • Strategy Center:  http://localhost:4768/strategy-center"
echo "   • Voice Center:     http://localhost:4768/voice-strategy-center"
echo ""
echo "🎮 F1 Game Setup:"
echo "   Settings → Telemetry → UDP Port: 20777, IP: 127.0.0.1"
echo ""
echo "🛑 To stop: ./stop.sh"
echo ""
