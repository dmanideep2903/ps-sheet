using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SettingsController : ControllerBase
    {
        private readonly AttendanceContext _context;

        public SettingsController(AttendanceContext context)
        {
            _context = context;
        }

        // GET: api/settings/network
        [HttpGet("network")]
        public async Task<IActionResult> GetNetworkSettings()
        {
            var routerMac = await _context.SystemSettings
                .FirstOrDefaultAsync(s => s.SettingKey == "AllowedRouterMac");
            var gatewayIp = await _context.SystemSettings
                .FirstOrDefaultAsync(s => s.SettingKey == "AllowedGatewayIp");
            var validationMode = await _context.SystemSettings
                .FirstOrDefaultAsync(s => s.SettingKey == "ValidationMode");

            return Ok(new
            {
                routerMac = routerMac?.SettingValue ?? "3C-64-CF-30-FC-2D",
                gatewayIp = gatewayIp?.SettingValue ?? "192.168.0.1",
                validationMode = validationMode?.SettingValue ?? "mac-ip"
            });
        }

        // POST: api/settings/network/verify
        [HttpPost("network/verify")]
        public IActionResult VerifyPasscode([FromBody] PasscodeRequest request)
        {
            // Hardcoded passcode: Passcode@2019
            if (request.Passcode == "Passcode@2019")
            {
                return Ok(new { verified = true, message = "Passcode verified successfully" });
            }
            return Unauthorized(new { verified = false, message = "Invalid passcode" });
        }

        // POST: api/settings/network
        [HttpPost("network")]
        public async Task<IActionResult> UpdateNetworkSettings([FromBody] NetworkSettingsRequest request)
        {
            // Verify passcode again for security
            if (request.Passcode != "Passcode@2019")
            {
                return Unauthorized(new { message = "Invalid passcode" });
            }

            try
            {
                // Get current user from token (you may need to implement this)
                var updatedBy = "Admin"; // You can get this from JWT claims

                // Update Router MAC
                var routerMacSetting = await _context.SystemSettings
                    .FirstOrDefaultAsync(s => s.SettingKey == "AllowedRouterMac");
                
                if (routerMacSetting == null)
                {
                    routerMacSetting = new SystemSettings
                    {
                        SettingKey = "AllowedRouterMac",
                        Description = "Allowed Router MAC Address for network validation"
                    };
                    _context.SystemSettings.Add(routerMacSetting);
                }
                routerMacSetting.SettingValue = request.RouterMac.ToUpper();
                routerMacSetting.UpdatedAt = DateTime.UtcNow;
                routerMacSetting.UpdatedBy = updatedBy;

                // Update Gateway IP
                var gatewayIpSetting = await _context.SystemSettings
                    .FirstOrDefaultAsync(s => s.SettingKey == "AllowedGatewayIp");
                
                if (gatewayIpSetting == null)
                {
                    gatewayIpSetting = new SystemSettings
                    {
                        SettingKey = "AllowedGatewayIp",
                        Description = "Allowed Gateway IP Address for network validation"
                    };
                    _context.SystemSettings.Add(gatewayIpSetting);
                }
                gatewayIpSetting.SettingValue = request.GatewayIp;
                gatewayIpSetting.UpdatedAt = DateTime.UtcNow;
                gatewayIpSetting.UpdatedBy = updatedBy;

                // Update Validation Mode
                var validationModeSetting = await _context.SystemSettings
                    .FirstOrDefaultAsync(s => s.SettingKey == "ValidationMode");
                
                if (validationModeSetting == null)
                {
                    validationModeSetting = new SystemSettings
                    {
                        SettingKey = "ValidationMode",
                        Description = "Network validation mode (mac-ip, mac, ip, disabled)"
                    };
                    _context.SystemSettings.Add(validationModeSetting);
                }
                validationModeSetting.SettingValue = request.ValidationMode;
                validationModeSetting.UpdatedAt = DateTime.UtcNow;
                validationModeSetting.UpdatedBy = updatedBy;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Network settings updated successfully",
                    routerMac = request.RouterMac.ToUpper(),
                    gatewayIp = request.GatewayIp,
                    validationMode = request.ValidationMode,
                    updatedAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Error updating settings: {ex.Message}" });
            }
        }
    }

    public class PasscodeRequest
    {
        public string Passcode { get; set; } = string.Empty;
    }

    public class NetworkSettingsRequest
    {
        public string Passcode { get; set; } = string.Empty;
        public string RouterMac { get; set; } = string.Empty;
        public string GatewayIp { get; set; } = string.Empty;
        public string ValidationMode { get; set; } = "mac-ip";
    }
}
