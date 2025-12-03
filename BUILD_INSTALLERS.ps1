# ========================================
# Multi-Company Installer Build Script
# ========================================
# This script builds separate installers for each company
# Each installer has a unique companyId hardcoded

param(
    [string]$CompanyName = "all"  # Options: "all", "CompanyA", "CompanyB", "MarkAudio"
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "========================================="
Write-Info "  Multi-Company Installer Builder"
Write-Info "========================================="
Write-Info ""

# Step 1: Build React App (only once)
Write-Info "[Step 1/4] Building React App..."
Set-Location "$PSScriptRoot\react-app"

if (Test-Path "build") {
    Write-Warning "  Cleaning old React build..."
    Remove-Item -Recurse -Force build
}

Write-Info "  Running npm run build..."
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Error "React build failed!"
    exit 1
}
Write-Success "  ✓ React build complete"
Write-Info ""

# Step 2: Copy React build to Electron app
Write-Info "[Step 2/4] Copying React build to Electron app..."
Set-Location "$PSScriptRoot\electron-app"

if (Test-Path "build") {
    Remove-Item -Recurse -Force build
}
Copy-Item -Recurse ..\react-app\build .\
Write-Success "  ✓ React build copied to electron-app/build"
Write-Info ""

# Step 3: Publish Backend
Write-Info "[Step 3/5] Publishing Backend for Windows..."
Set-Location "$PSScriptRoot\backend"

# Clean old publish folder
if (Test-Path "publish") {
    Remove-Item -Recurse -Force publish
}

Write-Info "  Running dotnet publish..."
dotnet publish -c Release -r win-x64 --self-contained true -o publish
if ($LASTEXITCODE -ne 0) {
    Write-Error "Backend publish failed!"
    exit 1
}

Write-Info "  Copying backend to electron-app..."
Set-Location "$PSScriptRoot\electron-app"
if (Test-Path "backend") {
    Remove-Item -Recurse -Force backend
}
Copy-Item -Recurse ..\backend\publish backend
Write-Success "  ✓ Backend published to electron-app/backend"
Write-Info ""

# Step 4: Build installers for each company
Write-Info "[Step 4/5] Building Company-Specific Installers..."
Write-Info ""

# Define companies (only MarkAudio for now)
$companies = @(
    @{Name="MarkAudio"; ConfigFile="appConfig-MarkAudio.json"; OutputName="MarkAudio"}
)

# Filter companies based on parameter
if ($CompanyName -ne "all") {
    $companies = $companies | Where-Object { $_.Name -eq $CompanyName }
    if ($companies.Count -eq 0) {
        Write-Error "Company '$CompanyName' not found!"
        exit 1
    }
}

# Backup current appConfig.json
Write-Info "  Backing up current appConfig.json..."
if (Test-Path "appConfig.json") {
    Copy-Item appConfig.json appConfig.json.backup -Force
}

foreach ($company in $companies) {
    Write-Info "--------------------------------------"
    $companyName = $company.Name
    Write-Info "  Building installer for: $companyName"
    Write-Info "--------------------------------------"
    
    # Check if config file exists
    $configFile = $company.ConfigFile
    if (-not (Test-Path $configFile)) {
        Write-Error "  Config file not found: $configFile"
        continue
    }
    
    # Step 3a: Replace appConfig.json with company-specific config
    Write-Info "  -> Using config: $configFile"
    Copy-Item $configFile appConfig.json -Force
    
    # Show company details
    $config = Get-Content appConfig.json | ConvertFrom-Json
    $companyId = $config.companyId
    $companyDisplayName = $config.companyName
    $apiUrl = $config.apiBaseUrl
    Write-Info "    Company ID: $companyId"
    Write-Info "    Company Name: $companyDisplayName"
    Write-Info "    API URL: $apiUrl"
    
    # Step 3b: Build Electron installer
    Write-Info "  -> Building Electron installer..."
    npm run dist 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        # Step 3c: Rename the installer
        $originalExe = Get-ChildItem -Path "dist" -Filter "*.exe" | Select-Object -First 1
        if ($originalExe) {
            $outputName = $company.OutputName
            $newName = "$outputName-Setup.exe"
            $newPath = Join-Path "dist" $newName
            
            # Remove old renamed file if exists
            if (Test-Path $newPath) {
                Remove-Item $newPath -Force
            }
            
            Move-Item $originalExe.FullName $newPath -Force
            Write-Success "  [OK] Installer created: dist\$newName"
            
            # Show file size
            $fileSize = [math]::Round((Get-Item $newPath).Length / 1MB, 2)
            Write-Info "    Size: $fileSize MB"
        } else {
            Write-Warning "  [WARN] Installer .exe not found in dist folder"
        }
    } else {
        $failedCompany = $company.Name
        Write-Error "  [FAIL] Build failed for $failedCompany"
    }
    
    Write-Info ""
}

# Step 5: Restore original appConfig.json
Write-Info "[Step 5/5] Restoring original appConfig.json..."
if (Test-Path "appConfig.json.backup") {
    Move-Item appConfig.json.backup appConfig.json -Force
    Write-Success "  [OK] Original config restored"
} else {
    Write-Warning "  [WARN] No backup found to restore"
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
