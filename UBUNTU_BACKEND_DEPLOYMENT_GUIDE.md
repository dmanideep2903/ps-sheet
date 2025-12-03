# 🚀 Ubuntu 24.04 + HestiaCP Backend Deployment Guide

**Server Details:**
- **OS:** Ubuntu 24.04.3 LTS
- **Control Panel:** HestiaCP
- **Server IP:** 72.61.226.129
- **Backend Port:** 5001
- **Database:** PostgreSQL 16
- **Backend:** .NET 9.0 Self-Contained (Linux x64)

---

## 📋 Prerequisites

### On Windows (Development Machine):
1. Backend published to `backend/publish-linux/` folder
2. 7-Zip or WinRAR installed (to create ZIP)
3. HestiaCP admin credentials

### On Ubuntu Server:
- Fresh Ubuntu 24.04 installation
- HestiaCP installed and accessible
- Root access via HestiaCP Web Terminal

---

## 🎯 Deployment Steps (Copy-Ready Commands)

### **STEP 1: Prepare Backend ZIP (Windows)**

```powershell
# Navigate to backend folder
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Publish backend for Linux x64
dotnet publish -c Release -r linux-x64 --self-contained true -o publish-linux

# Create ZIP file (use 7-Zip or File Explorer)
# Right-click publish-linux folder → Send to → Compressed (zipped) folder
# Name it: backend-upload.zip
```

**Expected Output:**
- `backend-upload.zip` containing all files from `publish-linux/` (~115 MB)

---

### **STEP 2: Upload ZIP to Server**

1. **Login to HestiaCP:**
   - URL: `https://72.61.226.129:8083`
   - Username: `admin`
   - Password: [your password]

2. **Upload via File Manager:**
   - Click **File Manager**
   - Navigate to: `/home/admin/web/srv1145703.hstgr.cloud/App/` (or create this folder)
   - Click **Upload** button
   - Select `backend-upload.zip`
   - Wait for upload to complete (2-3 minutes)

---

### **STEP 3: Deploy Backend (HestiaCP Web Terminal)**

Open **Web Terminal** in HestiaCP and run these commands:

#### 3.1 Create User and Extract Files
```bash
# Create system user 'pivot' (if not exists)
useradd -m -s /bin/bash pivot || true

# Create app directory
mkdir -p /home/pivot/app

# Copy ZIP to app directory
cp /home/admin/web/srv1145703.hstgr.cloud/App/backend-upload.zip /home/pivot/app/

# Extract files
cd /home/pivot/app
unzip -q backend-upload.zip -d backend/

# Set execute permission
chmod +x /home/pivot/app/backend/backend

# Fix ownership
chown -R pivot:pivot /home/pivot/app
```

#### 3.2 Install Dependencies
```bash
# Install required libraries
apt update
apt install -y libicu-dev libssl-dev postgresql unzip

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql
```

#### 3.3 Setup Database
```bash
# Create database
sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQL'
CREATE DATABASE attendancedb;
SQL

# Create user with password (use here-doc to avoid shell issues)
sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQL'
CREATE USER attendanceuser WITH PASSWORD 'Pivot@9492989700';
SQL

# Grant privileges
sudo -u postgres psql -d attendancedb -v ON_ERROR_STOP=1 <<'SQL'
GRANT ALL ON SCHEMA public TO attendanceuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO attendanceuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO attendanceuser;
SQL
```

#### 3.4 Update Backend Configuration
```bash
# Update appsettings.Production.json with correct password
sed -i.bak 's|Password=MarkAudio@2025!Secure|Password=Pivot@9492989700|g' /home/pivot/app/backend/appsettings.Production.json

# Verify the change
grep "DefaultConnection" /home/pivot/app/backend/appsettings.Production.json
```

**Expected output:**
```
"DefaultConnection": "Host=localhost;Port=5432;Database=attendancedb;Username=attendanceuser;Password=Pivot@9492989700;Timezone=Asia/Kolkata"
```

#### 3.5 Configure Firewall
```bash
# Allow backend port 5001
ufw allow 5001/tcp

# Allow SSH (if needed)
ufw allow 22/tcp

# Enable firewall
ufw --force enable

# Check firewall status
ufw status
```

#### 3.6 Create Systemd Service
```bash
# Create service file
cat > /etc/systemd/system/deskattendance.service <<'EOF'
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
Environment="ASPNETCORE_ENVIRONMENT=Production"
Environment="DOTNET_PRINT_TELEMETRY_MESSAGE=false"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable service to start on boot
systemctl enable deskattendance

# Start service
systemctl start deskattendance

# Check status
systemctl status deskattendance
```

**Expected output:**
```
● deskattendance.service - Desk Attendance Backend API
     Loaded: loaded (/etc/systemd/system/deskattendance.service; enabled)
     Active: active (running) since ...
   Main PID: ... (backend)
      Tasks: 20
     Memory: 56.4M
        CPU: 1.602s
```

---

### **STEP 4: Verify Deployment**

#### 4.1 Check Service Status
```bash
# Check if backend is running
systemctl status deskattendance

# Check logs for errors
journalctl -u deskattendance -n 50 --no-pager

# Check if port is listening
ss -tlnp | grep 5001
```

**Expected output:**
```
LISTEN 0  512  0.0.0.0:5001  0.0.0.0:*  users:(("backend",pid=...,fd=293))
```

#### 4.2 Test Local Access (on server)
```bash
# Test health endpoint (may return 404 - that's OK)
curl -v http://localhost:5001/api/health

# Test login endpoint (should return 405 Method Not Allowed)
curl -v http://localhost:5001/api/auth/login
```

#### 4.3 Test External Access (from Windows)
```powershell
# Test from Windows PowerShell
Invoke-WebRequest -Uri "http://72.61.226.129:5001/api/auth/login" -Method GET -UseBasicParsing
```

**Expected:** 405 Method Not Allowed (means endpoint is reachable)

---

## 🔧 Useful Management Commands

### Service Management
```bash
# Start service
systemctl start deskattendance

# Stop service
systemctl stop deskattendance

# Restart service
systemctl restart deskattendance

# Check status
systemctl status deskattendance

# View logs (last 100 lines)
journalctl -u deskattendance -n 100 --no-pager

# View logs (real-time)
journalctl -u deskattendance -f

# View logs (with errors only)
journalctl -u deskattendance -p err --no-pager
```

### Database Management
```bash
# Connect to PostgreSQL
sudo -u postgres psql

# List databases
\l

# Connect to attendancedb
\c attendancedb

# List tables
\dt

# View table structure
\d "Employees"

# Query data
SELECT * FROM "Employees" LIMIT 5;

# Exit
\q
```

### Update Backend (After Changes)
```bash
# Stop service
systemctl stop deskattendance

# Backup current backend
mv /home/pivot/app/backend /home/pivot/app/backend.backup.$(date +%Y%m%d_%H%M%S)

# Upload new backend-upload.zip via HestiaCP File Manager

# Extract new files
cd /home/pivot/app
unzip -q backend-upload.zip -d backend/
chmod +x /home/pivot/app/backend/backend
chown -R pivot:pivot /home/pivot/app

# Update config if needed
sed -i 's|Password=MarkAudio@2025!Secure|Password=Pivot@9492989700|g' /home/pivot/app/backend/appsettings.Production.json

# Start service
systemctl start deskattendance

# Check status
systemctl status deskattendance
```

---

## ❓ Troubleshooting

### Backend Not Starting
```bash
# Check logs for errors
journalctl -u deskattendance -n 200 --no-pager

# Common issues:
# 1. Permission denied → Check ownership: ls -la /home/pivot/app/backend/backend
# 2. Port already in use → Check: ss -tlnp | grep 5001
# 3. Database connection failed → Verify password in appsettings.Production.json
```

### Database Connection Errors
```bash
# Test database connection manually
PGPASSWORD='Pivot@9492989700' psql -h localhost -U attendanceuser -d attendancedb -c '\dt'

# If fails, reset password:
sudo -u postgres psql -c "ALTER ROLE attendanceuser WITH PASSWORD 'Pivot@9492989700';"
```

### Port 5001 Not Accessible Externally
```bash
# Check firewall
ufw status

# Allow port if blocked
ufw allow 5001/tcp

# Check if backend is listening on all interfaces (0.0.0.0)
ss -tlnp | grep 5001
```

### Service Keeps Restarting
```bash
# View crash logs
journalctl -u deskattendance -n 500 --no-pager | grep -i error

# Check for core dumps
coredumpctl list | tail -20

# View specific core dump
coredumpctl info <PID>
```

---

## 🤔 About HestiaCP

### **Was HestiaCP Necessary?**

**No**, HestiaCP is **NOT required** for deployment. It was used as a **convenience tool** because:

1. **Web Terminal** - Easy command-line access without SSH client
2. **File Manager** - GUI upload for ZIP files (alternative to SCP)
3. **System Management** - Nice interface for monitoring

### **Alternative Deployment Methods (Without HestiaCP):**

#### Method 1: Direct SSH
```powershell
# From Windows PowerShell
# Upload backend
scp -r backend/publish-linux/* root@72.61.226.129:/home/pivot/app/backend/

# Connect via SSH
ssh root@72.61.226.129

# Run all deployment commands directly
```

#### Method 2: Pure Command Line
```bash
# All commands can be run via standard SSH without any control panel:
ssh root@72.61.226.129 << 'EOF'
  # Install dependencies
  apt update && apt install -y libicu-dev libssl-dev postgresql unzip
  
  # Setup database
  sudo -u postgres psql -c "CREATE DATABASE attendancedb;"
  # ... rest of commands ...
EOF
```

### **HestiaCP Benefits:**
- ✅ Web-based terminal (no SSH client needed)
- ✅ File upload GUI (no SCP needed)
- ✅ Visual monitoring
- ✅ Beginner-friendly

### **Without HestiaCP:**
- ✅ Lighter server (less RAM/CPU usage)
- ✅ More control
- ✅ Standard Linux setup
- ❌ Need SSH client (PuTTY, Windows Terminal, etc.)
- ❌ Need SCP/SFTP for file uploads

---

## 📝 Summary

**You successfully deployed .NET backend on Ubuntu 24.04 with:**
- ✅ PostgreSQL 16 database
- ✅ Systemd service (auto-starts on boot)
- ✅ Firewall configured
- ✅ External access working
- ✅ All bug fixes deployed (UTC timezone, dropdown, SVG icons)

**Next time, you can:**
1. Use this guide to redeploy in ~10 minutes
2. Skip HestiaCP and use direct SSH if you prefer
3. Automate with a deployment script

---

**Created:** November 28, 2025  
**Server:** 72.61.226.129:5001  
**Backend Status:** ✅ Active and Running
