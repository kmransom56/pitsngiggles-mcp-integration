#!/bin/bash
# Start F1 Race Engineer MCP Server

set -e

echo "🏎️  Starting F1 Race Engineer MCP Server..."

# Check if .env.mcp exists
if [ ! -f .env.mcp ]; then
    echo "⚠️  No .env.mcp file found. Creating from example..."
    cp .env.mcp.example .env.mcp
    echo "⚠️  Please edit .env.mcp and configure your LLM API key!"
    echo "   - Get an OpenRouter API key from: https://openrouter.ai/keys"
    echo "   - Or use OpenAI, Anthropic, or other compatible APIs"
    read -p "Press Enter after configuring .env.mcp to continue..."
fi

# Generate self-signed SSL certificate if it doesn't exist
if [ ! -f ssl/cert.pem ]; then
    echo "🔐 Generating self-signed SSL certificate..."
    mkdir -p ssl
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -days 365 \
        -subj "/C=US/ST=State/L=City/O=PitsNGiggles/CN=localhost"
    echo "✅ SSL certificate generated"
fi

# Load environment variables
export $(cat .env.mcp | grep -v '^#' | xargs)

# Start Docker Compose
echo "🚀 Starting services..."
docker-compose -f docker-compose.mcp.yml --env-file .env.mcp up -d

echo ""
echo "✅ F1 Race Engineer MCP Server is running!"
echo ""
echo "📍 Access Points:"
echo "   - MCP Server: http://localhost:${MCP_PORT:-8765}"
echo "   - Nginx Proxy: http://localhost:${HTTP_PORT:-80}"
echo "   - HTTPS: https://localhost:${HTTPS_PORT:-443}"
echo ""
echo "🔧 API Endpoints:"
echo "   - Chat API: http://localhost:${HTTP_PORT:-80}/api/chat"
echo "   - WebSocket: ws://localhost:${HTTP_PORT:-80}/api/ws"
echo "   - MCP SSE (for AI clients): http://localhost:${HTTP_PORT:-80}/mcp/sse"
echo "   - Health Check: http://localhost:${HTTP_PORT:-80}/health"
echo ""
echo "📖 Next Steps:"
echo "   1. Start Pits N Giggles on the host (or uncomment in docker-compose.mcp.yml)"
echo "   2. Open Strategy Center in your browser"
echo "   3. Connect AI clients (ChatGPT, Claude) to http://localhost/mcp/sse"
echo ""
echo "📊 View logs: docker-compose -f docker-compose.mcp.yml logs -f"
echo "🛑 Stop: ./stop-mcp.sh"
echo ""
