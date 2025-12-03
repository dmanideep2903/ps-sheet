# 🚀 PRODUCTION DEPLOYMENT GUIDE
## Hostinger VPS - Zero-Downtime Deployment Strategy

**Last Updated:** November 26, 2024  
**Production Server:** 72.61.226.129:5001  
**Active Users:** Mark Audio (5 employees)  
**Database:** PostgreSQL (attendancedb)

---

## 📋 TABLE OF CONTENTS

1. [Deployment Scenarios](#deployment-scenarios)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Scenario 1: Backend + Frontend Changes](#scenario-1-backend--frontend-changes)
4. [Scenario 2: Backend Only Changes](#scenario-2-backend-only-changes)
5. [Scenario 3: Frontend Only Changes](#scenario-3-frontend-only-changes)
6. [Database Migration Strategy](#database-migration-strategy)
7. [Rollback Procedures](#rollback-procedures)
8. [Production Maintenance Best Practices](#production-maintenance-best-practices)
9. [Monitoring & Health Checks](#monitoring--health-checks)
10. [Emergency Procedures](#emergency-procedures)

---

## 🎯 DEPLOYMENT SCENARIOS

### Current Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT MACHINES                          │
│                  (Mark Audio - 5 Users)                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Electron App (MarkAudio-Setup.exe)                  │  │
│  │  - React Frontend (embedded in build/)               │  │
│  │  - Config: appConfig-MarkAudio.json                  │  │
│  │  - CompanyId: markaudio2019                          │  │
│  │  - API: http://72.61.226.129:5001                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS/HTTP
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              HOSTINGER VPS (72.61.226.129)                  │
│                    Ubuntu 24.04 LTS                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  Backend API (.NET 9)                                 │ │
│  │  Location: /home/pivot/app/backend/                   │ │
│  │  Service: deskattendance.service                      │ │
│  │  Port: 5001                                           │ │
│  │  Process: systemd managed                             │ │
│  │  Auto-restart: Yes                                    │ │
│  └───────────────────────────────────────────────────────┘ │
│                            │                                │
│                            ▼                                │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  PostgreSQL 16                                        │ │
│  │  Database: attendancedb                               │ │
│  │  User: attendanceuser                                 │ │
│  │  Timezone: Asia/Kolkata (IST)                         │ │
│  │  Auto-Migrations: Enabled on startup                  │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Understanding Change Impact

| Change Type | Backend Restart | Client Update | Downtime | Risk Level |
|-------------|----------------|---------------|----------|------------|
| Backend Code | ✅ Required | ❌ No | ~5 seconds | 🟡 Medium |
| Frontend Code | ❌ No | ✅ Required | None | 🟢 Low |
| Database Schema | ✅ Required | Depends | ~10 seconds | 🔴 High |
| Config Only | ✅ Required | Depends | ~5 seconds | 🟢 Low |
| Both Back+Front | ✅ Required | ✅ Required | ~5 seconds | 🟡 Medium |

---

## ✅ PRE-DEPLOYMENT CHECKLIST

### Before Every Deployment

```powershell
# Run this checklist on your Windows PC

# 1. Verify all tests pass
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend
dotnet test

# 2. Check for compilation errors
dotnet build -c Release

# 3. Verify React app builds without errors
cd ..\react-app
npm run build

# 4. Review changes
git status
git diff

# 5. Check migration files (if database changes)
cd ..\backend
dotnet ef migrations list

# 6. Backup current production database
# (See Database Backup section)
```

### Communication Protocol

**CRITICAL:** Always inform users before deployment!

```powershell
# Create deployment announcement
Write-Host @"
===========================================
DEPLOYMENT NOTIFICATION
===========================================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm")
Estimated Downtime: 30 seconds - 2 minutes
Changes: [Describe changes briefly]

Action Required:
- Save all work in progress
- Log out before deployment
- Log back in after notification

Timing: Deployment in 15 minutes
===========================================
"@ -ForegroundColor Yellow
```

**Send to users via:**
- Company WhatsApp/Slack
- Email notification
- In-app notification (if implemented)

### Environment Verification

```bash
# Run on VPS before deployment
# SSH into server: ssh pivot@72.61.226.129

# 1. Check service status
sudo systemctl status deskattendance

# 2. Check disk space (need at least 1GB free)
df -h

# 3. Check database connectivity
psql -U attendanceuser -d attendancedb -c "SELECT version();"

# 4. Check memory usage
free -h

# 5. Verify backup directory exists
ls -lh ~/backups/

# 6. Check current backend version (if you implement versioning)
curl http://localhost:5001/health
```

---

## 📦 SCENARIO 1: BACKEND + FRONTEND CHANGES

**Use Case:** You've made changes to both API logic and UI components  
**Current Changes:** All 10 fixes you just implemented  
**Downtime:** ~30 seconds to 2 minutes  
**Risk Level:** 🟡 MEDIUM

### Step-by-Step Deployment

#### PHASE 1: Prepare on Windows (Dev Machine)

```powershell
# Open PowerShell as Administrator
cd P:\SourceCode-PIVOT\DeskAttendanceApp

# ==========================================
# STEP 1: BUILD BACKEND FOR LINUX
# ==========================================
Write-Host "[1/5] Building Backend for Linux..." -ForegroundColor Cyan

cd backend

# Clean previous builds
if (Test-Path "publish") { Remove-Item -Recurse -Force publish }

# Build for Linux x64
dotnet publish -c Release -r linux-x64 --self-contained false -o publish

# Verify critical files exist
$criticalFiles = @("backend", "appsettings.json", "appsettings.Production.json")
foreach ($file in $criticalFiles) {
    if (-not (Test-Path "publish\$file")) {
        Write-Error "CRITICAL: $file not found in publish folder!"
        exit 1
    }
}

# Create deployment package with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backendZip = "backend-deploy-$timestamp.zip"

Compress-Archive -Path publish\* -DestinationPath $backendZip -Force
Write-Host "✓ Backend package created: $backendZip" -ForegroundColor Green

# ==========================================
# STEP 2: BUILD REACT APP
# ==========================================
Write-Host "[2/5] Building React Frontend..." -ForegroundColor Cyan

cd ..\react-app

# Clean old build
if (Test-Path "build") { Remove-Item -Recurse -Force build }

# Build production React app
npm run build

# Verify build success
if (-not (Test-Path "build\index.html")) {
    Write-Error "React build failed - index.html not found!"
    exit 1
}

Write-Host "✓ React app built successfully" -ForegroundColor Green

# ==========================================
# STEP 3: BUILD ELECTRON INSTALLER
# ==========================================
Write-Host "[3/5] Building Electron Installer..." -ForegroundColor Cyan

cd ..\electron-app

# Copy React build to Electron
if (Test-Path "build") { Remove-Item -Recurse -Force build }
Copy-Item -Recurse ..\react-app\build .\

# Verify company config exists
if (-not (Test-Path "appConfig-MarkAudio.json")) {
    Write-Error "Company config not found: appConfig-MarkAudio.json"
    exit 1
}

# Build installer for MarkAudio
cd ..
.\BUILD_INSTALLERS.ps1 -CompanyName "MarkAudio"

# Verify installer was created
$installer = Get-ChildItem "electron-app\dist\MarkAudio-Setup.exe" -ErrorAction SilentlyContinue
if (-not $installer) {
    Write-Error "Installer not created!"
    exit 1
}

$installerSize = [math]::Round($installer.Length / 1MB, 2)
Write-Host "✓ Installer created: MarkAudio-Setup.exe ($installerSize MB)" -ForegroundColor Green

# ==========================================
# STEP 4: UPLOAD TO VPS
# ==========================================
Write-Host "[4/5] Uploading backend to VPS..." -ForegroundColor Cyan

cd backend

# Upload backend package (replace with your actual VPS IP)
scp $backendZip pivot@72.61.226.129:/home/pivot/deployments/

if ($LASTEXITCODE -ne 0) {
    Write-Error "Upload failed! Check SSH connection."
    exit 1
}

Write-Host "✓ Backend uploaded to VPS" -ForegroundColor Green

Write-Host @"

==========================================
WINDOWS PREPARATION COMPLETE
==========================================
✓ Backend package: $backendZip
✓ Installer: electron-app\dist\MarkAudio-Setup.exe

Next Steps:
1. SSH into VPS
2. Run deployment script (see PHASE 2)
3. Distribute new installer to users

"@ -ForegroundColor Green
```

#### PHASE 2: Deploy on VPS (Production Server)

```bash
# SSH into your VPS
ssh pivot@72.61.226.129
# Enter password when prompted

# ==========================================
# STEP 1: PREPARE DEPLOYMENT
# ==========================================
echo "[1/6] Preparing deployment environment..."

# Create deployment directory if not exists
mkdir -p ~/deployments
mkdir -p ~/backups

# Set variables
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKEND_ZIP=$(ls -t ~/deployments/backend-deploy-*.zip | head -1)
BACKUP_DIR=~/backups/backup-$TIMESTAMP
APP_DIR=~/app/backend

echo "Deployment package: $BACKEND_ZIP"
echo "Backup directory: $BACKUP_DIR"

# ==========================================
# STEP 2: BACKUP CURRENT VERSION
# ==========================================
echo "[2/6] Backing up current version..."

# Backup database first (CRITICAL!)
sudo -u postgres pg_dump attendancedb > ~/backups/db-backup-$TIMESTAMP.sql

if [ $? -ne 0 ]; then
    echo "❌ DATABASE BACKUP FAILED! ABORTING DEPLOYMENT!"
    exit 1
fi

echo "✓ Database backed up: db-backup-$TIMESTAMP.sql"

# Backup current backend files
mkdir -p $BACKUP_DIR
cp -r $APP_DIR $BACKUP_DIR/backend-old

echo "✓ Backend files backed up"

# Save current service status
systemctl status deskattendance > $BACKUP_DIR/service-status.txt

# ==========================================
# STEP 3: HEALTH CHECK BEFORE DEPLOYMENT
# ==========================================
echo "[3/6] Running pre-deployment health check..."

# Test database connection
psql -U attendanceuser -d attendancedb -c "SELECT COUNT(*) FROM \"UserProfiles\";" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "⚠️  WARNING: Database connection test failed!"
    read -p "Continue anyway? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment aborted by user."
        exit 1
    fi
fi

# Check current active connections
ACTIVE_USERS=$(psql -U attendanceuser -d attendancedb -t -c "SELECT COUNT(DISTINCT \"Email\") FROM \"AttendanceRecords\" WHERE \"Timestamp\" > NOW() - INTERVAL '1 hour';")
echo "Active users in last hour: $ACTIVE_USERS"

if [ $ACTIVE_USERS -gt 0 ]; then
    echo "⚠️  WARNING: Users may be actively using the application!"
    echo "Consider scheduling deployment during off-hours."
    read -p "Continue deployment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment aborted by user."
        exit 1
    fi
fi

# ==========================================
# STEP 4: STOP SERVICE (DOWNTIME STARTS)
# ==========================================
echo "[4/6] Stopping backend service..."
echo "⏰ DOWNTIME STARTED at $(date)"

sudo systemctl stop deskattendance

# Verify service stopped
sleep 2
if systemctl is-active --quiet deskattendance; then
    echo "❌ Service failed to stop! Force killing..."
    sudo systemctl kill deskattendance
    sleep 2
fi

echo "✓ Service stopped"

# ==========================================
# STEP 5: DEPLOY NEW VERSION
# ==========================================
echo "[5/6] Deploying new backend..."

# Extract new backend
cd $APP_DIR
unzip -o $BACKEND_ZIP

# Set execute permissions
chmod +x backend

# Verify critical files
if [ ! -f "backend" ] || [ ! -f "appsettings.Production.json" ]; then
    echo "❌ CRITICAL FILES MISSING! Rolling back..."
    
    # Restore backup
    rm -rf $APP_DIR/*
    cp -r $BACKUP_DIR/backend-old/* $APP_DIR/
    
    # Restart service with old version
    sudo systemctl start deskattendance
    
    echo "❌ DEPLOYMENT FAILED - Rolled back to previous version"
    exit 1
fi

echo "✓ New backend extracted"

# Database migrations will run automatically on startup
# (Your Program.cs has: context.Database.Migrate())

# ==========================================
# STEP 6: START SERVICE (DOWNTIME ENDS)
# ==========================================
echo "[6/6] Starting backend service..."

sudo systemctl start deskattendance

# Wait for service to start
sleep 3

# Check service status
if systemctl is-active --quiet deskattendance; then
    echo "✓ Service started successfully"
    echo "⏰ DOWNTIME ENDED at $(date)"
else
    echo "❌ SERVICE FAILED TO START! Rolling back..."
    
    # Restore backup
    sudo systemctl stop deskattendance
    rm -rf $APP_DIR/*
    cp -r $BACKUP_DIR/backend-old/* $APP_DIR/
    chmod +x $APP_DIR/backend
    
    # Restore database
    sudo -u postgres psql attendancedb < ~/backups/db-backup-$TIMESTAMP.sql
    
    sudo systemctl start deskattendance
    
    echo "❌ DEPLOYMENT FAILED - Rolled back to previous version"
    exit 1
fi

# ==========================================
# STEP 7: POST-DEPLOYMENT VERIFICATION
# ==========================================
echo ""
echo "Running post-deployment health checks..."

# Wait for migrations to complete
echo "Waiting 10 seconds for migrations..."
sleep 10

# Test health endpoint
HEALTH_CHECK=$(curl -s http://localhost:5001/health)

if [ -z "$HEALTH_CHECK" ]; then
    echo "⚠️  WARNING: Health check endpoint not responding!"
else
    echo "✓ Health check: $HEALTH_CHECK"
fi

# Check service logs for errors
echo ""
echo "Recent logs:"
sudo journalctl -u deskattendance -n 20 --no-pager

# Test database connection from backend
echo ""
echo "Testing database connectivity..."
curl -s http://localhost:5001/api/Auth/health 2>&1 | head -5

# Check if migrations ran
echo ""
echo "Checking applied migrations..."
sudo journalctl -u deskattendance | grep -i "migration" | tail -5

echo ""
echo "=========================================="
echo "DEPLOYMENT COMPLETE"
echo "=========================================="
echo "Timestamp: $(date)"
echo "Backup location: $BACKUP_DIR"
echo "Service status: $(systemctl is-active deskattendance)"
echo ""
echo "Next steps:"
echo "1. Test login from one client machine"
echo "2. Verify all features working"
echo "3. Distribute new installer: electron-app/dist/MarkAudio-Setup.exe"
echo "4. Monitor logs: sudo journalctl -u deskattendance -f"
echo "=========================================="
```

#### PHASE 3: Client Update (Users)

```
CLIENT UPDATE INSTRUCTIONS
Send to Mark Audio employees:

Subject: DeskAttendance App Update Available

Dear Team,

A new version of the DeskAttendance app is available with important improvements:

NEW FEATURES:
✓ IST timezone support
✓ DD-MM-YYYY date format
✓ Employee settings (change password, address, mobile)
✓ Real-time updates every 10 seconds
✓ Improved profile management

HOW TO UPDATE:
1. Close the current DeskAttendance app completely
2. Download the new installer: [Provide download link or attach file]
3. Run MarkAudio-Setup.exe
4. Installation will update automatically
5. Open the app and log in

⚠️ IMPORTANT:
- Your data is safe (stored on server)
- No need to re-register
- Update takes ~2 minutes
- Contact IT if you face any issues

Thank you,
IT Team
```

---

## 📦 SCENARIO 2: BACKEND ONLY CHANGES

**Use Case:** API logic, database models, business logic changes  
**Example:** Bug fixes, new API endpoints, performance improvements  
**Downtime:** ~5-10 seconds  
**Risk Level:** 🟡 MEDIUM

### When Backend-Only Deployment is Safe

✅ **Safe scenarios:**
- Bug fixes in existing endpoints
- Performance optimizations
- New API endpoints (backward compatible)
- Database schema additions (new columns/tables)
- Configuration changes

❌ **Unsafe scenarios (need frontend update too):**
- Changing API response structure (breaking changes)
- Removing API endpoints
- Changing required fields
- Modifying authentication flow

### Deployment Steps

```powershell
# ==========================================
# WINDOWS: BUILD BACKEND ONLY
# ==========================================

cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Build for Linux
dotnet publish -c Release -r linux-x64 --self-contained false -o publish

# Package with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Compress-Archive -Path publish\* -DestinationPath "backend-only-$timestamp.zip" -Force

# Upload to VPS
scp "backend-only-$timestamp.zip" pivot@72.61.226.129:/home/pivot/deployments/

Write-Host "✓ Backend uploaded. Now SSH to VPS and run deployment."
```

```bash
# ==========================================
# VPS: QUICK BACKEND DEPLOYMENT
# ==========================================

ssh pivot@72.61.226.129

# Set variables
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKEND_ZIP=$(ls -t ~/deployments/backend-only-*.zip | head -1)

# Quick backup (database + files)
sudo -u postgres pg_dump attendancedb > ~/backups/db-quick-$TIMESTAMP.sql
cp -r ~/app/backend ~/backups/backend-quick-$TIMESTAMP

# Stop service
echo "Stopping service..."
sudo systemctl stop deskattendance

# Deploy new version
cd ~/app/backend
unzip -o $BACKEND_ZIP
chmod +x backend

# Start service
echo "Starting service..."
sudo systemctl start deskattendance

# Wait and verify
sleep 5
systemctl status deskattendance

# Check health
curl http://localhost:5001/health

echo "✓ Backend-only deployment complete"
echo "Clients do NOT need to update"
```

### Verification

```bash
# Monitor logs for errors
sudo journalctl -u deskattendance -f

# Test critical endpoints
curl http://localhost:5001/health
curl http://localhost:5001/api/Auth/health

# Check migration status (if database changes)
sudo journalctl -u deskattendance | grep -i "migration" | tail -10
```

---

## 📦 SCENARIO 3: FRONTEND ONLY CHANGES

**Use Case:** UI improvements, styling, client-side logic  
**Example:** Button colors, layout changes, validation logic  
**Downtime:** ZERO (no backend restart needed)  
**Risk Level:** 🟢 LOW

### When Frontend-Only Deployment Works

✅ **Safe scenarios:**
- UI/UX improvements
- CSS/styling changes
- Client-side validation
- New React components
- Bug fixes in frontend logic

### Deployment Steps

```powershell
# ==========================================
# WINDOWS: BUILD INSTALLER ONLY
# ==========================================

cd P:\SourceCode-PIVOT\DeskAttendanceApp

# Step 1: Build React app
cd react-app
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
npm run build

# Step 2: Copy to Electron
cd ..\electron-app
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Copy-Item -Recurse ..\react-app\build .\

# Step 3: Build installer (no backend needed)
cd ..
.\BUILD_INSTALLERS.ps1 -CompanyName "MarkAudio"

# Verify installer
$installer = Get-ChildItem "electron-app\dist\MarkAudio-Setup.exe"
$size = [math]::Round($installer.Length / 1MB, 2)

Write-Host @"

✓ Frontend-only installer ready
  File: electron-app\dist\MarkAudio-Setup.exe
  Size: $size MB

NO VPS DEPLOYMENT NEEDED!
Just distribute this installer to users.

"@ -ForegroundColor Green
```

### Client Update Process

**Option 1: Manual Update (Recommended for small teams)**

```
Email to users:

Subject: DeskAttendance UI Update

Hi Team,

We've improved the app interface with some bug fixes.

UPDATE INSTRUCTIONS:
1. Download: [Attach MarkAudio-Setup.exe]
2. Close the current app
3. Run the installer
4. Open and continue working

No data loss, no server downtime!
```

**Option 2: Auto-Update (Future Enhancement)**

If you implement auto-update feature:
```json
// In appConfig-MarkAudio.json
{
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://your-update-server.com/releases/latest"
  }
}
```

---

## 🗄️ DATABASE MIGRATION STRATEGY

### Understanding Migrations

Your backend uses **Entity Framework Core** with **automatic migrations**:

```csharp
// From your Program.cs line 68
context.Database.Migrate();
```

This means:
- ✅ Migrations run automatically on startup
- ✅ No manual `dotnet ef database update` needed
- ⚠️ Zero-downtime migrations require careful planning

### Types of Database Changes

#### 1. **Safe Migrations (Additive)**
✅ No downtime, old clients still work

```csharp
// Examples:
- Adding new tables
- Adding new columns (nullable)
- Adding new indexes
- Adding default values
```

**Deployment:**
1. Deploy backend with migration
2. Backend starts, migration runs automatically
3. Old clients keep working (ignore new fields)
4. Update clients gradually

#### 2. **Risky Migrations (Breaking Changes)**
⚠️ Require careful coordination

```csharp
// Examples:
- Removing columns
- Renaming columns
- Changing data types
- Adding non-nullable columns
```

**Safe Deployment Strategy:**

```csharp
// BAD: Direct removal (breaks old clients)
public class UserProfile {
    // public string OldField { get; set; }  // ❌ Removed - breaks old clients!
    public string NewField { get; set; }
}

// GOOD: Two-phase deployment
// Phase 1: Add new field, keep old field
public class UserProfile {
    [Obsolete] public string OldField { get; set; }  // Keep for now
    public string NewField { get; set; }             // New field
}
// Deploy backend → Update all clients → Phase 2

// Phase 2: Remove old field (after all clients updated)
public class UserProfile {
    public string NewField { get; set; }
}
```

### Manual Migration Testing (Before Production)

```bash
# On your Windows PC (dev environment)
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Check pending migrations
dotnet ef migrations list

# Create new migration (if you changed models)
dotnet ef migrations add YourMigrationName

# Test migration on local database
dotnet ef database update

# Review generated SQL
dotnet ef migrations script

# If problems, remove migration
dotnet ef migrations remove
```

### Production Migration Checklist

```bash
# Before deploying migrations to production:

✅ 1. Backup database (CRITICAL!)
sudo -u postgres pg_dump attendancedb > ~/backups/pre-migration-$(date +%Y%m%d-%H%M%S).sql

✅ 2. Test migration on staging database (if you have one)

✅ 3. Review migration file
cat backend/Migrations/*_YourMigrationName.cs

✅ 4. Estimate migration duration
# For large tables, migrations can take minutes!

✅ 5. Plan rollback strategy

✅ 6. Schedule during low-usage hours
# Check user activity:
psql -U attendanceuser -d attendancedb -c "
  SELECT COUNT(*) as active_users 
  FROM \"AttendanceRecords\" 
  WHERE \"Timestamp\" > NOW() - INTERVAL '30 minutes';
"
```

### Rollback Database Migration

```bash
# If migration fails or causes issues:

# OPTION 1: Restore from backup (safest)
sudo systemctl stop deskattendance

sudo -u postgres psql attendancedb <<EOF
DROP DATABASE attendancedb;
CREATE DATABASE attendancedb;
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;
EOF

sudo -u postgres psql attendancedb < ~/backups/pre-migration-TIMESTAMP.sql

# Restore old backend version
cd ~/app/backend
rm -rf *
cp -r ~/backups/backup-TIMESTAMP/backend-old/* .
chmod +x backend

sudo systemctl start deskattendance

# OPTION 2: Revert migration (if recent)
# Only works if you haven't deleted migration files
cd ~/app/backend
dotnet ef database update PreviousMigrationName
```

---

## 🔄 ROLLBACK PROCEDURES

### When to Rollback

🚨 **Immediate rollback required:**
- Service fails to start
- Critical errors in logs
- Database corruption
- User reports complete inability to use app
- Data loss detected

⚠️ **Consider rollback:**
- Performance degradation >50%
- Intermittent errors affecting >20% of requests
- New bugs affecting core functionality

### Quick Rollback Script

```bash
# Save this as: ~/scripts/emergency-rollback.sh

#!/bin/bash

echo "=== EMERGENCY ROLLBACK ==="
read -p "Enter backup timestamp (format: YYYYMMDD-HHMMSS): " TIMESTAMP

BACKUP_DIR=~/backups/backup-$TIMESTAMP

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup not found: $BACKUP_DIR"
    exit 1
fi

echo "Stopping service..."
sudo systemctl stop deskattendance

echo "Restoring database..."
sudo -u postgres psql attendancedb < ~/backups/db-backup-$TIMESTAMP.sql

echo "Restoring backend files..."
cd ~/app/backend
rm -rf *
cp -r $BACKUP_DIR/backend-old/* .
chmod +x backend

echo "Starting service..."
sudo systemctl start deskattendance

sleep 5

if systemctl is-active --quiet deskattendance; then
    echo "✓ Rollback successful!"
    curl http://localhost:5001/health
else
    echo "❌ Service failed to start after rollback!"
    sudo journalctl -u deskattendance -n 50
fi
```

### Make it executable:

```bash
chmod +x ~/scripts/emergency-rollback.sh

# Usage:
~/scripts/emergency-rollback.sh
# Enter timestamp when prompted
```

---

## 🛡️ PRODUCTION MAINTENANCE BEST PRACTICES

### 1. Regular Backups

**Automated Daily Backups:**

```bash
# Create backup script: ~/scripts/daily-backup.sh

#!/bin/bash

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=~/backups/daily

mkdir -p $BACKUP_DIR

# Database backup
sudo -u postgres pg_dump attendancedb | gzip > $BACKUP_DIR/db-$TIMESTAMP.sql.gz

# Backend files backup
tar -czf $BACKUP_DIR/backend-$TIMESTAMP.tar.gz -C ~/app backend

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "✓ Backup completed: $TIMESTAMP"
```

**Setup Cron Job:**

```bash
# Make script executable
chmod +x ~/scripts/daily-backup.sh

# Add to crontab (runs daily at 2 AM)
crontab -e

# Add this line:
0 2 * * * /home/pivot/scripts/daily-backup.sh >> /home/pivot/logs/backup.log 2>&1
```

### 2. Log Rotation

```bash
# Configure log rotation for your service
sudo nano /etc/logrotate.d/deskattendance

# Add:
/var/log/deskattendance/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 pivot pivot
    sharedscripts
    postrotate
        systemctl reload deskattendance > /dev/null 2>&1 || true
    endscript
}
```

### 3. Disk Space Monitoring

```bash
# Create monitoring script: ~/scripts/check-disk.sh

#!/bin/bash

THRESHOLD=80  # Alert if disk usage > 80%
CURRENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ $CURRENT -gt $THRESHOLD ]; then
    echo "⚠️ WARNING: Disk usage at ${CURRENT}%"
    echo "Cleaning old logs and backups..."
    
    # Clean old backups (keep last 7 days)
    find ~/backups -type f -mtime +7 -delete
    
    # Clean old logs
    sudo journalctl --vacuum-time=7d
    
    echo "Cleanup complete"
fi
```

**Add to crontab (runs every 6 hours):**

```bash
0 */6 * * * /home/pivot/scripts/check-disk.sh
```

### 4. Database Maintenance

```bash
# Create maintenance script: ~/scripts/db-maintenance.sh

#!/bin/bash

echo "Running database maintenance..."

# Vacuum analyze (cleanup and optimize)
psql -U attendanceuser -d attendancedb <<EOF
VACUUM ANALYZE;
REINDEX DATABASE attendancedb;
EOF

# Check database size
echo "Database size:"
psql -U attendanceuser -d attendancedb -c "
SELECT 
    pg_size_pretty(pg_database_size('attendancedb')) as db_size;
"

# Check table sizes
echo "Top 5 largest tables:"
psql -U attendanceuser -d attendancedb -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 5;
"

echo "✓ Maintenance complete"
```

**Run weekly:**

```bash
chmod +x ~/scripts/db-maintenance.sh

# Add to crontab (runs Sunday 3 AM)
crontab -e
0 3 * * 0 /home/pivot/scripts/db-maintenance.sh >> /home/pivot/logs/maintenance.log 2>&1
```

### 5. Security Updates

```bash
# Auto-update Ubuntu security patches
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Check for updates manually
sudo apt update
sudo apt list --upgradable

# Apply security updates
sudo apt upgrade -y

# Restart services if needed (after kernel updates)
sudo reboot
```

### 6. Service Health Monitoring

**Create health check script:**

```bash
# ~/scripts/health-check.sh

#!/bin/bash

SERVICE="deskattendance"
HEALTH_URL="http://localhost:5001/health"

# Check service status
if ! systemctl is-active --quiet $SERVICE; then
    echo "❌ Service is down! Attempting restart..."
    sudo systemctl start $SERVICE
    sleep 5
    
    if systemctl is-active --quiet $SERVICE; then
        echo "✓ Service restarted successfully"
    else
        echo "🚨 CRITICAL: Service failed to restart!"
        # TODO: Send email/SMS alert
    fi
fi

# Check health endpoint
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ "$RESPONSE" != "200" ]; then
    echo "⚠️ Health endpoint returned: $RESPONSE"
fi

# Check database connectivity
if ! psql -U attendanceuser -d attendancedb -c "SELECT 1" > /dev/null 2>&1; then
    echo "❌ Database connection failed!"
fi

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    echo "⚠️ Disk usage critical: ${DISK_USAGE}%"
fi

# Check memory
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ $MEM_USAGE -gt 90 ]; then
    echo "⚠️ Memory usage high: ${MEM_USAGE}%"
fi

echo "✓ Health check completed at $(date)"
```

**Run every 5 minutes:**

```bash
chmod +x ~/scripts/health-check.sh

crontab -e
*/5 * * * * /home/pivot/scripts/health-check.sh >> /home/pivot/logs/health.log 2>&1
```

### 7. User Activity Monitoring

```sql
-- Save as: ~/scripts/check-activity.sql

-- Active users (last 24 hours)
SELECT 
    COUNT(DISTINCT "Email") as active_users_24h
FROM "AttendanceRecords"
WHERE "Timestamp" > NOW() - INTERVAL '24 hours';

-- Punch statistics (today)
SELECT 
    COUNT(*) FILTER (WHERE "IsClockIn" = true) as clock_ins,
    COUNT(*) FILTER (WHERE "IsClockIn" = false) as clock_outs,
    COUNT(DISTINCT "Email") as unique_users
FROM "AttendanceRecords"
WHERE "Timestamp"::date = CURRENT_DATE;

-- Task statistics (last 7 days)
SELECT 
    "Status",
    COUNT(*) as count
FROM "TaskAssignments"
WHERE "CreatedAt" > NOW() - INTERVAL '7 days'
GROUP BY "Status";
```

```bash
# Run daily report
psql -U attendanceuser -d attendancedb -f ~/scripts/check-activity.sql
```

---

## 📊 MONITORING & HEALTH CHECKS

### Real-Time Monitoring Commands

```bash
# ==========================================
# SERVICE MONITORING
# ==========================================

# Check service status
sudo systemctl status deskattendance

# View live logs
sudo journalctl -u deskattendance -f

# View last 100 lines
sudo journalctl -u deskattendance -n 100

# Filter errors only
sudo journalctl -u deskattendance -p err

# Check service restart count
systemctl show deskattendance | grep NRestarts

# ==========================================
# PERFORMANCE MONITORING
# ==========================================

# Real-time system monitoring
htop

# Process-specific monitoring
top -p $(pgrep -f "backend")

# Memory usage
free -h

# Disk usage
df -h

# Network connections
sudo netstat -tulpn | grep 5001

# Active database connections
psql -U attendanceuser -d attendancedb -c "
SELECT COUNT(*) as active_connections 
FROM pg_stat_activity 
WHERE datname = 'attendancedb';
"

# ==========================================
# APPLICATION HEALTH CHECKS
# ==========================================

# Test health endpoint
curl http://localhost:5001/health

# Test from external network (replace with your IP)
curl http://72.61.226.129:5001/health

# Test database connectivity through API
curl -X POST http://localhost:5001/api/Auth/login \
  -H "Content-Type: application/json" \
  -H "X-Company-Id: markaudio2019" \
  -d '{"email":"test@test.com","password":"test"}'

# Check response time
time curl -s http://localhost:5001/health

# ==========================================
# DATABASE MONITORING
# ==========================================

# Database size
psql -U attendanceuser -d attendancedb -c "
SELECT pg_size_pretty(pg_database_size('attendancedb'));
"

# Table sizes
psql -U attendanceuser -d attendancedb -c "
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size('\"'||tablename||'\"')) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size('\"'||tablename||'\"') DESC;
"

# Slow queries (if query logging enabled)
psql -U attendanceuser -d attendancedb -c "
SELECT 
    query,
    calls,
    total_time / 1000 as total_seconds,
    mean_time / 1000 as mean_seconds
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
"

# Lock monitoring
psql -U attendanceuser -d attendancedb -c "
SELECT * FROM pg_locks WHERE NOT granted;
"
```

### Setting Up Email Alerts (Optional)

```bash
# Install mail utilities
sudo apt install mailutils -y

# Configure postfix (select "Internet Site")
sudo dpkg-reconfigure postfix

# Test email
echo "Test alert from DeskAttendance server" | mail -s "Test Alert" your-email@example.com

# Create alert script
cat > ~/scripts/send-alert.sh << 'EOF'
#!/bin/bash

SUBJECT="$1"
MESSAGE="$2"
EMAIL="your-email@example.com"

echo "$MESSAGE" | mail -s "$SUBJECT" $EMAIL
EOF

chmod +x ~/scripts/send-alert.sh

# Use in health check script:
# ~/scripts/send-alert.sh "Service Down" "DeskAttendance service stopped unexpectedly"
```

---

## 🚨 EMERGENCY PROCEDURES

### Scenario 1: Service Won't Start

```bash
# 1. Check logs for errors
sudo journalctl -u deskattendance -n 100

# 2. Common issues and fixes:

# Issue: Port already in use
sudo netstat -tulpn | grep 5001
# Fix: Kill process using port 5001
sudo kill -9 $(sudo lsof -t -i:5001)

# Issue: Database connection failed
# Fix: Verify PostgreSQL is running
sudo systemctl status postgresql
sudo systemctl start postgresql

# Issue: Permission denied
# Fix: Set correct permissions
sudo chown -R pivot:pivot ~/app/backend
chmod +x ~/app/backend/backend

# Issue: Missing dependencies
# Fix: Reinstall .NET runtime
sudo apt install --reinstall dotnet-runtime-9.0

# 3. Try starting manually to see detailed errors
cd ~/app/backend
./backend

# 4. If all else fails, rollback
~/scripts/emergency-rollback.sh
```

### Scenario 2: Database Corrupted

```bash
# 1. Stop service immediately
sudo systemctl stop deskattendance

# 2. Check database integrity
psql -U attendanceuser -d attendancedb -c "
SELECT * FROM pg_stat_database WHERE datname = 'attendancedb';
"

# 3. Restore from latest backup
LATEST_BACKUP=$(ls -t ~/backups/daily/db-*.sql.gz | head -1)

sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS attendancedb;
CREATE DATABASE attendancedb;
GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;
EOF

gunzip -c $LATEST_BACKUP | sudo -u postgres psql attendancedb

# 4. Restart service
sudo systemctl start deskattendance
```

### Scenario 3: Server Under Attack

```bash
# 1. Check for suspicious activity
sudo tail -f /var/log/auth.log  # SSH login attempts
sudo netstat -an | grep :5001   # Active connections

# 2. Block IP if needed
sudo ufw deny from SUSPICIOUS_IP

# 3. Rate limiting (install fail2ban if not already)
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 4. Check current bans
sudo fail2ban-client status sshd
```

### Scenario 4: Out of Disk Space

```bash
# 1. Check what's using space
du -sh ~/* | sort -h
du -sh /var/* | sort -h

# 2. Clean up
# Clean old logs
sudo journalctl --vacuum-time=3d

# Clean old backups
find ~/backups -type f -mtime +3 -delete

# Clean package cache
sudo apt clean
sudo apt autoremove -y

# 3. Verify space freed
df -h
```

### Scenario 5: High CPU/Memory Usage

```bash
# 1. Identify the problem
htop
top

# 2. Check if backend is causing it
ps aux | grep backend

# 3. Check for runaway queries
psql -U attendanceuser -d attendancedb -c "
SELECT pid, query, state, query_start
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY query_start;
"

# 4. Kill long-running query if needed
psql -U attendanceuser -d attendancedb -c "
SELECT pg_terminate_backend(PID_HERE);
"

# 5. Restart service if memory leak suspected
sudo systemctl restart deskattendance
```

---

## 📱 CLIENT TROUBLESHOOTING

### Common Client Issues After Deployment

#### Issue 1: "Cannot connect to server"

**Cause:** Client still pointing to old server or network issue

**Solution:**
```
1. Check VPS is running:
   curl http://72.61.226.129:5001/health

2. Verify client config:
   - Open: %APPDATA%\DeskAttendanceApp\appConfig.json
   - Verify: "apiBaseUrl": "http://72.61.226.129:5001"

3. Check firewall:
   - VPS: sudo ufw status
   - Client: Windows Firewall not blocking outbound 5001

4. Test from browser:
   http://72.61.226.129:5001/health
   (Should show: {"status":"ok"})
```

#### Issue 2: "Profile not found" after update

**Cause:** CompanyId mismatch

**Solution:**
```
1. Check database:
   psql -U attendanceuser -d attendancedb -c "
   SELECT DISTINCT \"CompanyId\" FROM \"UserProfiles\";
   "

2. Verify client config matches:
   "companyId": "markaudio2019"

3. If mismatch, update database:
   UPDATE "UserProfiles" 
   SET "CompanyId" = 'markaudio2019'
   WHERE "CompanyId" = 'old_id';
```

#### Issue 3: Old version still running

**Cause:** Update didn't install properly

**Solution:**
```
1. Completely uninstall old version:
   - Control Panel → Uninstall Programs
   - Remove "DeskAttendance" or "Mark Audio Attendance"

2. Delete app data:
   - Delete: %APPDATA%\DeskAttendanceApp
   - Delete: %LOCALAPPDATA%\DeskAttendanceApp

3. Fresh install:
   - Run MarkAudio-Setup.exe as Administrator
   - Complete installation
   - Login again
```

---

## 📝 DEPLOYMENT CHECKLIST TEMPLATE

### Pre-Deployment

```
□ Code reviewed and tested locally
□ All tests passing
□ Database backup completed
□ Backend files backup completed
□ Users notified (15 min advance notice)
□ Deployment scheduled during low-usage hours
□ Rollback plan ready
□ Health check script prepared
□ Emergency contact available
```

### During Deployment

```
□ Pre-deployment health check passed
□ Service stopped gracefully
□ New version deployed
□ Migrations completed (if any)
□ Service started successfully
□ Health endpoint responding
□ No errors in logs
□ Database connectivity verified
```

### Post-Deployment

```
□ Service running for 5+ minutes without errors
□ Test login from client machine
□ Verify all 10 new features working:
   □ IST timezone correct
   □ DD-MM-YYYY format showing
   □ Right-click popup working
   □ 10-second polling active
   □ Employee settings accessible
   □ Actions column removed (admin)
   □ Date columns renamed correctly
   □ Name uppercase working
   □ Mobile validation (10 digits)
   □ Profile shows after creation
□ Performance acceptable (response time < 2s)
□ No memory leaks (check after 1 hour)
□ Users notified deployment complete
□ Documentation updated
□ Backup retention verified
```

---

## 🎓 KNOWLEDGE BASE

### Understanding Your Architecture

**1. Multi-Tenant Design:**
- Each company has unique `companyId` (e.g., "markaudio2019")
- All data segregated by `X-Company-Id` header
- Database: Single PostgreSQL database, filtered by CompanyId
- Allows multiple companies on same server

**2. Electron App Structure:**
```
MarkAudio-Setup.exe
├── Electron Shell (Desktop wrapper)
├── React App (UI - embedded in build/)
├── Backend (.NET - embedded in backend/)
├── PostgreSQL Client Libraries
└── appConfig.json (Company-specific config)
```

**3. Data Flow:**
```
User Action → React Component → API Call (with CompanyId header)
→ .NET Controller → PostgreSQL (WHERE CompanyId = 'markaudio2019')
→ Response → React → UI Update
```

### Critical Files Explained

**Backend:**
- `Program.cs`: App startup, middleware, database config
- `appsettings.Production.json`: Production DB connection
- `Controllers/`: API endpoints
- `Models/`: Database entities
- `Migrations/`: Database schema changes

**Frontend:**
- `src/components/`: React UI components
- `src/config/networkConfig.js`: API URL, CompanyId loader
- `src/utils/helpers.js`: Date formatting, utilities

**Electron:**
- `main.js`: Desktop app initialization
- `appConfig.json`: Runtime configuration (CompanyId, API URL)
- `build/`: Compiled React app (embedded)
- `backend/`: Compiled .NET backend (embedded)

### Common Gotchas

**1. Database Timezone:**
```csharp
// Your connection string MUST include:
Timezone=Asia/Kolkata

// Otherwise timestamps will be UTC!
```

**2. CompanyId Header:**
```javascript
// ALWAYS include in API calls:
headers: {
  'X-Company-Id': getCompanyId()
}

// Missing this = wrong company data!
```

**3. Migration Auto-Run:**
```csharp
// Migrations run on EVERY startup
context.Database.Migrate();

// Slow migrations = slow startup!
// Test migrations separately first
```

**4. CORS Configuration:**
```csharp
// Your current config allows ALL origins:
policy.AllowAnyOrigin()

// Consider restricting in production:
policy.WithOrigins("http://72.61.226.129:5001")
```

### Performance Optimization Tips

**1. Database Indexing:**
```sql
-- Check if indexes exist:
SELECT * FROM pg_indexes WHERE tablename = 'AttendanceRecords';

-- Add index for common queries:
CREATE INDEX idx_attendance_email ON "AttendanceRecords"("Email");
CREATE INDEX idx_attendance_timestamp ON "AttendanceRecords"("Timestamp");
CREATE INDEX idx_attendance_companyid ON "AttendanceRecords"("CompanyId");
```

**2. Connection Pooling:**
```csharp
// Already configured in your connection string
// PostgreSQL default pool size: 100
// Monitor with:
// SELECT count(*) FROM pg_stat_activity;
```

**3. Response Caching:**
```csharp
// For static data, add caching:
[ResponseCache(Duration = 60)] // Cache for 60 seconds
public IActionResult GetStaticData() { ... }
```

### Security Considerations

**1. Password Storage:**
```csharp
// CRITICAL: Your current code stores passwords in plain text!
// TODO: Implement password hashing:

using Microsoft.AspNetCore.Identity;
var hasher = new PasswordHasher<User>();
user.Password = hasher.HashPassword(user, plainPassword);

// Verify:
var result = hasher.VerifyHashedPassword(user, user.Password, plainPassword);
```

**2. JWT Token Security:**
```csharp
// Your secret key is hardcoded!
// TODO: Move to environment variable:

// appsettings.Production.json:
{
  "Jwt": {
    "SecretKey": "YOUR-256-BIT-SECRET-KEY-HERE"
  }
}

// Program.cs:
var secretKey = builder.Configuration["Jwt:SecretKey"];
```

**3. SQL Injection Prevention:**
```csharp
// ✅ SAFE: EF Core uses parameterized queries
var user = context.Users.FirstOrDefault(u => u.Email == email);

// ❌ UNSAFE: Never use raw SQL with concatenation
// var user = context.Users.FromSqlRaw($"SELECT * FROM Users WHERE Email = '{email}'");
```

---

## 📚 ADDITIONAL RESOURCES

### Useful Commands Quick Reference

```bash
# ============ SERVICE MANAGEMENT ============
sudo systemctl start deskattendance      # Start service
sudo systemctl stop deskattendance       # Stop service
sudo systemctl restart deskattendance    # Restart service
sudo systemctl status deskattendance     # Check status
sudo systemctl enable deskattendance     # Enable on boot
sudo systemctl disable deskattendance    # Disable on boot

# ============ LOGS ============
sudo journalctl -u deskattendance -f               # Live logs
sudo journalctl -u deskattendance -n 100           # Last 100 lines
sudo journalctl -u deskattendance --since "1 hour ago"
sudo journalctl -u deskattendance --since "2024-11-26 10:00"
sudo journalctl -u deskattendance -p err           # Errors only

# ============ DATABASE ============
psql -U attendanceuser -d attendancedb             # Connect to DB
sudo -u postgres psql attendancedb                 # Connect as postgres
\dt                                                # List tables
\d "TableName"                                     # Describe table
\q                                                 # Quit psql

# Backup
sudo -u postgres pg_dump attendancedb > backup.sql
gunzip -c backup.sql.gz | sudo -u postgres psql attendancedb

# ============ DISK & MEMORY ============
df -h                    # Disk usage
du -sh ~/*              # Directory sizes
free -h                 # Memory usage
htop                    # Process monitor
ncdu                    # Interactive disk analyzer

# ============ NETWORK ============
sudo netstat -tulpn                              # All listening ports
sudo netstat -tulpn | grep 5001                  # Check port 5001
curl http://localhost:5001/health                # Test locally
curl http://72.61.226.129:5001/health           # Test externally
ping 72.61.226.129                              # Test connectivity

# ============ FIREWALL ============
sudo ufw status                  # Check firewall rules
sudo ufw allow 5001/tcp          # Allow port 5001
sudo ufw deny from 1.2.3.4       # Block IP
sudo ufw reload                  # Reload firewall

# ============ FILE MANAGEMENT ============
ls -lh                          # List files with sizes
tail -f file.log               # Watch log file
grep "error" file.log          # Search in file
find . -name "*.exe"           # Find files
tar -czf backup.tar.gz folder/ # Create archive
tar -xzf backup.tar.gz         # Extract archive
```

### Monitoring Dashboard (Optional - Future)

Consider setting up Grafana + Prometheus for visual monitoring:

```bash
# Install Prometheus
sudo apt install prometheus -y

# Install Grafana
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt update
sudo apt install grafana -y

# Enable and start
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Access at: http://YOUR_VPS_IP:3000
# Default login: admin/admin
```

### Learning Resources

- **PostgreSQL Admin:** https://www.postgresql.org/docs/
- **Systemd Services:** https://www.freedesktop.org/software/systemd/man/systemd.service.html
- **Ubuntu Server:** https://ubuntu.com/server/docs
- **.NET Deployment:** https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/linux-nginx
- **EF Core Migrations:** https://docs.microsoft.com/en-us/ef/core/managing-schemas/migrations/

---

## 🎉 CONCLUSION

You now have a comprehensive guide for deploying your DeskAttendance application to production with zero or minimal downtime.

### Key Takeaways:

1. **Always backup** before any deployment
2. **Test locally** before deploying to production
3. **Inform users** before deployment
4. **Monitor closely** after deployment
5. **Have a rollback plan** ready
6. **Document changes** in a changelog
7. **Schedule deployments** during low-usage hours
8. **Automate** repetitive tasks with scripts

### Your Current Status:

✅ **Backend:** Hostinger VPS (72.61.226.129:5001)  
✅ **Database:** PostgreSQL with auto-migrations  
✅ **Active Users:** Mark Audio (5 employees)  
✅ **Recent Changes:** All 10 fixes implemented  
✅ **Next Step:** Deploy using Scenario 1 (Backend + Frontend)  

### Recommended Next Steps:

1. **Immediate:** Deploy your 10 fixes using Scenario 1
2. **This Week:** Setup automated daily backups
3. **This Month:** Implement password hashing
4. **Future:** Setup monitoring dashboard (Grafana)

---

**Need Help?**

- Check logs: `sudo journalctl -u deskattendance -f`
- Test health: `curl http://localhost:5001/health`
- Emergency rollback: `~/scripts/emergency-rollback.sh`

**Good luck with your deployment! 🚀**
