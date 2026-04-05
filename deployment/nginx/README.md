# Nginx Deployment Guide

This directory contains nginx configuration for deploying Pits N' Giggles with reverse proxy support, replacing ngrok for production deployments.

## Features

- **HTTPS/TLS**: Secure connections with SSL/TLS
- **WebSocket Support**: Full Socket.IO compatibility
- **MCP Endpoint**: Server-Sent Events for AI tool integration
- **CORS**: Configured for cross-origin MCP requests
- **HTTP/2**: Modern protocol support

## Quick Setup

### 1. Install Nginx

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install nginx
```

**CentOS/RHEL:**
```bash
sudo yum install nginx
```

**macOS:**
```bash
brew install nginx
```

**Windows:**
Download from https://nginx.org/en/download.html

### 2. Install Configuration

```bash
# Copy configuration file
sudo cp pitsngiggles.conf /etc/nginx/sites-available/

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/pitsngiggles.conf /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### 3. Generate SSL Certificate

#### Option A: Self-Signed Certificate (Development)

```bash
# Create SSL directory
sudo mkdir -p /etc/nginx/ssl/pitsngiggles

# Generate certificate
sudo openssl req -x509 -newkey rsa:4096 -nodes \
  -out /etc/nginx/ssl/pitsngiggles/fullchain.pem \
  -keyout /etc/nginx/ssl/pitsngiggles/privkey.pem \
  -days 365 \
  -subj "/CN=localhost"

# Set permissions
sudo chmod 600 /etc/nginx/ssl/pitsngiggles/privkey.pem
sudo chmod 644 /etc/nginx/ssl/pitsngiggles/fullchain.pem
```

#### Option B: Let's Encrypt (Production)

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d your-domain.com

# Update nginx config with your domain
sudo sed -i 's/server_name localhost;/server_name your-domain.com;/' \
  /etc/nginx/sites-available/pitsngiggles.conf

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

Certificate auto-renewal is configured automatically by certbot.

### 4. Start Pits N' Giggles

```bash
cd /path/to/pits-n-giggles
./start.sh
```

### 5. Access the Application

- **Driver View**: https://localhost:8443/
- **Engineer View**: https://localhost:8443/eng-view
- **Strategy Center**: https://localhost:8443/strategy-center
- **MCP Endpoint**: https://localhost:8443/mcp

## Configuration Customization

### Change Port

Edit `pitsngiggles.conf` and change:

```nginx
listen 8443 ssl http2;
```

to your desired port, for example:

```nginx
listen 443 ssl http2;
```

### Custom Domain

Replace all instances of `localhost` with your domain:

```nginx
server_name your-domain.com;
```

### Backend Server Port

If Pits N' Giggles runs on a different port, update:

```nginx
proxy_pass http://localhost:4768/;
```

to:

```nginx
proxy_pass http://localhost:YOUR_PORT/;
```

### Add Authentication

To protect MCP endpoint with basic auth:

```nginx
location /mcp {
    auth_basic "F1 Telemetry Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    proxy_pass http://localhost:4768/mcp;
    # ... rest of proxy config
}
```

Create password file:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd username
```

### Rate Limiting

Add to `http` block in `/etc/nginx/nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=mcp_limit:10m rate=10r/s;
```

Then in `location /mcp`:

```nginx
location /mcp {
    limit_req zone=mcp_limit burst=20;
    # ... rest of config
}
```

## Firewall Configuration

### UFW (Ubuntu)

```bash
sudo ufw allow 8443/tcp
sudo ufw allow 80/tcp
sudo ufw reload
```

### Firewalld (CentOS/RHEL)

```bash
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload
```

### Windows Firewall

```powershell
New-NetFirewallRule -DisplayName "Pits N Giggles HTTPS" `
  -Direction Inbound -Protocol TCP -LocalPort 8443 -Action Allow
```

## Testing

### Test Nginx Configuration

```bash
sudo nginx -t
```

### Test HTTP to HTTPS Redirect

```bash
curl -I http://localhost/
```

Should return `301 Moved Permanently`.

### Test MCP Endpoint

```bash
curl -N -H "Accept: text/event-stream" https://localhost:8443/mcp
```

Should stream MCP events.

### Test WebSocket

Open browser console at `https://localhost:8443/` and check for Socket.IO connection.

## Monitoring

### Access Logs

```bash
sudo tail -f /var/log/nginx/pitsngiggles.access.log
```

### Error Logs

```bash
sudo tail -f /var/log/nginx/pitsngiggles.error.log
```

### Nginx Status

```bash
sudo systemctl status nginx
```

## Troubleshooting

### 502 Bad Gateway

**Cause**: Pits N' Giggles backend not running

**Solution**:
```bash
# Check if backend is running
curl http://localhost:4768/

# Start backend
cd /path/to/pits-n-giggles
./start.sh
```

### SSL Certificate Error

**Cause**: Certificate not found or invalid

**Solution**:
```bash
# Check certificate paths
ls -la /etc/nginx/ssl/pitsngiggles/

# Regenerate if needed (see Setup section)
```

### MCP Connection Timeout

**Cause**: Firewall blocking port or timeout too short

**Solution**:
```bash
# Allow port through firewall (see Firewall Configuration)

# Increase timeout in nginx config
proxy_read_timeout 7200s;
```

### WebSocket Not Working

**Cause**: Missing upgrade headers

**Solution**: Ensure these headers are in your config:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## Performance Tuning

### Worker Processes

Edit `/etc/nginx/nginx.conf`:

```nginx
worker_processes auto;
worker_connections 1024;
```

### Gzip Compression

Add to `http` block:

```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
gzip_min_length 1000;
```

### Caching

Add caching for static files:

```nginx
location /static/ {
    proxy_pass http://localhost:4768/static/;
    proxy_cache_valid 200 1h;
    proxy_cache_bypass $http_pragma $http_authorization;
    add_header X-Cache-Status $upstream_cache_status;
}
```

## Security Best Practices

1. **Always use HTTPS** in production
2. **Enable fail2ban** to prevent brute force
3. **Use strong SSL/TLS** configuration
4. **Implement rate limiting** for MCP endpoints
5. **Keep nginx updated**: `sudo apt update && sudo apt upgrade nginx`
6. **Monitor logs** regularly for suspicious activity
7. **Use authentication** for public deployments

## Uninstall

```bash
# Remove configuration
sudo rm /etc/nginx/sites-enabled/pitsngiggles.conf
sudo rm /etc/nginx/sites-available/pitsngiggles.conf

# Remove SSL certificates
sudo rm -rf /etc/nginx/ssl/pitsngiggles

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

## Advanced: Load Balancing

For multiple backend instances:

```nginx
upstream pitsngiggles_backend {
    least_conn;
    server localhost:4768;
    server localhost:4769;
    server localhost:4770;
}

server {
    location / {
        proxy_pass http://pitsngiggles_backend;
        # ... rest of config
    }
}
```

## Support

For issues:
- Check logs: `/var/log/nginx/pitsngiggles.error.log`
- Nginx docs: https://nginx.org/en/docs/
- Pits N' Giggles issues: https://github.com/ashwin-nat/pits-n-giggles/issues
