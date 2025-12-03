# Backend Deployment Script for VPS
# Deploys the fixed backend to 72.61.226.129:5001

param(
    [string]$VpsUser = "root",
    [string]$VpsHost = "72.61.226.129",
    [string]$BackendPath = "/root/attendance-backend"
)

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   BACKEND DEPLOYMENT - TIMEZONE FIX" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Step 1: Compress backend build
Write-Host "📦 Step 1: Compressing backend build..." -ForegroundColor Yellow
$buildPath = "p:\SourceCode-PIVOT\DeskAttendanceApp\backend\publish-win"
$zipPath = "p:\SourceCode-PIVOT\DeskAttendanceApp\backend\backend-deploy.zip"

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path "$buildPath\*" -DestinationPath $zipPath -Force
Write-Host "✅ Backend compressed: $zipPath`n" -ForegroundColor Green

# Display file size
$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "   Size: $([math]::Round($zipSize, 2)) MB`n" -ForegroundColor Gray

# Step 2: Instructions for VPS deployment
Write-Host "📤 Step 2: Upload to VPS" -ForegroundColor Yellow
Write-Host "   You need to upload the zip file to VPS using one of these methods:`n" -ForegroundColor Gray

Write-Host "   Method 1 - Using SCP (if you have SSH access):" -ForegroundColor Cyan
Write-Host "   scp `"$zipPath`" ${VpsUser}@${VpsHost}:/root/backend-deploy.zip`n" -ForegroundColor White

Write-Host "   Method 2 - Using WinSCP (GUI tool):" -ForegroundColor Cyan
Write-Host "   - Open WinSCP" -ForegroundColor White
Write-Host "   - Connect to: $VpsHost" -ForegroundColor White
Write-Host "   - Upload: $zipPath" -ForegroundColor White
Write-Host "   - To: /root/backend-deploy.zip`n" -ForegroundColor White

Write-Host "   Method 3 - Using RDP (if Windows VPS):" -ForegroundColor Cyan
Write-Host "   - Connect via Remote Desktop to $VpsHost" -ForegroundColor White
Write-Host "   - Copy the zip file directly`n" -ForegroundColor White

# Step 3: VPS commands
Write-Host "🔧 Step 3: Run these commands on VPS (SSH/RDP)" -ForegroundColor Yellow
Write-Host "   After uploading, execute these commands on the VPS:`n" -ForegroundColor Gray

$vpsCommands = @"
# Stop the backend service
sudo systemctl stop attendance-backend
# OR if using pm2:
# pm2 stop attendance-backend

# Backup current backend
cd /root
if [ -d "attendance-backend-backup" ]; then rm -rf attendance-backend-backup; fi
if [ -d "attendance-backend" ]; then mv attendance-backend attendance-backend-backup; fi

# Extract new backend
mkdir -p attendance-backend
unzip -o backend-deploy.zip -d attendance-backend/
chmod +x attendance-backend/backend

# Restart backend service
sudo systemctl start attendance-backend
# OR if using pm2:
# cd attendance-backend && pm2 start backend --name attendance-backend

# Check status
sudo systemctl status attendance-backend
# OR:
# pm2 status

# View logs
sudo journalctl -u attendance-backend -f
# OR:
# pm2 logs attendance-backend
"@

Write-Host $vpsCommands -ForegroundColor White

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "✅ What was fixed:" -ForegroundColor Green
Write-Host "   - Removed double timezone conversion in AttendanceController.cs" -ForegroundColor White
Write-Host "   - Removed double timezone conversion in AdminController.cs" -ForegroundColor White
Write-Host "   - Backend now stores UTC timestamps as-is (no conversion)" -ForegroundColor White
Write-Host "   - Frontend handles all timezone conversions (UTC ↔ IST)`n" -ForegroundColor White

Write-Host "📋 Expected behavior after deployment:" -ForegroundColor Green
Write-Host "   - Enter time: 17:03 IST" -ForegroundColor White
Write-Host "   - Frontend converts: 17:03 - 5:30 = 11:33 UTC" -ForegroundColor White
Write-Host "   - Backend stores: 11:33 UTC (no conversion)" -ForegroundColor White
Write-Host "   - Backend returns: 11:33 UTC" -ForegroundColor White
Write-Host "   - Frontend displays: 11:33 + 5:30 = 17:03 IST ✅`n" -ForegroundColor White

Write-Host "⚠️  Important:" -ForegroundColor Yellow
Write-Host "   - Existing wrong data in database won't be fixed automatically" -ForegroundColor White
Write-Host "   - New attendance entries will work correctly" -ForegroundColor White
Write-Host "   - You may need to manually fix old records if needed`n" -ForegroundColor White

Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "Press any key to open the build folder..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
explorer.exe (Split-Path $zipPath -Parent)
