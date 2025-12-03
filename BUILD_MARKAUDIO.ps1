# ========================================
# MarkAudio Installer Build Script
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "`n=========================================`n" -ForegroundColor Cyan
Write-Host "  MarkAudio Installer Builder" -ForegroundColor Cyan
Write-Host "`n=========================================`n" -ForegroundColor Cyan

# Step 1: Build React App
Write-Host "[Step 1/5] Building React App..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\react-app"

if (Test-Path "build") {
    Remove-Item -Recurse -Force build
}

Write-Host "  Running npm run build..." -ForegroundColor Gray
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "React build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  SUCCESS: React build complete`n" -ForegroundColor Green

# Step 2: Copy React build to Electron app
Write-Host "[Step 2/5] Copying React build to Electron app..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\electron-app"

if (Test-Path "build") {
    Remove-Item -Recurse -Force build
}
Copy-Item -Recurse ..\react-app\build .\
Write-Host "  SUCCESS: React build copied`n" -ForegroundColor Green

# Step 3: Publish Backend
Write-Host "[Step 3/5] Publishing Backend for Windows..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\backend"

if (Test-Path "publish") {
    Remove-Item -Recurse -Force publish
}

Write-Host "  Running dotnet publish..." -ForegroundColor Gray
dotnet publish -c Release -r win-x64 --self-contained true -o publish
if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend publish failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  Copying backend to electron-app..." -ForegroundColor Gray
Set-Location "$PSScriptRoot\electron-app"
if (Test-Path "backend") {
    Remove-Item -Recurse -Force backend
}
Copy-Item -Recurse ..\backend\publish backend

# Create Data folder for SQLite database
if (-not (Test-Path "backend\Data")) {
    New-Item -ItemType Directory -Path "backend\Data" -Force | Out-Null
}

Write-Host "  SUCCESS: Backend published`n" -ForegroundColor Green

# Step 4: Configure for MarkAudio
Write-Host "[Step 4/5] Configuring for MarkAudio..." -ForegroundColor Cyan

# Backup current appConfig.json
if (Test-Path "appConfig.json") {
    Copy-Item appConfig.json appConfig.json.backup -Force
}

# Use MarkAudio config
if (Test-Path "appConfig-MarkAudio.json") {
    Copy-Item appConfig-MarkAudio.json appConfig.json -Force
    Write-Host "  Using config: appConfig-MarkAudio.json" -ForegroundColor Gray
    
    $config = Get-Content appConfig.json | ConvertFrom-Json
    Write-Host "  Company ID: $($config.companyId)" -ForegroundColor Gray
    Write-Host "  Company Name: $($config.companyName)" -ForegroundColor Gray
    Write-Host "  API URL: $($config.apiBaseUrl)" -ForegroundColor Gray
} else {
    Write-Host "  WARNING: appConfig-MarkAudio.json not found, using default" -ForegroundColor Yellow
}

Write-Host "  SUCCESS: Configuration set`n" -ForegroundColor Green

# Step 5: Build Electron installer
Write-Host "[Step 5/5] Building MarkAudio installer..." -ForegroundColor Cyan
Write-Host "  Running electron-builder (this may take 2-3 minutes)..." -ForegroundColor Gray

npm run dist

if ($LASTEXITCODE -eq 0) {
    # Find and rename the installer
    $originalExe = Get-ChildItem -Path "dist" -Filter "*.exe" | Select-Object -First 1
    if ($originalExe) {
        $newName = "MarkAudio-Setup-1.1.0.exe"
        $newPath = Join-Path "dist" $newName
        
        if (Test-Path $newPath) {
            Remove-Item $newPath -Force
        }
        
        Move-Item $originalExe.FullName $newPath -Force
        
        $fileSize = [math]::Round((Get-Item $newPath).Length / 1MB, 2)
        Write-Host "`n  SUCCESS: Installer created!" -ForegroundColor Green
        Write-Host "  Location: electron-app\dist\$newName" -ForegroundColor Green
        Write-Host "  Size: $fileSize MB`n" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Installer .exe not found in dist folder" -ForegroundColor Red
    }
} else {
    Write-Host "  ERROR: Build failed" -ForegroundColor Red
}

# Restore original appConfig.json
if (Test-Path "appConfig.json.backup") {
    Move-Item appConfig.json.backup appConfig.json -Force
}

Write-Host "`n=========================================`n" -ForegroundColor Cyan
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "`n=========================================`n" -ForegroundColor Cyan

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test: Install MarkAudio-Setup-1.1.0.exe" -ForegroundColor White
Write-Host "  2. Verify app starts without errors" -ForegroundColor White
Write-Host "  3. Test login and basic features`n" -ForegroundColor White

Write-Host "NOTE: Using SQLite database (no PostgreSQL needed)" -ForegroundColor Yellow
Write-Host "Database will be created at: %APPDATA%\MarkAudio\Data\AttendanceDb.sqlite`n" -ForegroundColor Yellow
