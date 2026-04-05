# Pits n' Giggles - Nginx Reverse Proxy Deployment

This directory contains the Nginx reverse proxy configuration for exposing the Pits n' Giggles MCP server over HTTPS.

## Quick Setup

Run the automated setup script:

```bash
cd deployment/scripts
./setup-nginx.sh
```

This will:
1. Generate a self-signed SSL certificate
2. Install the Nginx configuration
3. Enable and reload Nginx

## Manual Setup

### 1. Generate SSL Certificate

```bash
./scripts/generate-self-signed-cert.sh /etc/nginx/ssl/pitsngiggles localhost
```

### 2. Install Nginx Configuration

```bash
sudo cp nginx/pitsngiggles-mcp.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/pitsngiggles-mcp.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## MCP Endpoint

Once configured, your MCP server will be available at:
- **HTTPS**: `https://localhost:8443/mcp`
- **HTTP**: `http://localhost:80` (redirects to HTTPS)

## Connecting AI Tools

### ChatGPT Desktop
1. Enable Developer Mode in Settings
2. Create New App:
   - Name: `Pits n' Giggles`
   - URL: `https://localhost:8443/mcp`
   - Transport: `SSE`

### Cursor IDE
1. Settings → Features → MCP
2. Add Server:
   - Name: `Telemetry`
   - Type: `SSE`
   - URL: `https://localhost:8443/mcp`

### Claude Desktop
Edit `%APPDATA%\Claude\claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "pitsngiggles": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://localhost:8443/mcp"]
    }
  }
}
```

## Troubleshooting

### Check Nginx Status
```bash
sudo systemctl status nginx
```

### View Logs
```bash
sudo tail -f /var/log/nginx/pitsngiggles-mcp.error.log
sudo tail -f /var/log/nginx/pitsngiggles-mcp.access.log
```

### Test Certificate
```bash
openssl s_client -connect localhost:8443 -servername localhost
```

### SSL Certificate Warnings
The self-signed certificate will show warnings in browsers and AI tools. You need to:
- **Browser**: Accept the certificate exception
- **ChatGPT/AI Tools**: May need to add certificate to system trust store

## Production Deployment

For production with a real domain:

1. Get a proper SSL certificate (Let's Encrypt, etc.)
2. Update `server_name` in `pitsngiggles-mcp.conf`
3. Replace certificate paths in the config
4. Configure firewall to allow ports 80 and 8443

## Files

- `nginx/pitsngiggles-mcp.conf` - Nginx configuration
- `scripts/generate-self-signed-cert.sh` - SSL certificate generator
- `scripts/setup-nginx.sh` - Automated setup script
