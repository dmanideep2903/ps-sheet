# Multi-Tenant + Auto-Update Setup Guide
## DeskAttendance App - Complete Implementation

**Date:** November 17, 2025  
**Features:** Multi-tenant support + Automatic updates

---

## 🎯 WHAT WAS IMPLEMENTED

### ✅ Part 1: Multi-Tenant Database Support
- Added `CompanyId` field to all database models
- Each company's data is isolated by CompanyId
- Single server, multiple companies supported

### ✅ Part 2: Auto-Update System
- Installed `electron-updater` package
- Configured automatic update checks
- GitHub Releases integration
- Silent background updates

---

## 📋 SETUP INSTRUCTIONS

### STEP 1: Create Database Migration

Run this command to update your database schema:

```powershell
cd backend
dotnet ef migrations add AddMultiTenantSupport
dotnet ef database update
```

This adds `CompanyId` column to all tables.

---

### STEP 2: Update Backend Controllers

You need to modify your controllers to filter by CompanyId. Here's an example:

**File: `backend/Controllers/AuthController.cs`**

Add this middleware to extract CompanyId from headers:

```csharp
// At the top of each API method:
var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
```

**Example for Login:**

```csharp
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] User loginRequest)
{
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    
    var user = await _context.Users
        .FirstOrDefaultAsync(u => 
            u.Email == loginRequest.Email && 
            u.CompanyId == companyId); // Filter by company
    
    if (user == null || user.Password != loginRequest.Password)
    {
        return Unauthorized(new { message = "Invalid credentials" });
    }
    
    return Ok(user);
}
```

**Same pattern for all controllers:**
- AttendanceController
- EmployeesController
- WorkLogController
- TaskController
- ProfileController

---

### STEP 3: Update React App to Send CompanyId

**File: `react-app/src/config/networkConfig.js`** (create if doesn't exist)

```javascript
// Read company ID from Electron
let COMPANY_ID = 'default';
let API_BASE_URL = 'http://localhost:5000';

// Get config from Electron when app loads
if (window.electronAPI && window.electronAPI.getAppConfig) {
  window.electronAPI.getAppConfig().then(config => {
    COMPANY_ID = config.companyId;
    API_BASE_URL = config.apiBaseUrl;
    console.log('Loaded company config:', config);
  });
}

export { COMPANY_ID, API_BASE_URL };
```

**Update all API calls to include CompanyId header:**

```javascript
// Example: Login API call
import { COMPANY_ID, API_BASE_URL } from './config/networkConfig';

const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Company-Id': COMPANY_ID  // ← Add this header
  },
  body: JSON.stringify({ email, password })
});
```

---

### STEP 4: Update Preload.js

**File: `electron-app/preload.js`**

Add this to expose config to React:

```javascript
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // Existing methods...
  getNetworkInfo: () => ipcRenderer.invoke('get-network-info'),
  
  // NEW: Get app configuration
  getAppConfig: () => ipcRenderer.invoke('get-app-config'),
  
  // NEW: Manual update check
  checkForUpdates: () => ipcRenderer.invoke('check-for-updates')
});
```

---

### STEP 5: Build Company-Specific Installers

**Create separate config files for each company:**

**File: `electron-app/appConfig-CompanyA.json`**
```json
{
  "companyId": "company_a",
  "companyName": "Company A",
  "apiBaseUrl": "http://your-oracle-cloud-ip:5000",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/deskattendance"
  }
}
```

**File: `electron-app/appConfig-CompanyB.json`**
```json
{
  "companyId": "company_b",
  "companyName": "Company B",
  "apiBaseUrl": "http://your-oracle-cloud-ip:5000",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/deskattendance"
  }
}
```

**Build process for each company:**

```powershell
# Company A build
Copy-Item appConfig-CompanyA.json appConfig.json
npm run dist
Rename-Item "dist/Company Attendance-Setup-1.1.0.exe" "DeskAttendance-CompanyA-Setup-1.1.0.exe"

# Company B build
Copy-Item appConfig-CompanyB.json appConfig.json
npm run dist
Rename-Item "dist/Company Attendance-Setup-1.1.0.exe" "DeskAttendance-CompanyB-Setup-1.1.0.exe"
```

---

## 🚀 AUTO-UPDATE SETUP

### OPTION 1: GitHub Releases (RECOMMENDED - FREE)

**Step 1: Create GitHub Repository**

1. Go to https://github.com
2. Create new repository: `deskattendance`
3. Make it **Private** (recommended) or Public

**Step 2: Generate GitHub Personal Access Token**

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Name: "DeskAttendance Auto-Update"
4. Permissions: Select `repo` (all sub-permissions)
5. Generate token
6. **Copy the token** (you won't see it again!)

**Step 3: Set Environment Variable**

```powershell
# Windows PowerShell (set permanently)
[System.Environment]::SetEnvironmentVariable('GH_TOKEN', 'your-github-token-here', 'User')

# Verify it's set
$env:GH_TOKEN
```

**Step 4: Update package.json with your GitHub details**

```json
{
  "build": {
    "publish": [
      {
        "provider": "github",
        "owner": "your-github-username",
        "repo": "deskattendance",
        "private": true
      }
    ]
  }
}
```

**Step 5: Build and Publish**

```powershell
cd electron-app

# Build and publish to GitHub Releases
npm run publish
```

This will:
- Build the .exe file
- Create a GitHub Release with version from package.json
- Upload .exe and update files to GitHub
- Auto-update will download from this release

---

### OPTION 2: Custom Update Server (For More Control)

**If you want to host updates on your Oracle Cloud server:**

**File: `electron-app/package.json`**

```json
{
  "build": {
    "publish": [
      {
        "provider": "generic",
        "url": "http://your-oracle-cloud-ip:8080/updates"
      }
    ]
  }
}
```

**Setup simple update server on Oracle Cloud:**

```bash
# On Oracle Cloud server
mkdir -p /var/www/updates
cd /var/www/updates

# Upload your .exe files here
# Structure:
# /var/www/updates/
#   ├── Company-Attendance-Setup-1.1.0.exe
#   ├── latest.yml  (generated by electron-builder)

# Serve with Python
python3 -m http.server 8080
```

---

## 📦 PUBLISHING UPDATES

### When You Have Bug Fixes or New Features:

**Step 1: Update Version**

Edit `electron-app/package.json`:

```json
{
  "version": "1.2.0"  // Increment version
}
```

**Step 2: Build Updated Backend (if needed)**

```powershell
cd backend
dotnet publish -c Release -r win-x64 --self-contained true -o ../electron-app/backend
```

**Step 3: Build Updated React App (if needed)**

```powershell
cd react-app
npm run build
xcopy /e /i /y build ..\electron-app\build
```

**Step 4: Publish Update**

```powershell
cd electron-app
npm run publish
```

**Step 5: Users Auto-Update**

When users launch the app:
1. App checks GitHub Releases for new version
2. If found, shows "Update Available" dialog
3. User clicks "Download & Install"
4. App downloads in background
5. After download, prompts to restart
6. App restarts with new version!

---

## 🔐 SECURITY BEST PRACTICES

### 1. Code Signing (Optional but Recommended)

Without code signing, Windows SmartScreen will warn users:

```
Windows protected your PC
Unknown publisher
```

**To fix:**
- Buy code signing certificate (~$100-300/year)
- Or use free EV certificate from cloud providers
- Add to electron-builder config

### 2. Private GitHub Releases

Keep repository private so competitors can't download your app.

### 3. Encrypted Config

For production, encrypt sensitive data in `appConfig.json`:

```javascript
// In main.js
const crypto = require('crypto');

function decryptConfig(encryptedConfig) {
  const decipher = crypto.createDecipher('aes-256-cbc', 'your-secret-key');
  let decrypted = decipher.update(encryptedConfig, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return JSON.parse(decrypted);
}
```

---

## 🧪 TESTING AUTO-UPDATE

### Test on Development Machine:

**Step 1: Build version 1.1.0**

```powershell
# package.json: "version": "1.1.0"
npm run dist
```

**Step 2: Install the app**

Run `dist/Company-Attendance-Setup-1.1.0.exe`

**Step 3: Publish version 1.2.0 to GitHub**

```powershell
# package.json: "version": "1.2.0"
npm run publish
```

**Step 4: Launch installed app (v1.1.0)**

- App will detect v1.2.0 on GitHub
- Shows update dialog
- Downloads and installs
- Restarts with v1.2.0

---

## 🎯 DEPLOYMENT CHECKLIST

Before deploying to 10 systems:

### Backend (Oracle Cloud):
- [ ] Deploy backend to Oracle Cloud
- [ ] Install PostgreSQL on Oracle Cloud
- [ ] Run database migration (add CompanyId)
- [ ] Update all controllers to filter by CompanyId
- [ ] Test API with X-Company-Id header

### Desktop App:
- [ ] Update appConfig.json with Oracle Cloud IP
- [ ] Test login with CompanyId
- [ ] Build installers for each company
- [ ] Test auto-update (v1.1.0 → v1.2.0)
- [ ] Verify data isolation (Company A can't see Company B data)

### Distribution:
- [ ] Install on 1 test machine
- [ ] Verify connection to Oracle Cloud
- [ ] Test attendance punch in/out
- [ ] Install on remaining 9 machines
- [ ] Train users on auto-update process

---

## 📞 NEXT STEPS

**Ready to deploy? Tell me:**

1. Do you want GitHub Releases or custom server for updates?
2. Should I help update the controllers for CompanyId filtering?
3. Need help deploying backend to Oracle Cloud?

Once you decide, I'll guide you through the complete deployment! 🚀
