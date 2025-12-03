# ========================================
# MarkAudio Quick Build Script
# ========================================
# Assumes React is already built

$ErrorActionPreference = "Stop"

Write-Host "`n=========================================`n" -ForegroundColor Cyan
Write-Host "  MarkAudio Installer Builder (Quick)" -ForegroundColor Cyan
Write-Host "`n=========================================`n" -ForegroundColor Cyan

Set-Location "$PSScriptRoot\electron-app"

# Step 1: Copy React build (if exists)
Write-Host "[Step 1/4] Checking React build..." -ForegroundColor Cyan
if (Test-Path "..\react-app\build") {
    if (Test-Path "build") {
        Remove-Item -Recurse -Force build
    }
    Copy-Item -Recurse ..\react-app\build .\
    Write-Host "  SUCCESS: React build copied`n" -ForegroundColor Green
} else {
    Write-Host "  WARNING: React build not found, skipping`n" -ForegroundColor Yellow
}

# Step 2: Publish Backend
Write-Host "[Step 2/4] Publishing Backend for Windows..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\backend"

if (Test-Path "publish") {
    Remove-Item -Recurse -Force publish
}

Write-Host "  Running dotnet publish (this takes 1-2 minutes)..." -ForegroundColor Gray
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

# Step 3: Configure for MarkAudio
Write-Host "[Step 3/4] Configuring for MarkAudio..." -ForegroundColor Cyan

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

# Step 4: Build Electron installer
Write-Host "[Step 4/4] Building MarkAudio installer..." -ForegroundColor Cyan
Write-Host "  Running electron-builder (this may take 2-3 minutes)..." -ForegroundColor Gray
Write-Host "  Please wait...`n" -ForegroundColor Gray

# Clean old installers
if (Test-Path "dist") {
    Remove-Item dist\*.exe -Force -ErrorAction SilentlyContinue
}

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
        Write-Host "`n=========================================`n" -ForegroundColor Green
        Write-Host "  SUCCESS! Installer Created!" -ForegroundColor Green
        Write-Host "`n=========================================`n" -ForegroundColor Green
        Write-Host "Location: electron-app\dist\$newName" -ForegroundColor Cyan
        Write-Host "Size: $fileSize MB`n" -ForegroundColor Cyan
    } else {
        Write-Host "`n  ERROR: Installer .exe not found in dist folder" -ForegroundColor Red
    }
} else {
    Write-Host "`n  ERROR: Build failed" -ForegroundColor Red
}

# Restore original appConfig.json
if (Test-Path "appConfig.json.backup") {
    Move-Item appConfig.json.backup appConfig.json -Force
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Install: electron-app\dist\MarkAudio-Setup-1.1.0.exe" -ForegroundColor White
Write-Host "  2. Run the app and verify no errors" -ForegroundColor White
Write-Host "  3. Login with admin credentials`n" -ForegroundColor White

Write-Host "Database Info:" -ForegroundColor Yellow
Write-Host "  Type: SQLite (no PostgreSQL needed)" -ForegroundColor White
Write-Host "  Location: Created automatically in app data folder`n" -ForegroundColor White
