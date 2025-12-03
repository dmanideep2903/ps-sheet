# 🧪 DeskAttendance App - Testing Checklist

## Quick Test (5 minutes)

### ✅ 1. Login Test
- [ ] Open DeskAttendance.exe (Electron app should be running)
- [ ] Login with admin credentials:
  - **Email:** pivotadmin@gmail.com
  - **Password:** Admin123
- [ ] Verify successful login and dashboard loads

### ✅ 2. Attendance Punch Test
- [ ] Click "Punch In" button
- [ ] Verify attendance record created
- [ ] Check timestamp is correct
- [ ] Click "Punch Out" button
- [ ] Verify punch out recorded

### ✅ 3. Admin Panel Test
- [ ] Navigate to Admin Dashboard
- [ ] View all attendance records
- [ ] Verify data displays correctly
- [ ] Check search and filter functions

---

## Full Test (30 minutes)

### ✅ 1. Authentication & Security
- [ ] Test login with correct credentials
- [ ] Test login with wrong password (should fail)
- [ ] Test login with non-existent email (should fail)
- [ ] Verify JWT token is stored
- [ ] Test logout functionality
- [ ] Verify session persists on app restart

### ✅ 2. Employee Features
**Attendance Tracking:**
- [ ] Punch In creates new record
- [ ] Punch Out updates existing record
- [ ] Cannot punch in twice without punch out
- [ ] Attendance history displays correctly
- [ ] Filter attendance by date range

**Work Log:**
- [ ] Create new work log entry
- [ ] Edit existing work log
- [ ] Delete work log
- [ ] View work log history
- [ ] Submit work log for approval

**Profile Management:**
- [ ] View employee profile
- [ ] Update profile information
- [ ] Upload profile picture
- [ ] Change password

### ✅ 3. Admin Features
**Employee Management:**
- [ ] View all employees list
- [ ] Add new employee
- [ ] Edit employee details
- [ ] Delete employee
- [ ] Search employees by name/email
- [ ] Filter employees by department/role

**Attendance Management:**
- [ ] View all attendance records
- [ ] Export attendance to CSV/Excel
- [ ] Filter by employee
- [ ] Filter by date range
- [ ] Edit attendance records
- [ ] Delete attendance records

**Work Log Approval:**
- [ ] View pending work logs
- [ ] Approve work log
- [ ] Reject work log with reason
- [ ] View approved/rejected history

**Reports:**
- [ ] Generate attendance summary report
- [ ] Generate employee performance report
- [ ] Export reports to PDF/Excel
- [ ] Filter reports by date range

### ✅ 4. Database (PostgreSQL)
**Connection:**
- [ ] Backend connects to PostgreSQL successfully
- [ ] Database migrations applied correctly
- [ ] Seed data exists (admin user, settings)

**Data Persistence:**
- [ ] Create attendance record → Check database
- [ ] Update record → Verify in database
- [ ] Delete record → Confirm deletion
- [ ] App restart → Data still exists

**Backup Test:**
- [ ] Run backup script: `.\backup-database.ps1`
- [ ] Verify backup file created in DatabaseBackups folder
- [ ] Check backup file size is reasonable
- [ ] Test restore (optional): Load backup to new database

### ✅ 5. Performance Tests
**Load Testing:**
- [ ] Create 100 attendance records (stress test)
- [ ] Search with 100+ records (response < 1 second)
- [ ] Filter with large dataset
- [ ] Export large dataset to CSV

**Concurrency Test:**
- [ ] Open app on 2 different machines
- [ ] Both punch in/out simultaneously
- [ ] Verify both records saved correctly
- [ ] No data corruption or conflicts

### ✅ 6. Network Validation
- [ ] Test with correct WiFi network (should pass)
- [ ] Test with wrong WiFi network (should block)
- [ ] Test with wrong router MAC (should block)
- [ ] Admin can bypass network restrictions
- [ ] Settings can be updated in admin panel

### ✅ 7. Face Recognition (if enabled)
- [ ] Capture face for new employee
- [ ] Face recognition on punch in
- [ ] Reject unrecognized faces
- [ ] Multiple faces detection
- [ ] Low light conditions

### ✅ 8. Error Handling
- [ ] Backend offline → Show error message
- [ ] Database connection lost → Retry logic
- [ ] Invalid form data → Show validation errors
- [ ] Network timeout → Graceful error
- [ ] No internet → Offline mode (if implemented)

### ✅ 9. Cross-Platform (if applicable)
- [ ] Test on Windows 10
- [ ] Test on Windows 11
- [ ] Test on different screen resolutions
- [ ] Test on laptop (smaller screen)
- [ ] Test on desktop (large monitor)

### ✅ 10. Docker & PostgreSQL
- [ ] Docker container running: `docker ps`
- [ ] PostgreSQL accessible: `docker exec attendance-postgres psql -U postgres -c "\l"`
- [ ] Container restarts automatically: `docker update --restart=always attendance-postgres`
- [ ] Data persists after container restart

---

## Common Issues & Solutions

### ❌ Backend Won't Start
**Problem:** Port 5001 already in use
**Solution:** 
```powershell
# Kill all .NET processes
Get-Process | Where-Object {$_.ProcessName -eq "dotnet"} | Stop-Process -Force
```

### ❌ Database Connection Failed
**Problem:** PostgreSQL container not running
**Solution:**
```powershell
# Start PostgreSQL container
docker start attendance-postgres

# Check status
docker ps | findstr attendance-postgres
```

### ❌ Login Failed
**Problem:** Database not seeded with admin user
**Solution:**
```powershell
cd backend
dotnet ef database update
```

### ❌ Face Recognition Not Working
**Problem:** Models not loaded
**Solution:**
- Check `react-app/public/models` folder exists
- Download models from face-api.js repository
- Restart app

---

## Performance Benchmarks

| Test | Expected Result | Actual Result |
|------|----------------|---------------|
| Login time | < 1 second | _____ |
| Punch in/out | < 500ms | _____ |
| Load 100 records | < 2 seconds | _____ |
| Search | < 1 second | _____ |
| Export CSV | < 5 seconds | _____ |
| Backend startup | < 10 seconds | _____ |
| Database query | < 100ms | _____ |

---

## Test Results Summary

**Date:** ________________

**Tester:** ________________

**Version:** ________________

**Pass Rate:** _____ / _____ tests passed

**Critical Issues:** 
- [ ] None
- [ ] List issues here:

**Notes:**
