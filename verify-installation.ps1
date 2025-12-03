# Company Attendance App - Installation Verification Script
# Run this script on the target system BEFORE installing the app

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Company Attendance App - System Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allGood = $true

# Check 1: .NET Runtime (Optional - bundled in app)
Write-Host "Checking .NET Runtime..." -NoNewline
Write-Host " ⓘ OPTIONAL" -ForegroundColor Cyan
Write-Host "  .NET Runtime is bundled with the app" -ForegroundColor Gray
try {
    $dotnetVersion = & dotnet --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $dotnetVersion) {
        Write-Host "  Found installed version: $dotnetVersion" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Not installed (OK - bundled with app)" -ForegroundColor Gray
}

# Check 2: SQL Server LocalDB
Write-Host "`nChecking SQL Server LocalDB..." -NoNewline
try {
    $sqlLocalDB = & sqllocaldb info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓ PASS" -ForegroundColor Green
        Write-Host "  Instances: $($sqlLocalDB -join ', ')" -ForegroundColor Gray
        
        # Try to start mssqllocaldb if it exists
        if ($sqlLocalDB -contains "mssqllocaldb") {
            $startResult = & sqllocaldb start mssqllocaldb 2>&1
            Write-Host "  Started instance: mssqllocaldb" -ForegroundColor Gray
        }
    } else {
        throw "Not found"
    }
} catch {
    Write-Host " ✗ FAIL" -ForegroundColor Red
    Write-Host "  SQL Server LocalDB is required" -ForegroundColor Yellow
    Write-Host "  Download: https://aka.ms/ssmsfullsetup" -ForegroundColor Yellow
    $allGood = $false
}

# Check 3: Port 5001 availability
Write-Host "`nChecking Port 5001..." -NoNewline
$portInUse = Get-NetTCPConnection -LocalPort 5001 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host " ✗ WARNING" -ForegroundColor Yellow
    Write-Host "  Port 5001 is already in use by process: $($portInUse.OwningProcess)" -ForegroundColor Yellow
    Write-Host "  You may need to stop this process or change the app's port" -ForegroundColor Yellow
} else {
    Write-Host " ✓ PASS" -ForegroundColor Green
    Write-Host "  Port 5001 is available" -ForegroundColor Gray
}

# Check 4: Windows version
Write-Host "`nChecking Windows version..." -NoNewline
$osInfo = Get-CimInstance Win32_OperatingSystem
$osVersion = $osInfo.Caption
$osArch = $osInfo.OSArchitecture
if ($osArch -eq "64-bit") {
    Write-Host " ✓ PASS" -ForegroundColor Green
    Write-Host "  $osVersion ($osArch)" -ForegroundColor Gray
} else {
    Write-Host " ✗ FAIL" -ForegroundColor Red
    Write-Host "  64-bit Windows is required" -ForegroundColor Yellow
    $allGood = $false
}

# Check 5: Disk space
Write-Host "`nChecking available disk space..." -NoNewline
$drive = Get-PSDrive C
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
if ($freeSpaceGB -gt 1) {
    Write-Host " ✓ PASS" -ForegroundColor Green
    Write-Host "  Available: ${freeSpaceGB} GB" -ForegroundColor Gray
} else {
    Write-Host " ✗ WARNING" -ForegroundColor Yellow
    Write-Host "  Low disk space: ${freeSpaceGB} GB" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✓ System Ready for Installation" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "You can proceed with installing the application." -ForegroundColor Green
} else {
    Write-Host "✗ System Not Ready" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "Please install the missing prerequisites before installing the app." -ForegroundColor Yellow
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
