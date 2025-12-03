# Auto-Update System - Quick Reference

## 🚀 HOW AUTO-UPDATE WORKS

```
User launches app
    ↓
App checks GitHub Releases for new version
    ↓
New version found?
    ├─ YES → Show "Update Available" dialog
    │         ↓
    │    User clicks "Download"
    │         ↓
    │    Download .exe in background (progress bar)
    │         ↓
    │    Show "Restart to Install" dialog
    │         ↓
    │    User clicks "Restart"
    │         ↓
    │    App closes → Installer runs → App relaunches
    │         ↓
    │    ✅ Updated to new version!
    │
    └─ NO → Continue with current version
```

---

## 📦 PUBLISHING UPDATES (3 STEPS)

### Step 1: Update Version Number

**File: `electron-app/package.json`**
```json
{
  "version": "1.2.0"  // Change from 1.1.0 to 1.2.0
}
```

### Step 2: Build & Publish

```powershell
cd electron-app
npm run publish
```

This command:
- Builds the .exe file
- Creates GitHub Release (v1.2.0)
- Uploads files to GitHub
- Users will auto-download next time they launch app

### Step 3: Done!

All 10 systems will auto-update next time users open the app.

---

## 🎯 UPDATE STRATEGIES

### Strategy 1: GitHub Releases (FREE, RECOMMENDED)

**Pros:**
- ✅ FREE (unlimited bandwidth)
- ✅ Automatic hosting
- ✅ Version management
- ✅ No server maintenance

**Cons:**
- ⚠️ Requires GitHub account
- ⚠️ Token management

**Setup:** 5 minutes (see main guide)

---

### Strategy 2: Oracle Cloud Custom Server

**Pros:**
- ✅ Full control
- ✅ No GitHub dependency
- ✅ Can customize update logic

**Cons:**
- ⚠️ Must setup web server
- ⚠️ Limited bandwidth (Oracle Free Tier: 10TB/month)
- ⚠️ Manual file management

**Setup:** 30 minutes (need nginx + update folder)

---

## 🔄 MULTI-TENANT ARCHITECTURE

### How Data is Isolated:

```
Database: attendance_db
├── Users Table
│   ├── User 1 (CompanyId: "company_a")
│   ├── User 2 (CompanyId: "company_a")
│   ├── User 3 (CompanyId: "company_b")  ← Different company
│   └── User 4 (CompanyId: "company_b")
│
├── AttendanceRecords Table
│   ├── Record 1 (CompanyId: "company_a", EmployeeId: "user1@companya.com")
│   ├── Record 2 (CompanyId: "company_a", EmployeeId: "user2@companya.com")
│   ├── Record 3 (CompanyId: "company_b", EmployeeId: "user3@companyb.com")  ← Isolated
│   └── Record 4 (CompanyId: "company_b", EmployeeId: "user4@companyb.com")
```

### API Request Flow:

```
Desktop App (Company A)
    ↓ Sends header: X-Company-Id: company_a
    ↓
ASP.NET Backend
    ↓ Reads header
    ↓ Filters query: WHERE CompanyId = 'company_a'
    ↓
PostgreSQL Database
    ↓ Returns only Company A data
    ↓
Desktop App (Company A)
    ✅ Sees only their data (never sees Company B)
```

---

## 🛠️ BUILDING COMPANY-SPECIFIC INSTALLERS

### For Company A:

```powershell
cd electron-app

# 1. Copy Company A config
Copy-Item appConfig-CompanyA.json appConfig.json

# 2. Build
npm run dist

# 3. Rename
Rename-Item "dist/Company Attendance-Setup-1.1.0.exe" "DeskAttendance-CompanyA-1.1.0.exe"
```

### For Company B:

```powershell
# 1. Copy Company B config
Copy-Item appConfig-CompanyB.json appConfig.json

# 2. Build
npm run dist

# 3. Rename
Rename-Item "dist/Company Attendance-Setup-1.1.0.exe" "DeskAttendance-CompanyB-1.1.0.exe"
```

**Result:**
- `DeskAttendance-CompanyA-1.1.0.exe` → Hardcoded for Company A
- `DeskAttendance-CompanyB-1.1.0.exe` → Hardcoded for Company B

Install different .exe on each company's computers!

---

## 📊 COMPARISON: GitHub vs Custom Server

| Feature | GitHub Releases | Custom Server (Oracle) |
|---------|----------------|------------------------|
| **Cost** | FREE | FREE (Oracle Free Tier) |
| **Setup Time** | 5 minutes | 30 minutes |
| **Bandwidth** | Unlimited | 10TB/month (enough) |
| **Reliability** | 99.9% uptime | Depends on your setup |
| **Management** | Automatic | Manual file uploads |
| **Security** | Private repos supported | DIY security |
| **Speed** | GitHub CDN (fast) | Oracle datacenter speed |
| **Recommended** | ✅ YES | Only if GitHub blocked |

---

## 🎓 WHEN TO USE EACH OPTION

### Use GitHub Releases if:
- ✅ You're comfortable with GitHub
- ✅ Want zero maintenance
- ✅ Need automatic version management
- ✅ Want fastest setup

### Use Custom Server if:
- ✅ GitHub is blocked in your network
- ✅ Need 100% control over updates
- ✅ Want custom update logic
- ✅ Already have web server running

---

## 💡 MY RECOMMENDATION

### For Your Use Case (2 companies, 10 systems total):

**Use GitHub Releases**

**Why:**
1. FREE forever
2. 5-minute setup
3. Zero maintenance
4. Automatic version management
5. Reliable (GitHub infrastructure)
6. Easy to publish updates

**Steps:**
1. Create private GitHub repo (5 min)
2. Generate token (2 min)
3. Configure package.json (2 min)
4. Run `npm run publish` (done!)

**Total effort:** 10 minutes setup, then `npm run publish` for each update.

---

## 🚦 DEPLOYMENT SEQUENCE

### Phase 1: Setup (ONE TIME)

1. ✅ Add CompanyId to database (DONE - models updated)
2. ⏳ Create database migration
3. ⏳ Update backend controllers
4. ⏳ Deploy backend to Oracle Cloud
5. ⏳ Setup GitHub repository
6. ⏳ Build company-specific installers

### Phase 2: Deploy to 10 Systems

1. ⏳ Install on 1 test machine (Company A)
2. ⏳ Verify login + attendance works
3. ⏳ Install on remaining 4 Company A machines
4. ⏳ Install on 5 Company B machines
5. ⏳ Train users

### Phase 3: First Update (TEST AUTO-UPDATE)

1. ⏳ Make small change (e.g., fix typo)
2. ⏳ Update version to 1.2.0
3. ⏳ Run `npm run publish`
4. ⏳ Ask one user to launch app
5. ⏳ Verify auto-update works
6. ✅ All users will auto-update gradually

---

## 📞 WHAT TO DO NEXT

**Tell me which path you want:**

### Path A: GitHub Releases (RECOMMENDED)
```
I'll help you:
1. Create GitHub repo
2. Generate token
3. Configure package.json
4. Test auto-update locally
5. Publish first release

Time: 30 minutes
```

### Path B: Custom Server on Oracle Cloud
```
I'll help you:
1. Setup nginx on Oracle Cloud
2. Create update directory
3. Configure electron-builder
4. Upload .exe files manually
5. Test auto-update

Time: 2 hours
```

### Path C: Deploy Backend to Oracle Cloud First
```
I'll help you:
1. Create Oracle Cloud instance (if not done)
2. Install PostgreSQL
3. Deploy ASP.NET backend
4. Run database migration
5. Update controllers for CompanyId
6. Test API

Time: 2-3 hours
```

**Which path do you want to take first?** 🚀
