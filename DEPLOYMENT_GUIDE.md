# ============================================
# MULTI-COMPANY DEPLOYMENT GUIDE
# ============================================

## Overview
This app supports **multi-tenant deployment** where a single backend serves multiple companies, each with isolated data. Each company gets a unique installer with their `companyId` hardcoded.

---

## 📦 Building Company-Specific Installers

### Method 1: Automated Script (Recommended)

#### Build ALL companies:
```powershell
.\BUILD_INSTALLERS.ps1
```

#### Build SINGLE company:
```powershell
.\BUILD_INSTALLERS.ps1 -CompanyName "MarkAudio"
.\BUILD_INSTALLERS.ps1 -CompanyName "CompanyA"
.\BUILD_INSTALLERS.ps1 -CompanyName "CompanyB"
```

### Method 2: Manual Build (Step-by-Step)

#### Step 1: Build React App (ONCE)
```powershell
cd react-app
npm run build
```

#### Step 2: Copy React Build to Electron
```powershell
cd ..\electron-app
if (Test-Path build) { Remove-Item -Recurse -Force build }
Copy-Item -Recurse ..\react-app\build .\
```

#### Step 3: Build Company A Installer
```powershell
# Replace appConfig.json with Company A config
Copy-Item appConfig-CompanyA.json appConfig.json

# Build installer
npm run dist

# Rename output
Rename-Item dist\DeskAttendance-Setup-1.1.0.exe DeskAttendance-CompanyA-Setup.exe
```

#### Step 4: Build Company B Installer
```powershell
# Replace appConfig.json with Company B config
Copy-Item appConfig-CompanyB.json appConfig.json

# Build installer
npm run dist

# Rename output
Rename-Item dist\DeskAttendance-Setup-1.1.0.exe DeskAttendance-CompanyB-Setup.exe
```

#### Step 5: Build Mark Audio Installer
```powershell
# Replace appConfig.json with Mark Audio config
Copy-Item appConfig-MarkAudio.json appConfig.json

# Build installer
npm run dist

# Rename output
Rename-Item dist\DeskAttendance-Setup-1.1.0.exe DeskAttendance-MarkAudio-Setup.exe
```

---

## 🏢 Adding a New Company

### Step 1: Create Config File
Create `electron-app/appConfig-NewCompany.json`:
```json
{
  "companyId": "newcompany_003",
  "companyName": "New Company Inc",
  "apiBaseUrl": "http://YOUR_ORACLE_CLOUD_IP:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/deskattendance/releases/latest"
  }
}
```

**Important:**
- `companyId` must be **UNIQUE** across all companies
- Use lowercase, no spaces (e.g., `newcompany_003`, `acme_corp_2024`)
- `apiBaseUrl` should point to your centralized backend server

### Step 2: Add to Build Script
Edit `BUILD_INSTALLERS.ps1`, add to `$companies` array:
```powershell
$companies = @(
    @{Name="MarkAudio"; ConfigFile="appConfig-MarkAudio.json"; OutputName="DeskAttendance-MarkAudio"},
    @{Name="CompanyA"; ConfigFile="appConfig-CompanyA.json"; OutputName="DeskAttendance-CompanyA"},
    @{Name="CompanyB"; ConfigFile="appConfig-CompanyB.json"; OutputName="DeskAttendance-CompanyB"},
    @{Name="NewCompany"; ConfigFile="appConfig-NewCompany.json"; OutputName="DeskAttendance-NewCompany"}
)
```

### Step 3: Build Installer
```powershell
.\BUILD_INSTALLERS.ps1 -CompanyName "NewCompany"
```

---

## 🗄️ Backend Setup (One-Time)

### Prerequisites
- PostgreSQL installed on Oracle Cloud (or any server)
- Backend deployed and running

### Apply Database Migration
```bash
cd backend
dotnet ef database update
```
This adds the `CompanyId` column to all tables.

### Verify Backend Filtering
All API endpoints automatically filter by `X-Company-Id` header:
- Company A users → Only see Company A data
- Company B users → Only see Company B data
- **No code changes needed!**

---

## 🚀 Deployment Workflow

### Initial Setup (Once)
1. **Deploy Backend** to Oracle Cloud
   - Update `appsettings.Production.json` with PostgreSQL connection
   - Run `dotnet publish -c Release`
   - Deploy to server

2. **Build All Installers**
   ```powershell
   .\BUILD_INSTALLERS.ps1
   ```

3. **Distribute to Companies**
   - Company A → `DeskAttendance-CompanyA-Setup.exe`
   - Company B → `DeskAttendance-CompanyB-Setup.exe`
   - Mark Audio → `DeskAttendance-MarkAudio-Setup.exe`

### Adding New Company
1. Create `appConfig-NewCompany.json`
2. Build installer: `.\BUILD_INSTALLERS.ps1 -CompanyName "NewCompany"`
3. Send installer to customer
4. **Done!** No backend changes required.

---

## 🔄 Auto-Update Setup

### One-Time GitHub Setup
1. Create GitHub repository (can be private)
2. Generate Personal Access Token:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Permissions: `repo` (Full control)
   - Copy token

3. Set environment variable:
   ```powershell
   $env:GH_TOKEN = "your_github_token_here"
   ```

4. Update `electron-app/package.json`:
   ```json
   "repository": {
     "type": "git",
     "url": "https://github.com/YOUR_USERNAME/deskattendance.git"
   },
   "publish": {
     "provider": "github",
     "owner": "YOUR_USERNAME",
     "repo": "deskattendance"
   }
   ```

### Publishing Updates
```powershell
cd electron-app

# Increment version in package.json (e.g., 1.1.0 → 1.2.0)
# Edit package.json: "version": "1.2.0"

# Build and publish
npm run publish
```

This uploads the installer to GitHub Releases. All installed apps will auto-update on next launch!

---

## 📊 How Multi-Tenancy Works

### Request Flow:
```
┌─────────────────────┐
│ Company A Installer │
│ companyId: "co_a"   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────┐
│ Electron App            │
│ Loads appConfig.json    │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ React App               │
│ Adds X-Company-Id: co_a │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Backend API             │
│ Filters by CompanyId    │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ PostgreSQL Database     │
│ WHERE CompanyId = 'co_a'│
└─────────────────────────┘
```

### Data Isolation:
- **Database Level:** All queries filter by `CompanyId`
- **Request Level:** Every API call includes `X-Company-Id` header
- **Client Level:** Each installer has unique `companyId` hardcoded
- **Result:** Company A **CANNOT** see Company B data ✅

---

## 🧪 Testing

### Test Multi-Tenancy
1. Install Company A on Machine 1
2. Install Company B on Machine 2
3. Register users on both
4. Add attendance/tasks on both
5. Verify:
   - Company A sees only their data
   - Company B sees only their data
   - No data leakage

### Test Auto-Update
1. Publish v1.1.0
2. Install on test machine
3. Publish v1.2.0
4. Restart app on test machine
5. Verify auto-update prompt appears

---

## 📁 File Structure

```
DeskAttendanceApp/
├── BUILD_INSTALLERS.ps1           ← Build all installers
├── DEPLOYMENT_GUIDE.md             ← This file
├── react-app/
│   └── build/                      ← Built once, shared by all
├── electron-app/
│   ├── appConfig.json              ← Current/default config
│   ├── appConfig-MarkAudio.json    ← Mark Audio config
│   ├── appConfig-CompanyA.json     ← Company A config
│   ├── appConfig-CompanyB.json     ← Company B config
│   ├── build/                      ← Copied from react-app
│   └── dist/                       ← Output installers
│       ├── DeskAttendance-MarkAudio-Setup.exe
│       ├── DeskAttendance-CompanyA-Setup.exe
│       └── DeskAttendance-CompanyB-Setup.exe
└── backend/
    └── (deployed to Oracle Cloud)
```

---

## ⚠️ Important Notes

1. **Never share installers between companies!**
   - Each installer is company-specific
   - Wrong installer = wrong data isolation

2. **CompanyId must be unique**
   - Use meaningful names: `markaudio_2024`, `acme_corp`
   - Keep a registry of all company IDs

3. **Backend must be accessible**
   - Update `apiBaseUrl` to your Oracle Cloud IP
   - Ensure firewall allows port 5001

4. **Auto-update applies to all companies**
   - All installers share the same update source
   - Bug fixes/features deployed to everyone simultaneously

5. **Database backups are critical**
   - All company data in one database
   - Regular backups prevent total data loss

---

## 🆘 Troubleshooting

### "Cannot see data after installation"
- Check `appConfig.json` inside installed app: `C:\Users\<user>\AppData\Local\Programs\deskattendance\resources\app.asar`
- Verify `companyId` matches database records

### "Connection refused"
- Check `apiBaseUrl` in config file
- Verify backend is running
- Check firewall rules

### "Seeing other company's data"
- **CRITICAL:** Check backend is filtering by `CompanyId`
- Verify migration was applied
- Check `X-Company-Id` header in browser DevTools

---

## 📞 Support Checklist

When selling to new company:
- [ ] Create unique `appConfig-<CompanyName>.json`
- [ ] Build installer: `.\BUILD_INSTALLERS.ps1 -CompanyName "<CompanyName>"`
- [ ] Test installer on clean machine
- [ ] Provide admin credentials
- [ ] Verify data isolation
- [ ] Document company's `companyId` in registry
- [ ] Send installer via secure channel

---

**You're now ready to deploy to unlimited companies without code changes!** 🎉
