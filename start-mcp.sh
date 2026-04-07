#!/bin/bash
# Start F1 Race Engineer MCP Server

set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

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

# Start Docker Compose (V2 plugin preferred)
echo "🚀 Starting services..."
if docker compose version &>/dev/null; then
  docker compose -f docker-compose.mcp.yml --env-file .env.mcp up -d
else
  docker-compose -f docker-compose.mcp.yml --env-file .env.mcp up -d
fi

echo ""
echo "⏳ Waiting for MCP healthcheck and nginx..."
sleep 4

export MCP_HEALTH="http://127.0.0.1:${MCP_PORT:-8765}/health"
export NGINX_HEALTH="http://127.0.0.1:${HTTP_PORT:-9080}/health"
echo "🔎 Verifying MCP + nginx (${MCP_HEALTH}, ${NGINX_HEALTH})..."
if bash "${PWD}/scripts/verify-png-stack.sh" --mcp-stack-only; then
  echo "✅ MCP stack verification passed"
else
  echo "⚠️  MCP stack verification failed — check: docker compose -f docker-compose.mcp.yml logs"
  exit 1
fi

echo ""
echo "✅ F1 Race Engineer MCP Server is running!"
echo ""
echo "📍 Access Points:"
echo "   - MCP Server (direct): http://localhost:${MCP_PORT:-8765}"
echo "   - Nginx HTTP: http://localhost:${HTTP_PORT:-9080}"
echo "   - Nginx HTTPS: https://localhost:${HTTPS_PORT:-9443}"
echo "   - Pits N Giggles (host): http://localhost:4768"
echo ""
echo "🔧 Endpoints:"
echo "   - MCP chat (direct): POST http://localhost:${MCP_PORT:-8765}/mcp/chat"
echo "   - MCP WebSocket (direct): ws://localhost:${MCP_PORT:-8765}/mcp/ws"
echo "   - Same paths via nginx: http://localhost:${HTTP_PORT:-9080}/mcp/..."
echo "   - SSE for AI clients (PNG, not mcp_server): https://localhost:${HTTPS_PORT:-9443}/telemetry/mcp"
echo "   - SSE direct to PNG: http://localhost:4768/mcp"
echo "   - Health (via nginx): http://localhost:${HTTP_PORT:-9080}/health"
echo ""
echo "📖 Next Steps:"
echo "   1. Start Pits N Giggles on the host (or uncomment in docker-compose.mcp.yml)"
echo "   2. Open Strategy Center in your browser"
echo "   3. Point ChatGPT/Claude SSE clients at https://localhost:${HTTPS_PORT:-9443}/telemetry/mcp (skip TLS verify for self-signed)"
echo ""
echo "📊 View logs: docker compose -f docker-compose.mcp.yml logs -f  (or docker-compose ...)"
echo "🛑 Stop: ./stop-mcp.sh"
echo ""
