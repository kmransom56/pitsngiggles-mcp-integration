@echo off
REM Start F1 Race Engineer MCP Server

echo.
echo 🏎️  Starting F1 Race Engineer MCP Server...
echo.

REM Check if .env.mcp exists
if not exist .env.mcp (
    echo ⚠️  No .env.mcp file found. Creating from example...
    copy .env.mcp.example .env.mcp
    echo ⚠️  Please edit .env.mcp and configure your LLM API key!
    echo    - Get an OpenRouter API key from: https://openrouter.ai/keys
    echo    - Or use OpenAI, Anthropic, or other compatible APIs
    echo.
    pause
)

REM Generate self-signed SSL certificate if it doesn't exist
if not exist ssl\cert.pem (
    echo 🔐 Generating self-signed SSL certificate...
    mkdir ssl 2>nul
    openssl req -x509 -newkey rsa:4096 -nodes -keyout ssl\key.pem -out ssl\cert.pem -days 365 -subj "/C=US/ST=State/L=City/O=PitsNGiggles/CN=localhost"
    echo ✅ SSL certificate generated
)

REM Start Docker Compose
echo 🚀 Starting services...
docker-compose -f docker-compose.mcp.yml --env-file .env.mcp up -d

echo.
echo ✅ F1 Race Engineer MCP Server is running!
echo.
echo 📍 Access Points:
echo    - MCP Server (direct): http://localhost:8765
echo    - Nginx HTTP (default): http://localhost:9080
echo    - Nginx HTTPS (default): https://localhost:9443
echo    - Pits N Giggles (host): http://localhost:4768
echo    - Strategy Center: http://localhost:4768/strategy-center
echo    - Voice Strategy: http://localhost:4768/voice-strategy-center
echo.
echo 🔧 Endpoints:
echo    - MCP POST /mcp/chat (direct): http://localhost:8765/mcp/chat
echo    - MCP WebSocket: ws://localhost:8765/mcp/ws
echo    - Via nginx: http://localhost:9080/mcp/...
echo    - SSE for AI clients (PNG): https://localhost:9443/telemetry/mcp
echo    - SSE direct to PNG: http://localhost:4768/mcp
echo    - Health (nginx): http://localhost:9080/health
echo.
echo 📖 Next Steps:
echo    1. Start F1 23/24/25 and enable UDP telemetry (port 20777)
echo    2. Start Pits N Giggles on the host (or in Docker)
echo    3. Open Strategy Center in your browser
echo    4. Point ChatGPT/Claude SSE at https://localhost:9443/telemetry/mcp
echo.
echo 📊 View logs: docker-compose -f docker-compose.mcp.yml logs -f
echo 🛑 Stop: stop-mcp.bat
echo.
pause
