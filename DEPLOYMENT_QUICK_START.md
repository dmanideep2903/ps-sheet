# 🚀 QUICK DEPLOYMENT STEPS - MarkAudio to Oracle Cloud

**Status:** Ready to deploy! All files prepared.  
**Time Required:** ~60 minutes  
**Cost:** $0 (Oracle Free Tier)

---

## ✅ COMPLETED

- [x] Backend configured for PostgreSQL
- [x] Production build created (6.72 MB)
- [x] Auto-update code ready
- [x] Server setup script created
- [x] No Docker needed! Direct Ubuntu installation

---

## 📦 FILES READY

1. **markaudio-backend-deploy.zip** (6.72 MB)
   - Backend application for Linux ARM64
   - Database migrations included
   - Ready to upload to server

2. **setup-server.sh**
   - Automated server setup script
   - Installs .NET 9, PostgreSQL 15
   - Creates database, user, service
   - Configures firewall

---

## 🎯 STEP-BY-STEP DEPLOYMENT

### STEP 1: Create Oracle Cloud Instance (15 minutes)

1. **Login to Oracle Cloud:**
   - Go to: https://cloud.oracle.com
   - Sign in with your Oracle account

2. **Create Compute Instance:**
   ```
   Navigation: Hamburger Menu → Compute → Instances → Create Instance
   
   Configuration:
   ├─ Name: markaudio-attendance-server
   ├─ Image: Ubuntu 22.04 Minimal aarch64
   ├─ Shape: VM.Standard.A1.Flex
   │  ├─ OCPUs: 4 (FREE)
   │  └─ Memory: 24 GB (FREE)
   ├─ Network: Default VCN (or create new)
   ├─ Public IP: Assign IPv4 address ✅
   └─ SSH Key: Upload your public key
   ```

3. **Configure Security Rules:**
   ```
   Navigation: Networking → Virtual Cloud Networks → 
               Your VCN → Security Lists → Default Security List
   
   Add Ingress Rules:
   
   Rule 1 - Backend API:
   ├─ Source CIDR: 0.0.0.0/0
   ├─ IP Protocol: TCP
   └─ Destination Port: 5001
   
   Rule 2 - PostgreSQL (Optional):
   ├─ Source CIDR: YOUR_OFFICE_IP/32
   ├─ IP Protocol: TCP
   └─ Destination Port: 5432
   ```

4. **Note Your Public IP:**
   ```
   After instance is created (2-3 min):
   Click instance → Copy Public IP
   
   Example: 152.67.123.45
   
   WRITE IT HERE: _____________________
   ```

---

### STEP 2: Upload Files to Server (5 minutes)

**From Windows PowerShell:**

```powershell
# Navigate to project folder
cd P:\SourceCode-HM\DeskAttendanceApp

# Upload deployment package
scp markaudio-backend-deploy.zip ubuntu@YOUR_IP:~/

# Upload setup script
scp setup-server.sh ubuntu@YOUR_IP:~/

# Example (replace with your IP):
# scp markaudio-backend-deploy.zip ubuntu@152.67.123.45:~/
```

**Troubleshooting:**
```powershell
# If scp not found, use WinSCP or install OpenSSH:
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

---

### STEP 3: Run Server Setup (30 minutes)

**SSH to your server:**
```bash
ssh ubuntu@YOUR_IP

# Example:
# ssh ubuntu@152.67.123.45
```

**Run setup script:**
```bash
# Make executable
chmod +x setup-server.sh

# Run setup (this will take ~20 minutes)
./setup-server.sh
```

**What the script does:**
1. ✅ Updates Ubuntu packages
2. ✅ Installs .NET 9 Runtime (ARM64)
3. ✅ Installs PostgreSQL 15
4. ✅ Creates database: `attendancedb`
5. ✅ Creates user: `markaudio_user`
6. ✅ Extracts backend application
7. ✅ Runs database migrations
8. ✅ Creates systemd service (auto-start)
9. ✅ Configures firewall (UFW)
10. ✅ Starts backend on port 5001

**Expected output (at the end):**
```
=== SETUP COMPLETE! ===

Backend is running on: http://152.67.123.45:5001

View logs: sudo journalctl -u markaudio-backend -f
Restart: sudo systemctl restart markaudio-backend

Next: Update desktop app with server IP!
```

---

### STEP 4: Verify Deployment (5 minutes)

**Test backend health:**
```bash
# On server
curl http://localhost:5001/health

# Should return: {"status":"ok"}
```

**Test from Windows PC:**
```powershell
# Replace with your IP
Invoke-RestMethod -Uri "http://152.67.123.45:5001/health"

# Should return: @{status=ok}
```

**Check service status:**
```bash
# On server
sudo systemctl status markaudio-backend

# Should show: Active: active (running)
```

**View logs:**
```bash
# Real-time logs
sudo journalctl -u markaudio-backend -f

# Last 50 lines
sudo journalctl -u markaudio-backend -n 50
```

---

### STEP 5: Update Desktop App (10 minutes)

**Edit appConfig.json:**
```json
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://YOUR_ORACLE_IP:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/YOUR_USERNAME/markaudio/releases/latest"
  }
}
```

**Example:**
```json
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://152.67.123.45:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/markaudio/attendance/releases/latest"
  }
}
```

**Build new installer:**
```powershell
cd P:\SourceCode-HM\DeskAttendanceApp\electron-app

# Update appConfig.json with your Oracle IP
# Then build installer:
npm run dist
```

**Install on test system:**
```powershell
# Installer will be in: electron-app\dist\
# Example: MarkAudio Setup 1.0.0.exe
```

---

### STEP 6: Test Everything (10 minutes)

**On ONE test system:**

1. **Install app** (new version with cloud IP)

2. **Test Admin Login:**
   - Email: `pivotadmin@gmail.com`
   - Password: `Admin123`
   - Should login successfully ✅

3. **Create Test Employee:**
   - Add new employee
   - Register face
   - Note employee credentials

4. **Test Employee Login:**
   - Logout admin
   - Login as employee
   - Should validate network ✅
   - Should record attendance ✅

5. **Check Database:**
   ```bash
   # On server
   sudo -u postgres psql -d attendancedb

   # List users
   SELECT "Email", "Name", "Role" FROM "Users";

   # List attendance
   SELECT * FROM "AttendanceRecords" ORDER BY "Id" DESC LIMIT 5;

   # Exit
   \q
   ```

---

## 🔥 TROUBLESHOOTING

### Backend won't start
```bash
# Check status
sudo systemctl status markaudio-backend

# Check logs
sudo journalctl -u markaudio-backend -n 100

# Restart service
sudo systemctl restart markaudio-backend

# Check if port is listening
sudo netstat -tulpn | grep 5001
```

### Can't connect from desktop app
```bash
# On server - check firewall
sudo ufw status

# Should show:
# 5001/tcp   ALLOW   Anywhere

# If not, add rule:
sudo ufw allow 5001/tcp
```

### Database connection failed
```bash
# Check PostgreSQL
sudo systemctl status postgresql

# Test connection
sudo -u postgres psql -d attendancedb -c "SELECT version();"

# Check user permissions
sudo -u postgres psql
\l attendancedb
\du markaudio_user
```

### Desktop app shows 401 Unauthorized
```
This is NORMAL for employee login if network validation fails!

Admin login should always work (bypasses network check).

For employee:
1. Must be on registered network
2. Gateway IP: 192.168.0.1
3. Router MAC: 3C-64-CF-30-FC-2D

Update these in database SystemSettings table if needed.
```

---

## 📊 SERVER MANAGEMENT COMMANDS

### Service Control
```bash
# Start backend
sudo systemctl start markaudio-backend

# Stop backend
sudo systemctl stop markaudio-backend

# Restart backend
sudo systemctl restart markaudio-backend

# Enable auto-start on boot
sudo systemctl enable markaudio-backend

# View status
sudo systemctl status markaudio-backend
```

### Logs
```bash
# Real-time logs
sudo journalctl -u markaudio-backend -f

# Today's logs
sudo journalctl -u markaudio-backend --since today

# Last 100 lines
sudo journalctl -u markaudio-backend -n 100

# Errors only
sudo journalctl -u markaudio-backend -p err
```

### Database Backup
```bash
# Manual backup
sudo -u postgres pg_dump attendancedb > ~/backup_$(date +%Y%m%d).sql

# Automated daily backup (cron)
crontab -e
# Add line:
0 2 * * * sudo -u postgres pg_dump attendancedb > ~/backups/db_$(date +\%Y\%m\%d).sql
```

### Update Backend Code
```bash
# Stop service
sudo systemctl stop markaudio-backend

# Upload new files to ~/markaudio-backend-new
# Then:
cd ~/markaudio-backend
rm -rf *
mv ~/markaudio-backend-new/* .

# Run migrations if needed
export ASPNETCORE_ENVIRONMENT=Production
dotnet ef database update

# Restart service
sudo systemctl restart markaudio-backend
```

---

## 🎯 DEPLOYMENT CHECKLIST

**Pre-Deployment:**
- [ ] Oracle Cloud account ready
- [ ] SSH key generated
- [ ] Files prepared (markaudio-backend-deploy.zip, setup-server.sh)

**Oracle Cloud:**
- [ ] Instance created (VM.Standard.A1.Flex)
- [ ] Public IP noted: `_______________`
- [ ] Security rules added (port 5001)
- [ ] Can SSH to server

**Server Setup:**
- [ ] Files uploaded (scp)
- [ ] setup-server.sh executed
- [ ] Backend service running
- [ ] Health check passes: `curl http://localhost:5001/health`

**Desktop App:**
- [ ] appConfig.json updated with Oracle IP
- [ ] New installer built
- [ ] Tested on ONE system
- [ ] Admin login works
- [ ] Employee login works
- [ ] Attendance recording works

**Production Rollout:**
- [ ] Install on all 10 systems
- [ ] Test each system
- [ ] Train users
- [ ] Setup monitoring

---

## 📞 NEXT STEPS AFTER DEPLOYMENT

### 1. Setup Auto-Update (Optional)
```
1. Create GitHub repository
2. Create first release (v1.0.0)
3. Upload installer to release
4. Update appConfig.json with GitHub URL
5. Rebuild installer
6. All future updates will auto-install!
```

### 2. Setup SSL/HTTPS (Optional)
```
Requires domain name:
1. Point domain to Oracle IP
2. Install Nginx + Certbot
3. Get Let's Encrypt SSL certificate
4. Update appConfig.json to https://
```

### 3. Setup Monitoring
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor in real-time
htop  # CPU/Memory
sudo iotop  # Disk I/O
sudo nethogs  # Network
```

---

## 💰 COSTS

**Oracle Cloud Free Tier:**
- VM.Standard.A1.Flex (4 OCPU, 24GB): **FREE**
- 200 GB Block Storage: **FREE**
- 10 TB/month Bandwidth: **FREE**
- Public IP: **FREE**

**Total Monthly Cost: $0** ✅

---

## ⏱️ TIME ESTIMATE

| Step | Time |
|------|------|
| Create Oracle instance | 15 min |
| Upload files | 5 min |
| Run server setup | 30 min |
| Test deployment | 10 min |
| Update desktop app | 10 min |
| **TOTAL** | **~70 minutes** |

---

## 🎉 SUCCESS CRITERIA

✅ Backend running on Oracle Cloud  
✅ PostgreSQL database created  
✅ Desktop app connects to cloud  
✅ Admin can login from anywhere  
✅ Employees can login from office network  
✅ Attendance records saved to cloud  
✅ All 10 systems connected  

---

## 📝 IMPORTANT NOTES

1. **Database Password:** `MarkAudio@2025!Secure`
   - Stored in: backend/appsettings.Production.json
   - Change if needed before deployment

2. **Network Validation:**
   - Stored in database: SystemSettings table
   - Gateway IP: 192.168.0.1
   - Router MAC: 3C-64-CF-30-FC-2D
   - Update if your network is different

3. **Firewall:**
   - Port 5001 must be open on Oracle Security List AND Ubuntu UFW
   - Both are configured by setup script

4. **Backups:**
   - Setup automated daily backups (see commands above)
   - Store backups off-server for safety

5. **Updates:**
   - To update backend: stop service, replace files, restart
   - To update desktop app: use auto-update or reinstall

---

## 🆘 NEED HELP?

**Check logs first:**
```bash
sudo journalctl -u markaudio-backend -n 100
```

**Common issues:**
- Can't SSH: Check Oracle Security List allows port 22
- Backend won't start: Check logs for database connection error
- Can't connect from app: Check firewall allows port 5001
- Login fails: Check network validation settings in database

---

## ✅ READY TO DEPLOY!

You have everything you need. The whole process takes ~70 minutes.

**Start with STEP 1:** Create Oracle Cloud Instance

Good luck! 🚀
