# VPS Hosting Setup for PS Sheet Installer

This folder contains scripts to set up direct download hosting for your PS Sheet installer on your VPS server, meeting Microsoft Partner Center requirements.

## What This Does

✅ Creates versioned directory structure (`/var/www/downloads/1.0.0/`, `/1.0.1/`, etc.)  
✅ Installs and configures Nginx web server  
✅ Sets up HTTPS with SSL certificate (Let's Encrypt or self-signed)  
✅ Configures proper headers for direct download (no redirects)  
✅ Creates a "latest" symlink for auto-update scenarios  
✅ Opens required firewall ports (80, 443)

## Quick Start

### Prerequisites

- A VPS server (Ubuntu/Debian recommended)
- SSH access with sudo privileges
- Your VPS IP address
- OpenSSH client installed on Windows (usually pre-installed)

### One-Command Setup

From your Windows development machine, run:

```powershell
.\tools\upload-to-vps.ps1 -VpsUser root -VpsIP 72.61.226.129 -Version "1.0.0"
```

Replace:
- `root` with your SSH username
- `72.61.226.129` with your VPS IP address
- `1.0.0` with your current version

### What Happens

1. **Uploads installer** (~50-100MB) to your VPS
2. **Uploads setup script** to VPS
3. **Runs automated setup** on VPS:
   - Installs Nginx
   - Creates `/var/www/downloads/1.0.0/` directory
   - Moves installer to version directory
   - Configures Nginx for direct download
   - Sets up SSL certificate
   - Restarts web server
4. **Outputs final URL** for Partner Center

### Your Download URL

After setup completes, your URL will be:

```
https://72.61.226.129/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe
```

This URL:
- ✅ Uses HTTPS (secure)
- ✅ Has version in path (`/1.0.0/`)
- ✅ Returns 200 OK (no redirects)
- ✅ Serves file directly with proper headers

## Advanced Usage

### Custom Parameters

```powershell
.\tools\upload-to-vps.ps1 `
  -VpsUser ubuntu `
  -VpsIP 72.61.226.129 `
  -Version "1.0.1" `
  -LocalExePath ".\custom-path\installer.exe" `
  -RemoteFileName "PS.Sheet.Setup.1.0.1.exe"
```

### Manual Setup (if script fails)

If the PowerShell script fails, you can manually run steps:

1. **Upload files to VPS:**
   ```powershell
   scp "electron-app\dist\PS Sheet Setup 1.0.0.exe" root@72.61.226.129:~/PS.Sheet.Setup.1.0.0.exe
   scp "tools\setup-vps-hosting.sh" root@72.61.226.129:~/
   ```

2. **SSH to VPS:**
   ```powershell
   ssh root@72.61.226.129
   ```

3. **Run setup script:**
   ```bash
   chmod +x ~/setup-vps-hosting.sh
   sudo ~/setup-vps-hosting.sh 72.61.226.129 1.0.0 PS.Sheet.Setup.1.0.0.exe
   ```

## Directory Structure Created

```
/var/www/downloads/
├── 1.0.0/
│   └── PS.Sheet.Setup.1.0.0.exe
├── 1.0.1/
│   └── PS.Sheet.Setup.1.0.1.exe
└── latest/
    └── setup.exe → ../1.0.1/PS.Sheet.Setup.1.0.1.exe
```

## Nginx Configuration

The script creates `/etc/nginx/sites-available/ps-sheet-downloads` with:

- Direct file serving (no directory listing)
- Proper MIME types and download headers
- Security headers (X-Content-Type-Options, etc.)
- SSL/TLS configuration
- Cache control headers

## SSL Certificate Options

The script automatically chooses:

1. **Let's Encrypt** (if you have a domain name)
   - Free, trusted by all browsers
   - Auto-renewal configured
   - Recommended if you have a domain

2. **Self-signed** (if using IP address only)
   - Works immediately
   - Browsers show warning (expected)
   - Good enough for Microsoft Partner Center

## Testing Your URL

### Test with PowerShell

```powershell
# Check headers (should show 200 OK, no redirects)
$response = Invoke-WebRequest -Uri "https://72.61.226.129/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe" -Method Head
$response.StatusCode  # Should be 200
$response.Headers     # Should have Content-Disposition: attachment

# Download file
Invoke-WebRequest -Uri "https://72.61.226.129/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe" -OutFile "test-download.exe"
```

### Test with curl

```bash
# Check headers
curl -I https://72.61.226.129/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe

# Download
curl -O https://72.61.226.129/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe
```

### Browser Test

Open in browser (should download immediately):
```
https://72.61.226.129/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe
```

## For Future Versions

When releasing v1.0.1:

```powershell
.\tools\upload-to-vps.ps1 -VpsUser root -VpsIP 72.61.226.129 -Version "1.0.1"
```

This creates a new versioned directory alongside the old one:
- Old: `https://72.61.226.129/downloads/1.0.0/...`
- New: `https://72.61.226.129/downloads/1.0.1/...`

Both URLs remain accessible (users on old version can still download).

## Troubleshooting

### "Permission denied" when uploading

- Ensure you have SSH access to the VPS
- Check SSH key is added to VPS (`ssh-copy-id root@72.61.226.129`)
- Or use password authentication

### "Nginx test failed"

```bash
# SSH to VPS and check logs
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

### "Port 443 not accessible"

```bash
# Check firewall
sudo ufw status
sudo ufw allow 443/tcp

# Check if Nginx is listening
sudo netstat -tlnp | grep :443
```

### SSL certificate warnings

- **Expected** if using self-signed certificate
- Users can proceed through warning
- Or: Buy a domain ($2-5/year) and use Let's Encrypt

### "File not found (404)"

```bash
# Check file exists
ls -la /var/www/downloads/1.0.0/

# Check Nginx config
sudo nginx -t
sudo cat /etc/nginx/sites-available/ps-sheet-downloads
```

## Using a Domain Name (Optional)

If you buy a domain later:

1. **Point domain to VPS:**
   - Create A record: `downloads.yourcompany.com` → `72.61.226.129`

2. **Update Nginx config:**
   ```bash
   sudo nano /etc/nginx/sites-available/ps-sheet-downloads
   # Change server_name to your domain
   ```

3. **Get Let's Encrypt cert:**
   ```bash
   sudo certbot --nginx -d downloads.yourcompany.com
   ```

4. **New URL:**
   ```
   https://downloads.yourcompany.com/downloads/1.0.0/PS.Sheet.Setup.1.0.0.exe
   ```

## Security Notes

- Files are served with `Content-Disposition: attachment` (forced download)
- Directory listing disabled
- Hidden files (`.htaccess`, etc.) blocked
- Security headers added
- HTTPS enforced (if SSL configured)
- Regular Nginx security updates recommended

## Performance

For high traffic:
- Enable Nginx caching
- Use a CDN (Cloudflare free tier works great)
- Consider bandwidth limits on your VPS plan

## Support

If the automated script fails:
1. Check the output for specific errors
2. Run manual setup steps (see above)
3. Check VPS firewall and security groups
4. Verify SSH access and sudo permissions

---

**Ready to deploy?** Run the upload script and get your Microsoft-ready download URL in minutes! 🚀
