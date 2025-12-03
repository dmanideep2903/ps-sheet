# WorkLog Feature - Complete UI Testing Guide
**End-to-End Testing: Task Assignment → Approval (All Scenarios)**

---

## 🎯 Test Preparation

### Current Database State:
```
Task 2: Approved (RejectionCount=0) - pivot102@gmail.com
Task 3: Approved (RejectionCount=2) - pivot102@gmail.com  
Task 4: Pending (RejectionCount=0) - pivot102@gmail.com
Task 5: Rejected (RejectionCount=1) - pivot104@gmail.com
Task 6: Rejected (RejectionCount=3) - pivot110@gmail.com
Task 7: Pending (RejectionCount=0) - pivot102@gmail.com
```

### Test User Credentials:
- **Admin:** admin@company.com / password: Admin@123
- **Employee 1:** pivot102@gmail.com / password: Pivot@102
- **Employee 2:** pivot104@gmail.com / password: Pivot@104
- **Employee 3:** pivot110@gmail.com / password: Pivot@110

---

## 📋 TEST SCENARIO 1: Admin Assigns New Task

### Steps:
1. **Login as Admin** (admin@company.com)
2. Navigate to **Admin Dashboard**
3. Click on **"Task Assignment"** tab
4. Click **"+ Assign New Task"** button

### Fill Task Form:
```
Title: Create User Report
Description: Generate monthly user activity report with charts
Assign To: pivot102@gmail.com (select from dropdown)
Due Date: [Select 3 days from today]
Priority: High
```

5. Click **"Assign Task"** button
6. ✅ **Verify:** Success message appears
7. ✅ **Verify:** New task appears in task list with Status: "Pending"

### Expected Result:
- Task created successfully
- Status shows as "Pending"
- Assigned employee email visible

---

## 📋 TEST SCENARIO 2: Employee Views Assigned Tasks

### Steps:
1. **Logout from Admin**
2. **Login as Employee** (pivot102@gmail.com)
3. Navigate to **"Work Log"** tab

### ✅ Verify Display:

#### Pending Tasks Section (Blue):
- [ ] Task 4: "Code Review Task" - checkbox unchecked
- [ ] Task 7: "Fix Login Bug" - checkbox unchecked
- [ ] Task 8 (NEW): "Create User Report" - checkbox unchecked

#### Approved Tasks Section (Green):
- [ ] Task 2: "Fix Login Bug" ✅ (grayed out, disabled)
- [ ] Task 3: "Update Documentation" ✅ (grayed out, disabled)

### Expected Result:
- All pending tasks visible with checkboxes
- Approved tasks visible but disabled
- No revoke button on approved tasks
- Submit button visible at bottom

---

## 📋 TEST SCENARIO 3: Employee Submits Task (Pending → Completed)

### Steps:
1. **Still logged in as pivot102@gmail.com**
2. In Work Log page, find Task 4: "Code Review Task"
3. **Check the checkbox** next to Task 4
4. **Enter remarks** in the textarea:
   ```
   Completed security review of PR #234. Found and fixed 2 vulnerabilities.
   ```
5. Click **"✅ Submit Completed Tasks"** button
6. ✅ **Verify:** Confirmation dialog appears
7. Click **"OK"** to confirm

### ✅ Verify Result:
- [ ] Task 4 moves to **"Completed Tasks"** section (Yellow/Orange)
- [ ] Task shows "⏰ Awaiting Approval" status
- [ ] Task is now grayed out (cannot modify)
- [ ] **Revoke button** appears on Task 4 ← **TEST REQUIREMENT 4!**
- [ ] Your remarks are visible

### Expected Result:
- Task status changed to "Completed"
- Remarks saved
- Revoke button visible

---

## 📋 TEST SCENARIO 4: Employee Revokes Completed Task (Completed → Pending)

### Steps:
1. **Still in Work Log page as pivot102@gmail.com**
2. Find Task 4 in **"Completed Tasks"** section
3. Click **"Revoke"** button
4. ✅ **Verify:** Confirmation dialog appears
5. Click **"OK"** to confirm

### ✅ Verify Result:
- [ ] Task 4 returns to **"Pending Tasks"** section
- [ ] Task is now editable again (checkbox enabled)
- [ ] Previous remarks are cleared
- [ ] Revoke button is gone
- [ ] Task status back to "Pending"

### Expected Result:
✅ **REQUIREMENT 4 TESTED:** Employee can revoke Completed tasks!

---

## 📋 TEST SCENARIO 5: Employee Resubmits Task

### Steps:
1. **Still as pivot102@gmail.com**
2. Check Task 4 checkbox again
3. Enter new remarks:
   ```
   Security review completed. All vulnerabilities fixed. Added unit tests for validation.
   ```
4. Click **"✅ Submit Completed Tasks"**
5. Confirm submission

### ✅ Verify Result:
- [ ] Task 4 back in "Completed Tasks" section
- [ ] New remarks visible
- [ ] Revoke button appears again
- [ ] Cannot modify task anymore

### Expected Result:
- Task resubmitted successfully
- Ready for admin review

---

## 📋 TEST SCENARIO 6: Admin Approves Task WITH Optional Remarks

### Steps:
1. **Logout from Employee**
2. **Login as Admin** (admin@company.com)
3. Navigate to **"Admin Dashboard" → "Work Log Management"** tab
4. Select **"Completed"** status from dropdown
5. Find **pivot102@gmail.com** section
6. Find Task 4: "Code Review Task"

### ✅ Verify Task Display:
- [ ] Employee name: pivot102
- [ ] Task title visible
- [ ] Employee remarks visible
- [ ] **"Approve"** and **"Reject"** buttons visible

### Approve Task:
7. Click **"Approve"** button
8. In the dialog, **OPTIONALLY** enter admin remarks:
   ```
   Excellent work! Security review is thorough. Approved.
   ```
9. Click **"Approve"** (or Submit)

### ✅ Verify Result:
- [ ] Success message appears
- [ ] Task removed from "Completed" section
- [ ] Task appears in **"Approved"** section

### Expected Result:
✅ **REQUIREMENT 2 TESTED:** AdminRemarks are OPTIONAL for approval!

---

## 📋 TEST SCENARIO 7: Admin Rejects Task WITH Mandatory Remarks

### Steps:
1. **Still logged in as Admin**
2. Navigate to **"Work Log Management"**
3. Select **"Completed"** status
4. Find another employee or submit Task 7 as pivot102 first

### Prepare Task for Rejection:
- Login as pivot102@gmail.com
- Submit Task 7 with remarks: "Login bug fixed"
- Logout and login as Admin

### Reject Task:
5. In Work Log Management → Completed section
6. Find Task 7 for pivot102@gmail.com
7. Click **"Reject"** button
8. ✅ **IMPORTANT TEST:** Try clicking Reject without entering remarks

### ✅ Verify Validation:
- [ ] Error message appears: "Admin remarks are mandatory for rejection"
- [ ] Task NOT rejected yet

9. Now enter admin remarks in the dialog:
   ```
   The fix is incomplete. Please also update the error handling for timeout scenarios.
   ```
10. Click **"Reject"** button

### ✅ Verify Result:
- [ ] Success message appears
- [ ] Task removed from "Completed" section
- [ ] Task appears in **"Rejected"** section (if filter available)

### Expected Result:
✅ **REQUIREMENT 2 TESTED:** AdminRemarks are MANDATORY for rejection!

---

## 📋 TEST SCENARIO 8: Employee Sees Rejection with UI Indicators

### Steps:
1. **Logout from Admin**
2. **Login as pivot102@gmail.com**
3. Navigate to **"Work Log"** tab

### ✅ Verify Rejection Display for Task 7:
- [ ] Task 7 appears in **"Rejected Tasks"** section (Red background)
- [ ] **🔴 Red rejection icon** appears before task title ← **REQUIREMENT 3!**
- [ ] **⚠️ Yellow badge** shows "Rejected 1x" ← **REQUIREMENT 3!**
- [ ] **Red box** displays admin remarks ← **REQUIREMENT 3!**
  ```
  ❌ Rejection Reason:
  The fix is incomplete. Please also update the error handling for timeout scenarios.
  ```
- [ ] Task has checkbox enabled (can edit and resubmit)
- [ ] Remarks textarea available

### Expected Result:
✅ **REQUIREMENT 3 TESTED:** Employee sees rejection icon, badge, and admin remarks!

---

## 📋 TEST SCENARIO 9: Multiple Rejection Cycles (RejectionCount Increments)

### Steps (Round 1):
1. **Still as pivot102@gmail.com**
2. Check Task 7 checkbox
3. Enter updated remarks:
   ```
   Fixed timeout error handling with retry logic.
   ```
4. Submit task
5. Logout and login as Admin
6. Reject Task 7 again with remarks:
   ```
   Retry logic needs exponential backoff. Please implement proper delay strategy.
   ```

### ✅ Verify After 2nd Rejection:
7. Login as pivot102@gmail.com
8. Check Task 7 display:
   - [ ] **⚠️ Badge shows "Rejected 2x"** ← Count incremented!
   - [ ] Badge color may change (more prominent for 2+)
   - [ ] New admin remarks visible
   - [ ] Still editable

### Steps (Round 2):
9. Update and resubmit Task 7 with:
   ```
   Implemented exponential backoff with max 3 retries. Added comprehensive unit tests.
   ```
10. Logout, login as Admin
11. **APPROVE** Task 7 this time with remarks:
    ```
    Perfect! Now the error handling is robust. Approved.
    ```

### ✅ Verify Final State:
12. Task 7 moves to **Approved** section
13. RejectionCount remains = 2 (preserved in history)

### Expected Result:
- RejectionCount increments with each rejection
- Historical data preserved even after approval
- Multiple rejection cycles work correctly

---

## 📋 TEST SCENARIO 10: WorkLog History - RejectionCount Display

### Steps:
1. **Login as any employee** (pivot102@gmail.com)
2. Navigate to **"Work Log History"** tab

### ✅ Verify Table Display:
- [ ] **"Times Rejected" column** is visible ← **REQUIREMENT 1!**
- [ ] Column header is **sortable** (click to sort)
- [ ] Column has **filter dropdown** with options:
  - All
  - Never Rejected
  - Rejected (Any)
  - 1 time
  - 2+ times

### ✅ Verify Badge Display:

#### Task 2 (Never Rejected):
- [ ] Shows: **✓ Never** (green text)

#### Task 3 (RejectionCount = 2):
- [ ] Shows: **🔴 2** (red badge, red background)

#### Task 5 (RejectionCount = 1):
- [ ] Shows: **🔴 1** (yellow badge, yellow background)

#### Task 6 (RejectionCount = 3):
- [ ] Shows: **🔴 3** (red badge, darker red background)

#### Task 7 (RejectionCount = 2, now Approved):
- [ ] Shows: **🔴 2** (red badge) ← Count preserved!

### Test Sorting:
3. Click **"Times Rejected"** column header
4. ✅ **Verify:** Table sorts by rejection count (ascending)
5. Click again
6. ✅ **Verify:** Table sorts descending

### Test Filtering:
7. Select **"Never Rejected"** from filter dropdown
8. ✅ **Verify:** Only tasks with RejectionCount = 0 visible
9. Select **"2+ times"**
10. ✅ **Verify:** Only tasks 3, 6, 7 visible (RejectionCount ≥ 2)

### Expected Result:
✅ **REQUIREMENT 1 TESTED:** RejectionCount column displays with filtering and sorting!

---

## 📋 TEST SCENARIO 11: Test Different Employees

### Test pivot104@gmail.com:
1. **Login as pivot104@gmail.com**
2. Navigate to **"Work Log"**

### ✅ Verify Task 5 Display:
- [ ] Task 5 in **"Rejected Tasks"** section
- [ ] 🔴 Red rejection icon
- [ ] ⚠️ Badge: "Rejected 1x" (yellow)
- [ ] Admin remarks visible:
  ```
  Need performance benchmarks before and after optimization
  ```
- [ ] Can edit and resubmit

### Test pivot110@gmail.com:
3. **Login as pivot110@gmail.com**
4. Navigate to **"Work Log"**

### ✅ Verify Task 6 Display:
- [ ] Task 6 in **"Rejected Tasks"** section
- [ ] 🔴 Red rejection icon
- [ ] ⚠️ Badge: "Rejected 3x" (red, prominent)
- [ ] Admin remarks visible:
  ```
  Third rejection: Please follow the coding standards document
  ```
- [ ] Can edit and resubmit

### Expected Result:
- Each employee sees only their own tasks
- Rejection indicators work for all employees
- Different rejection counts display correctly

---

## 📋 TEST SCENARIO 12: Export/Print WorkLog History

### Steps:
1. **Login as any employee**
2. Navigate to **"Work Log History"**
3. Click **"Export to CSV"** button

### ✅ Verify CSV Export:
- [ ] CSV file downloads
- [ ] Open CSV in Excel/Notepad
- [ ] **"Times Rejected"** column present
- [ ] Values match UI display (0, 1, 2, 3, etc.)

4. Click **"Print"** button

### ✅ Verify Print Preview:
- [ ] Print dialog opens
- [ ] Preview shows table
- [ ] **"Times Rejected"** column visible in print

### Expected Result:
- Export includes rejection count data
- Print preview displays all columns

---

## 📋 TEST SCENARIO 13: Admin Views Task Overview

### Steps:
1. **Login as Admin**
2. Navigate to **"Admin Dashboard" → "Tasks Overview"** tab

### ✅ Verify Overview Display:
- [ ] Total tasks count
- [ ] Pending tasks count
- [ ] Completed tasks count
- [ ] Approved tasks count
- [ ] Rejected tasks count
- [ ] List of all tasks with statuses

### ✅ Verify Task Details:
- [ ] Each task shows:
  - Title
  - Assigned employee
  - Status
  - Priority
  - Due date
  - RejectionCount (if applicable)

### Expected Result:
- Admin can see overview of all tasks
- Status tracking works across all employees
- Rejection counts visible in overview

---

## 📋 TEST SCENARIO 14: Edge Cases & Error Handling

### Test 1: Submit Empty Task
1. Login as employee
2. Try to submit task without selecting any checkbox
3. ✅ **Verify:** Appropriate message (no tasks selected)

### Test 2: Submit Without Remarks (Optional)
4. Select a pending task
5. Leave remarks empty
6. Submit
7. ✅ **Verify:** Submission works (remarks are optional for employee)

### Test 3: Revoke Non-Completed Task
8. Try to find revoke button on Pending task
9. ✅ **Verify:** Revoke button NOT visible (only on Completed)

### Test 4: Revoke Approved Task
10. Look at Approved task
11. ✅ **Verify:** No revoke button (cannot revoke approved tasks)

### Test 5: Modify Completed Task
12. Try to check/uncheck checkbox on Completed task
13. ✅ **Verify:** Checkbox is disabled (cannot modify)

### Test 6: Approve Already Approved Task
14. Login as Admin
15. Go to Approved section
16. ✅ **Verify:** No action buttons (already approved)

### Expected Result:
- Proper validation at all steps
- Edge cases handled gracefully
- No data corruption

---

## 📋 TEST SCENARIO 15: Real-World Complete Flow

### Complete Journey of One Task:

**Day 1 - Assignment:**
1. Admin assigns "Fix Database Bug" to pivot102@gmail.com
2. Employee logs in, sees task in Pending

**Day 2 - First Attempt:**
3. Employee submits task with remarks
4. Admin reviews and rejects: "Missing unit tests"
5. RejectionCount = 1

**Day 3 - Second Attempt:**
6. Employee sees rejection (🔴 icon, ⚠️ badge)
7. Employee adds unit tests and resubmits
8. Admin reviews and rejects: "Test coverage insufficient"
9. RejectionCount = 2

**Day 4 - Third Attempt:**
10. Employee adds comprehensive tests
11. Employee submits
12. **Before admin reviews**, employee realizes mistake
13. Employee clicks **Revoke button**
14. Task back to Pending, no rejection count change

**Day 5 - Final Submission:**
15. Employee fixes mistake and resubmits
16. Admin reviews and **Approves**: "Excellent work!"
17. Task status = Approved
18. RejectionCount = 2 (preserved in history)

### ✅ Verify Throughout:
- [ ] All status transitions work correctly
- [ ] RejectionCount updates properly
- [ ] Revoke works as expected
- [ ] Historical data preserved
- [ ] All UI indicators display correctly

---

## 🎯 FINAL CHECKLIST - All 4 Requirements

### ✅ Requirement 1: RejectionCount in WorkLogHistory
- [ ] Column displays in history table
- [ ] Sortable by clicking header
- [ ] Filter dropdown works (All, Never, Rejected, 1 time, 2+)
- [ ] Colored badges (Yellow for 1, Red for 2+)
- [ ] Included in CSV export
- [ ] Visible in print preview

### ✅ Requirement 2: AdminRemarks Validation
- [ ] Rejection WITHOUT remarks → Error message
- [ ] Rejection WITH remarks → Success
- [ ] Approval WITHOUT remarks → Success (optional)
- [ ] Approval WITH remarks → Success (optional)

### ✅ Requirement 3: Employee Rejection Display
- [ ] 🔴 Red rejection icon visible
- [ ] ⚠️ Rejection count badge visible
- [ ] Badge shows correct count (1x, 2x, 3x, etc.)
- [ ] Red box displays admin remarks
- [ ] Clear rejection reason label
- [ ] All indicators update with each rejection

### ✅ Requirement 4: Employee Revoke Functionality
- [ ] Revoke button appears on Completed tasks
- [ ] Revoke button NOT on Pending/Approved/Rejected
- [ ] Click revoke → Confirmation dialog
- [ ] After revoke → Task returns to Pending
- [ ] After revoke → Remarks cleared
- [ ] After revoke → Task becomes editable

---

## 📊 Test Results Summary

Fill this out as you test:

| Scenario | Status | Notes |
|----------|--------|-------|
| 1. Admin Assigns Task | ⬜ | |
| 2. Employee Views Tasks | ⬜ | |
| 3. Employee Submits Task | ⬜ | |
| 4. Employee Revokes Task | ⬜ | |
| 5. Employee Resubmits Task | ⬜ | |
| 6. Admin Approves (Optional Remarks) | ⬜ | |
| 7. Admin Rejects (Mandatory Remarks) | ⬜ | |
| 8. Employee Sees Rejection UI | ⬜ | |
| 9. Multiple Rejection Cycles | ⬜ | |
| 10. WorkLog History Display | ⬜ | |
| 11. Different Employees | ⬜ | |
| 12. Export/Print | ⬜ | |
| 13. Admin Task Overview | ⬜ | |
| 14. Edge Cases | ⬜ | |
| 15. Real-World Flow | ⬜ | |

### Final Result: ⬜ PASS / ⬜ FAIL

---

## 🐛 Issues Found (If Any)

Record any bugs or issues discovered during testing:

1. **Issue:**
   - **Steps to Reproduce:**
   - **Expected:**
   - **Actual:**
   - **Severity:** High / Medium / Low

---

## ✅ **START TESTING NOW!**

**Recommended Order:**
1. Start with Scenario 1-5 (Basic flow)
2. Then Scenario 6-9 (Approval/Rejection)
3. Then Scenario 10 (History verification)
4. Then Scenario 11-14 (Additional tests)
5. Finally Scenario 15 (Complete journey)

**Good luck with testing! 🚀**
