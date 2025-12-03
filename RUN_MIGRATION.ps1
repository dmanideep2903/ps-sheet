# =====================================================
# Run IST to UTC Migration on Hostinger PostgreSQL
# =====================================================

$server = "72.61.226.129"
$username = "root"
$dbPassword = "Pivot@9492989700"
$dbUser = "attendanceuser"
$database = "attendancedb"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "IST TO UTC TIMESTAMP MIGRATION" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will convert ALL existing timestamps from IST to UTC" -ForegroundColor Yellow
Write-Host "Database: $database on $server" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Type 'YES' to proceed with migration"
if ($confirm -ne "YES") {
    Write-Host "Migration cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Connecting to server..." -ForegroundColor Cyan

# Create backup command
$backupCommand = @"
PGPASSWORD='$dbPassword' pg_dump -h localhost -U $dbUser -d $database -f /home/pivot/app/backup_before_migration_`$(date +%Y%m%d_%H%M%S).sql
"@

# Create migration command
$migrationFile = "MIGRATE_IST_TO_UTC.sql"
$remotePath = "/home/pivot/app/$migrationFile"

Write-Host ""
Write-Host "Step 1: Creating database backup..." -ForegroundColor Yellow

$sshBackup = @"
ssh root@$server "$backupCommand"
"@

Write-Host "Manual steps required:" -ForegroundColor Red
Write-Host ""
Write-Host "1. Upload MIGRATE_IST_TO_UTC.sql to the server:" -ForegroundColor White
Write-Host "   - Use HestiaCP File Manager" -ForegroundColor Gray
Write-Host "   - Upload to: /home/user/web/srv1145703.hstgr.cloud/App/" -ForegroundColor Gray
Write-Host ""
Write-Host "2. SSH into server and run these commands:" -ForegroundColor White
Write-Host ""
Write-Host "# Backup database first" -ForegroundColor Green
Write-Host "PGPASSWORD='$dbPassword' pg_dump -h localhost -U $dbUser -d $database -f /home/pivot/app/backup_before_migration_`$(date +%Y%m%d_%H%M%S).sql"
Write-Host ""
Write-Host "# Copy SQL file" -ForegroundColor Green
Write-Host "cp /home/user/web/srv1145703.hstgr.cloud/App/MIGRATE_IST_TO_UTC.sql /home/pivot/app/"
Write-Host ""
Write-Host "# Run migration" -ForegroundColor Green  
Write-Host "PGPASSWORD='$dbPassword' psql -h localhost -U $dbUser -d $database -f /home/pivot/app/MIGRATE_IST_TO_UTC.sql"
Write-Host ""
Write-Host "# Verify results" -ForegroundColor Green
Write-Host "PGPASSWORD='$dbPassword' psql -h localhost -U $dbUser -d $database -c `"SELECT 'AttendanceRecords', COUNT(*), MIN(\`"Timestamp\`"), MAX(\`"Timestamp\`") FROM \`"AttendanceRecords\`";`""
Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
