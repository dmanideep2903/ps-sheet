# PostgreSQL Database Backup Script
# Run this daily to backup your attendance database

$backupFolder = "DatabaseBackups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFile = "$backupFolder\AttendanceDb_$timestamp.sql"

# Create backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
    Write-Host "Created backup folder: $backupFolder" -ForegroundColor Green
}

# Check if Docker container is running
$containerStatus = docker ps --filter "name=attendance-postgres" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "ERROR: PostgreSQL container is not running!" -ForegroundColor Red
    Write-Host "  Start it with: docker start attendance-postgres" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nStarting database backup..." -ForegroundColor Cyan

# Create backup
try {
    docker exec attendance-postgres pg_dump -U postgres AttendanceDb > $backupFile
    
    $fileSize = (Get-Item $backupFile).Length / 1KB
    Write-Host "SUCCESS: Backup created!" -ForegroundColor Green
    Write-Host "  File: $backupFile" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor White
    
    # Keep only last 7 backups
    Get-ChildItem $backupFolder -Filter "*.sql" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -Skip 7 | 
        Remove-Item -Force
    
    $backupCount = (Get-ChildItem $backupFolder -Filter "*.sql").Count
    Write-Host "  Total backups: $backupCount (keeping last 7)" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: Backup failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nBackup complete!`n" -ForegroundColor Green
