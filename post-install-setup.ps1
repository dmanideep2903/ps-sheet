# Company Attendance App - Post-Installation Setup
# Run this script AFTER installing the application

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Company Attendance App - Post-Install Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Find installation directory
$possiblePaths = @(
    "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app\backend",
    "$env:LOCALAPPDATA\Programs\company-attendance-app\resources\app.asar.unpacked\backend"
)

$backendPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $backendPath = $path
        break
    }
}

if (-not $backendPath) {
    Write-Host "✗ ERROR: Cannot find installation directory" -ForegroundColor Red
    Write-Host "Please ensure the app is installed correctly." -ForegroundColor Yellow
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Found installation at: $backendPath`n" -ForegroundColor Green

# Step 1: Check database connection
Write-Host "Step 1: Checking database configuration..." -ForegroundColor Cyan
$appsettingsPath = Join-Path $backendPath "appsettings.json"

if (Test-Path $appsettingsPath) {
    Write-Host "✓ appsettings.json found" -ForegroundColor Green
    
    $appsettings = Get-Content $appsettingsPath | ConvertFrom-Json
    $connectionString = $appsettings.ConnectionStrings.DefaultConnection
    Write-Host "Connection String: $connectionString" -ForegroundColor Gray
} else {
    Write-Host "✗ appsettings.json not found!" -ForegroundColor Red
}

# Step 2: Test SQL Server connection
Write-Host "`nStep 2: Testing SQL Server connection..." -ForegroundColor Cyan
try {
    # Start LocalDB if not running
    $instances = & sqllocaldb info 2>&1
    if ($instances -contains "mssqllocaldb") {
        $status = & sqllocaldb info mssqllocaldb 2>&1
        if ($status -match "State: Running") {
            Write-Host "✓ SQL Server LocalDB is running" -ForegroundColor Green
        } else {
            Write-Host "Starting SQL Server LocalDB..." -NoNewline
            & sqllocaldb start mssqllocaldb | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓ Started" -ForegroundColor Green
            } else {
                Write-Host " ✗ Failed" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Creating mssqllocaldb instance..." -NoNewline
        & sqllocaldb create mssqllocaldb | Out-Null
        & sqllocaldb start mssqllocaldb | Out-Null
        Write-Host " ✓ Created and started" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ SQL Server error: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Run database migrations
Write-Host "`nStep 3: Setting up database..." -ForegroundColor Cyan
Write-Host "This will create the database and tables." -ForegroundColor Gray

$runMigration = Read-Host "`nDo you want to run database migrations now? (Y/N)"
if ($runMigration -eq 'Y' -or $runMigration -eq 'y') {
    Write-Host "`nRunning migrations..." -ForegroundColor Yellow
    Push-Location $backendPath
    
    try {
        # Check if migrations folder exists
        $migrationsPath = Join-Path $backendPath "Migrations"
        if (Test-Path $migrationsPath) {
            Write-Host "✓ Migrations folder found" -ForegroundColor Green
            
            # Run migrations
            $output = & dotnet ef database update 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Database migrations completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "✗ Migration failed:" -ForegroundColor Red
                Write-Host $output -ForegroundColor Yellow
                Write-Host "`nTrying alternative method..." -ForegroundColor Yellow
                
                # Try running the backend manually once to trigger migrations
                $backendExe = Join-Path $backendPath "backend.exe"
                if (Test-Path $backendExe) {
                    Write-Host "Starting backend to initialize database..." -ForegroundColor Yellow
                    $proc = Start-Process -FilePath $backendExe -WorkingDirectory $backendPath -PassThru -WindowStyle Hidden
                    Start-Sleep -Seconds 10
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                    Write-Host "✓ Database should be initialized now" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "✗ Migrations folder not found" -ForegroundColor Red
            Write-Host "Database will be created on first app launch" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Skipping migrations. Database will be created on first app launch." -ForegroundColor Yellow
}

# Step 4: Test backend startup
Write-Host "`nStep 4: Testing backend startup..." -ForegroundColor Cyan
$testBackend = Read-Host "Do you want to test backend startup? (Y/N)"
if ($testBackend -eq 'Y' -or $testBackend -eq 'y') {
    Write-Host "`nStarting backend..." -ForegroundColor Yellow
    Write-Host "This will open in a new window. Check for errors." -ForegroundColor Gray
    Write-Host "Press Ctrl+C in that window to stop the backend.`n" -ForegroundColor Gray
    
    $backendExe = Join-Path $backendPath "backend.exe"
    if (Test-Path $backendExe) {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; .\backend.exe"
        Write-Host "✓ Backend started in new window" -ForegroundColor Green
        Write-Host "Check the window for 'Now listening on: http://localhost:5001'" -ForegroundColor Gray
    } else {
        Write-Host "✗ backend.exe not found at: $backendExe" -ForegroundColor Red
    }
}

# Step 5: Summary and next steps
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Close any test backend windows (Ctrl+C)" -ForegroundColor White
Write-Host "2. Launch 'Company Attendance' from Start Menu" -ForegroundColor White
Write-Host "3. Wait 15-30 seconds for backend to start" -ForegroundColor White
Write-Host "4. Login with default admin credentials:" -ForegroundColor White
Write-Host "   Email: admin@admin.com" -ForegroundColor Yellow
Write-Host "   Password: Admin@123" -ForegroundColor Yellow

Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
Write-Host "- If you see 'ERR_CONNECTION_REFUSED', wait longer for backend" -ForegroundColor White
Write-Host "- Press Ctrl+Shift+I in the app to see console logs" -ForegroundColor White
Write-Host "- Check for '[BACKEND] Now listening on: http://localhost:5001'" -ForegroundColor White

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
