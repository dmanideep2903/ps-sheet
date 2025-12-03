# Stop any running backend processes
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Starting Backend Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir "backend"

Write-Host "Backend directory: $backendDir" -ForegroundColor Yellow
Write-Host ""

# Kill any existing backend processes
Write-Host "Checking for existing backend processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*backend*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Change to backend directory
Set-Location -Path $backendDir

Write-Host ""
Write-Host "Starting backend on http://localhost:5001..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the backend
dotnet run
