# Quick Guide: Update React Components for Multi-Tenant

## Search & Replace Pattern

Use your editor's find & replace (Ctrl+H) to update all remaining React files.

---

## Step 1: Update Imports

**Find:**
```javascript
import { validateNetwork } from '../config/networkConfig';
```

**Replace with:**
```javascript
import { validateNetwork, getApiBaseUrl, getApiHeaders } from '../config/networkConfig';
```

**OR if file doesn't import validateNetwork:**

**Find:**
```javascript
import React
```

**Replace with:**
```javascript
import { getApiBaseUrl, getApiHeaders } from '../config/networkConfig';
import React
```

---

## Step 2: Update Fetch Calls

### Pattern 1: POST/PUT/DELETE with Body

**Find:**
```javascript
fetch('http://localhost:5001/api/ENDPOINT', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data)
})
```

**Replace with:**
```javascript
fetch(`${getApiBaseUrl()}/api/ENDPOINT`, {
  method: 'POST',
  headers: getApiHeaders(),
  body: JSON.stringify(data)
})
```

### Pattern 2: GET without Body

**Find:**
```javascript
fetch('http://localhost:5001/api/ENDPOINT')
```

**Replace with:**
```javascript
fetch(`${getApiBaseUrl()}/api/ENDPOINT`, {
  headers: getApiHeaders()
})
```

### Pattern 3: GET with Query Parameters

**Find:**
```javascript
fetch(`http://localhost:5001/api/ENDPOINT?param=${value}`)
```

**Replace with:**
```javascript
fetch(`${getApiBaseUrl()}/api/ENDPOINT?param=${value}`, {
  headers: getApiHeaders()
})
```

### Pattern 4: Conditional URL (Ternary)

**Find:**
```javascript
const url = someCondition
  ? 'http://localhost:5001/api/ENDPOINT1'
  : 'http://localhost:5001/api/ENDPOINT2';
```

**Replace with:**
```javascript
const url = someCondition
  ? `${getApiBaseUrl()}/api/ENDPOINT1`
  : `${getApiBaseUrl()}/api/ENDPOINT2`;
```

---

## Files to Update (In Order of Priority)

### 🔴 HIGH PRIORITY

#### 1. EmployeeManagement.jsx (8 updates)
**Lines to change:**
- Line 32: `fetch('http://localhost:5001/api/employees', {`
- Line 41: `fetch('http://localhost:5001/api/employees/unapproved', {`
- Line 150: `fetch('http://localhost:5001/api/employees', {`
- Line 207: `fetch(`http://localhost:5001/api/employees/${id}`, {`
- Line 225: `fetch(`http://localhost:5001/api/employees/${id}`, {`
- Line 257: `fetch(`http://localhost:5001/api/employees/${id}`, {`
- Line 280: `fetch(`http://localhost:5001/api/employees/approve/${id}`, {`

**Import to add:**
```javascript
import { getApiBaseUrl, getApiHeaders } from '../config/networkConfig';
```

#### 2. AdminDashboard.jsx (12 updates)
**Lines to change:**
- Line 83: `fetch('http://localhost:5001/api/employees', {`
- Line 95: `fetch('http://localhost:5001/api/Task/all', {`
- Line 106: `fetch(`http://localhost:5001/api/Admin/AttendanceRecords${queryString}`, {`
- Line 134: URL ternary for edit/assign task
- Line 135: URL ternary continuation
- Line 249: `fetch('http://localhost:5001/api/Task/assign', {`
- Line 339: `fetch(`http://localhost:5001/api/Task/delete/${taskId}`, {`
- Line 445: `fetch(`http://localhost:5001/api/Admin/AttendanceRecord/${id}`, {`
- Line 493: `fetch(`http://localhost:5001/api/admin/AttendanceRecord/${id}`, {`
- Line 577: `fetch('http://localhost:5001/api/Attendance', {`

**Import to add:**
```javascript
import { getApiBaseUrl, getApiHeaders } from '../config/networkConfig';
```

### 🟡 MEDIUM PRIORITY

#### 3. WorkLog.jsx (6 updates)
**Lines to change:**
- Line 25: `fetch(`http://localhost:5001/api/Task/employee/${encodedEmail}`)`
- Line 73: `fetch(`http://localhost:5001/api/WorkLog/employee/${encodeURIComponent(employeeEmail)}`)`
- Line 124: `endpoint: 'http://localhost:5001/api/Task/submit-single'`
- Line 127: `fetch('http://localhost:5001/api/Task/submit-single', {`
- Line 182: `fetch(`http://localhost:5001/api/Task/revoke/${taskId}`, {`

#### 4. WorkLogManagement.jsx (6 updates)
**Lines to change:**
- Line 25: `fetch('http://localhost:5001/api/Task/all');`
- Line 81: `fetch(`http://localhost:5001/api/Task/delete/${taskId}`, {`
- Line 118: `fetch(`http://localhost:5001/api/Task/approve/${selectedTaskForAction.id}`, {`
- Line 154: `fetch(`http://localhost:5001/api/Task/reject/${selectedTaskForAction.id}`, {`
- Line 187: `fetch(`http://localhost:5001/api/Task/reverse/${taskId}`, {`
- Line 221: `fetch(`http://localhost:5001/api/Task/edit/${editingTask.id}`, {`

#### 5. EmployeeDetailsView.jsx (3 updates)
**Lines to change:**
- Line 43: `fetch(`http://localhost:5001/api/Profile/${employeeEmail}`);`
- Line 54: `fetch(`http://localhost:5001/api/admin/AttendanceRecords?employeeId=${encodeURIComponent(employeeEmail)}`, {`
- Line 72: `fetch(`http://localhost:5001/api/Task/employee/${encodeURIComponent(employeeEmail)}`);`

### 🟢 LOW PRIORITY

#### 6. WorkLogHistory.jsx (2 updates)
**Lines to change:**
- Line 34-35: Ternary URL for task endpoint

#### 7. NetworkManagement.jsx (3 updates - Optional)
**Note:** This component manages network settings and may not need CompanyId filtering, but should still use dynamic API URL for consistency.

---

## Quick Copy-Paste Snippets

### For fetch() with headers object already present:

**Before:**
```javascript
headers: { 'Content-Type': 'application/json' }
```

**After:**
```javascript
headers: getApiHeaders()
```

### For fetch() without headers:

**Before:**
```javascript
fetch('http://localhost:5001/api/ENDPOINT')
```

**After:**
```javascript
fetch(`${getApiBaseUrl()}/api/ENDPOINT`, {
  headers: getApiHeaders()
})
```

---

## Verification Steps

After updating each file:

1. **Check for syntax errors:**
   ```powershell
   cd react-app
   npm run build
   ```

2. **Verify import is at top of file**
3. **Ensure ALL instances of `localhost:5001` are replaced**
4. **Test the component in app**

---

## Common Mistakes to Avoid

❌ **Don't forget backticks:**
```javascript
// WRONG
fetch('${getApiBaseUrl()}/api/endpoint')

// RIGHT
fetch(`${getApiBaseUrl()}/api/endpoint`)
```

❌ **Don't forget headers on GET requests:**
```javascript
// WRONG (missing CompanyId header)
fetch(`${getApiBaseUrl()}/api/endpoint`)

// RIGHT
fetch(`${getApiBaseUrl()}/api/endpoint`, {
  headers: getApiHeaders()
})
```

❌ **Don't mix quote styles:**
```javascript
// WRONG
fetch(`${getApiBaseUrl()}/api/endpoint", {

// RIGHT
fetch(`${getApiBaseUrl()}/api/endpoint`, {
```

---

## Time Estimate

- EmployeeManagement.jsx: 10 minutes
- AdminDashboard.jsx: 15 minutes
- WorkLog.jsx: 8 minutes
- WorkLogManagement.jsx: 8 minutes
- EmployeeDetailsView.jsx: 5 minutes
- WorkLogHistory.jsx: 3 minutes
- NetworkManagement.jsx: 5 minutes

**Total: ~1 hour** (including testing)

---

## Testing After Updates

1. **Build React app:**
   ```powershell
   cd react-app
   npm run build
   ```

2. **Copy to Electron:**
   ```powershell
   cd ../electron-app
   Remove-Item -Recurse -Force build
   Copy-Item -Recurse ../react-app/build ./
   ```

3. **Test with default config:**
   ```powershell
   # Edit appConfig.json
   npm start
   ```

4. **Verify CompanyId in Network tab:**
   - Open DevTools (F12)
   - Go to Network tab
   - Perform action (login, punch, etc.)
   - Check request headers → Should see `X-Company-Id: default`

---

**Good luck! 🚀**
