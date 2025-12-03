# Oracle Cloud Deployment Guide - MarkAudio Attendance System
**Target**: Ubuntu 22.04 Minimal aarch64 (ARM64)  
**Date**: November 18, 2025

---

## 📋 DEPLOYMENT OPTIONS

### Option 1: SQLite (Standalone Systems)
- Each of 10 systems has its own database
- Cloud server only hosts backend API
- ❌ No centralized data access

### Option 2: PostgreSQL (Centralized Database) ⭐ **RECOMMENDED**
- All 10 systems connect to cloud database
- Centralized attendance records
- ✅ Admin can access all data from anywhere
- ✅ Backup one database instead of 10

---

## 🚀 STEP-BY-STEP DEPLOYMENT (PostgreSQL Option)

### PHASE 1: Create Oracle Cloud Instance

#### Step 1.1: Create VM Instance
1. Login to Oracle Cloud Console
2. Go to **Compute** → **Instances** → **Create Instance**
3. Configure:
   - **Name**: `markaudio-attendance-server`
   - **Image**: Ubuntu 22.04 Minimal aarch64
   - **Shape**: VM.Standard.A1.Flex (4 OCPU, 24GB RAM) - **FREE TIER**
   - **Network**: Create new VCN or use existing
   - **Public IP**: Assign a public IPv4 address
   - **SSH Keys**: Upload your SSH public key

4. Click **Create** and wait 2-3 minutes

#### Step 1.2: Note Your Public IP
```
Example: 152.67.123.45
Save this IP - you'll need it!
```

---

### PHASE 2: Configure Firewall Rules

#### Step 2.1: Oracle Cloud Security List
1. Go to **Networking** → **Virtual Cloud Networks**
2. Click your VCN → **Security Lists** → **Default Security List**
3. Click **Add Ingress Rules**:

```
Rule 1 - Backend API:
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port: 5001
Description: ASP.NET Core Backend

Rule 2 - PostgreSQL (Optional - for remote admin):
Source CIDR: YOUR_OFFICE_IP/32
IP Protocol: TCP
Destination Port: 5432
Description: PostgreSQL Database
```

#### Step 2.2: Ubuntu Firewall
```bash
# Will configure this after SSH login
```

---

### PHASE 3: Connect to Server & Initial Setup

#### Step 3.1: SSH to Server
```bash
# From your Windows PC using PowerShell
ssh ubuntu@152.67.123.45
# Replace with your actual IP
```

#### Step 3.2: Update System
```bash
sudo apt update
sudo apt upgrade -y
```

#### Step 3.3: Install Required Software
```bash
# Install .NET 9 SDK
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 9.0

# Add to PATH
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
source ~/.bashrc

# Verify installation
dotnet --version
# Should show: 9.0.x

# Install PostgreSQL 15
sudo apt install postgresql postgresql-contrib -y

# Install Nginx (for reverse proxy - optional but recommended)
sudo apt install nginx -y
```

---

### PHASE 4: Setup PostgreSQL Database

#### Step 4.1: Configure PostgreSQL
```bash
# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Switch to postgres user
sudo -i -u postgres

# Create database and user
psql
```

#### Step 4.2: Run SQL Commands
```sql
-- Create database
CREATE DATABASE attendancedb;

-- Create user with password
CREATE USER markaudio_user WITH ENCRYPTED PASSWORD 'YourSecurePassword123!';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO markaudio_user;

-- Grant schema privileges
\c attendancedb
GRANT ALL ON SCHEMA public TO markaudio_user;

-- Exit psql
\q
exit
```

#### Step 4.3: Configure PostgreSQL for Remote Connections
```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/15/main/postgresql.conf

# Find and change:
listen_addresses = '*'

# Save and exit (Ctrl+X, Y, Enter)

# Edit pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Add at the end:
host    attendancedb    markaudio_user    0.0.0.0/0    scram-sha-256

# Save and exit

# Restart PostgreSQL
sudo systemctl restart postgresql
```

---

### PHASE 5: Deploy Backend Application

#### Step 5.1: Prepare Backend Files on Windows
```powershell
# On your Windows PC
cd P:\SourceCode-HM\DeskAttendanceApp\backend

# Update appsettings.Production.json with cloud PostgreSQL
```

**Edit `appsettings.Production.json`:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=attendancedb;Username=markaudio_user;Password=YourSecurePassword123!"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:5001"
      }
    }
  }
}
```

#### Step 5.2: Publish Backend
```powershell
# Build for Linux ARM64
dotnet publish -c Release -r linux-arm64 --self-contained false -o publish

# Create deployment package
Compress-Archive -Path publish\* -DestinationPath backend-deploy.zip
```

#### Step 5.3: Upload to Server
```powershell
# Use SCP to upload
scp backend-deploy.zip ubuntu@152.67.123.45:~/
```

#### Step 5.4: Extract and Setup on Server
```bash
# SSH to server
ssh ubuntu@152.67.123.45

# Create app directory
mkdir -p ~/markaudio-backend
cd ~/markaudio-backend

# Extract files
unzip ~/backend-deploy.zip
rm ~/backend-deploy.zip

# Make executable
chmod +x backend

# Set environment
export ASPNETCORE_ENVIRONMENT=Production
```

---

### PHASE 6: Run Database Migrations

```bash
# Install EF Core tools
dotnet tool install --global dotnet-ef

# Add to PATH
echo 'export PATH=$PATH:$HOME/.dotnet/tools' >> ~/.bashrc
source ~/.bashrc

# Run migrations
cd ~/markaudio-backend
dotnet ef database update --context AttendanceContext
```

---

### PHASE 7: Create Systemd Service (Auto-start)

#### Step 7.1: Create Service File
```bash
sudo nano /etc/systemd/system/markaudio-backend.service
```

#### Step 7.2: Service Configuration
```ini
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
```

#### Step 7.3: Enable and Start Service
```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (auto-start on boot)
sudo systemctl enable markaudio-backend

# Start service
sudo systemctl start markaudio-backend

# Check status
sudo systemctl status markaudio-backend

# View logs
sudo journalctl -u markaudio-backend -f
```

---

### PHASE 8: Configure Ubuntu Firewall

```bash
# Allow SSH (important - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow backend API
sudo ufw allow 5001/tcp

# Allow PostgreSQL (only from your office IP for security)
# Replace YOUR_OFFICE_IP with actual IP
sudo ufw allow from YOUR_OFFICE_IP to any port 5432

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

---

### PHASE 9: Configure Nginx Reverse Proxy (Optional but Recommended)

#### Why Nginx?
- SSL/HTTPS support
- Better performance
- Standard port 80/443
- DDoS protection

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/markaudio
```

**Nginx Config:**
```nginx
server {
    listen 80;
    server_name 152.67.123.45;  # Replace with your IP or domain

    location / {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/markaudio /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Enable Nginx on boot
sudo systemctl enable nginx
```

**Now your API is accessible at:**
- Direct: `http://152.67.123.45:5001`
- Via Nginx: `http://152.67.123.45`

---

### PHASE 10: Update Desktop App Configuration

#### Step 10.1: Update appConfig.json
Edit `electron-app/appConfig.json`:
```json
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://152.67.123.45:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/markaudio-attendance/releases/latest"
  }
}
```

#### Step 10.2: Update Backend Connection String
Edit `backend/appsettings.Production.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=152.67.123.45;Port=5432;Database=attendancedb;Username=markaudio_user;Password=YourSecurePassword123!"
  }
}
```

#### Step 10.3: Rebuild Installer
```powershell
# On Windows PC
cd P:\SourceCode-HM\DeskAttendanceApp

# Build new installer with cloud config
npm run dist
```

---

## 🎯 DEPLOYMENT CHECKLIST

### Pre-Deployment
- [ ] Oracle Cloud instance created (Ubuntu 22.04 ARM64)
- [ ] Public IP noted: `_______________`
- [ ] SSH key configured
- [ ] Firewall rules added (5001, 5432)

### Server Setup
- [ ] Connected via SSH
- [ ] System updated (`apt update && upgrade`)
- [ ] .NET 9 installed and verified
- [ ] PostgreSQL 15 installed
- [ ] Database created: `attendancedb`
- [ ] User created: `markaudio_user`
- [ ] PostgreSQL configured for remote access

### Backend Deployment
- [ ] `appsettings.Production.json` updated
- [ ] Backend published for `linux-arm64`
- [ ] Files uploaded to server
- [ ] Migrations run successfully
- [ ] Systemd service created and started
- [ ] Backend running on port 5001

### Network & Security
- [ ] UFW firewall configured
- [ ] Nginx installed and configured
- [ ] API accessible: `http://YOUR_IP:5001/api/health`

### Desktop App
- [ ] `appConfig.json` updated with cloud IP
- [ ] New installer built
- [ ] Tested on one system before deploying to all 10

---

## 🧪 TESTING CHECKLIST

### Test 1: Backend Health Check
```bash
curl http://152.67.123.45:5001/api/health
# Should return: OK or 200 status
```

### Test 2: Database Connection
```bash
# SSH to server
sudo -u postgres psql -d attendancedb -c "SELECT * FROM \"Users\" LIMIT 1;"
```

### Test 3: Desktop App Login
1. Install new version on ONE test system
2. Login with admin: `pivotadmin@gmail.com` / `Admin123`
3. Check network validation works
4. Create test employee
5. Test employee login

### Test 4: Network Validation
1. Connect test system to office router
2. Login as employee
3. Should detect:
   - Gateway IP: 192.168.0.1
   - Router MAC: 3C-64-CF-30-FC-2D
4. Verify attendance recording works

---

## 🔐 SECURITY RECOMMENDATIONS

### 1. Change Default Passwords
```bash
# Change postgres user password
sudo -u postgres psql
ALTER USER postgres WITH PASSWORD 'NewStrongPassword123!';
\q
```

### 2. Setup SSL/HTTPS (Recommended for Production)
```bash
# Install Certbot for Let's Encrypt SSL
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate (requires domain name)
sudo certbot --nginx -d yourdomain.com
```

### 3. Database Backups
```bash
# Create backup script
nano ~/backup-db.sh
```

**Backup Script:**
```bash
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
sudo -u postgres pg_dump attendancedb > $BACKUP_DIR/attendancedb_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: attendancedb_$DATE.sql"
```

```bash
# Make executable
chmod +x ~/backup-db.sh

# Test backup
./backup-db.sh

# Schedule daily backups at 2 AM
crontab -e
# Add line:
0 2 * * * /home/ubuntu/backup-db.sh
```

---

## 📊 MONITORING & LOGS

### View Backend Logs
```bash
# Real-time logs
sudo journalctl -u markaudio-backend -f

# Last 100 lines
sudo journalctl -u markaudio-backend -n 100

# Today's logs
sudo journalctl -u markaudio-backend --since today
```

### View Nginx Logs
```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
```

### View PostgreSQL Logs
```bash
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## 🚨 TROUBLESHOOTING

### Backend Not Starting
```bash
# Check status
sudo systemctl status markaudio-backend

# Check logs
sudo journalctl -u markaudio-backend -n 50

# Common issues:
# 1. Port 5001 already in use
sudo netstat -tulpn | grep 5001

# 2. Database connection failed
sudo -u postgres psql -d attendancedb -c "SELECT version();"
```

### Cannot Connect from Desktop App
```bash
# 1. Check backend is running
curl http://localhost:5001/api/health

# 2. Check firewall
sudo ufw status

# 3. Check if port is open from outside
# From Windows PC:
Test-NetConnection -ComputerName 152.67.123.45 -Port 5001
```

### PostgreSQL Connection Issues
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Test remote connection
psql -h 152.67.123.45 -U markaudio_user -d attendancedb
```

---

## 📱 AUTO-UPDATE SETUP

### 1. Create GitHub Repository
1. Go to GitHub → Create New Repository
2. Name: `markaudio-attendance`
3. Public or Private (your choice)

### 2. Enable GitHub Releases
1. Go to repository → Releases
2. Click "Create a new release"
3. Tag: `v1.0.0`
4. Upload: `MarkAudio Setup 1.0.0.exe`
5. Publish release

### 3. Update appConfig.json
```json
{
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/YOURUSERNAME/markaudio-attendance/releases/latest"
  }
}
```

### 4. How Updates Work
1. You release v1.0.1 on GitHub
2. All 10 systems check for updates on startup
3. Auto-download and install
4. Users see: "Update available - restart to install"

---

## 💰 ESTIMATED COSTS

### Oracle Cloud Free Tier
- **VM.Standard.A1.Flex**: FREE (4 OCPU, 24GB RAM)
- **Storage**: 200GB FREE
- **Bandwidth**: 10TB/month FREE
- **Public IP**: FREE

**Total Cost: $0/month** ✅

---

## ⏱️ DEPLOYMENT TIME ESTIMATE

| Phase | Time |
|-------|------|
| Oracle Cloud Setup | 15 min |
| Server Installation | 20 min |
| PostgreSQL Setup | 15 min |
| Backend Deployment | 20 min |
| Testing | 20 min |
| **Total** | **~90 minutes** |

---

## 📞 SUPPORT COMMANDS

### Quick Reference
```bash
# Start backend
sudo systemctl start markaudio-backend

# Stop backend
sudo systemctl stop markaudio-backend

# Restart backend
sudo systemctl restart markaudio-backend

# View logs
sudo journalctl -u markaudio-backend -f

# Check database
sudo -u postgres psql -d attendancedb

# Backup database
./backup-db.sh

# Update backend code
cd ~/markaudio-backend
# (upload new files, then restart service)
sudo systemctl restart markaudio-backend
```

---

## ✅ CONFIRMATION QUESTIONS

Before we proceed, please confirm:

1. **Do you want PostgreSQL (centralized) or SQLite (standalone)?**
   - PostgreSQL = All 10 systems share one database on cloud ⭐ **RECOMMENDED**
   - SQLite = Each system has its own database

2. **Do you have Oracle Cloud account ready?**
   - Yes → Proceed with deployment
   - No → I'll guide you through account creation

3. **When do you want to deploy?**
   - Now → I'll help you step-by-step
   - Tomorrow 6 AM IST → I'll prepare everything
   - Later → Let me know when

4. **Do you want SSL/HTTPS?**
   - Yes → You need a domain name (e.g., attendance.markaudio.com)
   - No → We'll use HTTP (works fine for internal use)

Please reply with your choices, and I'll help you deploy! 🚀
