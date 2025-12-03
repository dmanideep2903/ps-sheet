# ====================================================================
# TIMEZONE FIX DEPLOYMENT - Removes Timezone=Asia/Kolkata from DB connection
# ====================================================================
# Issue: Backend was adding Timezone=Asia/Kolkata in Program.cs
#        causing PostgreSQL to return timestamps WITHOUT timezone indicator
#        Frontend was then treating them as local time instead of UTC
#
# Fix: Removed ";Timezone=Asia/Kolkata" from connection string
#      Now backend returns proper UTC timestamps with 'Z' suffix
#
# Expected Result: Timestamps display correctly in IST (+5:30 from UTC)
# ====================================================================

$VPS_IP = "72.61.226.129"
$VPS_USER = "pivot"
$VPS_PATH = "/home/pivot/app/backend"
$LOCAL_ZIP = "P:\SourceCode-PIVOT\DeskAttendanceApp\backend\backend-TIMEZONE-FIX.zip"
$EXPECTED_HASH = "849FD385D7D0E7F1CA4A69355FA020C6"

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "  TIMEZONE FIX DEPLOYMENT - Backend Update" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Issue: Timestamps missing UTC indicator ('Z' suffix)" -ForegroundColor Yellow
Write-Host "  Fix: Removed Timezone=Asia/Kolkata from connection string" -ForegroundColor Green
Write-Host "==================================================================`n" -ForegroundColor Cyan

# Step 1: Verify local file
Write-Host "[1/7] Verifying local deployment package..." -ForegroundColor Cyan
if (-not (Test-Path $LOCAL_ZIP)) {
    Write-Host "  ERROR: File not found: $LOCAL_ZIP" -ForegroundColor Red
    exit 1
}

$actualHash = (Get-FileHash $LOCAL_ZIP -Algorithm MD5).Hash
if ($actualHash -ne $EXPECTED_HASH) {
    Write-Host "  ERROR: Hash mismatch!" -ForegroundColor Red
    Write-Host "    Expected: $EXPECTED_HASH" -ForegroundColor Yellow
    Write-Host "    Got: $actualHash" -ForegroundColor Yellow
    exit 1
}
Write-Host "  OK: Hash verified: $actualHash" -ForegroundColor Green

# Step 2: Upload to VPS
Write-Host "`n[2/7] Uploading to VPS..." -ForegroundColor Cyan
scp $LOCAL_ZIP "${VPS_USER}@${VPS_IP}:/tmp/backend-TIMEZONE-FIX.zip"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Upload failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  OK: Uploaded successfully" -ForegroundColor Green

# Step 3: Stop backend service
Write-Host "`n[3/7] Stopping backend service..." -ForegroundColor Cyan
ssh "${VPS_USER}@${VPS_IP}" "sudo systemctl stop deskattendance"
Write-Host "  OK: Service stopped" -ForegroundColor Green

# Step 4: Backup current version
Write-Host "`n[4/7] Backing up current version..." -ForegroundColor Cyan
$backupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
ssh "${VPS_USER}@${VPS_IP}" "cd $VPS_PATH && cd .. && cp -r backend $backupName"
Write-Host "  OK: Backup created: $backupName" -ForegroundColor Green

# Step 5: Deploy new version
Write-Host "`n[5/7] Deploying new backend..." -ForegroundColor Cyan
ssh "${VPS_USER}@${VPS_IP}" @"
cd $VPS_PATH && \
rm -rf * && \
unzip -q /tmp/backend-TIMEZONE-FIX.zip && \
chmod +x backend && \
rm /tmp/backend-TIMEZONE-FIX.zip
"@
Write-Host "  OK: Files deployed" -ForegroundColor Green

# Step 6: Start backend service
Write-Host "`n[6/7] Starting backend service..." -ForegroundColor Cyan
ssh "${VPS_USER}@${VPS_IP}" "sudo systemctl start deskattendance"
Start-Sleep -Seconds 3
Write-Host "  OK: Service started" -ForegroundColor Green

# Step 7: Verify deployment
Write-Host "`n[7/7] Verifying deployment..." -ForegroundColor Cyan

Write-Host "  Checking service status..." -ForegroundColor Gray
$status = ssh "${VPS_USER}@${VPS_IP}" "sudo systemctl is-active deskattendance"
if ($status -ne "active") {
    Write-Host "    ERROR: Service not running!" -ForegroundColor Red
    ssh "${VPS_USER}@${VPS_IP}" "sudo journalctl -u deskattendance -n 50 --no-pager"
    exit 1
}
Write-Host "    Service: $status" -ForegroundColor Green

Write-Host "  Checking backend health..." -ForegroundColor Gray
Start-Sleep -Seconds 2
try {
    $health = Invoke-RestMethod -Uri "http://${VPS_IP}:5001/health" -TimeoutSec 5
    Write-Host "    Health: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "    WARNING: Health check failed - $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "  Verifying DLL hash on VPS..." -ForegroundColor Gray
$vpsHash = ssh "${VPS_USER}@${VPS_IP}" "md5sum $VPS_PATH/backend.dll | cut -d' ' -f1"
Write-Host "    VPS DLL Hash: $vpsHash" -ForegroundColor Green

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "  Backend deployed with TIMEZONE FIX" -ForegroundColor Cyan
Write-Host "  - Removed: Timezone=Asia/Kolkata from connection" -ForegroundColor Yellow
Write-Host "  - Backend now returns: UTC timestamps with 'Z' suffix" -ForegroundColor Yellow
Write-Host "  - Frontend will: Add +5:30 hours for IST display" -ForegroundColor Yellow
Write-Host "`n  TEST: Create new attendance record and check console logs" -ForegroundColor Cyan
Write-Host "  Expected: Timestamps with 'Z' like '2025-12-14T07:16:00.000Z'" -ForegroundColor Green
Write-Host "==================================================================`n" -ForegroundColor Green
