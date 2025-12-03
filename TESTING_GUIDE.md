# Quick Start Guide - Phase 2 Features

## 🚀 Starting the Application

### Backend (Already Running)
```powershell
# Backend is running on PID 13416
# Port: 5001
# If needed to restart:
cd p:\SourceCode-HM\DeskAttendanceApp\backend
dotnet run
```

### Frontend
```powershell
# Development mode:
cd p:\SourceCode-HM\DeskAttendanceApp\react-app
npm start

# OR use Electron app:
cd p:\SourceCode-HM\DeskAttendanceApp\electron-app
npm start
```

---

## 🎯 Testing Phase 2 Features

### 1️⃣ Profile System

**Test Profile Creation:**
1. Register a new user or use existing user without profile
2. Login with credentials
3. **ProfileForm modal should appear** blocking access
4. Fill in all required fields:
   - Upload profile picture (click circular placeholder)
   - First Name, Last Name
   - Date of Birth (use date picker)
   - Phone Number
   - Address
5. Click "Complete Profile"
6. Modal closes, **ProfileCard appears on left side**

**Expected Result:**
- Modal blocks access until profile completed
- ProfileCard shows on left side with avatar
- Dashboard content appears on right side

---

### 2️⃣ Employee Details View

**Test Employee Details:**
1. Login as Admin
2. Go to Employee Management tab
3. **Click on any employee name** (blue, underlined)
4. Full-page view opens showing:
   - Profile card at top (avatar, name, contact info)
   - Attendance records table (middle)
   - Work logs table (bottom)

**Test Features:**
- Search filters work on both tables
- Pagination works (10 rows per page)
- Export buttons create CSV files
- Print buttons open print dialog
- Close button (red X) returns to employee list

**Expected Result:**
- Clean full-page overlay
- All employee data visible
- Navigation works smoothly

---

### 3️⃣ Loading Cursors

**Test on ALL buttons:**

**AdminDashboard:**
- Click "Delete" on any record → cursor changes to spinning circle
- Click "Save" after editing → loading cursor appears
- Click "Add Manual Entry" → loading cursor appears

**EmployeeManagement:**
- Click "Add Employee" → loading cursor
- Click "Edit" then "Save" → loading cursor
- Click "Delete" → loading cursor
- Click "Approve" on unapproved user → loading cursor

**WorkLogManagement:**
- Click "Approve" on pending log → loading cursor

**PunchInOut:**
- Click "Punch In" → loading cursor
- Click "Punch Out" → loading cursor

**Login/Register:**
- Click "Login" button → loading cursor
- Click "Register" button → loading cursor

**ProfileForm:**
- Click "Complete Profile" → loading cursor

**Expected Result:**
- Cursor changes to `wait` (spinning circle) during all async operations
- Cursor returns to normal after operation completes

---

### 4️⃣ Export/Print ALL Records

**Test Export:**
1. Go to any table with data (AdminDashboard, PunchInOut, etc.)
2. Apply a search filter (e.g., search for specific employee)
3. Note the filtered record count
4. Click "Export" button
5. **Confirmation dialog appears:** "Export all X records?"
6. Click OK
7. CSV file downloads with ALL filtered records (not just current page)

**Test Print:**
1. Same steps as export
2. Click "Print" button
3. **Confirmation dialog appears:** "Print all X records?"
4. Click OK
5. Print dialog opens showing ALL filtered records

**Expected Result:**
- Confirmation dialogs show correct record counts
- Export includes ALL records from all pages
- Search filter applied correctly before export

---

### 5️⃣ PunchInOut Enhancements

**Test Attendance History:**
1. Login as Employee
2. View "Attendance History" section
3. **New features visible:**
   - Search input box (top right)
   - Record count displayed
   - Export and Print buttons
   - Pagination controls (if >10 records)

**Test Features:**
- Type in search box → filters records instantly
- Page through records using Previous/Next buttons
- Click Export → confirmation dialog → CSV downloads
- Click Print → confirmation dialog → print dialog opens

**Expected Result:**
- 10 records per page
- Search filters across date/time/status
- Export/print work with confirmation

---

### 6️⃣ Manual Attendance Fix

**Test Manual Entry:**
1. Login as Admin
2. Go to Admin Dashboard
3. Fill manual attendance form:
   - Select employee
   - Select date
   - Enter clock in/out times
4. Click "Add Manual Entry"
5. **Loading cursor appears**
6. Record added successfully

**Expected Result:**
- No 404 error
- Record appears in attendance table
- Manual entry bypasses WiFi restriction
- Loading cursor visible during operation

---

## 🧪 Profile System Flow Test

### Complete User Journey:

1. **Registration:**
   ```
   Register → Login → ProfileForm appears
   ```

2. **Profile Creation:**
   ```
   Upload photo → Fill fields → Submit → Modal closes
   ```

3. **Dashboard Access:**
   ```
   ProfileCard visible (left) → Dashboard content (right)
   ```

4. **Subsequent Logins:**
   ```
   Login → Profile loads automatically → No modal
   ```

---

## 🎨 Visual Checks

### Layout Verification:

**Admin View:**
```
┌─────────────────────────────────────────────┐
│  EMPLOYEE TIMEPULSE                         │
├─────────────┬───────────────────────────────┤
│ ProfileCard │  Admin Dashboard              │
│  (280px)    │  - Attendance Records         │
│  Avatar     │  - Manual Entry Form          │
│  Name       │  - Pagination                 │
│  Email      │  - Export/Print               │
│  Phone      │                               │
│  Birthday   │                               │
│  Address    │                               │
└─────────────┴───────────────────────────────┘
```

**Employee View:**
```
┌─────────────────────────────────────────────┐
│  EMPLOYEE TIMEPULSE                         │
├─────────────┬───────────────────────────────┤
│ ProfileCard │  Punch In/Out                 │
│  (280px)    │  - Punch buttons              │
│  Avatar     │  - Attendance History         │
│  Name       │  - Search filter              │
│  Email      │  - Pagination                 │
│  Phone      │  - Export/Print               │
│  Birthday   │                               │
│  Address    │  Work Log toggle              │
└─────────────┴───────────────────────────────┘
```

**Employee Details View:**
```
┌─────────────────────────────────────────────┐
│  Employee Details: John Doe           ✕     │
├─────────────────────────────────────────────┤
│  ┌───────────────────────────────────────┐  │
│  │  Profile Information                  │  │
│  │  [Avatar]  Name, Email, Phone, etc.   │  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │  Attendance Records (50)              │  │
│  │  [Search] [Export] [Print]            │  │
│  │  [Table with pagination]              │  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │  Work Logs (25)                       │  │
│  │  [Search] [Export] [Print]            │  │
│  │  [Table with pagination]              │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

---

## 📊 Test Data Scenarios

### Scenario 1: New User
- No profile exists
- ProfileForm modal appears
- Must complete profile before access

### Scenario 2: Existing User
- Profile exists
- Direct access to dashboard
- ProfileCard visible immediately

### Scenario 3: Large Dataset
- >10 attendance records
- Pagination appears
- Export includes ALL pages
- Confirmation shows total count

### Scenario 4: Filtered Data
- Apply search filter
- Record count updates
- Export only filtered records
- Confirmation shows filtered count

---

## ✅ Success Criteria

### All features working when:
- ✅ ProfileForm appears for new users
- ✅ ProfileCard visible on all dashboards
- ✅ Employee names clickable in management
- ✅ EmployeeDetailsView shows full data
- ✅ Loading cursor on ALL button clicks
- ✅ Confirmation dialogs before export/print
- ✅ Export includes ALL filtered records
- ✅ Pagination works everywhere (10 rows)
- ✅ Search filters work correctly
- ✅ Manual attendance uses correct endpoint
- ✅ No console errors
- ✅ Responsive design works

---

## 🐛 Common Issues & Solutions

### Issue: ProfileForm not appearing
**Solution:** Check browser console, ensure `/api/Profile/exists/{email}` returns correct response

### Issue: Loading cursor not visible
**Solution:** Check browser zoom level, cursor style might be affected

### Issue: Export shows only current page
**Solution:** Verify using `records` array, not `paginatedRecords`

### Issue: Employee details not loading
**Solution:** Check network tab, verify all 3 API endpoints responding

### Issue: Profile picture not showing
**Solution:** Check file size (<2MB), verify base64 encoding

---

## 📞 Quick Reference: API Endpoints

```
Backend URL: http://localhost:5001

Profile:
  GET  /api/Profile/{email}
  POST /api/Profile
  PUT  /api/Profile/{email}
  GET  /api/Profile/exists/{email}

Attendance:
  GET  /api/Attendance
  POST /api/Attendance
  GET  /api/Attendance/{email}

WorkLog:
  GET  /api/WorkLog
  POST /api/WorkLog
  GET  /api/WorkLog/employee/{email}
  POST /api/WorkLog/approve/{id}

Employees:
  GET  /api/employees
  POST /api/employees
  PUT  /api/employees/{id}
  DELETE /api/employees/{id}
  POST /api/employees/approve/{id}

Auth:
  POST /api/auth/login
  POST /api/auth/register
```

---

## 🎉 READY TO TEST!

All Phase 2 features are implemented and ready for comprehensive testing. Follow the test scenarios above to verify each feature works as expected.

**Pro Tip:** Start with the Profile System test, then move through each feature systematically. Use the Visual Checks section to verify layout correctness on different screen sizes.
