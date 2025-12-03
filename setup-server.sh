#!/bin/bash
# ===================================================================
# MarkAudio Server Setup Script for Ubuntu 22.04 ARM64
# ===================================================================

set -e

echo "=== MarkAudio Server Setup ==="
echo "Starting installation..."

# Update system
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install .NET 9 Runtime (ARM64)
echo "Installing .NET 9 Runtime..."
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 9.0 --runtime aspnetcore

# Add to PATH
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
source ~/.bashrc

# Install PostgreSQL 15
echo "Installing PostgreSQL 15..."
sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
echo "Setting up database..."
sudo -u postgres psql << EOF
CREATE DATABASE attendancedb;
CREATE USER markaudio_user WITH ENCRYPTED PASSWORD 'MarkAudio@2025!Secure';
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO markaudio_user;
\c attendancedb
GRANT ALL ON SCHEMA public TO markaudio_user;
ALTER DATABASE attendancedb OWNER TO markaudio_user;
EOF

# Configure PostgreSQL for remote connections
echo "Configuring PostgreSQL..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/15/main/postgresql.conf
echo "host    attendancedb    markaudio_user    0.0.0.0/0    scram-sha-256" | sudo tee -a /etc/postgresql/15/main/pg_hba.conf
sudo systemctl restart postgresql

# Extract backend files
echo "Extracting backend application..."
mkdir -p ~/markaudio-backend
cd ~/markaudio-backend
unzip ~/markaudio-backend-deploy.zip
chmod +x backend

# Install EF Core tools
echo "Installing Entity Framework tools..."
$HOME/.dotnet/dotnet tool install --global dotnet-ef
echo 'export PATH=$PATH:$HOME/.dotnet/tools' >> ~/.bashrc
export PATH=$PATH:$HOME/.dotnet/tools

# Run database migrations
echo "Running database migrations..."
export ASPNETCORE_ENVIRONMENT=Production
dotnet ef database update --context AttendanceContext

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/markaudio-backend.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=MarkAudio Attendance Backend
After=network.target postgresql.service

[Service]
Type=notify
User=ubuntu
WorkingDirectory=/home/ubuntu/markaudio-backend
ExecStart=/home/ubuntu/.dotnet/dotnet /home/ubuntu/markaudio-backend/backend.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=markaudio-backend
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_ROOT=/home/ubuntu/.dotnet

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable markaudio-backend
sudo systemctl start markaudio-backend

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 5001/tcp
sudo ufw --force enable

# Wait for service to start
echo "Waiting for backend to start..."
sleep 5

# Check service status
echo ""
echo "=== Service Status ==="
sudo systemctl status markaudio-backend --no-pager

echo ""
echo "=== Testing Backend ==="
curl -s http://localhost:5001/health || echo "Health check failed!"

echo ""
echo "=== SETUP COMPLETE! ==="
echo ""
echo "Backend is running on: http://$(curl -s ifconfig.me):5001"
echo ""
echo "View logs: sudo journalctl -u markaudio-backend -f"
echo "Restart: sudo systemctl restart markaudio-backend"
echo ""
echo "Next: Update desktop app with server IP!"
