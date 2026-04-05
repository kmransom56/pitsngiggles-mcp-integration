#!/bin/bash
# Stop F1 Race Engineer MCP Server

echo "🛑 Stopping F1 Race Engineer MCP Server..."

docker-compose -f docker-compose.mcp.yml down

echo "✅ MCP Server stopped"
