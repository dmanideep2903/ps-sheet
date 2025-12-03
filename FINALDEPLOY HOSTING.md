# Backend Deployment Guide - Hostinger VPS

## Complete Step-by-Step Deployment Process

### STEP 1: Build Backend on Windows

```powershell
# Navigate to backend directory
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Publish for Linux
dotnet publish -c Release -r linux-x64 --self-contained -o publish-linux

# Create deployment zip
cd ..
Compress-Archive -Path "backend\publish-linux\*" -DestinationPath "backend-deploy.zip" -Force

# Verify zip created (should be ~100MB)
Get-Item "backend-deploy.zip"
```

**Output:** `P:\SourceCode-PIVOT\DeskAttendanceApp\backend-deploy.zip`

---

### STEP 2: Upload to Server via HestiaCP

1. **Login to HestiaCP:**
   - URL: `https://srv1145703.hstgr.cloud:8083`
   - Username: `user` (NOT pivot)
   - Password: Your HestiaCP password

2. **Navigate to File Manager:**
   - Click **File Manager** in left menu
   - Navigate to: `web/srv1145703.hstgr.cloud/App/`
   - If `App` folder doesn't exist, create it

3. **Upload File:**
   - Click **Upload** button
   - Select `backend-deploy.zip` from your computer
   - Wait for upload to complete

**Uploaded Location:** `/home/user/web/srv1145703.hstgr.cloud/App/backend-deploy.zip`

---

### STEP 3: Deploy on Server

**SSH into server as root:**
```bash
ssh root@72.61.226.129
```

**Run deployment commands:**
```bash
# Navigate to deployment directory
cd /home/pivot/app

# Copy zip from upload location
cp /home/user/web/srv1145703.hstgr.cloud/App/backend-deploy.zip .

# Remove old extraction folder if exists
rm -rf backend-new

# Extract the zip
unzip -q backend-deploy.zip -d backend-new

# Stop the running service
systemctl stop deskattendance

# Backup current backend (with timestamp)
mv backend backend-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || echo "No existing backend to backup"

# Move new version to active location
mv backend-new backend

# Set correct permissions
chmod +x backend/backend
chown -R pivot:pivot backend



# Verify configuration
grep "Password=" backend/appsettings.Production.json

# Restart service
systemctl restart deskattendance

# Wait for startup
sleep 3

# Check service status
systemctl status deskattendance

# Test health endpoint
curl http://localhost:5001/api/auth/health
```

**Expected Output:**
```json
{"status":"healthy","timestamp":"2025-11-29T06:05:12.5101653Z"}
```

---

### STEP 4: Verify Deployment

**Check service status:**
```bash
systemctl status deskattendance
```
Should show: `Active: active (running)`

**Test from external:**
```bash
curl http://72.61.226.129:5001/api/auth/health
```

**View logs if issues:**
```bash
journalctl -u deskattendance -f
```

---

## Quick Reference

### File Paths

| Location | Path |
|----------|------|
| **Windows Build Output** | `P:\SourceCode-PIVOT\DeskAttendanceApp\backend\publish-linux\` |
| **Windows Zip File** | `P:\SourceCode-PIVOT\DeskAttendanceApp\backend-deploy.zip` |
| **HestiaCP Upload Path** | `/home/user/web/srv1145703.hstgr.cloud/App/backend-deploy.zip` |
| **Server Deployment Path** | `/home/pivot/app/backend/` |
| **Service File** | `/etc/systemd/system/deskattendance.service` |
| **Backups** | `/home/pivot/app/backend-backup-YYYYMMDD-HHMMSS/` |

### Key Commands

```bash
# Check service status
systemctl status deskattendance

# View live logs
journalctl -u deskattendance -f

# Restart service
systemctl restart deskattendance

# Stop service
systemctl stop deskattendance

# Start service
systemctl start deskattendance

# Test health endpoint
curl http://localhost:5001/api/auth/health

# Check if port 5001 is listening
netstat -tulpn | grep 5001
```

### Database Configuration

- **Host:** localhost
- **Port:** 5432
- **Database:** attendancedb
- **Username:** attendanceuser
- **Password:** Pivot@9492989700
- **Timezone:** Asia/Kolkata

### Important Notes

1. **Always use `user` account** for HestiaCP File Manager uploads
2. **Upload path must be:** `/home/user/web/srv1145703.hstgr.cloud/App/`
3. **Service runs as `pivot` user**, not root
4. **Health endpoint is:** `/api/auth/health` (NOT `/api/health`)
5. **Port:** 5001 (configured in appsettings.Production.json)
6. **Backups are automatic** - old backend saved with timestamp

### Rollback Procedure

If deployment fails and you need to rollback:

```bash
# Stop current service
systemctl stop deskattendance

# Find latest backup
ls -la /home/pivot/app/ | grep backup

# Restore backup (replace YYYYMMDD-HHMMSS with actual timestamp)
mv /home/pivot/app/backend /home/pivot/app/backend-failed
mv /home/pivot/app/backend-backup-YYYYMMDD-HHMMSS /home/pivot/app/backend

# Restart service
systemctl restart deskattendance

# Verify
curl http://localhost:5001/api/auth/health
```

---

## One-Line Deployment Script

Save this for future quick deployments:

```bash
cd /home/pivot/app && cp /home/user/web/srv1145703.hstgr.cloud/App/backend-deploy.zip . && rm -rf backend-new && unzip -q backend-deploy.zip -d backend-new && systemctl stop deskattendance && mv backend backend-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null && mv backend-new backend && chmod +x backend/backend && chown -R pivot:pivot backend && systemctl restart deskattendance && sleep 3 && systemctl status deskattendance && curl http://localhost:5001/api/auth/health
```

**Use only if you're confident everything is correct!**
