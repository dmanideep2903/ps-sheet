-- =====================================================
-- MIGRATION: Convert ALL IST Timestamps to UTC
-- Run this ONCE on your PostgreSQL database
-- =====================================================

-- This migration assumes existing timestamps are in IST
-- and converts them to UTC by subtracting 5 hours 30 minutes

BEGIN;

-- 1. AttendanceRecords table
UPDATE "AttendanceRecords"
SET 
    "Timestamp" = "Timestamp" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
WHERE "Timestamp" IS NOT NULL;

-- 2. TaskAssignments table  
UPDATE "TaskAssignments"
SET 
    "CreatedAt" = "CreatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC',
    "UpdatedAt" = "UpdatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC',
    "DueDate" = "DueDate" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC',
    "CompletedDate" = CASE WHEN "CompletedDate" IS NOT NULL 
                          THEN "CompletedDate" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
                          ELSE NULL END,
    "ApprovedDate" = CASE WHEN "ApprovedDate" IS NOT NULL 
                         THEN "ApprovedDate" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
                         ELSE NULL END,
    "RejectedDate" = CASE WHEN "RejectedDate" IS NOT NULL 
                         THEN "RejectedDate" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
                         ELSE NULL END
WHERE "CreatedAt" IS NOT NULL;

-- 3. WorkLogs table
UPDATE "WorkLogs"
SET 
    "CreatedAt" = "CreatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC',
    "UpdatedAt" = "UpdatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC',
    "ApprovalTime" = CASE WHEN "ApprovalTime" IS NOT NULL 
                         THEN "ApprovalTime" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
                         ELSE NULL END
WHERE "CreatedAt" IS NOT NULL;

-- 4. UserProfiles table
UPDATE "UserProfiles"
SET 
    "CreatedAt" = "CreatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC',
    "UpdatedAt" = "UpdatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
WHERE "CreatedAt" IS NOT NULL;

-- 5. SystemSettings table
UPDATE "SystemSettings"
SET 
    "UpdatedAt" = "UpdatedAt" AT TIME ZONE 'Asia/Kolkata' AT TIME ZONE 'UTC'
WHERE "UpdatedAt" IS NOT NULL;

COMMIT;

-- Verify the migration (run separately to check results)
SELECT 'AttendanceRecords' as table_name, COUNT(*) as count, MIN("Timestamp") as earliest, MAX("Timestamp") as latest FROM "AttendanceRecords"
UNION ALL
SELECT 'TaskAssignments', COUNT(*), MIN("CreatedAt"), MAX("CreatedAt") FROM "TaskAssignments"
UNION ALL
SELECT 'WorkLogs', COUNT(*), MIN("CreatedAt"), MAX("CreatedAt") FROM "WorkLogs";
