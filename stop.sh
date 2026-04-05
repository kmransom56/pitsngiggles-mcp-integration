#!/bin/bash
# Stop Pits n' Giggles and all related services

echo "Stopping Pits n' Giggles..."

# Stop the main application
if [ -f .app.pid ]; then
    PID=$(cat .app.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping backend (PID: $PID)..."
        kill $PID
        sleep 2
        
        # Force kill if still running
        if ps -p $PID > /dev/null 2>&1; then
            echo "Force stopping..."
            kill -9 $PID
        fi
    fi
    rm .app.pid
fi

# Kill any remaining Python processes running the launcher
pkill -f "python.*apps.launcher" || true

echo "✓ Pits n' Giggles stopped"
echo ""
echo "Note: nginx reverse proxy is still running"
echo "To stop nginx: sudo systemctl stop nginx"
