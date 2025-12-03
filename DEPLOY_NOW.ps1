# Complete Deployment Script
# Run this to deploy backend to VPS

Write-Host "=== DEPLOYING BACKEND TO VPS ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Upload files
Write-Host "[1/2] Uploading backend files..." -ForegroundColor Yellow
Write-Host "When prompted:" -ForegroundColor White
Write-Host "  - Type 'yes' to accept SSH fingerprint" -ForegroundColor White
Write-Host "  - Enter your VPS password" -ForegroundColor White
Write-Host ""

scp -r backend/publish-linux/* pivot@72.61.226.129:/home/pivot/app/backend-new/

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Upload failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Files uploaded!" -ForegroundColor Green
Write-Host ""

# Step 2: Setup on VPS
Write-Host "[2/2] Setting up backend on VPS..." -ForegroundColor Yellow
Write-Host "Enter password when prompted" -ForegroundColor White
Write-Host ""

$script = @'
echo "Installing dependencies..."
sudo apt update
sudo apt install -y libicu-dev libssl-dev ca-certificates postgresql

echo "Setting up database..."
sudo -u postgres psql -c "CREATE DATABASE attendancedb;"
sudo -u postgres psql -c "CREATE USER attendanceuser WITH PASSWORD 'MarkAudio@2025!Secure';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;"

echo "Setting up backend..."
mkdir -p /home/pivot/app/backend
cd /home/pivot/app
[ -d "backend" ] && mv backend backend-backup
mv backend-new backend
chmod +x backend/backend

echo "Configuring firewall..."
sudo ufw allow 5001/tcp
sudo ufw --force enable

echo "Creating service..."
cat <<'EOF' | sudo tee /etc/systemd/system/deskattendance.service
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable deskattendance
sudo systemctl start deskattendance
sleep 5
sudo systemctl status deskattendance --no-pager
curl http://localhost:5001/api/health
'@

ssh pivot@72.61.226.129 $script

Write-Host ""
Write-Host "Testing external access..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

try {
    $r = Invoke-WebRequest -Uri "http://72.61.226.129:5001/api/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "SUCCESS! Backend is running!" -ForegroundColor Green
    Write-Host "Response: $($r.Content)" -ForegroundColor Green
}
catch {
    Write-Host "Cannot reach externally yet. Try: http://72.61.226.129:5001/api/health" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "Backend: http://72.61.226.129:5001" -ForegroundColor White
Write-Host "Installer: electron-app\dist\EMPLOYEE TIMEPULSE.exe" -ForegroundColor White
