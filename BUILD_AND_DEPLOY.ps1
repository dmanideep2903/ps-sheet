# Build and Deploy Script
# This script builds the React app and copies it to electron-app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Build & Deploy React App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reactDir = Join-Path $scriptDir "react-app"
$electronDir = Join-Path $scriptDir "electron-app"

# Build React app
Write-Host "Building React app..." -ForegroundColor Yellow
Set-Location -Path $reactDir
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build failed!" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# Copy to electron-app
Write-Host "Copying build to electron-app..." -ForegroundColor Yellow
$electronBuildDir = Join-Path $electronDir "build"

# Remove old build
if (Test-Path $electronBuildDir) {
    Remove-Item -Path $electronBuildDir -Recurse -Force
}

# Copy new build
Copy-Item -Path (Join-Path $reactDir "build") -Destination $electronBuildDir -Recurse

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "React app built and copied to electron-app/build" -ForegroundColor Green
Write-Host ""

pause
