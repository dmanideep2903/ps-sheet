#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Share your running app via localtunnel

.DESCRIPTION
    Creates a public URL for your localhost:3000 app
    Requires: React app already running on port 3000
#>

Write-Host "`n" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "      SHARING APP VIA LOCALTUNNEL" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if port 3000 is in use
$port3000 = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
if (-not $port3000) {
    Write-Host "❌ ERROR: React app is not running on port 3000!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the app first:" -ForegroundColor Yellow
    Write-Host "   1. Backend: cd backend; dotnet run" -ForegroundColor White
    Write-Host "   2. React:   cd react-app; npm start" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run: .\START_WEB_APP.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✅ React app detected on port 3000" -ForegroundColor Green
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Creating Public Tunnel..." -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "   1. Copy the URL that appears below" -ForegroundColor White
Write-Host "   2. Share this URL with your colleagues" -ForegroundColor White
Write-Host "   3. They can access the app from any browser" -ForegroundColor White
Write-Host "   4. Camera permission will be requested" -ForegroundColor White
Write-Host ""
Write-Host "Keep this window open as long as you want to share!" -ForegroundColor Yellow
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  YOUR PUBLIC URL:" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Start localtunnel
lt --port 3000 --subdomain markaudio-attendance

Write-Host ""
Write-Host "🛑 Tunnel stopped. Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
