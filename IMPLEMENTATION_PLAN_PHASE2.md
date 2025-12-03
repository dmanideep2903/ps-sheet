# IMPLEMENTATION PLAN - Phase 2 Enhancements

## Status: Backend Ready ✅
- UserProfile table created
- ProfileController API ready  
- AttendanceController updated for manual entry
- Backend running

## Frontend Implementation Order

### 1. Fix Manual Attendance Endpoint ✅ READY TO TEST
**File:** AdminDashboard.jsx line 107
**Change:** `'http://localhost:5001/api/Attendance/Clock'` → `'http://localhost:5001/api/Attendance'`
**Also add:** WifiSsid field to bypass restriction

### 2. Global Loading Cursor
**Files:** All components with buttons
**Implementation:** 
- Add `document.body.style.cursor = 'wait'` on click
- Reset to `'default'` in finally block
- Create utility function in helpers.js

### 3. Fix Export/Print to Include ALL Records
**Files:** AdminDashboard, EmployeeManagement, WorkLogManagement, WorkLog
**Change:** Use `records` instead of `paginatedRecords`
**Add:** Confirmation dialog before export

### 4. PunchInOut Pagination & Features
**File:** PunchInOut.jsx
**Add:**
- Pagination (10 rows)
- Search filter
- Export/Print buttons
- Sort already working

### 5. Profile Components (COMPLEX)

#### 5a. ProfileForm Component (NEW FILE)
- Form with all fields
- File upload for profile picture (convert to base64)
- Required at first login
- Modal/popup style

#### 5b. ProfileCard Component (NEW FILE)
- Display profile info
- Show on left side of pages
- Compact card design
- Profile picture display

#### 5c. Update App.jsx
- Check profile exists after login
- Show ProfileForm if not exists
- Block access until profile complete

### 6. Employee Details View (COMPLEX)

#### 6a. EmployeeDetailsView Component (NEW FILE)
- Full page view
- Three separate cards:
  - Profile Card (top)
  - Attendance Log Card
  - Work Log Card
- Close button returns to Employee Management
- Fetch data for specific employee

#### 6b. Update EmployeeManagement.jsx
- Make employee names clickable
- Pass employee email to details view
- Navigation logic

## Time Estimate
- Tasks 1-4: 30-45 minutes
- Task 5 (Profile): 60-90 minutes
- Task 6 (Employee Details): 45-60 minutes
- Total: ~3 hours

## Questions Answered
1. Manual attendance: Use POST /api/Attendance
2. Profile display: Left side card
3. Profile pic: File upload → Base64
4. Profile required: Yes, block access
5. Employee details: Full page, separate cards
6. Loading: Spinning cursor
7. Export: ALL filtered records with confirmation

## Next Steps
Start with quick fixes (1-4), then tackle complex features (5-6)
