#!/usr/bin/env bash
#
# PS Sheet VPS Hosting Setup
# Sets up Nginx with SSL (Let's Encrypt or self-signed) and versioned download hosting
#
# Usage: sudo ./setup-vps-hosting.sh <VPS_IP> <VERSION> <FILENAME>
# Example: sudo ./setup-vps-hosting.sh 72.61.226.129 1.0.0 PS.Sheet.Setup.1.0.0.exe

set -e

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

if [ "$#" -lt 3 ]; then
  echo "Usage: sudo $0 <VPS_IP> <VERSION> <FILENAME>"
  echo "Example: sudo $0 72.61.226.129 1.0.0 PS.Sheet.Setup.1.0.0.exe"
  exit 1
fi

VPS_IP="$1"
VERSION="$2"
FILENAME="$3"
DOWNLOADS_DIR="/var/www/downloads"
VERSION_DIR="$DOWNLOADS_DIR/$VERSION"
LATEST_DIR="$DOWNLOADS_DIR/latest"
NGINX_CONF="/etc/nginx/sites-available/ps-sheet-downloads"
NGINX_ENABLED="/etc/nginx/sites-enabled/ps-sheet-downloads"

echo "═══════════════════════════════════════════════════════"
echo "  PS Sheet VPS Hosting Setup"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "VPS IP:    $VPS_IP"
echo "Version:   $VERSION"
echo "File:      $FILENAME"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "❌ Cannot detect OS"
  exit 1
fi

echo "📦 Installing required packages..."

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
  apt-get update -qq
  apt-get install -y nginx certbot python3-certbot-nginx curl
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
  yum install -y nginx certbot python3-certbot-nginx curl
else
  echo "⚠ Unsupported OS: $OS (continuing anyway, manual setup may be required)"
fi

echo "✓ Packages installed"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$VERSION_DIR"
mkdir -p "$LATEST_DIR"
chmod -R 755 "$DOWNLOADS_DIR"

# Move uploaded file
if [ -f "$HOME/$FILENAME" ]; then
  echo "📦 Moving installer to version directory..."
  mv "$HOME/$FILENAME" "$VERSION_DIR/"
  chmod 644 "$VERSION_DIR/$FILENAME"
  
  # Create latest symlink
  ln -sf "$VERSION_DIR/$FILENAME" "$LATEST_DIR/setup.exe"
  
  echo "✓ File installed:"
  echo "   $VERSION_DIR/$FILENAME"
  echo "   $LATEST_DIR/setup.exe (symlink)"
else
  echo "⚠ Warning: $FILENAME not found in $HOME"
  echo "   You'll need to manually upload it to: $VERSION_DIR/"
fi

# Create Nginx configuration
echo "🌐 Configuring Nginx..."

# Ensure nginx sites directories exist
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

cat > "$NGINX_CONF" << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name VPS_IP_PLACEHOLDER;

    root /var/www/downloads;
    
    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location /downloads/ {
        alias /var/www/downloads/;
        autoindex off;
        
        # Force download for EXE/MSI files
        location ~* \.(exe|msi)$ {
            add_header Content-Disposition "attachment";
            add_header Content-Type "application/octet-stream";
            add_header Cache-Control "no-cache, must-revalidate";
            try_files $uri =404;
        }
        
        try_files $uri =404;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX_EOF

# Replace placeholder with actual IP
sed -i "s/VPS_IP_PLACEHOLDER/$VPS_IP/" "$NGINX_CONF"

# Enable site
ln -sf "$NGINX_CONF" "$NGINX_ENABLED"

# Remove default site if it exists
rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
echo "🧪 Testing Nginx configuration..."
nginx -t

# Restart Nginx
echo "🔄 Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

echo "✓ Nginx configured and running"

# Configure firewall (if ufw is available)
if command -v ufw >/dev/null 2>&1; then
  echo "🔥 Configuring firewall..."
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  echo "✓ Firewall configured"
fi

# SSL Certificate Setup
echo ""
echo "🔐 Setting up SSL certificate..."
echo ""
echo "Choose SSL option:"
echo "  1) Let's Encrypt (requires domain name)"
echo "  2) Self-signed certificate (works with IP)"
echo "  3) Skip SSL setup (manual configuration later)"
echo ""

# Auto-detect if we have a domain or just IP
if [[ $VPS_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Detected IP address - using self-signed certificate..."
  SSL_CHOICE=2
else
  echo "Detected domain name - attempting Let's Encrypt..."
  SSL_CHOICE=1
fi

case $SSL_CHOICE in
  1)
    # Let's Encrypt
    echo "📜 Requesting Let's Encrypt certificate for $VPS_IP..."
    if certbot --nginx -d "$VPS_IP" --non-interactive --agree-tos --email "admin@$VPS_IP" --redirect; then
      echo "✓ Let's Encrypt certificate installed"
      
      # Set up auto-renewal
      systemctl enable certbot.timer
      systemctl start certbot.timer
      echo "✓ Auto-renewal configured"
    else
      echo "⚠ Let's Encrypt failed. Falling back to self-signed certificate..."
      SSL_CHOICE=2
    fi
    ;;
  
  2)
    # Self-signed certificate
    echo "📜 Generating self-signed certificate..."
    SSL_DIR="/etc/ssl/ps-sheet"
    mkdir -p "$SSL_DIR"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$SSL_DIR/key.pem" \
      -out "$SSL_DIR/cert.pem" \
      -subj "/C=US/ST=State/L=City/O=PS Sheet/CN=$VPS_IP" 2>/dev/null
    
    chmod 600 "$SSL_DIR/key.pem"
    chmod 644 "$SSL_DIR/cert.pem"
    
    # Update Nginx config for HTTPS
    cat >> "$NGINX_CONF" << HTTPS_EOF

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $VPS_IP;

    ssl_certificate $SSL_DIR/cert.pem;
    ssl_certificate_key $SSL_DIR/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/downloads;
    
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location /downloads/ {
        alias /var/www/downloads/;
        autoindex off;
        
        location ~* \.(exe|msi)$ {
            add_header Content-Disposition "attachment";
            add_header Content-Type "application/octet-stream";
            add_header Cache-Control "no-cache, must-revalidate";
            try_files \$uri =404;
        }
        
        try_files \$uri =404;
    }
    
    location ~ /\. {
        deny all;
    }
}
HTTPS_EOF
    
    nginx -t && systemctl reload nginx
    echo "✓ Self-signed certificate installed"
    echo "⚠ Warning: Browsers will show security warning (expected for self-signed certs)"
    ;;
    
  *)
    echo "⏭ Skipping SSL setup"
    ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ Setup Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Your download URLs:"
echo ""
echo "  HTTP:  http://$VPS_IP/downloads/$VERSION/$FILENAME"
if [ $SSL_CHOICE -eq 1 ] || [ $SSL_CHOICE -eq 2 ]; then
  echo "  HTTPS: https://$VPS_IP/downloads/$VERSION/$FILENAME"
fi
echo ""
echo "Latest version (always points to newest):"
echo "  https://$VPS_IP/downloads/latest/setup.exe"
echo ""
echo "Directory structure:"
echo "  $VERSION_DIR/$FILENAME"
echo "  $LATEST_DIR/setup.exe (symlink)"
echo ""
echo "Test download:"
echo "  curl -I https://$VPS_IP/downloads/$VERSION/$FILENAME"
echo ""
echo "For Microsoft Partner Center, use:"
echo "  https://$VPS_IP/downloads/$VERSION/$FILENAME"
echo ""
echo "═══════════════════════════════════════════════════════"
