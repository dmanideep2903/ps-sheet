# ✅ DEPLOYMENT CHECKLIST - HestiaCP Web Terminal Method

**Date:** November 28, 2025  
**Server:** 72.61.226.129 (Ubuntu 24.04 + HestiaCP)  
**Backend File:** `P:\SourceCode-PIVOT\DeskAttendanceApp\backend-upload.zip` (READY)

---

## 📦 PART 1: Upload Backend Files

### ☐ Step 1: Access HestiaCP
1. Open browser
2. Go to: `https://72.61.226.129:8083`
3. Login with your HestiaCP credentials
4. ✓ You're in!

### ☐ Step 2: Create Folder and Upload ZIP File
1. In HestiaCP File Manager, you're currently at `/home/pivot/`
2. Click **"New Folder"** or **"Create Folder"** button
3. Name it: `app`
4. Double-click the `app` folder to enter it
5. Click **"Upload"** button
6. Select file: `P:\SourceCode-PIVOT\DeskAttendanceApp\backend-upload.zip`
7. Wait for upload to complete (may take 2-3 minutes)
8. You should see `backend-upload.zip` in the file list
9. ✓ File uploaded!

---

## 💻 PART 2: Setup Backend (Web Terminal)

### ☐ Step 3: Open Web Terminal
1. In HestiaCP, find **"Terminal"** or **"Web Terminal"** or **"Console"**
   - Usually under: Server section, or Tools, or Admin menu
2. Click to open terminal window
3. ✓ Terminal opened!

### ☐ Step 4: Run Setup Commands

**Copy and paste this ENTIRE block into Web Terminal:**

```bash
# Install dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y libicu-dev libssl-dev ca-certificates postgresql unzip

# Setup PostgreSQL
echo "Setting up database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE DATABASE attendancedb;"
sudo -u postgres psql -c "CREATE USER attendanceuser WITH PASSWORD 'MarkAudio@2025!Secure';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE attendancedb TO attendanceuser;"
sudo -u postgres psql -c "ALTER DATABASE attendancedb OWNER TO attendanceuser;"

# Create directory and extract files
echo "Extracting backend files..."
mkdir -p /home/pivot/app/backend
cd /home/pivot/app
unzip -o backend-upload.zip -d backend/
sudo chown -R pivot:pivot /home/pivot/app
chmod +x /home/pivot/app/backend/backend

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 5001/tcp
sudo ufw allow 22/tcp
sudo ufw --force enable

# Create systemd service
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

# Enable and start service
echo "Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl enable deskattendance
sudo systemctl start deskattendance

# Wait for startup
sleep 5

# Check status
echo ""
echo "=== Service Status ==="
sudo systemctl status deskattendance --no-pager

# Test backend
echo ""
echo "=== Testing Backend ==="
curl http://localhost:5001/api/health

echo ""
echo "✓ Deployment Complete!"
echo "Backend should be running at: http://72.61.226.129:5001"
```

**Press Enter and wait for all commands to complete (may take 2-3 minutes)**

✓ Setup complete!

---

## ✓ PART 3: Verify Deployment

### ☐ Step 5: Check Service Status (in Web Terminal)

```bash
sudo systemctl status deskattendance
```

**Expected output:** `active (running)` in green

### ☐ Step 6: Test Local Access (in Web Terminal)

```bash
curl http://localhost:5001/api/health
```

**Expected output:** `"Healthy"` or `200 OK`

### ☐ Step 7: Test External Access (from your Windows PC)

Open PowerShell and run:

```powershell
Invoke-WebRequest -Uri "http://72.61.226.129:5001/api/health" -UseBasicParsing
```

**Expected output:** `StatusCode: 200, Content: "Healthy"`

✓ Backend is accessible!

---

## 🚀 PART 4: Deploy Electron App

### ☐ Step 8: Install Electron App on Client Machines

1. Locate installer: `P:\SourceCode-PIVOT\DeskAttendanceApp\electron-app\dist\EMPLOYEE TIMEPULSE.exe`
2. Copy to client machines
3. Run installer
4. Launch app
5. Test login with backend: `http://72.61.226.129:5001`

✓ App installed!

---

## 🔍 TROUBLESHOOTING

### If Backend Won't Start:

**Check logs in Web Terminal:**
```bash
sudo journalctl -u deskattendance -n 50
```

**Check if port is in use:**
```bash
sudo netstat -tulnp | grep 5001
```

**Restart service:**
```bash
sudo systemctl restart deskattendance
```

### If Database Connection Fails:

**Test database:**
```bash
psql -h localhost -U attendanceuser -d attendancedb
# Password: MarkAudio@2025!Secure
```

**Check PostgreSQL:**
```bash
sudo systemctl status postgresql
```

### If External Access Fails:

**Check firewall:**
```bash
sudo ufw status
```

**Should show:**
- `5001/tcp ALLOW Anywhere`
- `22/tcp ALLOW Anywhere`

**Add rules if missing:**
```bash
sudo ufw allow 5001/tcp
sudo ufw reload
```

### If Files Didn't Extract:

**Manually extract:**
```bash
cd /home/pivot/app
unzip -o backend-upload.zip -d backend/
chmod +x backend/backend
ls -lah backend/
```

---

## 📝 USEFUL COMMANDS

**View live logs:**
```bash
sudo journalctl -u deskattendance -f
```

**Stop backend:**
```bash
sudo systemctl stop deskattendance
```

**Start backend:**
```bash
sudo systemctl start deskattendance
```

**Restart backend:**
```bash
sudo systemctl restart deskattendance
```

**Check backend process:**
```bash
ps aux | grep backend
```

**Check database:**
```bash
sudo -u postgres psql -d attendancedb -c "\dt"
```

---

## ✅ SUCCESS INDICATORS

- [ ] PostgreSQL running: `sudo systemctl status postgresql` shows "active"
- [ ] Database exists: `sudo -u postgres psql -l | grep attendancedb` shows database
- [ ] Backend service running: `sudo systemctl status deskattendance` shows "active (running)"
- [ ] Port 5001 open: `sudo netstat -tulnp | grep 5001` shows backend listening
- [ ] Local test works: `curl http://localhost:5001/api/health` returns "Healthy"
- [ ] External test works: Browser shows "Healthy" at `http://72.61.226.129:5001/api/health`
- [ ] Electron app connects and can login

---

## 🎯 WHAT YOU NEED TO DO

### RIGHT NOW:

1. ✅ **backend-upload.zip is ready** at: `P:\SourceCode-PIVOT\DeskAttendanceApp\`
2. 🔲 **Upload it** via HestiaCP File Manager to `/home/pivot/app/`
3. 🔲 **Run setup commands** in HestiaCP Web Terminal (copy-paste the big block above)
4. 🔲 **Verify** backend is running
5. 🔲 **Install** Electron app: `electron-app\dist\EMPLOYEE TIMEPULSE.exe`

### THAT'S IT!

**Time estimate:** 10-15 minutes total

**Questions?** Check the troubleshooting section above!

---

**Deployment prepared by:** GitHub Copilot  
**Backend:** .NET 9.0 Self-Contained (Linux x64)  
**Database:** PostgreSQL with attendancedb  
**Port:** 5001  
**Company:** revit
