# 🧪 LOCAL TESTING GUIDE
## Testing Changes Before Production Deployment

**Your Current Setup:**
- ✅ Backend: Running on VPS (72.61.226.129:5001)
- ✅ Database: PostgreSQL on VPS
- ✅ Active Users: Mark Audio (5 employees)
- ❓ Testing: Need to test locally before deployment

---

## 🎯 TESTING STRATEGIES (Choose One)

### **Option 1: Test Against Production Server** ⭐ RECOMMENDED
**Pros:** No local setup needed, real data, quick testing  
**Cons:** Uses production database (test carefully!)  
**Time:** 5 minutes

### **Option 2: Local Backend + Remote Database**
**Pros:** Test backend changes safely, real data  
**Cons:** Need to allow remote DB access  
**Time:** 15 minutes

### **Option 3: Fully Local Environment**
**Pros:** Complete isolation, safest for testing  
**Cons:** Need local PostgreSQL, sample data  
**Time:** 30 minutes

### **Option 4: Separate Test Database on VPS**
**Pros:** Real server environment, isolated from production  
**Cons:** Need to setup test database  
**Time:** 20 minutes

---

## ⭐ OPTION 1: Test Against Production Server (RECOMMENDED)

**Best for:** UI changes, frontend logic, non-breaking backend changes

### How It Works:
```
Your Windows PC (Development)
├── React App (npm start) → Port 3000
└── Electron App (npm start) → Uses production backend
                                ↓
                    http://72.61.226.129:5001
                                ↓
                        Production Backend + DB
```

### Step-by-Step Testing

#### 1. Test React App in Browser

```powershell
# Open PowerShell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\react-app

# Start React development server
npm start

# Browser will open at: http://localhost:3000
```

**Configure to use production backend:**

```javascript
// react-app/src/config/networkConfig.js
// Temporarily change line 60:

// FOR TESTING ONLY - Change back after testing!
apiBaseUrl: 'http://72.61.226.129:5001',  // Production server
```

**⚠️ IMPORTANT:** This uses REAL production data!

**What to test:**
- ✅ Login works
- ✅ All 10 new features visible:
  - IST timezone showing
  - DD-MM-YYYY date format
  - Right-click popup
  - Employee settings button
  - Name uppercase in forms
  - Mobile 10-digit validation
- ✅ No console errors (F12 → Console tab)
- ✅ No breaking changes

**When done testing:**
```powershell
# Stop React dev server
Ctrl+C

# Revert networkConfig.js to original
```

#### 2. Test Electron App (Full Experience)

```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\electron-app

# Copy latest React build
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Copy-Item -Recurse ..\react-app\build .\

# Make sure appConfig.json points to production
# (It should already have: "apiBaseUrl": "http://72.61.226.129:5001")

# Start Electron app
npm start
```

**What to test:**
- ✅ Login with real credentials
- ✅ Punch In/Out works
- ✅ Employee Settings accessible
- ✅ Right-click on text shows copy/print
- ✅ Date format is DD-MM-YYYY
- ✅ Profile creation works
- ✅ All features from your 10 fixes

**⚠️ Testing Tips:**
- Use a test employee account (not admin)
- Don't delete real data
- Test during off-hours if possible

#### 3. Test Backend Changes Locally (Without Deploying)

If you want to test backend code changes before deploying:

```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Run backend locally, connecting to REMOTE database
dotnet run --environment Production

# Backend starts at: http://localhost:5001
```

**Configure Electron app to use local backend:**

```json
// electron-app/appConfig.json
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio",
  "apiBaseUrl": "http://localhost:5001",  // ← Change to localhost
  "useRemoteBackend": false
}
```

**Test the app:**
```powershell
cd ..\electron-app
npm start
```

**⚠️ CRITICAL:** This still uses production database!

**When done:**
```json
// Change back to production server
"apiBaseUrl": "http://72.61.226.129:5001"
```

---

## 🔧 OPTION 2: Local Backend + Remote Database

**Best for:** Testing backend changes with real data

### Setup Remote Database Access

#### On VPS (One-time setup):

```bash
ssh pivot@72.61.226.129

# Allow your Windows PC IP to access PostgreSQL
# First, find your Windows PC public IP
# Visit: https://whatismyipaddress.com/
# Let's say it's: 203.0.113.50

# Edit PostgreSQL config
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Add this line (replace with YOUR actual IP):
host    attendancedb    attendanceuser    203.0.113.50/32    md5

# Save and restart PostgreSQL
sudo systemctl restart postgresql

# Allow port 5432 in firewall
sudo ufw allow from 203.0.113.50 to any port 5432

echo "✓ Remote database access configured"
```

#### On Windows (Testing):

```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend

# Edit appsettings.Development.json
```

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=72.61.226.129;Port=5432;Database=attendancedb;Username=attendanceuser;Password=YOUR_PASSWORD_HERE;Timezone=Asia/Kolkata"
  }
}
```

**Get the password from VPS:**
```bash
# On VPS
cat ~/app/backend/appsettings.Production.json
# Copy the password
```

**Test connection:**

```powershell
# Run backend locally
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend
dotnet run

# Should connect to remote database
# Check for: "Now listening on: http://localhost:5001"
```

**Test with Electron:**

```powershell
# Update electron-app/appConfig.json
# "apiBaseUrl": "http://localhost:5001"

cd ..\electron-app
npm start
```

**⚠️ Security Warning:** 
- Close port 5432 after testing!
- Don't leave database exposed to internet

**Clean up after testing:**

```bash
# On VPS - Remove remote access
ssh pivot@72.61.226.129

sudo nano /etc/postgresql/16/main/pg_hba.conf
# Remove the line you added

sudo systemctl restart postgresql
sudo ufw delete allow from 203.0.113.50 to any port 5432
```

---

## 🏠 OPTION 3: Fully Local Environment (SAFEST)

**Best for:** Major changes, schema migrations, destructive testing

### Step 1: Install PostgreSQL on Windows

```powershell
# Download PostgreSQL 16 for Windows
# https://www.postgresql.org/download/windows/

# Or use Chocolatey:
choco install postgresql16

# During installation:
# - Password: yourLocalPassword123
# - Port: 5432
# - Locale: Default
```

### Step 2: Create Local Database

```powershell
# Open PowerShell as Administrator

# Connect to PostgreSQL
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres

# In PostgreSQL prompt:
```

```sql
-- Create database
CREATE DATABASE attendancedb_local;

-- Create user
CREATE USER attendanceuser WITH PASSWORD 'localpass123';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE attendancedb_local TO attendanceuser;

-- Connect to database
\c attendancedb_local

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO attendanceuser;

-- Exit
\q
```

### Step 3: Configure Backend for Local DB

```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend
```

**Create `appsettings.Development.json`:**

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
    "DefaultConnection": "Host=localhost;Port=5432;Database=attendancedb_local;Username=attendanceuser;Password=localpass123;Timezone=Asia/Kolkata"
  }
}
```

### Step 4: Apply Migrations

```powershell
# Set environment to Development
$env:ASPNETCORE_ENVIRONMENT = "Development"

# Apply migrations (creates all tables)
dotnet run

# You'll see: "Applying migration..."
# Press Ctrl+C after it says "Application started"
```

### Step 5: Seed Test Data

**Option A: Copy from production (recommended)**

```bash
# On VPS - Export data
ssh pivot@72.61.226.129

sudo -u postgres pg_dump attendancedb --data-only --inserts > ~/production-data.sql

# Download to Windows
exit

# On Windows PowerShell:
scp pivot@72.61.226.129:~/production-data.sql C:\Temp\
```

```powershell
# Import to local database
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U attendanceuser -d attendancedb_local -f C:\Temp\production-data.sql
```

**Option B: Create test data manually**

```sql
-- Connect to local DB
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U attendanceuser -d attendancedb_local

-- Create test admin
INSERT INTO "Users" ("Email", "Password", "Role", "CompanyId", "CreatedAt", "IsApproved")
VALUES ('admin@test.com', 'admin123', 'Admin', 'markaudio2019', NOW(), true);

-- Create test employee
INSERT INTO "Users" ("Email", "Password", "Role", "CompanyId", "CreatedAt", "IsApproved")
VALUES ('employee@test.com', 'emp123', 'Employee', 'markaudio2019', NOW(), true);

-- Create profile for employee
INSERT INTO "UserProfiles" ("Email", "EmployeeId", "FirstName", "LastName", "CompanyId", "CreatedAt", "UpdatedAt")
VALUES ('employee@test.com', 'EMP001', 'TEST', 'EMPLOYEE', 'markaudio2019', NOW(), NOW());

\q
```

### Step 6: Run Full Stack Locally

**Terminal 1 - Backend:**
```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\backend
$env:ASPNETCORE_ENVIRONMENT = "Development"
dotnet run

# Runs at: http://localhost:5001
```

**Terminal 2 - React (Optional - for browser testing):**
```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\react-app
npm start

# Runs at: http://localhost:3000
```

**Terminal 3 - Electron:**
```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\electron-app

# Make sure appConfig.json has:
# "apiBaseUrl": "http://localhost:5001"

npm start
```

**Test everything locally!**

---

## 🔄 OPTION 4: Separate Test Database on VPS

**Best for:** Testing migrations, testing with production-like environment

### Setup Test Database on VPS

```bash
ssh pivot@72.61.226.129

# Create test database
sudo -u postgres psql <<EOF
CREATE DATABASE attendancedb_test;
GRANT ALL PRIVILEGES ON DATABASE attendancedb_test TO attendanceuser;
\c attendancedb_test
GRANT ALL ON SCHEMA public TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO attendanceuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO attendanceuser;
EOF

echo "✓ Test database created"

# Copy production data to test database
sudo -u postgres pg_dump attendancedb | sudo -u postgres psql attendancedb_test

echo "✓ Production data copied to test database"
```

### Create Test Backend Service

```bash
# Copy backend to test directory
mkdir -p ~/app/backend-test
cp -r ~/app/backend/* ~/app/backend-test/

# Create test config
cat > ~/app/backend-test/appsettings.Production.json << 'EOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=attendancedb_test;Username=attendanceuser;Password=YOUR_PASSWORD_HERE;Timezone=Asia/Kolkata"
  }
}
EOF

# Make executable
chmod +x ~/app/backend-test/backend
```

### Create Test Service

```bash
sudo nano /etc/systemd/system/deskattendance-test.service
```

```ini
[Unit]
Description=DeskAttendance TEST Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=pivot
Group=pivot
WorkingDirectory=/home/pivot/app/backend-test
ExecStart=/home/pivot/app/backend-test/backend
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=deskattendance-test
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=ASPNETCORE_URLS=http://0.0.0.0:5002

[Install]
WantedBy=multi-user.target
```

```bash
# Start test service
sudo systemctl daemon-reload
sudo systemctl start deskattendance-test
sudo systemctl status deskattendance-test

# Allow port 5002
sudo ufw allow 5002/tcp

# Test
curl http://localhost:5002/health
```

### Test from Windows

```json
// electron-app/appConfig-test.json (create new file)
{
  "companyId": "markaudio2019",
  "companyName": "Mark Audio TEST",
  "apiBaseUrl": "http://72.61.226.129:5002",
  "useRemoteBackend": true
}
```

```powershell
cd P:\SourceCode-PIVOT\DeskAttendanceApp\electron-app

# Use test config
Copy-Item appConfig-test.json appConfig.json -Force

# Test
npm start

# When done, restore production config
Copy-Item appConfig-MarkAudio.json appConfig.json -Force
```

---

## ✅ TESTING CHECKLIST

### Before Testing
```
□ Backup production database (if using production)
□ Identify which option to use
□ Set up test environment
□ Inform users (if testing on production)
```

### During Testing
```
□ Test all 10 new features:
  □ IST timezone correct
  □ DD-MM-YYYY format everywhere
  □ Right-click popup works
  □ 10-second polling active
  □ Employee Settings accessible
  □ Actions column removed (admin)
  □ Date columns renamed correctly
  □ Name auto-uppercase
  □ Mobile exactly 10 digits
  □ Profile shows after creation

□ Test existing features still work:
  □ Login (admin + employee)
  □ Punch In/Out
  □ Task assignment
  □ Work log submission
  □ Admin approval/rejection
  □ Profile creation/editing
  □ Face recognition (if used)

□ Check for errors:
  □ Browser console (F12)
  □ Backend logs
  □ Database errors
  □ Network errors

□ Performance check:
  □ Page load time < 3 seconds
  □ API response time < 1 second
  □ No memory leaks
  □ Smooth UI interactions
```

### After Testing
```
□ Document any issues found
□ Fix critical bugs
□ Retest fixes
□ Clean up test environment
□ Restore production config
□ Update deployment plan if needed
```

---

## 🎯 RECOMMENDED TESTING WORKFLOW

### For Your Current Situation (10 Fixes):

**Step 1: Quick Test (5 minutes)**
```powershell
# Option 1 - Test against production server
cd P:\SourceCode-PIVOT\DeskAttendanceApp\react-app
npm start

# Browser opens at localhost:3000
# Login and verify 10 features work
# Check console for errors (F12)
```

**Step 2: Full Electron Test (10 minutes)**
```powershell
cd ..\electron-app
npm start

# Test complete user journey:
# 1. Login as employee
# 2. Check date format (DD-MM-YYYY)
# 3. Select text → Right-click → Copy/Print
# 4. Open Employee Settings → Change password
# 5. Create new profile → Verify uppercase names
# 6. Enter mobile → Verify 10-digit validation
# 7. Submit profile → Verify shows immediately
# 8. Check WorkLog → Verify 10-second polling
# 9. Login as admin → Verify actions removed
# 10. Check WorkLogHistory → Verify new columns
```

**Step 3: Build Installer Test (15 minutes)**
```powershell
cd ..
.\BUILD_INSTALLERS.ps1 -CompanyName "MarkAudio"

# Install on a test machine or your own PC
# Run full test again
```

**Step 4: Decision Point**
```
If all tests pass → Deploy to production
If issues found → Fix and repeat testing
If unsure → Setup Option 3 (fully local) for safer testing
```

---

## 🚨 COMMON TESTING ISSUES

### Issue 1: "Cannot connect to server"

**When testing locally but pointing to production:**

```powershell
# Check VPS is running
curl http://72.61.226.129:5001/health

# If down, SSH and restart:
ssh pivot@72.61.226.129
sudo systemctl restart deskattendance
```

**When running backend locally:**

```powershell
# Make sure backend is running
cd backend
dotnet run

# Check it's listening
# Should see: "Now listening on: http://localhost:5001"
```

### Issue 2: CORS Error in Browser

```
Access to fetch at 'http://72.61.226.129:5001' from origin 'http://localhost:3000' 
has been blocked by CORS policy
```

**Solution:** Your backend already allows all origins, but if you see this:

```csharp
// backend/Program.cs - already configured correctly:
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp",
        policy => policy.AllowAnyOrigin()  // ✓ Already allows localhost:3000
                        .AllowAnyHeader()
                        .AllowAnyMethod());
});
```

### Issue 3: Wrong CompanyId Data

**Problem:** Seeing other company's data

**Solution:**

```javascript
// Check browser console (F12):
console.log('CompanyId:', getCompanyId());

// Should show: markaudio2019

// If wrong, check:
// electron-app/appConfig.json
// "companyId": "markaudio2019"
```

### Issue 4: Database Connection Failed (Local)

```
Npgsql.NpgsqlException: Connection refused
```

**Solution:**

```powershell
# Check PostgreSQL is running
Get-Service postgresql*

# If not running:
Start-Service postgresql-x64-16

# Test connection:
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U attendanceuser -d attendancedb_local
```

---

## 📊 TESTING SCENARIOS COMPARISON

| Scenario | Setup Time | Safety | Real Data | Best For |
|----------|-----------|--------|-----------|----------|
| **Option 1: Production Server** | 5 min | ⚠️ Medium | ✅ Yes | UI changes, quick tests |
| **Option 2: Local + Remote DB** | 15 min | ⚠️ Medium | ✅ Yes | Backend testing |
| **Option 3: Fully Local** | 30 min | ✅ High | ❌ No | Major changes, migrations |
| **Option 4: Test DB on VPS** | 20 min | ✅ High | ✅ Yes (copy) | Production-like testing |

---

## 🎓 BEST PRACTICES

### 1. Test in Stages

```
Stage 1: Development Testing (Your PC)
  ↓
Stage 2: Test Build (Install on your PC)
  ↓
Stage 3: User Acceptance Testing (One test user)
  ↓
Stage 4: Production Deployment (All users)
```

### 2. Keep Production Config Safe

```powershell
# Always backup before changing
Copy-Item electron-app\appConfig.json electron-app\appConfig.json.backup

# After testing, restore
Copy-Item electron-app\appConfig.json.backup electron-app\appConfig.json
```

### 3. Use Test Accounts

```sql
-- Create dedicated test accounts in database
INSERT INTO "Users" ("Email", "Password", "Role", "CompanyId", "IsApproved")
VALUES ('test-employee@markaudio.com', 'test123', 'Employee', 'markaudio2019', true);

INSERT INTO "Users" ("Email", "Password", "Role", "CompanyId", "IsApproved")
VALUES ('test-admin@markaudio.com', 'test123', 'Admin', 'markaudio2019', true);
```

### 4. Monitor Production While Testing

```bash
# On VPS - watch logs in real-time
ssh pivot@72.61.226.129
sudo journalctl -u deskattendance -f

# Watch for errors while you test
```

### 5. Document Test Results

```markdown
# Test Report - November 26, 2024

## Environment
- Tested on: Windows 11
- Backend: http://72.61.226.129:5001
- Test User: test-employee@markaudio.com

## Test Results
✅ Feature 1: IST Timezone - Working
✅ Feature 2: DD-MM-YYYY Format - Working
❌ Feature 3: Right-click popup - Console error (fixed)
...

## Issues Found
1. Issue description
2. Steps to reproduce
3. Screenshot/logs

## Next Steps
- Fix issue #3
- Retest
- Deploy to production
```

---

## 🚀 QUICK START FOR TODAY

**Recommended: Start with Option 1 (Simplest)**

```powershell
# 1. Start React dev server
cd P:\SourceCode-PIVOT\DeskAttendanceApp\react-app
npm start

# Browser opens, test features for 5 minutes

# 2. Build and test Electron
cd ..\electron-app
Copy-Item -Recurse ..\react-app\build .\ -Force
npm start

# Test full app for 10 minutes

# 3. If all looks good, build installer
cd ..
.\BUILD_INSTALLERS.ps1 -CompanyName "MarkAudio"

# 4. Test installer on your PC

# 5. If perfect, deploy to production!
```

**Total Time: ~30 minutes of testing before production deployment**

---

**Ready to test? Choose your option and start! 🧪**
