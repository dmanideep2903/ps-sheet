# Backend Connection Fix - Summary

## Issue Reported
After installing on a new system, the application was showing:
- "Server error, please try again"
- `ERR_CONNECTION_REFUSED` on all API calls (login, register, etc.)
- All requests to `http://localhost:5001` failing

## Root Cause
The backend server was not starting automatically when the Electron app launched on the installed system. The issue was in the `electron-app/main.js` file where the backend path was incorrectly configured for production mode.

## Fixes Applied

### 1. Fixed Backend Path in main.js
**Location**: `electron-app/main.js`

**Before:**
```javascript
const BACKEND_CMD = isDev
  ? 'dotnet'
  : path.join(process.resourcesPath, 'app','backend', 'backend.exe');
  
const BACKEND_CWD = isDev
  ? path.join(__dirname, '..', 'backend')
  : path.dirname(BACKEND_CMD);
```

**After:**
```javascript
const BACKEND_CMD = isDev
  ? 'dotnet'
  : path.join(__dirname, 'backend', 'backend.exe');
  
const BACKEND_CWD = isDev
  ? path.join(__dirname, '..', 'backend')
  : path.join(__dirname, 'backend');
```

**Why:** In production (when app is packaged), `__dirname` points to `resources/app`, so the backend is at `__dirname/backend/backend.exe`, not `process.resourcesPath/app/backend/backend.exe`.

### 2. Added Backend Health Check Endpoint
**Location**: `backend/Controllers/AuthController.cs`

**Added:**
```csharp
[HttpGet("health")]
public IActionResult Health()
{
    return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
}
```

**Why:** Allows Electron to verify backend is ready before showing the UI.

### 3. Added Backend Startup Wait Logic
**Location**: `electron-app/main.js`

**Added:**
```javascript
function waitForBackend(maxAttempts = 30) {
  return new Promise((resolve, reject) => {
    let attempts = 0;
    const checkBackend = () => {
      attempts++;
      console.log(`Checking backend... attempt ${attempts}/${maxAttempts}`);
      
      const req = http.get('http://localhost:5001/api/auth/health', (res) => {
        console.log('Backend is ready!');
        resolve();
      });
      
      req.on('error', (err) => {
        if (attempts >= maxAttempts) {
          reject(new Error('Backend startup timeout'));
        } else {
          setTimeout(checkBackend, 1000);
        }
      });
      
      req.end();
    };
    checkBackend();
  });
}
```

**Why:** Ensures the Electron window only opens after the backend is fully started and ready to accept requests.

### 4. Enhanced Error Logging
**Location**: `electron-app/main.js`

**Added:**
- Detailed console logs showing backend path resolution
- File existence checks
- Process error handlers
- Startup diagnostic information

**Why:** Makes it easier to diagnose backend startup issues by providing clear logs in the Developer Console.

### 5. Better Error Messaging
**Location**: `electron-app/main.js`

**Added:**
```javascript
dialog.showErrorBox(
  'Backend Startup Failed',
  'The backend server failed to start. Please check if:\n\n' +
  '1. .NET 9.0 Runtime is installed\n' +
  '2. SQL Server is running\n' +
  '3. Database connection is configured\n\n' +
  'Error: ' + err.message
);
```

**Why:** Provides actionable guidance to users when backend fails to start.

## Testing the Fix

### Development Mode Test
```bash
cd electron-app
npm start
```

Expected console output:
```
=== Backend Startup ===
isDev: true
Backend command: dotnet
Starting backend...
[BACKEND] Now listening on: http://localhost:5001
Checking backend... attempt 1/30
Backend is ready!
Creating window...
```

### Production Mode Test
```bash
cd electron-app
npm run dist
# Install the generated .exe
# Launch the app
# Press Ctrl+Shift+I to see console
```

Expected console output:
```
=== Backend Startup ===
isDev: false
Backend command: C:\Users\...\backend\backend.exe
Backend executable exists: true
[BACKEND] Now listening on: http://localhost:5001
Backend is ready!
Creating window...
```

## Additional Tools Created

### 1. Pre-Installation Verification Script
**File**: `verify-installation.ps1`
- Checks .NET Runtime
- Checks SQL Server LocalDB
- Checks port availability
- Verifies system requirements

### 2. Post-Installation Setup Script
**File**: `post-install-setup.ps1`
- Locates installation directory
- Tests database connection
- Runs database migrations
- Tests backend startup

### 3. Comprehensive Troubleshooting Guide
**File**: `INSTALLATION_TROUBLESHOOTING.md`
- Detailed error explanations
- Step-by-step solutions
- Configuration instructions
- Support information

### 4. Installation README
**File**: `README-INSTALLATION.md`
- Quick start guide
- System requirements
- Common issues and solutions
- Default credentials

## Files Modified in This Fix

1. `electron-app/main.js` - Fixed backend path and added wait logic
2. `backend/Controllers/AuthController.cs` - Added health endpoint
3. `verify-installation.ps1` - New file
4. `post-install-setup.ps1` - New file
5. `INSTALLATION_TROUBLESHOOTING.md` - New file
6. `electron-app/dist/README-INSTALLATION.md` - New file

## Deployment Instructions

### For Distribution:
The `electron-app/dist/` folder now contains:
- `Company Attendance-Setup-1.0.0.exe` (148 MB)
- `verify-installation.ps1`
- `post-install-setup.ps1`
- `INSTALLATION_TROUBLESHOOTING.md`
- `README-INSTALLATION.md`

Copy all these files to the target system.

### Installation Steps on New System:
1. Run `verify-installation.ps1` to check prerequisites
2. Install any missing prerequisites (.NET, SQL Server)
3. Run `Company Attendance-Setup-1.0.0.exe`
4. Run `post-install-setup.ps1` to configure database
5. Launch app from Start Menu
6. Wait 15-30 seconds for backend startup
7. Login with admin@admin.com / Admin@123

## Prevention for Future Builds

To ensure this issue doesn't recur:

1. **Always test the packaged installer** on a clean system
2. **Check Developer Console** logs during first launch
3. **Verify backend paths** match the actual packaged structure
4. **Include setup scripts** with every distribution
5. **Document prerequisites** clearly for end users

## Known Limitations

1. **First Launch Delay**: Backend takes 15-30 seconds to start on first launch
2. **No Auto-Update**: Users must manually download and install updates
3. **Manual Database Setup**: Database migrations need to be run via script or manually
4. **Single Port**: Backend is hardcoded to port 5001 (configurable but requires reinstall)

## Future Enhancements

1. Add splash screen during backend startup
2. Implement auto-update mechanism
3. Bundle SQL Server LocalDB with installer
4. Add installation wizard for database setup
5. Create system tray icon with backend status indicator
6. Add backend health check indicator in the UI
