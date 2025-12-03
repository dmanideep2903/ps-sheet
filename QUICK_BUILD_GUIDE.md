# Quick Start: Building Company Installers

## 🚀 EASIEST METHOD - One Command

```powershell
.\BUILD_INSTALLERS.ps1
```

This will:
1. Build React app (once)
2. Copy to Electron
3. Build 3 installers:
   - `DeskAttendance-MarkAudio-Setup.exe`
   - `DeskAttendance-CompanyA-Setup.exe`
   - `DeskAttendance-CompanyB-Setup.exe`

All installers in: `electron-app\dist\`

---

## 📝 Manual Method (If Script Fails)

### Step 1: Build React (ONCE)
```powershell
cd react-app
npm run build
```

### Step 2: Copy to Electron
```powershell
cd ..\electron-app
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Copy-Item -Recurse ..\react-app\build .\
```

### Step 3: Build Each Company

#### For Mark Audio:
```powershell
Copy-Item appConfig-MarkAudio.json appConfig.json
npm run dist
Rename-Item "dist\DeskAttendance Setup 1.1.0.exe" "DeskAttendance-MarkAudio-Setup.exe"
```

#### For Company A:
```powershell
Copy-Item appConfig-CompanyA.json appConfig.json
npm run dist
Rename-Item "dist\DeskAttendance Setup 1.1.0.exe" "DeskAttendance-CompanyA-Setup.exe"
```

#### For Company B:
```powershell
Copy-Item appConfig-CompanyB.json appConfig.json
npm run dist
Rename-Item "dist\DeskAttendance Setup 1.1.0.exe" "DeskAttendance-CompanyB-Setup.exe"
```

---

## ➕ Adding New Company

### 1. Create config file: `appConfig-NewCorp.json`
```json
{
  "companyId": "newcorp_2025",
  "companyName": "New Corporation",
  "apiBaseUrl": "http://YOUR_CLOUD_IP:5001",
  "autoUpdate": {
    "enabled": true,
    "checkOnStartup": true,
    "updateServerUrl": "https://github.com/yourusername/deskattendance/releases/latest"
  }
}
```

### 2. Update BUILD_INSTALLERS.ps1
Add to `$companies` array (around line 50):
```powershell
@{Name="NewCorp"; ConfigFile="appConfig-NewCorp.json"; OutputName="DeskAttendance-NewCorp"}
```

### 3. Build
```powershell
.\BUILD_INSTALLERS.ps1 -CompanyName "NewCorp"
```

---

## ✅ Verify Installers

Each installer should:
- Be ~200-300 MB in size
- Install to: `C:\Users\<user>\AppData\Local\Programs\deskattendance\`
- Show correct company name in app
- Send correct `X-Company-Id` header (check DevTools Network tab)
- Only show data for that company

---

## 🔥 Quick Troubleshooting

### "npm run dist" fails
- Make sure you're in `electron-app` folder
- Check `package.json` has correct version
- Delete `dist` and `node_modules\.cache` folders, try again

### "Can't find .exe file"
- Check `electron-app\dist\` folder
- Look for file matching pattern: `DeskAttendance Setup *.exe` or `*.exe`
- Build may have failed silently - check terminal output

### "Wrong company data showing"
- Extract installer → Check appConfig.json inside
- Should be in: `resources\app.asar` (use asar npm package to extract)
- Verify companyId matches expected value

---

## 📦 What Gets Built

```
electron-app/dist/
├── DeskAttendance-MarkAudio-Setup.exe    (companyId: "markaudio2019")
├── DeskAttendance-CompanyA-Setup.exe     (companyId: "company_a_001")
└── DeskAttendance-CompanyB-Setup.exe     (companyId: "company_b_002")
```

Each installer:
- **Different**: Company ID, Company Name, API URL
- **Same**: App code, features, auto-update logic

---

## 🎯 Distribution Checklist

Before sending installer to customer:
- [ ] Test installer on clean Windows machine
- [ ] Verify correct company name appears
- [ ] Check data isolation (only their data visible)
- [ ] Confirm API connection works
- [ ] Document company's `companyId` in your records
- [ ] Provide admin credentials separately (secure channel)

---

**Build Time:** ~5-10 minutes for all 3 installers
**Disk Space:** ~1 GB for all output files
