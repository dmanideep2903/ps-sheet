param(
    [Parameter(Mandatory=$true)]
    [string]$VpsUser,

    [Parameter(Mandatory=$true)]
    [string]$VpsIP,

    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0",

    [Parameter(Mandatory=$false)]
    [string]$LocalExePath = "P:\SourceCode-PIVOT\DeskAttendanceApp\electron-app\dist\PS Sheet Setup 1.0.0.exe",

    [Parameter(Mandatory=$false)]
    [string]$RemoteFileName = "PS.Sheet.Setup.1.0.0.exe"
)

$ErrorActionPreference = "Stop"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  PS Sheet - VPS Hosting Setup" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $LocalExePath)) {
    Write-Error "Installer not found: $LocalExePath"
    exit 1
}

$fileSize = (Get-Item $LocalExePath).Length / 1MB
$fileSizeMB = [math]::Round($fileSize, 2)
Write-Host "Found installer: $([System.IO.Path]::GetFileName($LocalExePath)) - $fileSizeMB MB" -ForegroundColor Green

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Error "SSH not found. Install OpenSSH client."
    exit 1
}

if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Error "SCP not found. Install OpenSSH client."
    exit 1
}

Write-Host "SSH/SCP available" -ForegroundColor Green
Write-Host ""

$setupScript = Join-Path $PSScriptRoot "setup-vps-hosting.sh"
if (-not (Test-Path $setupScript)) {
    Write-Error "Setup script not found: $setupScript"
    exit 1
}

Write-Host "Uploading setup script..." -ForegroundColor Yellow
scp "$setupScript" "${VpsUser}@${VpsIP}:~/setup-vps-hosting.sh"
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Failed to upload setup script"
    exit 1
}
Write-Host "Setup script uploaded" -ForegroundColor Green

Write-Host "Uploading installer - $fileSizeMB MB..." -ForegroundColor Yellow
scp "$LocalExePath" "${VpsUser}@${VpsIP}:~/$RemoteFileName"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to upload installer"
    exit 1
}
Write-Host "Installer uploaded" -ForegroundColor Green

Write-Host ""
Write-Host "Running VPS setup..." -ForegroundColor Yellow
Write-Host "(Installing Nginx, configuring SSL, setting up versioned hosting)" -ForegroundColor Gray
Write-Host ""

ssh "${VpsUser}@${VpsIP}" "chmod +x ~/setup-vps-hosting.sh; sudo ~/setup-vps-hosting.sh $VpsIP $Version $RemoteFileName"

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Setup script returned error. Check output above."
    Write-Host ""
    Write-Host "Manual setup command:" -ForegroundColor Yellow
    Write-Host "  ssh ${VpsUser}@${VpsIP}" -ForegroundColor Gray
    Write-Host "  sudo ~/setup-vps-hosting.sh $VpsIP $Version $RemoteFileName" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your download URL:" -ForegroundColor Cyan
    Write-Host "  https://$VpsIP/downloads/$Version/$RemoteFileName" -ForegroundColor White
    Write-Host ""
    Write-Host "Test it:" -ForegroundColor Yellow
    Write-Host "  Invoke-WebRequest -Uri 'https://$VpsIP/downloads/$Version/$RemoteFileName' -OutFile 'test.exe'" -ForegroundColor Gray
    Write-Host ""
}
