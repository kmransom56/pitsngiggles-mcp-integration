@echo off
REM Stop F1 Race Engineer MCP Server

echo.
echo 🛑 Stopping F1 Race Engineer MCP Server...
echo.

docker-compose -f docker-compose.mcp.yml down

echo.
echo ✅ F1 Race Engineer MCP Server stopped
echo.
echo 🚀 To start again: start-mcp.bat
echo.
pause
