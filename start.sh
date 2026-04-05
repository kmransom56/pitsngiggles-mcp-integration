#!/bin/bash
# Pits n' Giggles - One-Command Startup with F1 Race Engineer
# This script starts everything you need: telemetry app + MCP server + nginx reverse proxy

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Pits n' Giggles - F1 Race Engineer Starting...           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is in use
port_in_use() {
    lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1
}

echo -e "${YELLOW}[1/5]${NC} Checking prerequisites..."

# Check Python 3
if ! command_exists python3; then
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.8+${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Python 3 found"

# Check if using uv or pip
if command_exists uv; then
    PYTHON_MANAGER="uv"
    echo -e "${GREEN}✓${NC} uv package manager found (fast mode)"
else
    PYTHON_MANAGER="pip"
    echo -e "${GREEN}✓${NC} pip package manager found"
fi

# Check nginx
if ! command_exists nginx; then
    echo -e "${YELLOW}⚠${NC} nginx not found - MCP will only be available via HTTP (port 4768)"
    echo "  Install nginx for HTTPS access: sudo apt install nginx"
    NGINX_AVAILABLE=false
else
    echo -e "${GREEN}✓${NC} nginx found"
    NGINX_AVAILABLE=true
fi

# Check Node.js (for mcp-remote in Claude Desktop)
if command_exists node; then
    echo -e "${GREEN}✓${NC} Node.js found (v$(node -v))"
else
    echo -e "${YELLOW}⚠${NC} Node.js not found - Claude Desktop integration won't work"
    echo "  Install: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs"
fi

echo ""
echo -e "${YELLOW}[2/5]${NC} Setting up Python environment..."

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install/upgrade dependencies
if [ "$PYTHON_MANAGER" = "uv" ]; then
    echo "Installing dependencies with uv (fast)..."
    uv pip install --upgrade pip
    uv pip install -r requirements.txt
else
    echo "Installing dependencies with pip..."
    python -m pip install --upgrade pip
    pip install -r requirements.txt
fi

echo -e "${GREEN}✓${NC} Dependencies installed"

echo ""
echo -e "${YELLOW}[3/5]${NC} Configuring nginx reverse proxy..."

if [ "$NGINX_AVAILABLE" = true ]; then
    # Check if nginx config exists
    if [ ! -f "/etc/nginx/sites-available/pits-n-giggles-mcp" ]; then
        echo "nginx config not found. Creating..."
        
        # Create nginx config
        sudo tee /etc/nginx/sites-available/pits-n-giggles-mcp > /dev/null << 'NGINX_CONFIG'
server {
    listen 8443 ssl;
    server_name localhost;

    # Self-signed certificate (create if not exists)
    ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location /mcp {
        proxy_pass http://127.0.0.1:4768/mcp;
        proxy_http_version 1.1;
        
        # Server-Sent Events support
        proxy_set_header Connection '';
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 86400s;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
        add_header Access-Control-Allow-Headers 'Content-Type, Authorization';
    }
}
NGINX_CONFIG

        # Create self-signed certificate if it doesn't exist
        if [ ! -f "/etc/nginx/ssl/nginx-selfsigned.crt" ]; then
            echo "Creating self-signed SSL certificate..."
            sudo mkdir -p /etc/nginx/ssl
            sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout /etc/nginx/ssl/nginx-selfsigned.key \
                -out /etc/nginx/ssl/nginx-selfsigned.crt \
                -subj "/C=US/ST=State/L=City/O=PitsNGiggles/CN=localhost"
        fi
        
        # Enable site
        sudo ln -sf /etc/nginx/sites-available/pits-n-giggles-mcp /etc/nginx/sites-enabled/
        
        # Test nginx config
        sudo nginx -t && sudo systemctl reload nginx
        
        echo -e "${GREEN}✓${NC} nginx configured and reloaded"
    else
        echo -e "${GREEN}✓${NC} nginx already configured"
        
        # Make sure nginx is running
        if ! systemctl is-active --quiet nginx; then
            echo "Starting nginx..."
            sudo systemctl start nginx
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping nginx setup (not installed)"
fi

echo ""
echo -e "${YELLOW}[4/5]${NC} Starting Pits n' Giggles backend..."

# Check if app is already running
if port_in_use 4768; then
    echo -e "${YELLOW}⚠${NC} Port 4768 already in use - app may already be running"
    echo "  Kill existing process? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        pkill -f "python.*apps.launcher" || true
        sleep 2
    else
        echo "Keeping existing process"
        SKIP_LAUNCH=true
    fi
fi

if [ "$SKIP_LAUNCH" != true ]; then
    # Start the application in background
    export PYTHONPATH="$SCRIPT_DIR"
    nohup python -O -m apps.launcher > pits-n-giggles.log 2>&1 &
    APP_PID=$!
    echo $APP_PID > .app.pid
    
    # Wait for app to start
    echo "Waiting for backend to start..."
    for i in {1..30}; do
        if port_in_use 4768; then
            echo -e "${GREEN}✓${NC} Backend started (PID: $APP_PID)"
            break
        fi
        sleep 1
        if [ $i -eq 30 ]; then
            echo -e "${RED}✗${NC} Backend failed to start. Check pits-n-giggles.log"
            exit 1
        fi
    done
fi

echo ""
echo -e "${YELLOW}[5/5]${NC} Verifying services..."

# Check HTTP endpoint
if curl -s http://localhost:4768/race-info > /dev/null; then
    echo -e "${GREEN}✓${NC} HTTP telemetry server: http://localhost:4768"
else
    echo -e "${RED}✗${NC} HTTP telemetry server not responding"
fi

# Check MCP endpoint (HTTP)
if curl -s http://localhost:4768/mcp > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MCP server (HTTP): http://localhost:4768/mcp"
else
    echo -e "${YELLOW}⚠${NC} MCP server (HTTP) not responding yet"
fi

# Check MCP endpoint (HTTPS via nginx)
if [ "$NGINX_AVAILABLE" = true ]; then
    if curl -k -s https://localhost:8443/mcp > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} MCP server (HTTPS): https://localhost:8443/mcp"
    else
        echo -e "${YELLOW}⚠${NC} MCP server (HTTPS) not responding"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ✓ Pits n' Giggles is Running!                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "🏎️  Access Points:"
echo "  • Telemetry Dashboard:  http://localhost:4768"
echo "  • Engineer View:        http://localhost:4768/eng-view"
echo "  • F1 Race Engineer:     http://localhost:4768/strategy-center"
echo ""
echo "🤖 AI Integration:"
if [ "$NGINX_AVAILABLE" = true ]; then
    echo "  • MCP Endpoint (HTTPS): https://localhost:8443/mcp"
    echo "  • MCP Endpoint (HTTP):  http://localhost:4768/mcp"
else
    echo "  • MCP Endpoint (HTTP):  http://localhost:4768/mcp"
fi
echo ""
echo "📚 Quick Setup:"
echo "  • ChatGPT Desktop:  Settings → Apps → Create New App → URL: https://localhost:8443/mcp"
echo "  • Claude Desktop:   See docs/AI_CLIENT_SETUP.md"
echo "  • Cursor IDE:       Settings → MCP → Add Server → URL: https://localhost:8443/mcp"
echo ""
echo "📊 Available MCP Tools (10):"
echo "  • get_race_info - Current race status"
echo "  • get_telemetry_data - All drivers data"
echo "  • get_driver_info - Detailed driver analysis"
echo "  • analyze_tyre_strategy - Tyre comparison"
echo "  • get_lap_comparison - Lap time comparison"
echo "  • analyze_lap_time_consistency - Consistency analysis ⭐"
echo "  • diagnose_performance_issues - Issue detection ⭐"
echo "  • compare_to_leader - P1 comparison ⭐"
echo "  • analyze_sector_performance - Sector breakdown ⭐"
echo ""
echo "🎮 Next Steps:"
echo "  1. Start F1 23/24/25 game"
echo "  2. Enter a session (practice, qualifying, or race)"
echo "  3. Open Strategy Center: http://localhost:4768/strategy-center"
echo "  4. Ask AI: 'Analyze my current performance'"
echo ""
echo "📖 Documentation:"
echo "  • Full Guide:         docs/README.md"
echo "  • F1 Agent Setup:     docs/F1_RACE_ENGINEER_QUICK_SETUP.md"
echo "  • AI Client Setup:    docs/AI_CLIENT_SETUP.md"
echo "  • MCP Integration:    docs/MCP_INTEGRATION.md"
echo ""
echo "🛑 To Stop:"
echo "  ./stop.sh"
echo ""
echo "📋 Logs:"
echo "  tail -f pits-n-giggles.log"
echo ""
