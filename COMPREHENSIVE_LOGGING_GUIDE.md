# Comprehensive Logging System Documentation

## Overview
This document explains the comprehensive logging system implemented to track complete data flow in the Attendance App, with special focus on timezone conversions.

## File Structure

### 1. **`react-app/src/utils/istTimeUtils.js`** - PRIMARY TIMEZONE CONVERSION FILE
**Purpose**: Single source of truth for ALL timezone conversions (UTC ↔ IST)

**Functions**:

#### `formatUTCtoIST(timestamp, source)`
- **What it does**: Converts UTC timestamp from database to IST for UI display
- **When called**: Every time you see a timestamp on screen (attendance table, task list, etc.)
- **Logging output**:
  ```
  ═══════════════════════════════════════════════════════════
  🔄 [formatUTCtoIST] TIMEZONE CONVERSION STARTED
  ═══════════════════════════════════════════════════════════
  📍 SOURCE: AdminDashboard-AttendanceTable
  📥 INPUT FROM DATABASE (UTC): 2025-12-01T08:10:00+00:00
  📆 JAVASCRIPT DATE OBJECT: 2025-12-01T08:10:00.000Z
  ⚙️ CONVERSION PROCESS:
     ├─ UTC Milliseconds: 1733044200000
     ├─ IST Offset: +5:30 hours (19800000ms)
     ├─ IST Milliseconds: 1733064000000
     └─ IST Date Object: 2025-12-01T13:40:00.000Z
  ✅ FORMATTED FOR UI DISPLAY: 01-12-2025 13:40:00
  🖥️ THIS WILL SHOW ON SCREEN
  ```

#### `convertISTtoUTC(istDateTime, source)`
- **What it does**: Converts user's IST input to UTC for database storage
- **When called**: When admin adds attendance or employee punches in
- **Logging output**:
  ```
  ═══════════════════════════════════════════════════════════
  🔄 [convertISTtoUTC] IST → UTC CONVERSION FOR DATABASE
  ═══════════════════════════════════════════════════════════
  📍 SOURCE: AdminDashboard-AddAttendance
  👤 USER INPUT (IST): 2025-12-01T13:40
  🔍 PARSED COMPONENTS:
     ├─ Year: 2025
     ├─ Month: 12
     ├─ Day: 1
     ├─ Hour: 13
     └─ Minute: 40
  ⏱️ IST Milliseconds: 1733064000000
  ⚙️ CONVERSION PROCESS:
     ├─ IST Offset: -5:30 hours (19800000ms)
     ├─ UTC Milliseconds: 1733044200000
     └─ Offset Subtracted
  💾 OUTPUT FOR DATABASE (UTC): 2025-12-01T08:10:00.000Z
  ✅ READY TO SAVE TO POSTGRESQL
  ```

#### `formatTimeOnly(utcTimestamp, source)`
- **What it does**: Converts UTC timestamp to IST time-only format (HH:MM:SS)
- **When called**: Employee dashboard current time, punch-in/out time display

#### `getDateTimeLocalValue(utcTimestamp, source)`
- **What it does**: Gets IST time for datetime-local input fields
- **When called**: Pre-filling date/time inputs in forms

---

### 2. **`react-app/src/utils/apiLogger.js`** - API CALL LOGGER
**Purpose**: Track ALL API calls (requests and responses)

**Functions**:

#### `logApiRequest(method, url, headers, body)`
```javascript
import { logApiRequest } from '../utils/apiLogger';

const requestId = logApiRequest('POST', '/api/attendance', headers, JSON.stringify(data));
```

**Output**:
```
═══════════════════════════════════════════════════════════
🌐 [REQ-1] API REQUEST SENT
═══════════════════════════════════════════════════════════
📍 METHOD: POST
🔗 URL: http://72.61.226.129:5001/api/attendance
📋 HEADERS: {
  "X-Company-Id": "revit2025",
  "Authorization": "Bearer eyJhbGc..."
}
📦 REQUEST BODY:
{
  "employeeId": 123,
  "checkIn": "2025-12-01T08:10:00.000Z"
}
   ⏰ checkIn: 2025-12-01T08:10:00.000Z (will be stored in DB)
🚀 SENDING TO BACKEND...
```

#### `logApiResponse(requestId, method, url, status, responseData)`
**Output**:
```
═══════════════════════════════════════════════════════════
📨 [REQ-1] API RESPONSE RECEIVED
═══════════════════════════════════════════════════════════
📍 METHOD: POST
🔗 URL: http://72.61.226.129:5001/api/attendance
📊 STATUS: 200
📦 RESPONSE DATA:
[
  {
    "id": 456,
    "employeeId": 123,
    "checkIn": "2025-12-01T08:10:00+00:00",
    "status": "present"
  }
]

🔍 TIMESTAMP FIELDS:
   ⏰ checkIn: 2025-12-01T08:10:00+00:00 (from DB, needs IST conversion)

✅ DATA RECEIVED - READY FOR UI RENDERING
```

#### `logUserAction(action, component, details)`
**Purpose**: Track user interactions (button clicks, form submissions)

**Output**:
```
╔═══════════════════════════════════════════════════════════╗
║ 👤 USER ACTION                                             ║
╚═══════════════════════════════════════════════════════════╝
🎯 ACTION: Add Attendance
📱 COMPONENT: AdminDashboard
📝 DETAILS:
{
  "employeeId": 123,
  "employeeName": "John Doe",
  "checkInTime": "2025-12-01T13:40"
}
```

#### `logUIRender(component, description, data)`
**Purpose**: Track what data is being displayed on screen

**Output**:
```
╔═══════════════════════════════════════════════════════════╗
║ 🖥️  UI RENDERING                                           ║
╚═══════════════════════════════════════════════════════════╝
📱 COMPONENT: AdminDashboard
📄 DESCRIPTION: Attendance Table
📊 DATA BEING DISPLAYED:
[
  {
    "id": 456,
    "employeeName": "John Doe",
    "checkIn": "2025-12-01T08:10:00+00:00"
  }
]

🖼️  RENDERING 1 ITEMS ON SCREEN
   Item 1 - checkIn: WILL SHOW AS IST ON SCREEN
✅ RENDERING COMPLETE - CHECK UI
```

---

### 3. **`electron-app/logger.js`** - FILE LOGGER (Node.js)
**Purpose**: Write permanent log files to disk

**Features**:
- Creates daily log files: `logs/app-logs-YYYY-MM-DD.log`
- Auto-deletes logs older than 7 days
- Thread-safe file writing
- Structured log format

**Example Log File Content** (`logs/app-logs-2025-12-01.log`):
```
[2025-12-01 13:40:15.123] [API-REQUEST] POST http://72.61.226.129:5001/api/attendance
  Data: {
    "method": "POST",
    "headers": { "X-Company-Id": "revit2025" },
    "body": { "employeeId": 123, "checkIn": "2025-12-01T08:10:00.000Z" }
  }
────────────────────────────────────────────────────────────────────────────────────────────────────

[2025-12-01 13:40:15.456] [API-RESPONSE] POST http://72.61.226.129:5001/api/attendance → Status: 200
  Data: {
    "responseData": [
      { "id": 456, "checkIn": "2025-12-01T08:10:00+00:00" }
    ]
  }
────────────────────────────────────────────────────────────────────────────────────────────────────

[2025-12-01 13:40:15.789] [TIMEZONE-CONVERSION] formatUTCtoIST
  Data: {
    "source": "AdminDashboard-AttendanceTable",
    "input": "2025-12-01T08:10:00+00:00",
    "output": "01-12-2025 13:40:00",
    "offset": "+5:30 hours (IST)"
  }
────────────────────────────────────────────────────────────────────────────────────────────────────
```

---

## Complete Data Flow Example

### Scenario: Admin adds attendance at 13:40 IST

**Step 1: User Input**
```
👤 USER ACTION: Admin clicks "Add Attendance" button
📱 Component: AdminDashboard
📝 Input: 2025-12-01T13:40 (datetime-local field)
```

**Step 2: IST → UTC Conversion**
```javascript
convertISTtoUTC("2025-12-01T13:40", "AdminDashboard-AddAttendance")
```
**Console Log**:
```
📥 USER INPUT (IST): 2025-12-01T13:40
⚙️ CONVERSION: Subtract 5:30 hours
📤 OUTPUT (UTC for DB): 2025-12-01T08:10:00.000Z
```

**Step 3: API Request**
```javascript
logApiRequest('POST', '/api/attendance', headers, body)
```
**Console Log**:
```
🌐 [REQ-1] API REQUEST SENT
📦 BODY: { "checkIn": "2025-12-01T08:10:00.000Z" }
⏰ checkIn: Will be stored as UTC in PostgreSQL
```

**Step 4: Database Storage**
```
PostgreSQL Table: attendance
Column: check_in
Value: 2025-12-01 08:10:00+00 (UTC with timezone)
```

**Step 5: API Response**
```javascript
logApiResponse('REQ-1', 'POST', '/api/attendance', 200, data)
```
**Console Log**:
```
📨 [REQ-1] API RESPONSE RECEIVED
📦 RESPONSE: { "checkIn": "2025-12-01T08:10:00+00:00" }
⏰ checkIn: From DB, needs IST conversion for display
```

**Step 6: UTC → IST Conversion for Display**
```javascript
formatUTCtoIST("2025-12-01T08:10:00+00:00", "AdminDashboard-AttendanceTable")
```
**Console Log**:
```
📥 INPUT (UTC from DB): 2025-12-01T08:10:00+00:00
⚙️ CONVERSION: Add 5:30 hours
📤 OUTPUT (IST for UI): 01-12-2025 13:40:00
```

**Step 7: UI Rendering**
```javascript
logUIRender("AdminDashboard", "Attendance Table", attendanceData)
```
**Console Log**:
```
🖥️ UI RENDERING
📊 Displaying attendance: 01-12-2025 13:40:00
✅ User sees IST time on screen
```

---

## How to Use Console Logs

### Opening Developer Console
1. Press **F12** in Electron app
2. Click **Console** tab
3. You'll see ALL logs in real-time

### What to Look For

#### ✅ **Correct Flow** (IST time shows correctly):
```
📥 USER INPUT: 13:40
⚙️ Convert to UTC: 08:10 (-5:30)
💾 Save to DB: 08:10 UTC
📨 Read from DB: 08:10 UTC
⚙️ Convert to IST: 13:40 (+5:30)
🖥️ SHOW ON SCREEN: 13:40 ✅ MATCHES USER INPUT
```

#### ❌ **Wrong Flow** (UTC time shows on screen):
```
📥 USER INPUT: 13:40
⚙️ Convert to UTC: 08:10 (-5:30)
💾 Save to DB: 08:10 UTC
📨 Read from DB: 08:10 UTC
❌ NO CONVERSION ❌
🖥️ SHOW ON SCREEN: 08:10 ❌ WRONG! SHOULD BE 13:40
```

### Filtering Console Logs

**See only timezone conversions**:
```javascript
// Type in console:
console.log = ((originalLog) => {
  return function(...args) {
    if (args.join('').includes('formatUTCtoIST') || args.join('').includes('convertISTtoUTC')) {
      originalLog.apply(console, args);
    }
  };
})(console.log);
```

**See only API calls**:
```javascript
// Type in console:
console.log = ((originalLog) => {
  return function(...args) {
    if (args.join('').includes('[REQ-') || args.join('').includes('API')) {
      originalLog.apply(console, args);
    }
  };
})(console.log);
```

---

## Log File Locations

### Console Logs
- **Location**: Browser DevTools Console (F12)
- **Lifetime**: Session only (cleared on refresh)
- **Best For**: Real-time debugging

### File Logs
- **Location**: `electron-app/logs/app-logs-YYYY-MM-DD.log`
- **Lifetime**: 7 days (auto-deleted after)
- **Best For**: Historical analysis, debugging issues after they happen

### Example File Log Usage

**View today's logs**:
```powershell
Get-Content "electron-app\logs\app-logs-2025-12-01.log" | Select-String "TIMEZONE"
```

**Find specific conversion**:
```powershell
Get-Content "electron-app\logs\app-logs-2025-12-01.log" | Select-String "13:40"
```

**Count total conversions today**:
```powershell
(Get-Content "electron-app\logs\app-logs-2025-12-01.log" | Select-String "formatUTCtoIST").Count
```

---

## Understanding the Source Parameter

Every timezone function now takes a `source` parameter that tells you **WHERE** the conversion is being called from:

### Common Sources:

| Source | Meaning |
|--------|---------|
| `AdminDashboard-AttendanceTable` | Displaying attendance in admin table |
| `AdminDashboard-AddAttendance` | Admin manually adding attendance |
| `PunchInOut-CheckIn` | Employee punching in |
| `PunchInOut-CheckOut` | Employee punching out |
| `PunchInOut-CurrentTime` | Displaying current time to employee |
| `WorkLog-TaskTable` | Displaying tasks in work log |
| `WorkLog-AddTask` | Adding new task |
| `EmployeeDetailsView-AttendanceHistory` | Employee viewing their attendance history |

**Example**:
```javascript
// When you see this in console:
📍 SOURCE: AdminDashboard-AttendanceTable

// It means:
// "This timestamp is being converted for display in the 
//  attendance table on the Admin Dashboard"
```

---

## Debugging Common Issues

### Issue 1: "I see UTC time on screen instead of IST"

**What to check in console**:
1. Look for the conversion log:
   ```
   🔄 [formatUTCtoIST] TIMEZONE CONVERSION STARTED
   📍 SOURCE: AdminDashboard-AttendanceTable
   ```
2. Check if conversion is happening:
   - ✅ **Good**: You see the log with correct IST output
   - ❌ **Bad**: No log appears → conversion function not being called
3. Check the source:
   - If SOURCE is missing or says "Unknown", the component isn't passing source parameter

**Solution**:
- If no log: Component is not using `formatUTCtoIST()` function
- If log shows wrong output: Conversion logic has a bug
- If log shows correct output but UI shows wrong time: UI rendering issue

---

### Issue 2: "Time I enter gets stored wrong in database"

**What to check in console**:
1. Look for user input log:
   ```
   👤 USER INPUT (IST): 2025-12-01T13:40
   ```
2. Look for conversion log:
   ```
   💾 OUTPUT FOR DATABASE (UTC): 2025-12-01T08:10:00.000Z
   ```
3. Check if -5:30 offset was applied correctly:
   - 13:40 IST → 08:10 UTC ✅
   - 13:40 IST → 13:40 UTC ❌ (missing conversion)

---

### Issue 3: "Different times showing in different components"

**What to check in console**:
1. Search for all conversions of the same timestamp:
   ```
   📥 INPUT: 2025-12-01T08:10:00+00:00
   ```
2. Check if all components show same output:
   ```
   📤 OUTPUT: 01-12-2025 13:40:00
   ```
3. Check SOURCE field to see which component is wrong:
   ```
   📍 SOURCE: AdminDashboard-AttendanceTable ✅ Shows 13:40
   📍 SOURCE: WorkLog-TaskTable ✅ Shows 13:40
   📍 SOURCE: PunchInOut-CurrentTime ❌ Shows 08:10 (missing conversion)
   ```

---

## Summary

### Which File Does What?

| File | Purpose | When to Use |
|------|---------|-------------|
| `istTimeUtils.js` | **Core timezone conversion** | ALL timezone conversions (UTC↔IST) |
| `apiLogger.js` | **API call tracking** | Track requests/responses, network data flow |
| `logger.js` | **Disk-based logging** | Permanent records, historical debugging |

### Data Flow Trace:

```
1. 👤 USER INPUT (IST)
      ↓
2. 🔄 convertISTtoUTC() → Subtract 5:30 hours
      ↓
3. 🌐 API Request → Send UTC to backend
      ↓
4. 💾 DATABASE → Store UTC with timezone
      ↓
5. 📨 API Response → Receive UTC from backend
      ↓
6. 🔄 formatUTCtoIST() → Add 5:30 hours
      ↓
7. 🖥️ UI DISPLAY (IST) → Show to user
```

### Quick Reference:

- **See console logs**: Press F12 → Console tab
- **See file logs**: Open `electron-app/logs/app-logs-YYYY-MM-DD.log`
- **Debug timezone**: Search console for "formatUTCtoIST" or "convertISTtoUTC"
- **Debug API**: Search console for "[REQ-" or "API REQUEST"
- **Track user action**: Search console for "USER ACTION"

---

## Important Notes

1. **Every conversion is logged** - No timezone conversion happens without leaving a trace
2. **Source tracking** - You can always see which component called the conversion
3. **Complete data flow** - From user input → database → UI display, everything is tracked
4. **7-day log retention** - File logs auto-delete after 7 days to save disk space
5. **Performance impact** - Console logging is fast, but excessive logging may slow down the app in production

**For production**: Consider adding a toggle to disable detailed logging for better performance while keeping error logging active.
