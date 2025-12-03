# ===================================================================
# MarkAudio Attendance - Oracle Cloud Deployment Script
# ===================================================================
# This script prepares the backend for deployment to Oracle Cloud
# Target: Ubuntu 22.04 aarch64 (ARM64) with PostgreSQL
# ===================================================================

param(
    [string]$ServerIP = "REPLACE_WITH_YOUR_ORACLE_IP",
    [string]$SSHUser = "ubuntu"
)

Write-Host "`n=== MarkAudio Deployment Preparation ===" -ForegroundColor Cyan
Write-Host "Target: Oracle Cloud Ubuntu 22.04 ARM64`n" -ForegroundColor Yellow

# Step 1: Check if backend exists
if (-not (Test-Path "backend")) {
    Write-Host "ERROR: backend folder not found!" -ForegroundColor Red
    Write-Host "Run this script from: P:\SourceCode-HM\DeskAttendanceApp" -ForegroundColor Yellow
    exit 1
}

# Step 2: Publish backend for Linux ARM64
Write-Host "Step 1: Publishing backend for Linux ARM64..." -ForegroundColor Cyan
cd backend

# Clean previous publish
if (Test-Path "publish") {
    Remove-Item -Recurse -Force publish
}

# Publish for production
dotnet publish -c Release -r linux-arm64 --self-contained false -o publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Backend publish failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Backend published successfully!`n" -ForegroundColor Green

# Step 3: Create deployment package
Write-Host "Step 2: Creating deployment package..." -ForegroundColor Cyan
cd publish

# Create database migrations folder
New-Item -ItemType Directory -Force -Path "Migrations" | Out-Null

# Copy migration files
Copy-Item -Path "..\Migrations\*.cs" -Destination "Migrations\" -Force

# Create deployment zip
$zipFile = "..\..\markaudio-backend-deploy.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path * -DestinationPath $zipFile

Write-Host "✅ Deployment package created: markaudio-backend-deploy.zip`n" -ForegroundColor Green

# Step 4: Show deployment instructions
cd ..\..

Write-Host "`n=== DEPLOYMENT PACKAGE READY! ===" -ForegroundColor Green
Write-Host "`nFile created: markaudio-backend-deploy.zip" -ForegroundColor Cyan
Write-Host "Size: $([math]::Round((Get-Item markaudio-backend-deploy.zip).Length/1MB, 2)) MB`n" -ForegroundColor Cyan

Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "`n1. CREATE ORACLE CLOUD INSTANCE:" -ForegroundColor Cyan
Write-Host "   - Login to Oracle Cloud Console" -ForegroundColor White
Write-Host "   - Create VM.Standard.A1.Flex instance" -ForegroundColor White
Write-Host "   - Image: Ubuntu 22.04 Minimal aarch64" -ForegroundColor White
Write-Host "   - Shape: 4 OCPU, 24GB RAM (FREE TIER)" -ForegroundColor White
Write-Host "   - Assign public IP" -ForegroundColor White
Write-Host "   - Note your public IP: _________________`n" -ForegroundColor White

Write-Host "2. UPLOAD DEPLOYMENT PACKAGE:" -ForegroundColor Cyan
Write-Host "   Run this command (replace IP):" -ForegroundColor White
Write-Host "   scp markaudio-backend-deploy.zip ubuntu@YOUR_IP:~/" -ForegroundColor Yellow
Write-Host ""

Write-Host "3. SSH TO SERVER AND RUN SETUP:" -ForegroundColor Cyan
Write-Host "   ssh ubuntu@YOUR_IP" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Then run these commands:" -ForegroundColor White
Write-Host "   wget https://raw.githubusercontent.com/YOUR_REPO/setup-server.sh" -ForegroundColor Yellow
Write-Host "   chmod +x setup-server.sh" -ForegroundColor Yellow
Write-Host "   ./setup-server.sh" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== OR MANUAL SETUP ===" -ForegroundColor Yellow
Write-Host "`nFollow the complete guide in:" -ForegroundColor White
Write-Host "ORACLE_CLOUD_DEPLOYMENT_GUIDE.md`n" -ForegroundColor Cyan

# Step 5: Create server setup script
Write-Host "Creating server setup script..." -ForegroundColor Cyan

$setupScript = @'
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
'@

Set-Content -Path "setup-server.sh" -Value $setupScript
Write-Host "✅ Created: setup-server.sh`n" -ForegroundColor Green

Write-Host "=== FILES CREATED ===" -ForegroundColor Cyan
Write-Host "1. markaudio-backend-deploy.zip - Upload to server" -ForegroundColor White
Write-Host "2. setup-server.sh - Run on server to setup everything`n" -ForegroundColor White

Write-Host "Ready to deploy! 🚀" -ForegroundColor Green
