#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start Employee TimePulse as a web application accessible via localtunnel

.DESCRIPTION
    This script:
    1. Starts the ASP.NET Core backend (port 5001)
    2. Starts the React development server (port 3000)
    3. Creates a localtunnel to share the app with colleagues
    
.NOTES
    All colleagues need:
    - Modern browser (Chrome/Edge/Firefox)
    - Camera permission when prompted
    - The localtunnel URL you share with them
#>

Write-Host "`n" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "      EMPLOYEE TIMEPULSE - WEB APP STARTUP" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if localtunnel is installed
$ltInstalled = Get-Command lt -ErrorAction SilentlyContinue
if (-not $ltInstalled) {
    Write-Host "❌ localtunnel is not installed!" -ForegroundColor Red
    Write-Host "   Installing localtunnel..." -ForegroundColor Yellow
    npm install -g localtunnel
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Failed to install localtunnel. Please run: npm install -g localtunnel" -ForegroundColor Red
        exit 1
    }
}

# Kill any existing processes on our ports
Write-Host "🔍 Checking for existing processes..." -ForegroundColor Cyan
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
$port5001 = Get-NetTCPConnection -LocalPort 5001 -ErrorAction SilentlyContinue

if ($port3000) {
    Write-Host "   Stopping process on port 3000..." -ForegroundColor Yellow
    taskkill /F /PID $port3000.OwningProcess 2>$null
}
if ($port5001) {
    Write-Host "   Stopping process on port 5001..." -ForegroundColor Yellow
    taskkill /F /PID $port5001.OwningProcess 2>$null
}

Start-Sleep -Seconds 1

# Clean backend publish folder if exists
$publishPath = "P:\SourceCode-HM\DeskAttendanceApp\backend\publish"
if (Test-Path $publishPath) {
    Write-Host "🧹 Cleaning old backend publish folder..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force $publishPath -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  STEP 1: Starting Backend (Port 5001)" -ForegroundColor White
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Start backend in new window
$backendPath = "P:\SourceCode-HM\DeskAttendanceApp\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; Write-Host 'Starting ASP.NET Core Backend...' -ForegroundColor Green; dotnet run" -WindowStyle Normal

Write-Host "✅ Backend starting in separate window..." -ForegroundColor Green
Write-Host "   Waiting 10 seconds for backend to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Test backend
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5001/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Backend is responding!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend health check failed, but continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
Write-Host "  STEP 2: Starting React App (Port 3000)" -ForegroundColor White
Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""

# Start React in new window
$reactPath = "P:\SourceCode-HM\DeskAttendanceApp\react-app"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$reactPath'; Write-Host 'Starting React Development Server...' -ForegroundColor Blue; `$env:BROWSER='none'; npm start" -WindowStyle Normal

Write-Host "✅ React app starting in separate window..." -ForegroundColor Blue
Write-Host "   Waiting 20 seconds for React to compile..." -ForegroundColor Cyan
Start-Sleep -Seconds 20

# Test React
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ React app is responding!" -ForegroundColor Blue
} catch {
    Write-Host "⚠️  React app health check failed, but continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  STEP 3: Creating Public Tunnel" -ForegroundColor White
Write-Host "════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

Write-Host "🌐 Starting localtunnel on port 3000..." -ForegroundColor Magenta
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ WEB APP IS READY!" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📋 IMPORTANT INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Copy the localtunnel URL that appears below" -ForegroundColor White
Write-Host "2. Share this URL with your colleagues" -ForegroundColor White
Write-Host "3. They can access the app from any browser" -ForegroundColor White
Write-Host "4. Camera permission will be requested (click Allow)" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  YOUR PUBLIC URL (Copy this and share):" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Start localtunnel (this will block and show the URL)
lt --port 3000 --subdomain markaudio-attendance

# This line only runs if localtunnel is stopped
Write-Host ""
Write-Host "🛑 Localtunnel stopped. Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
