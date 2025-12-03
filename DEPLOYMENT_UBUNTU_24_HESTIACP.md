# Complete Deployment Guide - Ubuntu 24.04 + HestiaCP

## ✅ Ubuntu 24.04 with HestiaCP - Good Choice!

**Advantages:**
- Easy server management via web interface
- Built-in nginx/Apache web server
- SSL certificate management
- PostgreSQL database management
- Firewall configuration UI
- File manager and SSH access

---

## 📋 Step-by-Step Deployment

### **STEP 1: Connect to Your VPS**

Open PowerShell and connect:

```powershell
ssh root@72.61.226.129
# Or if using pivot user:
ssh pivot@72.61.226.129
```

**Note:** HestiaCP default admin is usually accessible at: `https://72.61.226.129:8083`

---

### **STEP 2: Install .NET 9.0 Runtime**

Your backend requires .NET 9.0. Since you published as self-contained, it includes runtime, but we need dependencies:

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install required dependencies for .NET
sudo apt install -y libicu-dev libssl-dev ca-certificates

# Verify system
lsb_release -a
```

---

### **STEP 3: Setup PostgreSQL Database**

HestiaCP likely has PostgreSQL installed. Configure it:

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start if not running
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql <<EOF
CREATE DATABASE attendancedb;
CREATE USER attendanceuser WITH PASSWORD 'MarkAudio@2025!Secure';
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;
ALTER DATABASE attendancedb OWNER TO attendanceuser;
\q
EOF

# Configure PostgreSQL to allow password authentication
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

**Edit pg_hba.conf** - Change this line:
```
# FROM:
local   all             all                                     peer

# TO:
local   all             all                                     md5
```

**Restart PostgreSQL:**
```bash
sudo systemctl restart postgresql
```

---

### **STEP 4: Create Application Directory**

```bash
# Create app directory
sudo mkdir -p /home/pivot/app/backend
sudo chown -R pivot:pivot /home/pivot/app

# Switch to pivot user (if logged in as root)
su - pivot

# Or create directory as pivot user
mkdir -p /home/pivot/app/backend
mkdir -p /home/pivot/app/backend-new
```

---

### **STEP 5: Upload Backend Files**

**From your Windows machine (PowerShell):**

```powershell
# Navigate to project
cd P:\SourceCode-PIVOT\DeskAttendanceApp

# Copy backend files to VPS
scp -r backend/publish-linux/* pivot@72.61.226.129:/home/pivot/app/backend-new/

# Wait for upload to complete (115 MB)
```

**Expected output:** Transfer progress, then "100%"

---

### **STEP 6: Configure Backend on VPS**

**Back on VPS SSH session:**

```bash
# Move files to correct location
cd /home/pivot/app
mv backend-new/* backend/
rmdir backend-new

# Set execute permissions
chmod +x /home/pivot/app/backend/backend

# Verify files
ls -lah /home/pivot/app/backend/
```

**Update appsettings.Production.json:**

```bash
cd /home/pivot/app/backend
nano appsettings.Production.json
```

**Content should be:**
```json
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
```

**Save:** `Ctrl+X`, `Y`, `Enter`

---

### **STEP 7: Configure Firewall**

```bash
# Allow port 5001 for backend API
sudo ufw allow 5001/tcp

# Check HestiaCP firewall status
sudo ufw status

# If firewall is inactive, enable it
sudo ufw enable
```

**Or via HestiaCP Web UI:**
- Login to HestiaCP: `https://72.61.226.129:8083`
- Go to: **Server** → **Firewall**
- Add rule: Port `5001`, Protocol `TCP`, Action `ACCEPT`

---

### **STEP 8: Create Systemd Service**

This makes your backend run automatically on boot:

```bash
# Create service file
sudo nano /etc/systemd/system/deskattendance.service
```

**Service content:**
```ini
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

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=deskattendance

[Install]
WantedBy=multi-user.target
```

**Save:** `Ctrl+X`, `Y`, `Enter`

**Enable and start service:**

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable deskattendance

# Start service
sudo systemctl start deskattendance

# Check status
sudo systemctl status deskattendance
```

**Expected output:** `active (running)`

---

### **STEP 9: Verify Backend is Running**

**Test from VPS:**
```bash
# Test health endpoint
curl http://localhost:5001/api/health

# Check if backend is listening on port 5001
sudo netstat -tulnp | grep 5001
```

**Test from your Windows machine:**
```powershell
# Test from PowerShell
Invoke-WebRequest -Uri "http://72.61.226.129:5001/api/health" -UseBasicParsing

# Or use browser:
# Open: http://72.61.226.129:5001/api/health
```

**Expected:** "Healthy" or 200 OK response

---

### **STEP 10: Run Database Migrations**

Your backend should auto-create tables on first run, but verify:

```bash
# Check backend logs
sudo journalctl -u deskattendance -f

# Press Ctrl+C to stop watching logs

# Or check last 50 lines
sudo journalctl -u deskattendance -n 50
```

**Look for:**
- "Now listening on: http://0.0.0.0:5001"
- Database connection success
- No errors

---

### **STEP 11: Test Backend Endpoints**

**From Windows PowerShell:**

```powershell
# Test login endpoint (should fail with proper error)
$body = @{
    email = "test@test.com"
    password = "test123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://72.61.226.129:5001/api/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body `
    -UseBasicParsing
```

**Expected:** 401 Unauthorized or proper error message (proves backend is working)

---

### **STEP 12: Configure Reverse Proxy (Optional)**

If you want to use domain name and SSL:

**Via HestiaCP:**
1. Login to HestiaCP: `https://72.61.226.129:8083`
2. Go to **Web** → **Add Web Domain**
3. Enter domain: `attendance.yourdomain.com`
4. Enable SSL (Let's Encrypt)
5. Add reverse proxy config

**Or manually with nginx:**

```bash
sudo nano /etc/nginx/sites-available/attendance
```

**Config:**
```nginx
server {
    listen 80;
    server_name attendance.yourdomain.com;

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

**Enable:**
```bash
sudo ln -s /etc/nginx/sites-available/attendance /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔍 Troubleshooting Commands

### Check Backend Status
```bash
# Service status
sudo systemctl status deskattendance

# View logs
sudo journalctl -u deskattendance -f

# Check if port is open
sudo netstat -tulnp | grep 5001

# Check process
ps aux | grep backend
```

### Database Issues
```bash
# Connect to database
sudo -u postgres psql -d attendancedb

# List tables
\dt

# Check user permissions
\du

# Exit
\q
```

### Restart Services
```bash
# Restart backend
sudo systemctl restart deskattendance

# Restart PostgreSQL
sudo systemctl restart postgresql

# Restart nginx (if using reverse proxy)
sudo systemctl restart nginx
```

### View All Logs
```bash
# Backend logs
sudo journalctl -u deskattendance -n 100

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-16-main.log

# Nginx logs (if using)
sudo tail -f /var/log/nginx/error.log
```

---

## 📱 Deploy Electron Installer

**On Client Machines:**

1. Copy installer: `electron-app/dist/EMPLOYEE TIMEPULSE.exe`
2. Run installer on Windows machines
3. During first launch, it will use: `http://72.61.226.129:5001`

**If you setup domain with SSL:**
- Update `react-app/src/config/networkConfig.js`
- Change API_BASE_URL to: `https://attendance.yourdomain.com`
- Rebuild React & Electron

---

## ✅ Verification Checklist

- [ ] PostgreSQL running: `sudo systemctl status postgresql`
- [ ] Database created: `sudo -u postgres psql -l | grep attendancedb`
- [ ] Backend service running: `sudo systemctl status deskattendance`
- [ ] Port 5001 open: `sudo ufw status | grep 5001`
- [ ] Health endpoint responds: `curl http://localhost:5001/api/health`
- [ ] External access works: `http://72.61.226.129:5001/api/health`
- [ ] Logs show no errors: `sudo journalctl -u deskattendance -n 50`

---

## 🚀 Quick Deployment Script

Save this as `deploy.sh` on VPS:

```bash
#!/bin/bash

echo "=== Deploying Backend ==="

# Stop service
sudo systemctl stop deskattendance

# Backup old version
rm -rf /home/pivot/app/backend-backup
mv /home/pivot/app/backend /home/pivot/app/backend-backup

# Move new version
mv /home/pivot/app/backend-new /home/pivot/app/backend

# Set permissions
chmod +x /home/pivot/app/backend/backend

# Start service
sudo systemctl start deskattendance

# Wait for startup
sleep 3

# Check status
sudo systemctl status deskattendance --no-pager

# Test endpoint
curl http://localhost:5001/api/health

echo "=== Deployment Complete ==="
```

**Make executable:**
```bash
chmod +x deploy.sh
```

**Run after uploading new files:**
```bash
./deploy.sh
```

---

## 📞 Support Commands

**If backend won't start:**
```bash
# Check what's using port 5001
sudo lsof -i :5001

# Kill process if needed
sudo kill -9 <PID>

# Check file permissions
ls -lah /home/pivot/app/backend/backend

# Try running manually to see errors
cd /home/pivot/app/backend
./backend
```

**If database connection fails:**
```bash
# Test connection
psql -h localhost -U attendanceuser -d attendancedb
# Enter password: MarkAudio@2025!Secure

# Check PostgreSQL is listening
sudo netstat -tulnp | grep 5432
```

---

## 🎯 Next Steps After Deployment

1. **Create admin user** via backend endpoint or database
2. **Register employees** in the system
3. **Configure network settings** (Router MAC, Gateway IP)
4. **Test punch in/out** from client app
5. **Setup backup** for database
6. **Configure SSL** for production use

**HestiaCP makes this easier** - you can manage database, backups, and SSL certificates from the web interface!

**Deployment Date:** November 28, 2025  
**Server:** Ubuntu 24.04 + HestiaCP  
**Backend:** .NET 9.0 Self-Contained  
**Database:** PostgreSQL 16  
**Port:** 5001
