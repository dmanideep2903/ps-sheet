# 🚀 Oracle Cloud ARM Instance - Complete Setup Guide
**For: DeskAttendance App - MarkAudio Company**
**Date: November 18, 2025**

---

## 📌 RECOMMENDED CONFIGURATION

```yaml
Cloud Provider: Oracle Cloud (Always Free Tier)
Region: AP-HYDERABAD-1 (or AP-MUMBAI-1 as fallback)
Instance Type: Compute - Virtual Machine
Image: Canonical Ubuntu 22.04 Minimal aarch64
Shape: VM.Standard.A1.Flex (ARM-based Ampere)
OCPUs: 4 (or 2 if 4 not available)
Memory: 24 GB (or 12 GB if 2 OCPUs)
Boot Volume: 100 GB (expandable to 200 GB free)
Network: Public IP required
Architecture: ARM64 (aarch64)
```

**Why Ubuntu 22.04 Minimal aarch64?**
- ✅ LTS support until April 2027
- ✅ ARM64 architecture (matches A1.Flex)
- ✅ Minimal = lightweight, faster boot
- ✅ Always Free eligible
- ✅ .NET 9 fully supported on ARM64
- ✅ PostgreSQL 16 available
- ✅ Well-tested and stable

---

## ⚠️ BEFORE YOU START - CRITICAL CHECKLIST

### Pre-Setup Requirements (Do Tonight)

- [ ] **Oracle Account Ready**
  - Login works: https://cloud.oracle.com
  - Email verified
  - Credit card added (for identity, not charged)
  - Home region selected (AP-HYDERABAD-1)

- [ ] **Computer Prepared**
  - Laptop fully charged (100%)
  - Stable internet (test: `ping oracle.com`)
  - Windows PowerShell ready
  - SSH client available (built-in on Windows 10+)

- [ ] **Time Allocated**
  - 6:00-8:00 AM IST (2 hours)
  - No interruptions expected
  - Coffee ready ☕

- [ ] **Backup Plan**
  - Mumbai region as fallback
  - 2 OCPU config if 4 not available
  - x86_64 Micro instance as last resort

---

## 🎯 PHASE 1: CREATE ORACLE CLOUD INSTANCE (6:00-6:20 AM)

### Step 1.1: Login to Oracle Cloud (2 min)

```
1. Open browser: https://cloud.oracle.com
2. Click "Sign in to Cloud"
3. Enter Cloud Account Name: <your-tenancy-name>
4. Click "Next"
5. Enter username and password
6. Wait for OCI Console to load
```

**Expected Result:**
- Oracle Cloud Console dashboard visible
- Region shown in top-right (e.g., "India South (Hyderabad)")

---

### Step 1.2: Navigate to Compute Instances (1 min)

```
1. Click hamburger menu (≡) on top-left
2. Scroll to "Compute"
3. Click "Instances"
4. Verify you're in correct compartment (usually "root")
5. Click "Create Instance" button (blue button)
```

---

### Step 1.3: Configure Instance - Basic Details (2 min)

**Name:**
```
deskattendance-production
```

**Create in Compartment:**
```
(root) - Keep default
```

**Placement:**
```
Availability Domain: AD-1
  (Hyderabad usually has only 1 AD)

Capacity Type: On-demand capacity
  (Keep default)

Fault Domain: Let Oracle choose
  (Keep default)
```

**Click "Show Advanced Options" (optional but recommended):**
```
Shielded Instance: ✅ Enable
  - Secure Boot: ✅ Enable
  - Measured Boot: ✅ Enable
  - Trusted Platform Module: ✅ Enable
```

---

### Step 1.4: Configure Image and Shape (5 min) ⚠️ CRITICAL

#### Image Selection:

**Click "Edit" next to "Image and shape"**

**Then click "Change Image"**

```
Image Source: Platform images (default)

Operating System: Canonical Ubuntu

OS Version: 22.04 Minimal aarch64
  ⚠️ CRITICAL: Must say "aarch64" at the end!
  
  Look for this EXACT text:
  "Canonical Ubuntu 22.04 Minimal aarch64"
  
  Do NOT select:
  ❌ Ubuntu 22.04 Minimal (without aarch64)
  ❌ Ubuntu 24.04 (not available for A1.Flex)
  ❌ Ubuntu 20.04 (too old)

Click "Select Image" button
```

**Verify:**
- Image name shows: "Canonical-Ubuntu-22.04-Minimal-aarch64-..."
- Date shows recent build (2024 or 2025)

---

#### Shape Selection:

**Click "Change Shape"**

```
Instance Type: Virtual machine (default)

Shape Series: ⚠️ CRITICAL - Select "Ampere"
  NOT: AMD, Intel, or any other series

Shape Name: VM.Standard.A1.Flex
  (This is the ARM-based Always Free eligible shape)

Number of OCPUs: 
  TRY IN THIS ORDER:
  
  ATTEMPT 1: 4 OCPUs
    - Set slider to 4
    - Memory will auto-adjust to 24 GB
    - Click away from field
    - If no error appears → Keep this ✅
    - If error "Out of capacity" → Try Attempt 2
  
  ATTEMPT 2: 3 OCPUs
    - Set slider to 3
    - Memory: 18 GB (auto)
    - If works → Keep this ✅
    - If fails → Try Attempt 3
  
  ATTEMPT 3: 2 OCPUs
    - Set slider to 2
    - Memory: 12 GB (auto)
    - This usually works ✅
  
  ATTEMPT 4: 1 OCPU (minimum)
    - Set slider to 1
    - Memory: 6 GB (auto)
    - Should always work

Network Bandwidth: 2 Gbps (auto-set based on OCPUs)

Always Free Badge:
  - Look for "Always Free-eligible" badge
  - Must show this to stay free!

Click "Select Shape" button
```

**Verify:**
- Shape: VM.Standard.A1.Flex
- OCPUs: 2-4 (whatever you selected)
- Memory: 12-24 GB
- "Always Free-eligible" badge visible

---

### Step 1.5: Configure Networking (3 min) ⚠️ CRITICAL

**Primary VNIC Information:**

```
Create New Virtual Cloud Network:
  ⚪ Select existing virtual cloud network (NO)
  ⚫ Create new virtual cloud network (YES) ✅

New Virtual Cloud Network:
  Name: deskattendance-vcn
  Compartment: (root) - keep default

Create New Subnet:
  ⚪ Select existing subnet (NO)
  ⚫ Create new subnet (YES) ✅

New Subnet:
  Name: public-subnet-deskattendance
  Compartment: (root)
  Subnet Type: Regional (recommended)
  
  IPv4 CIDR Block: 10.0.0.0/24
    (default is fine)
  
  Subnet Access: Public Subnet ⚠️ CRITICAL
    ⚫ Public Subnet (YES) ✅
    ⚪ Private Subnet (NO)

Public IPv4 Address:
  ⚠️ CRITICAL - Must enable!
  ⚫ Assign a public IPv4 address ✅
  
  If you don't check this, you won't be able to access the server!

Private IPv4 Address:
  - Keep default (auto-assigned)

Hostname:
  - Keep default or enter: deskattendance-prod

Network Security Group:
  - Leave unchecked (we'll use Security List)
```

**Verify:**
- ✅ "Create new virtual cloud network" selected
- ✅ "Create new subnet" selected
- ✅ "Public Subnet" selected
- ✅ "Assign a public IPv4 address" CHECKED

---

### Step 1.6: Add SSH Keys (5 min) ⚠️ CRITICAL

**⚠️ STOP! Don't click "Create" yet!**

You need SSH key first. Two options:

---

#### Option A: Generate New SSH Key (Recommended)

**On Windows PowerShell:**

```powershell
# Create .ssh directory if doesn't exist
New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\oracle_cloud_key" -N ""

# This creates:
# - Private key: C:\Users\YourName\.ssh\oracle_cloud_key
# - Public key:  C:\Users\YourName\.ssh\oracle_cloud_key.pub

# Display public key
Get-Content "$env:USERPROFILE\.ssh\oracle_cloud_key.pub"
```

**Copy the output** (starts with `ssh-rsa AAAAB3...`)

**Alternative - Copy to clipboard:**
```powershell
Get-Content "$env:USERPROFILE\.ssh\oracle_cloud_key.pub" | Set-Clipboard
Write-Host "Public key copied to clipboard!" -ForegroundColor Green
```

---

#### Option B: Use Existing SSH Key (If you have one)

```powershell
# List existing keys
dir "$env:USERPROFILE\.ssh\*.pub"

# Display specific key
Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
```

---

**Back in Oracle Cloud Console:**

```
Add SSH Keys:
  ⚪ Generate a key pair for me (NO - less secure)
  ⚫ Paste public keys (YES) ✅

SSH Keys:
  [Paste your public key here]
  
  Should look like:
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-computer-name

  Make sure to paste ENTIRE key (one long line)
```

**Verify:**
- Text box shows key starting with "ssh-rsa"
- Key is complete (ends with username/hostname)
- No extra spaces or line breaks

---

### Step 1.7: Configure Boot Volume (2 min)

**Scroll down to "Boot Volume"**

```
Boot Volume Size: 
  - Default: 50 GB
  - Recommended: 100 GB ✅
  - Maximum Free: 200 GB
  
  ⚠️ Set to 100 GB for production use

Use in-transit encryption: ✅ Enable (recommended)

Encryption: Use Oracle-managed keys (default)
```

---

### Step 1.8: Advanced Options (Optional but Recommended)

**Click "Show Advanced Options"**

```
Management Tab:
  Cloud-init script: (optional - we'll configure manually)
  
  OR paste this for auto-update on boot:
  
  #!/bin/bash
  apt-get update -y
  apt-get upgrade -y
  timedatectl set-timezone Asia/Kolkata

Oracle Cloud Agent: ✅ Enable all (recommended)
  - Monitoring
  - Management
  - Bastion
```

---

### Step 1.9: Create Instance (1 min) 🚀

**Final Checklist Before Clicking "Create":**

- [ ] Name: deskattendance-production
- [ ] Image: Ubuntu 22.04 Minimal aarch64
- [ ] Shape: VM.Standard.A1.Flex
- [ ] OCPUs: 2-4 (whatever worked)
- [ ] Memory: 12-24 GB
- [ ] Always Free badge visible
- [ ] Network: Create new VCN
- [ ] Subnet: Public subnet
- [ ] **Public IPv4: CHECKED** ⚠️
- [ ] SSH key: Pasted correctly
- [ ] Boot volume: 100 GB

**All good? Click "Create" button!**

---

### Step 1.10: Wait for Provisioning (3-5 min)

```
Status: Provisioning (orange icon 🟠)
  ↓
  Wait 2-5 minutes
  ↓
Status: Running (green icon 🟢) ✅
```

**While Waiting:**
- Don't refresh page
- Don't close browser
- Grab coffee ☕

**After "Running" appears:**

```
Instance Details Page will show:

Public IP Address: XXX.XXX.XXX.XXX ⚠️ WRITE THIS DOWN!

Private IP Address: 10.0.0.X

Status: RUNNING ✅

Shape: VM.Standard.A1.Flex

Image: Canonical-Ubuntu-22.04-Minimal-aarch64
```

**Copy and save the Public IP address!**

---

## ⚠️ TROUBLESHOOTING - If Instance Creation Fails

### Error: "Out of host capacity"

**Solution 1: Try different OCPU count**
```
- Cancel instance creation
- Try again with:
  - 3 OCPUs / 18 GB
  - 2 OCPUs / 12 GB
  - 1 OCPU / 6 GB
```

**Solution 2: Try different time**
```
- Wait 30 minutes
- Try again at 6:30 AM or 7:00 AM
- Capacity often frees up
```

**Solution 3: Try Mumbai region**
```
1. Top-right corner → Click region name
2. Select "India West (Mumbai)" - AP-MUMBAI-1
3. Repeat instance creation
4. Mumbai usually has better ARM capacity
```

**Solution 4: Use x86 Free Tier (Last Resort)**
```
Shape: VM.Standard.E2.1.Micro
Image: Ubuntu 22.04 (x86_64)
OCPUs: 1
Memory: 1 GB
- Less powerful but always available
```

---

### Error: "Service limit exceeded"

**This means you already used your Always Free resources**

**Check:**
```
1. Console → Governance → Limits
2. Look for "Compute" limits
3. Check if you have other instances running
4. Delete old/unused instances
5. Try again
```

---

## 🔐 PHASE 2: CONFIGURE FIREWALL (6:20-6:25 AM)

**After instance is RUNNING, configure network rules:**

### Step 2.1: Open Security List

```
1. On Instance Details page
2. Scroll to "Primary VNIC" section
3. Click "Subnet" link (e.g., "public-subnet-deskattendance")
4. On left sidebar, click "Security Lists"
5. Click "Default Security List for deskattendance-vcn"
```

---

### Step 2.2: Add Ingress Rules

**Click "Add Ingress Rules"**

**Rule 1: ASP.NET Backend API (Port 5001)**
```
Stateless: ❌ Unchecked
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Source Port Range: All
Destination Port Range: 5001
Description: ASP.NET Backend API

Click "Add Ingress Rules"
```

**Rule 2: PostgreSQL (Port 5432) - Optional, for external access**
```
Stateless: ❌ Unchecked
Source Type: CIDR
Source CIDR: 0.0.0.0/0
  (⚠️ Security: In production, restrict to your IP only!)
IP Protocol: TCP
Destination Port Range: 5432
Description: PostgreSQL Database

Click "Add Ingress Rules"
```

**Rule 3: HTTP (Port 80) - For future web interface**
```
Stateless: ❌ Unchecked
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 80
Description: HTTP Web Access

Click "Add Ingress Rules"
```

**Rule 4: HTTPS (Port 443) - For secure access**
```
Stateless: ❌ Unchecked
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 443
Description: HTTPS Secure Web Access

Click "Add Ingress Rules"
```

---

## 🔌 PHASE 3: CONNECT TO SERVER (6:25-6:30 AM)

### Step 3.1: Test SSH Connection

**On Windows PowerShell:**

```powershell
# Set correct permissions on SSH key
icacls "$env:USERPROFILE\.ssh\oracle_cloud_key" /inheritance:r
icacls "$env:USERPROFILE\.ssh\oracle_cloud_key" /grant:r "$env:USERNAME:R"

# Connect to server
ssh -i "$env:USERPROFILE\.ssh\oracle_cloud_key" ubuntu@YOUR_PUBLIC_IP

# Replace YOUR_PUBLIC_IP with actual IP (e.g., 132.145.23.45)
```

**First Connection:**
```
The authenticity of host 'XXX.XXX.XXX.XXX' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no/[fingerprint])? 

Type: yes [Enter]
```

**Expected Result:**
```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1050-oracle aarch64)

ubuntu@deskattendance-production:~$ 
```

**✅ Success! You're now connected to your Oracle Cloud server!**

---

## 📦 PHASE 4: INSTALL SOFTWARE (6:30-7:00 AM)

### Step 4.1: Update System (5 min)

```bash
# Update package list
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Install essential tools
sudo apt install -y wget curl git nano htop ufw

# Set timezone to India
sudo timedatectl set-timezone Asia/Kolkata

# Verify
timedatectl
```

---

### Step 4.2: Install .NET 9 Runtime (5 min)

**.NET 9 is REQUIRED for your backend (built with .NET 9)**

```bash
# Download Microsoft package signing key
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

# Install Microsoft package repository
sudo dpkg -i packages-microsoft-prod.deb

# Clean up
rm packages-microsoft-prod.deb

# Update package list
sudo apt update

# Install .NET 9 Runtime (NOT SDK, just runtime)
sudo apt install -y aspnetcore-runtime-9.0

# Verify installation
dotnet --list-runtimes

# Expected output should include:
# Microsoft.AspNetCore.App 9.0.x [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
# Microsoft.NETCore.App 9.0.x [/usr/share/dotnet/shared/Microsoft.NETCore.App]
```

**✅ Verify .NET 9 is installed:**
```bash
dotnet --version
# Should show: 9.0.x
```

---

### Step 4.3: Install PostgreSQL 16 (10 min)

```bash
# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package list
sudo apt update

# Install PostgreSQL 16
sudo apt install -y postgresql-16 postgresql-contrib-16

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
sudo systemctl status postgresql

# Should show: active (running) ✅
```

---

### Step 4.4: Configure PostgreSQL (5 min)

```bash
# Switch to postgres user
sudo -i -u postgres

# Create database for each company
psql -c "CREATE DATABASE markaudio_db;"
psql -c "CREATE DATABASE pivot_db;"
psql -c "CREATE DATABASE revit_db;"

# Create database user
psql -c "CREATE USER deskattendance WITH PASSWORD 'YourSecurePassword123!';"

# Grant permissions
psql -c "GRANT ALL PRIVILEGES ON DATABASE markaudio_db TO deskattendance;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE pivot_db TO deskattendance;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE revit_db TO deskattendance;"

# Allow remote connections (for desktop apps)
psql -c "ALTER USER deskattendance WITH CREATEDB;"

# Exit postgres user
exit
```

**Configure PostgreSQL to accept remote connections:**

```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/16/main/postgresql.conf

# Find this line (around line 59):
#listen_addresses = 'localhost'

# Change to:
listen_addresses = '*'

# Save and exit (Ctrl+X, Y, Enter)
```

**Edit pg_hba.conf to allow password authentication:**

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Add this line at the end:
host    all             all             0.0.0.0/0               md5

# Save and exit (Ctrl+X, Y, Enter)
```

**Restart PostgreSQL:**

```bash
sudo systemctl restart postgresql

# Verify listening on all interfaces
sudo netstat -tuln | grep 5432
# Should show: 0.0.0.0:5432
```

---

### Step 4.5: Configure Ubuntu Firewall (3 min)

```bash
# Enable firewall
sudo ufw enable

# Allow SSH (port 22)
sudo ufw allow 22/tcp

# Allow ASP.NET backend (port 5001)
sudo ufw allow 5001/tcp

# Allow PostgreSQL (port 5432)
sudo ufw allow 5432/tcp

# Allow HTTP/HTTPS (for future)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status

# Expected output:
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 5001/tcp                   ALLOW       Anywhere
# 5432/tcp                   ALLOW       Anywhere
```

---

## 🚀 PHASE 5: DEPLOY BACKEND (7:00-7:30 AM)

### Step 5.1: Prepare Backend Files on Windows

**On your Windows machine (PowerShell):**

```powershell
# Navigate to backend folder
cd P:\SourceCode-HM\DeskAttendanceApp\backend

# Publish backend for Linux ARM64
dotnet publish -c Release -r linux-arm64 --self-contained false -o publish-linux-arm64

# This creates: backend/publish-linux-arm64/ folder with all files
```

**Verify publish successful:**
```powershell
dir publish-linux-arm64

# Should see:
# - backend.dll
# - appsettings.json
# - Many other .dll files
```

---

### Step 5.2: Create Deployment Package

```powershell
# Create zip file for easy upload
Compress-Archive -Path publish-linux-arm64\* -DestinationPath backend-deploy.zip -Force

# Verify zip created
dir backend-deploy.zip

# Should show file size around 10-20 MB
```

---

### Step 5.3: Upload to Oracle Cloud

**Option A: Using SCP (Recommended)**

```powershell
# Upload zip file
scp -i "$env:USERPROFILE\.ssh\oracle_cloud_key" backend-deploy.zip ubuntu@YOUR_PUBLIC_IP:/home/ubuntu/

# Replace YOUR_PUBLIC_IP with actual IP
```

**Option B: Using WinSCP (GUI)**

```
1. Download WinSCP: https://winscp.net
2. Install and open
3. Connection:
   - File protocol: SCP
   - Host name: YOUR_PUBLIC_IP
   - User name: ubuntu
   - Private key: C:\Users\YourName\.ssh\oracle_cloud_key
4. Click "Login"
5. Drag and drop backend-deploy.zip to /home/ubuntu/
```

---

### Step 5.4: Extract and Configure on Server

**Back in SSH session:**

```bash
# Create deployment directory
sudo mkdir -p /opt/deskattendance
sudo chown ubuntu:ubuntu /opt/deskattendance

# Extract backend files
unzip backend-deploy.zip -d /opt/deskattendance/

# Clean up
rm backend-deploy.zip

# Navigate to backend folder
cd /opt/deskattendance

# List files
ls -la

# Should see: backend.dll, appsettings.json, etc.
```

---

### Step 5.5: Update Connection String

```bash
# Edit appsettings.json
nano appsettings.json

# Find ConnectionStrings section and update to:
```

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=markaudio_db;Username=deskattendance;Password=YourSecurePassword123!"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
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

**Save and exit (Ctrl+X, Y, Enter)**

---

### Step 5.6: Apply Database Migrations

```bash
# Navigate to backend folder
cd /opt/deskattendance

# Install EF Core tools (if not already in project)
dotnet tool install --global dotnet-ef

# Apply migrations to create tables
dotnet ef database update --project backend.dll

# Or if ef tool not available, use this:
dotnet backend.dll --migrate

# Expected output:
# Applying migration 'AddMultiTenantSupport'
# Done.
```

---

### Step 5.7: Test Backend Manually

```bash
# Run backend temporarily (to test)
dotnet backend.dll

# Expected output:
# info: Microsoft.Hosting.Lifetime[14]
#       Now listening on: http://0.0.0.0:5001
# info: Microsoft.Hosting.Lifetime[0]
#       Application started. Press Ctrl+C to shut down.
```

**On your Windows machine, test API:**

```powershell
# Replace YOUR_PUBLIC_IP with actual IP
Invoke-WebRequest -Uri "http://YOUR_PUBLIC_IP:5001/api/auth/health"

# Expected: HTTP 200 OK
```

**Stop the test server (Ctrl+C in SSH)**

---

### Step 5.8: Create systemd Service (Run Backend Automatically)

```bash
# Create service file
sudo nano /etc/systemd/system/deskattendance.service
```

**Paste this content:**

```ini
[Unit]
Description=DeskAttendance Backend API
After=network.target postgresql.service

[Service]
Type=notify
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/deskattendance
ExecStart=/usr/bin/dotnet /opt/deskattendance/backend.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=deskattendance
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
```

**Save and exit (Ctrl+X, Y, Enter)**

---

### Step 5.9: Start Backend Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable deskattendance.service

# Start service
sudo systemctl start deskattendance.service

# Check status
sudo systemctl status deskattendance.service

# Expected output:
# ● deskattendance.service - DeskAttendance Backend API
#    Loaded: loaded (/etc/systemd/system/deskattendance.service; enabled)
#    Active: active (running) since...
```

**View logs:**
```bash
# Real-time logs
sudo journalctl -u deskattendance.service -f

# Last 50 lines
sudo journalctl -u deskattendance.service -n 50
```

---

## ✅ PHASE 6: VERIFY DEPLOYMENT (7:30-7:45 AM)

### Test API Endpoints

**From Windows PowerShell:**

```powershell
# Replace YOUR_PUBLIC_IP with actual IP
$IP = "YOUR_PUBLIC_IP"

# Test 1: Health check
Invoke-WebRequest -Uri "http://${IP}:5001/api/auth/health"

# Test 2: Login (should fail with 401 - expected)
Invoke-RestMethod -Uri "http://${IP}:5001/api/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"test","password":"test"}'

# Test 3: Get employees (should fail with 401 - expected, no auth)
Invoke-WebRequest -Uri "http://${IP}:5001/api/employees"
```

**Expected Results:**
- ✅ Health check: HTTP 200 OK
- ✅ Login: HTTP 401 Unauthorized (correct - no valid user yet)
- ✅ Employees: HTTP 401 Unauthorized (correct - need auth token)

---

## 🔄 PHASE 7: UPDATE DESKTOP APP (7:45-8:00 AM)

### Step 7.1: Update appConfig.json for MarkAudio

**On Windows, edit:**
```
P:\SourceCode-HM\DeskAttendanceApp\electron-app\appConfig-MarkAudio.json
```

**Change from:**
```json
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://localhost:5001"
}
```

**To:**
```json
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://YOUR_PUBLIC_IP:5001"
}
```

**Replace YOUR_PUBLIC_IP with actual Oracle Cloud IP!**

---

### Step 7.2: Rebuild MarkAudio Installer

```powershell
cd P:\SourceCode-HM\DeskAttendanceApp

# Run build script
.\BUILD_INSTALLERS.ps1 -CompanyName MarkAudio
```

---

### Step 7.3: Test Installer

```
1. Install MarkAudio-Setup.exe on your laptop
2. Run the application
3. Try logging in with admin credentials
4. Verify it connects to Oracle Cloud backend
5. Check data loads properly
```

---

## 🎯 SUCCESS CHECKLIST

- [ ] Oracle Cloud instance RUNNING
- [ ] Public IP assigned and noted
- [ ] SSH connection working
- [ ] PostgreSQL installed and configured
- [ ] .NET 9 runtime installed
- [ ] Backend deployed to /opt/deskattendance
- [ ] Database migrations applied
- [ ] systemd service running
- [ ] API endpoints responding (health check works)
- [ ] Firewall rules configured (ports 5001, 5432)
- [ ] Desktop app updated with Oracle IP
- [ ] Installer tested and working
- [ ] Can login and see data

---

## 📱 MONITORING AND MAINTENANCE

### Useful Commands

```bash
# Check backend status
sudo systemctl status deskattendance.service

# View backend logs
sudo journalctl -u deskattendance.service -f

# Restart backend
sudo systemctl restart deskattendance.service

# Check database connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE datname = 'markaudio_db';"

# Monitor server resources
htop

# Check disk space
df -h

# Check memory
free -h
```

### Database Backup

```bash
# Backup MarkAudio database
sudo -u postgres pg_dump markaudio_db > ~/markaudio_backup_$(date +%Y%m%d).sql

# Restore from backup
sudo -u postgres psql markaudio_db < ~/markaudio_backup_20250118.sql
```

---

## 🆘 TROUBLESHOOTING GUIDE

### Issue: Can't connect to instance

**Check:**
```bash
# On Windows
ping YOUR_PUBLIC_IP
ssh -v -i "$env:USERPROFILE\.ssh\oracle_cloud_key" ubuntu@YOUR_PUBLIC_IP
```

**Solutions:**
- Verify instance is RUNNING (not stopped)
- Check Security List has SSH rule (port 22)
- Verify public IP is correct
- Check SSH key permissions

---

### Issue: Backend not starting

**Check logs:**
```bash
sudo journalctl -u deskattendance.service -n 100
```

**Common fixes:**
```bash
# Check .NET runtime
dotnet --version

# Check file permissions
ls -la /opt/deskattendance

# Fix permissions if needed
sudo chown -R ubuntu:ubuntu /opt/deskattendance
```

---

### Issue: Database connection failed

**Check PostgreSQL:**
```bash
sudo systemctl status postgresql
sudo -u postgres psql -l
```

**Test connection:**
```bash
psql -h localhost -U deskattendance -d markaudio_db
# Enter password when prompted
```

**Check connection string in appsettings.json**

---

### Issue: Desktop app can't connect

**Check:**
- Firewall rules (port 5001 open)
- Backend service running
- Correct IP in appConfig.json
- Try from browser: http://YOUR_IP:5001/api/auth/health

---

## 📊 COST MONITORING

### Always Free Limits

```
Compute (A1.Flex ARM):
- 4 OCPUs total across all instances
- 24 GB RAM total
- Always Free ✅

Block Storage:
- 200 GB total
- Always Free ✅

Database (PostgreSQL):
- Self-managed on compute instance
- Always Free ✅ (uses compute resources)

Networking:
- 10 TB outbound per month
- Always Free ✅
```

**Monitor usage:**
```
Console → Governance → Cost Management
```

**Set up cost alerts:**
```
Console → Account Management → Budgets
```

---

## 🎉 FINAL RESULT

**After completing this guide, you will have:**

✅ **Oracle Cloud ARM instance** running Ubuntu 22.04 aarch64  
✅ **PostgreSQL 16 database** with multi-tenant support  
✅ **.NET 9 backend API** running as systemd service  
✅ **Public IP** accessible from internet  
✅ **Firewall configured** for security  
✅ **Auto-start on boot** configured  
✅ **Desktop app** connecting to cloud backend  
✅ **Production-ready** deployment  

**Total Cost: ₹0 (Always Free Tier)** 💰

**Total Time: 2 hours** ⏱️

---

## 📝 NEXT STEPS

1. **Configure Auto-Update:**
   - Create GitHub repository
   - Publish v1.1.0 release
   - Test auto-update mechanism

2. **Add SSL/HTTPS:**
   - Get domain name
   - Install Let's Encrypt certificate
   - Configure Nginx reverse proxy

3. **Set up Backups:**
   - Automated database backups
   - Oracle Cloud Object Storage
   - Backup retention policy

4. **Deploy for other companies:**
   - Create Pivot database
   - Create Revit database
   - Build separate installers

5. **Monitoring:**
   - Set up health checks
   - Email alerts
   - Performance monitoring

---

**Good luck with your deployment! 🚀**

**If you encounter any issues, refer to the Troubleshooting section or check Oracle Cloud documentation.**
