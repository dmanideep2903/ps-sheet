# 🚀 Hostinger VPS KVM 4 Deployment Guide
## Ubuntu 24.04 LTS - Complete Setup

This guide will walk you through deploying your DeskAttendance application on Hostinger VPS from scratch.

---

## 📋 Prerequisites

- Hostinger account with VPS KVM 4 plan purchased
- Your Windows PC with this project
- Basic terminal knowledge

---

## PART 1: Initial VPS Setup (Hostinger Dashboard)

### Step 1: Create VPS Instance

1. **Login to Hostinger**
   - Go to: https://hpanel.hostinger.com/
   - Login with your credentials

2. **Access VPS Section**
   - Click on "VPS" in the left sidebar
   - Click on your VPS KVM 4 plan

3. **Create New VPS**
   - Click "Set Up" or "Create VPS"
   - Choose **Ubuntu 24.04 LTS** as operating system
   - Choose your datacenter location (closest to your users)
   - Click "Create"
   - Wait 2-5 minutes for provisioning

4. **Get VPS Credentials**
   - Once created, you'll see:
     - **IP Address** (e.g., 203.0.113.45)
     - **Root password** (or SSH key if you set one)
     - **SSH port** (usually 22)
   - **IMPORTANT:** Save these credentials securely!

### Step 2: Access VPS via SSH

**Option A: Using Hostinger's Browser Terminal (Easiest)**
1. In Hostinger dashboard, click "Open Terminal" or "Browser SSH"
2. Login with root credentials
3. Skip to Part 2

**Option B: Using Windows PowerShell**
1. Open PowerShell on your Windows PC
2. Run:
```powershell
ssh root@YOUR_VPS_IP
# Replace YOUR_VPS_IP with actual IP (e.g., 203.0.113.45)
```
3. Type `yes` when prompted about fingerprint
4. Enter root password
5. You should see: `root@vps-hostname:~#`

---

## PART 2: Secure Your VPS (Ubuntu Terminal)

### Step 1: Update System
```bash
apt update && apt upgrade -y
```
*This takes 2-5 minutes*

### Step 2: Create a Non-Root User
```bash
# Create new user (replace 'deployuser' with your preferred username)
adduser deployuser

# Follow prompts:
# - Enter password (twice)
# - Full name: (press Enter to skip)
# - Other fields: (press Enter to skip)
# - Is the information correct? Y

# Give sudo privileges
usermod -aG sudo deployuser
```

### Step 3: Configure Firewall
```bash
# Install and enable UFW firewall
ufw allow OpenSSH
ufw allow 5001/tcp    # Backend API
ufw allow 80/tcp      # HTTP (optional, for future)
ufw allow 443/tcp     # HTTPS (optional, for future)
ufw enable

# Check status
ufw status
```

### Step 4: Switch to New User
```bash
# Login as new user
su - deployuser

# Verify sudo access
sudo whoami
# Should output: root
```

---

## PART 3: Install PostgreSQL Database

### Step 1: Install PostgreSQL
```bash
sudo apt install postgresql postgresql-contrib -y

# Check PostgreSQL is running
sudo systemctl status postgresql
# Press 'q' to exit
```

### Step 2: Configure PostgreSQL
```bash
# Switch to postgres user
sudo -u postgres psql

# You'll see: postgres=#
```

### Step 3: Create Database and User
```sql
-- Create database
CREATE DATABASE attendancedb;

-- Create user with password
CREATE USER attendanceuser WITH PASSWORD 'YourStrongPassword123!';

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;

-- Grant schema permissions (required for PostgreSQL 15+)
\c attendancedb
GRANT ALL ON SCHEMA public TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO attendanceuser;

-- Exit psql
\q
```

### Step 4: Configure PostgreSQL for Remote Connections
```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/16/main/postgresql.conf

# Find this line (around line 59):
#listen_addresses = 'localhost'

# Change to:
listen_addresses = '*'

# Save and exit (Ctrl+X, then Y, then Enter)
```

```bash
# Edit pg_hba.conf
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Add this line at the end:
host    attendancedb    attendanceuser    0.0.0.0/0    md5

# Save and exit (Ctrl+X, then Y, then Enter)
```

```bash
# Restart PostgreSQL
sudo systemctl restart postgresql

# Verify it's running
sudo systemctl status postgresql
```

### Step 5: Test Database Connection
```bash
# Test local connection
psql -U attendanceuser -d attendancedb -h localhost

# If successful, you'll see: attendancedb=>
# Type \q to exit
```

---

## PART 4: Install .NET 8 SDK

### Step 1: Install .NET 8
```bash
# Add Microsoft package repository
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install .NET 8 SDK
sudo apt update
sudo apt install -y dotnet-sdk-8.0

# Verify installation
dotnet --version
# Should show: 8.0.x
```

---

## PART 5: Deploy Backend Application

### Step 1: Prepare Local Build (On Your Windows PC)

Open PowerShell in your project folder:
```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Build for Linux
dotnet publish -c Release -r linux-x64 --self-contained false -o publish
```

### Step 2: Create Deployment Package
```powershell
# Compress the publish folder
Compress-Archive -Path publish\* -DestinationPath backend-deploy.zip

# The file will be at: P:\SourceCode-PIVOT\DeskAttendanceApp\backend\backend-deploy.zip
```

### Step 3: Upload to VPS

**Option A: Using SCP (Recommended)**
```powershell
# In PowerShell on Windows
scp backend-deploy.zip deployuser@YOUR_VPS_IP:/home/deployuser/

# Enter password when prompted
```

**Option B: Using Hostinger File Manager**
1. In Hostinger dashboard, go to "File Manager"
2. Navigate to `/home/deployuser/`
3. Upload `backend-deploy.zip`

### Step 4: Extract on VPS

Back in your SSH terminal (as deployuser):
```bash
cd /home/deployuser

# Create app directory
mkdir -p ~/app/backend
cd ~/app/backend

# Extract files
unzip ~/backend-deploy.zip

# Make the binary executable
chmod +x ./backend

# Verify files
ls -la
# You should see: backend, appsettings.json, etc.
```

### Step 5: Configure Production Settings
```bash
# Create production appsettings
nano appsettings.Production.json
```

Paste this content (replace placeholders):
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
    "DefaultConnection": "Host=localhost;Database=attendancedb;Username=attendanceuser;Password=YourStrongPassword123!"
  }
}
```

**Replace:**
- `YourStrongPassword123!` with the password you set in Part 3, Step 3

Save and exit (Ctrl+X, Y, Enter)

### Step 6: Apply Database Migrations

**Note:** Your backend automatically applies migrations on startup, but you can also run it manually.

**Option A: Automatic (Recommended) - Skip this step**
The backend will automatically run migrations when it starts for the first time.

**Option B: Manual Migration (If needed)**
```bash
cd ~/app/backend

# Set environment to Production
export ASPNETCORE_ENVIRONMENT=Production

# Run the backend once - it will apply migrations automatically
./backend
# You'll see migration messages, then press Ctrl+C after it says "Application started"
```

### Step 7: Test Backend Manually
```bash
cd ~/app/backend
export ASPNETCORE_ENVIRONMENT=Production
./backend
```

You should see:
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://0.0.0.0:5001
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

**Test from another terminal:**
```bash
curl http://localhost:5001/health
# Should return: {"status":"ok"}
```

Press `Ctrl+C` to stop the backend.

---

## PART 6: Setup Backend as System Service

### Step 1: Create systemd Service File
```bash
sudo nano /etc/systemd/system/deskattendance.service
```

Paste this content:
```ini
[Unit]
Description=DeskAttendance Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=pivot
Group=pivot
WorkingDirectory=/home/pivot/app/backend
ExecStart=/home/pivot/app/backend/backend
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=deskattendance
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
```

Save and exit (Ctrl+X, Y, Enter)

### Step 2: Enable and Start Service
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

You should see:
```
● deskattendance.service - DeskAttendance Backend API
     Loaded: loaded (/etc/systemd/system/deskattendance.service; enabled)
     Active: active (running) since ...
```

### Step 3: Verify Service is Working
```bash
# Test health endpoint
curl http://localhost:5001/health
# Should return: {"status":"ok"}

# Check logs
sudo journalctl -u deskattendance -f
# Press Ctrl+C to exit
```

---

## PART 7: Configure Electron Apps

### Step 1: Get Your VPS IP Address
```bash
# On VPS, get your public IP
curl ifconfig.me
# Note this IP (e.g., 203.0.113.45)
```

### Step 2: Update Company Config Files (On Windows PC)

Edit each config file in `electron-app/` folder:

**File: `appConfig-MarkAudio.json`**
```json
{
  "companyId": "markaudio_001",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://YOUR_VPS_IP:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/deskattendance/releases/latest"
  }
}
```

**File: `appConfig-CompanyA.json`**
```json
{
  "companyId": "companyA_002",
  "companyName": "Company A",
  "apiBaseUrl": "http://YOUR_VPS_IP:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/deskattendance/releases/latest"
  }
}
```

Repeat for all company config files, replacing `YOUR_VPS_IP` with your actual VPS IP.

### Step 3: Rebuild Installers
```powershell
# In PowerShell on Windows
cd P:\SourceCode-PIVOT\DeskAttendanceApp

# Build all installers
.\BUILD_INSTALLERS.ps1

# Or build specific company
.\BUILD_INSTALLERS.ps1 -CompanyName "MarkAudio"
```

### Step 4: Test Installation
1. Install the generated `.exe` file on a client machine
2. App should connect to your VPS backend
3. Create admin account and test functionality

---

## PART 8: Monitoring & Maintenance

### Check Backend Status
```bash
sudo systemctl status deskattendance
```

### View Live Logs
```bash
sudo journalctl -u deskattendance -f
```

### Restart Backend
```bash
sudo systemctl restart deskattendance
```

### Stop Backend
```bash
sudo systemctl stop deskattendance
```

### Check Database Connections
```bash
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE datname = 'attendancedb';"
```

### Backup Database
```bash
# Create backup
sudo -u postgres pg_dump attendancedb > ~/backups/attendancedb_$(date +%Y%m%d).sql

# Restore backup
sudo -u postgres psql attendancedb < ~/backups/attendancedb_20241124.sql
```

---

## PART 9: Deploy Updates

### When You Update Backend Code:

**On Windows PC:**
```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Build new version
dotnet publish -c Release -r linux-x64 --self-contained false -o publish

# Create package
Compress-Archive -Path publish\* -DestinationPath backend-deploy-v2.zip -Force

# Upload to VPS
scp backend-deploy-v2.zip deployuser@YOUR_VPS_IP:/home/deployuser/
```

**On VPS:**
```bash
cd ~/app/backend

# Stop service
sudo systemctl stop deskattendance

# Backup current version
cd ~/app
cp -r backend backend-backup-$(date +%Y%m%d)

# Extract new version
cd backend
unzip -o ~/backend-deploy-v2.zip

# Apply new migrations if any
export ASPNETCORE_ENVIRONMENT=Production
dotnet ef database update

# Start service
sudo systemctl start deskattendance

# Check status
sudo systemctl status deskattendance
```

---

## 🔒 PART 10: Security Hardening (Recommended)

### Step 1: Disable Root SSH Login
```bash
sudo nano /etc/ssh/sshd_config

# Find and change:
PermitRootLogin no

# Save and restart SSH
sudo systemctl restart sshd
```

### Step 2: Setup Automatic Security Updates
```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
# Select "Yes"
```

### Step 3: Install Fail2Ban (Prevent Brute Force)
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Step 4: Setup SSL/HTTPS (Optional but Recommended)

**Install Nginx as Reverse Proxy:**
```bash
sudo apt install nginx -y

# Configure Nginx
sudo nano /etc/nginx/sites-available/deskattendance
```

Paste:
```nginx
server {
    listen 80;
    server_name YOUR_VPS_IP;

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
sudo ln -s /etc/nginx/sites-available/deskattendance /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Update firewall
sudo ufw allow 'Nginx Full'

# Now your app is accessible at: http://YOUR_VPS_IP (port 80)
```

---

## 🧪 PART 11: Testing Checklist

- [ ] VPS is accessible via SSH
- [ ] PostgreSQL is running and accessible
- [ ] Backend service is running: `sudo systemctl status deskattendance`
- [ ] Health check works: `curl http://localhost:5001/health`
- [ ] External access works: Test from Windows browser: `http://YOUR_VPS_IP:5001/health`
- [ ] Electron app can connect and login
- [ ] Database migrations applied successfully
- [ ] Logs are clean: `sudo journalctl -u deskattendance -n 50`
- [ ] Service auto-starts after reboot: `sudo reboot` then check status

---

## 📊 Your VPS Architecture

```
┌─────────────────────────────────────────┐
│         Hostinger VPS KVM 4             │
│         Ubuntu 24.04 LTS                │
│         IP: YOUR_VPS_IP                 │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Backend API (.NET 8)              │ │
│  │  Port: 5001                        │ │
│  │  User: deployuser                  │ │
│  │  Service: deskattendance.service   │ │
│  └───────────────────────────────────┘ │
│               │                         │
│               ▼                         │
│  ┌───────────────────────────────────┐ │
│  │  PostgreSQL 16                     │ │
│  │  Database: attendancedb            │ │
│  │  User: attendanceuser              │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  UFW Firewall                      │ │
│  │  - SSH (22)                        │ │
│  │  - API (5001)                      │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  Client Machines     │
    │  Electron Apps       │
    │  (Multiple Companies)│
    └──────────────────────┘
```

---

## ⚠️ Important Notes

1. **Save Your VPS IP**: You'll need it for all client configurations
2. **Secure Your Passwords**: Use strong passwords for:
   - VPS root/user
   - PostgreSQL database
   - Admin accounts
3. **Regular Backups**: Setup automated database backups
4. **Monitor Resources**: VPS KVM 4 specs (check Hostinger dashboard)
5. **Update Electron Apps**: After deployment, rebuild and redistribute installers

---

## 🆘 Troubleshooting

### Backend Won't Start
```bash
# Check logs
sudo journalctl -u deskattendance -n 100

# Check if port 5001 is already in use
sudo netstat -tulpn | grep 5001

# Test manually
cd ~/app/backend
export ASPNETCORE_ENVIRONMENT=Production
./backend
```

### Can't Connect to Database
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U attendanceuser -d attendancedb -h localhost

# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

### Firewall Blocking Connections
```bash
# Check firewall status
sudo ufw status

# Allow port 5001
sudo ufw allow 5001/tcp

# Reload firewall
sudo ufw reload
```

### Electron App Can't Connect
1. Verify VPS IP in `appConfig.json`
2. Test from Windows browser: `http://YOUR_VPS_IP:5001/health`
3. Check Windows firewall isn't blocking outbound connections
4. Verify backend is running: `sudo systemctl status deskattendance`

---

## 📞 Quick Reference Commands

```bash
# Service Management
sudo systemctl start deskattendance
sudo systemctl stop deskattendance
sudo systemctl restart deskattendance
sudo systemctl status deskattendance

# View Logs
sudo journalctl -u deskattendance -f          # Live logs
sudo journalctl -u deskattendance -n 100      # Last 100 lines

# Database
sudo -u postgres psql attendancedb            # Connect to DB
sudo systemctl restart postgresql             # Restart PostgreSQL

# System
htop                                          # Monitor resources
df -h                                         # Check disk space
free -h                                       # Check memory
```

---

## 🎉 You're Done!

Your DeskAttendance application is now:
- ✅ Deployed on Hostinger VPS
- ✅ Running on Ubuntu 24.04 LTS
- ✅ Using PostgreSQL database
- ✅ Configured as system service (auto-start on boot)
- ✅ Secured with firewall
- ✅ Ready to serve multiple companies

**Next Steps:**
1. Test with one client installation
2. Setup automated backups
3. Configure SSL/HTTPS (optional)
4. Deploy to all companies
5. Setup monitoring alerts

**Support:** If you encounter issues, check:
- Backend logs: `sudo journalctl -u deskattendance -f`
- PostgreSQL logs: `sudo tail -f /var/log/postgresql/postgresql-16-main.log`
- System resources: `htop`

---

**Last Updated:** November 24, 2025
**Version:** 1.0
**Tested On:** Hostinger VPS KVM 4, Ubuntu 24.04 LTS
