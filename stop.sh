#!/bin/bash
# Stop Pits n' Giggles and all related services

echo "Stopping Pits n' Giggles..."

stop_pidfile() {
    local file=$1
    local label=$2
    if [ ! -f "$file" ]; then
        return 0
    fi
    PID=$(cat "$file" 2>/dev/null)
    rm -f "$file"
    if [ -z "$PID" ] || ! [[ "$PID" =~ ^[0-9]+$ ]]; then
        return 0
    fi
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping ${label} (PID: ${PID})..."
        kill "$PID"
        sleep 2
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Force stopping ${label}..."
            kill -9 "$PID"
        fi
    fi
}

# start.sh / start-auto.sh write .backend.pid; legacy scripts may have used .app.pid
stop_pidfile .backend.pid "backend"
stop_pidfile .app.pid "backend (legacy pid)"

# Native MCP helper started by start.sh (docker MCP: use ./stop-mcp.sh or compose down)
stop_pidfile .mcp.pid "MCP server"

# Kill any remaining Python processes running the old launcher
pkill -f "python.*apps.launcher" || true

echo "✓ Pits n' Giggles stopped"
echo ""
echo "Note: nginx reverse proxy is still running"
echo "To stop nginx: sudo systemctl stop nginx"
