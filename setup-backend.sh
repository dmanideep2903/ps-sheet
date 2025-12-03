#!/bin/bash
# Run this script in HestiaCP Web Terminal

echo "=== Setting Up Desk Attendance Backend ==="
echo ""

# Step 1: Install dependencies
echo "[1/7] Installing dependencies..."
sudo apt update
sudo apt install -y libicu-dev libssl-dev ca-certificates postgresql

# Step 2: Setup PostgreSQL
echo ""
echo "[2/7] Setting up PostgreSQL database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres psql <<EOF
CREATE DATABASE attendancedb;
CREATE USER attendanceuser WITH PASSWORD 'MarkAudio@2025!Secure';
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;
ALTER DATABASE attendancedb OWNER TO attendanceuser;
\q
EOF

# Step 3: Create directory structure
echo ""
echo "[3/7] Creating directory structure..."
mkdir -p /home/pivot/app/backend
chown -R pivot:pivot /home/pivot/app

# Step 4: Configure appsettings
echo ""
echo "[4/7] Creating appsettings.Production.json..."
cat > /home/pivot/app/backend/appsettings.Production.json <<'JSONEOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=attendancedb;Username=attendanceuser;Password=MarkAudio@2025!Secure"
  },
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:5001"
      }
    }
  }
}
JSONEOF

# Step 5: Configure firewall
echo ""
echo "[5/7] Configuring firewall..."
sudo ufw allow 5001/tcp
sudo ufw allow 22/tcp
sudo ufw --force enable

# Step 6: Create systemd service
echo ""
echo "[6/7] Creating systemd service..."
sudo tee /etc/systemd/system/deskattendance.service > /dev/null <<'SERVICEEOF'
[Unit]
Description=Desk Attendance Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=pivot
WorkingDirectory=/home/pivot/app/backend
ExecStart=/home/pivot/app/backend/backend
Restart=always
RestartSec=10
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
StandardOutput=journal
StandardError=journal
SyslogIdentifier=deskattendance

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Step 7: Enable and start service
echo ""
echo "[7/7] Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl enable deskattendance

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "IMPORTANT: You need to upload backend files to /home/pivot/app/backend/"
echo ""
echo "After uploading files, run these commands:"
echo "  chmod +x /home/pivot/app/backend/backend"
echo "  sudo systemctl start deskattendance"
echo "  sudo systemctl status deskattendance"
echo ""
echo "Then test with: curl http://localhost:5001/api/health"
echo ""
