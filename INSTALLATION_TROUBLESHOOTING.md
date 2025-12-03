# Company Attendance App - Installation & Troubleshooting Guide

## 📋 Prerequisites

Before installing, ensure the target system has:

1. **Operating System**: Windows 10/11 (64-bit)
2. **.NET 9.0 Runtime** (Download: https://dotnet.microsoft.com/download/dotnet/9.0)
3. **SQL Server** (LocalDB, Express, or Full)
   - LocalDB: https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/sql-server-express-localdb
   - Express: https://www.microsoft.com/en-us/sql-server/sql-server-downloads

## 🚀 Installation Steps

### Step 1: Install Prerequisites

**Install .NET 9.0 Runtime:**
1. Download from: https://dotnet.microsoft.com/download/dotnet/9.0/runtime
2. Choose: "ASP.NET Core Runtime 9.0.x - Windows x64 Installer"
3. Run the installer
4. Verify installation:
   ```powershell
   dotnet --version
   ```

**Install SQL Server LocalDB:**
1. Download from: https://aka.ms/ssmsfullsetup
2. Or use SQL Server Express installer
3. Verify installation:
   ```powershell
   sqllocaldb info
   ```

### Step 2: Install the Application

1. Run `Company Attendance-Setup-1.0.0.exe`
2. Follow the installation wizard
3. The app will be installed to: `C:\Users\[Username]\AppData\Local\Programs\company-attendance-app`

### Step 3: Configure Database

**Default Installation Location:**
```
C:\Users\[YourUsername]\AppData\Local\Programs\company-attendance-app
```

**Navigate to backend folder:**
```powershell
cd "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app.asar.unpacked\backend"
```

**Or if asar is disabled:**
```powershell
cd "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend"
```

**Edit `appsettings.json`:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=AttendanceDB;Trusted_Connection=true;TrustServerCertificate=true;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Step 4: Create Database

**Option A: Using Entity Framework (Recommended)**
```powershell
cd "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend"
dotnet ef database update
```

**Option B: Manual SQL Server Connection**
1. Open SQL Server Management Studio (SSMS)
2. Connect to: `(localdb)\mssqllocaldb`
3. Create database: `AttendanceDB`
4. Run migrations from the app backend folder

### Step 5: Launch Application

1. Find "Company Attendance" in Start Menu
2. Or double-click desktop shortcut
3. Wait for backend to start (15-30 seconds first time)

## 🔍 Troubleshooting

### Error: "Server error, please try again" / "ERR_CONNECTION_REFUSED"

**Symptoms:**
- Registration fails
- Login fails
- All API calls return connection errors

**Causes & Solutions:**

#### 1. Backend Not Starting

**Check if backend is running:**
```powershell
# Open PowerShell and check if port 5001 is listening
netstat -ano | findstr :5001
```

**View backend logs:**
- Open the app
- Press `Ctrl+Shift+I` to open Developer Tools
- Check Console tab for backend startup messages

**Look for these messages:**
```
[BACKEND] Now listening on: http://localhost:5001
[BACKEND] Application started
```

#### 2. .NET Runtime Not Installed

**Verify .NET installation:**
```powershell
dotnet --version
```

**Expected output:** `9.0.x` or higher

**If not found:**
- Download and install .NET 9.0 Runtime
- Restart the application

#### 3. Database Connection Failed

**Check SQL Server:**
```powershell
sqllocaldb info
sqllocaldb start mssqllocaldb
```

**Test connection string:**
```powershell
sqlcmd -S "(localdb)\mssqllocaldb" -Q "SELECT @@VERSION"
```

**Common fixes:**
- Start SQL Server service: `sqllocaldb start mssqllocaldb`
- Update connection string in `appsettings.json`
- Run database migrations

#### 4. Port 5001 Already in Use

**Check what's using port 5001:**
```powershell
netstat -ano | findstr :5001
```

**Kill the process:**
```powershell
# Note the PID from previous command
taskkill /F /PID [ProcessID]
```

**Or change the port:**
Edit `appsettings.json` and add:
```json
{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://localhost:5002"
      }
    }
  }
}
```

Then update React app API URL (requires rebuild).

### Error: Backend Crashes on Startup

**View detailed error:**
1. Open Command Prompt as Administrator
2. Navigate to backend folder:
   ```cmd
   cd "%LOCALAPPDATA%\Programs\company-attendance-app\resources\app\backend"
   ```
3. Run backend manually:
   ```cmd
   backend.exe
   ```
4. Read the error messages

**Common issues:**
- Missing DLL files → Reinstall .NET Runtime
- Database connection error → Check SQL Server
- Port binding error → Check firewall/port usage

### Database Migration Issues

**Error: "No migrations found"**

**Solution:** Copy migration files:
1. From source: `backend\Migrations\*.cs`
2. To: `[InstallDir]\resources\app\backend\Migrations\`

**Run migrations:**
```powershell
cd "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend"
dotnet ef database update
```

### Firewall Blocking Backend

**Add firewall exception:**
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Company Attendance Backend" -Direction Inbound -Program "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend\backend.exe" -Action Allow
```

### Application Won't Start

**Clear application data:**
```powershell
Remove-Item "$env:APPDATA\company-attendance-app" -Recurse -Force
```

**Reinstall:**
1. Uninstall from Control Panel
2. Delete installation folder
3. Reinstall from `.exe`

## 📝 Default Credentials

After database setup:

- **Admin Account:**
  - Email: `admin@admin.com`
  - Password: `Admin@123`

## 🔧 Manual Backend Start (Development Mode)

If you need to run backend separately for debugging:

```powershell
cd "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend"
.\backend.exe
```

Keep this window open and launch the Electron app separately.

## 📞 Support

If issues persist:

1. **Collect logs:**
   - Open app
   - Press `Ctrl+Shift+I`
   - Copy Console output
   
2. **Check backend logs:**
   - Run backend manually as shown above
   - Copy error messages

3. **System information:**
   ```powershell
   systeminfo | findstr /C:"OS Name" /C:"OS Version"
   dotnet --version
   sqllocaldb info
   ```

## 🔄 Updating the Application

1. Uninstall old version
2. Install new version
3. Database migrations run automatically on first launch
4. If not, run manually:
   ```powershell
   cd "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend"
   dotnet ef database update
   ```

## 📁 Important File Locations

**Installation Directory:**
```
C:\Users\[Username]\AppData\Local\Programs\company-attendance-app\
```

**Backend Files:**
```
resources\app\backend\
```

**Configuration:**
```
resources\app\backend\appsettings.json
```

**Database (LocalDB):**
```
C:\Users\[Username]\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\mssqllocaldb\
```

**Application Data:**
```
C:\Users\[Username]\AppData\Roaming\company-attendance-app\
```
