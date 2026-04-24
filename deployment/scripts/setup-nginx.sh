#!/usr/bin/env bash
# Setup Nginx reverse proxy for Pits n' Giggles MCP server

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF="$SCRIPT_DIR/../nginx/pitsngiggles-mcp.conf"

echo "=== Pits n' Giggles Nginx MCP Proxy Setup ==="
echo ""

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "Error: nginx is not installed"
    echo "Install with: sudo apt install nginx"
    exit 1
fi

# SSL certificates: localhost vhost + f1-race-engineer.netintegrate.net vhost (see nginx config)
echo "Step 1: Generating SSL certificates..."
bash "$SCRIPT_DIR/generate-self-signed-cert.sh" /etc/nginx/ssl/pitsngiggles localhost
bash "$SCRIPT_DIR/generate-self-signed-cert.sh" /etc/nginx/ssl/f1-race-engineer.netintegrate.net f1-race-engineer.netintegrate.net

# WSL2: upstreams must target Windows (502 if Nginx in WSL used 127.0.0.1 for services on host)
echo ""
echo "Step 1b: Configuring upstream IP for 4768 / 11734 (Windows host on WSL2)..."
sudo mkdir -p /etc/nginx/snippets
sudo bash "$SCRIPT_DIR/apply-wsl2-nginx-upstreams.sh"

# Copy nginx config
echo ""
echo "Step 2: Installing Nginx configuration..."
sudo cp "$NGINX_CONF" /etc/nginx/sites-available/pitsngiggles-mcp.conf

# Enable site
if [ -f /etc/nginx/sites-enabled/pitsngiggles-mcp.conf ]; then
    echo "Configuration already enabled, replacing..."
    sudo rm /etc/nginx/sites-enabled/pitsngiggles-mcp.conf
fi
sudo ln -s /etc/nginx/sites-available/pitsngiggles-mcp.conf /etc/nginx/sites-enabled/

# Test nginx config
echo ""
echo "Step 3: Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration test failed"
    exit 1
fi

# Reload nginx
echo ""
echo "Step 4: Reloading Nginx..."
sudo systemctl reload nginx || sudo systemctl restart nginx

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Your Pits n' Giggles MCP server is now accessible via:"
echo "  • HTTPS (local):  https://localhost:8443/f1-race-engineer-lan  (legacy path: /mcp)"
echo "  • HTTPS (LAN DNS): https://f1-race-engineer.netintegrate.net:8443/f1-race-engineer-lan"
echo "  • HTTP:  port 80 redirects to HTTPS for localhost and f1-race-engineer.netintegrate.net"
echo ""
echo "Next steps:"
echo "  1. Ensure DNS A record f1-race-engineer.netintegrate.net → this Nginx host (you have this)"
echo "  2. Start Pits n' Giggles with MCP server enabled on 4768"
echo "  3. Configure AI clients to: https://f1-race-engineer.netintegrate.net:8443/f1-race-engineer-lan  (or localhost URL)"
echo "  3. Accept the self-signed certificate in your browser/AI tool"
echo ""
echo "To check Nginx status: sudo systemctl status nginx"
echo "To view logs: sudo tail -f /var/log/nginx/pitsngiggles-mcp.error.log"
