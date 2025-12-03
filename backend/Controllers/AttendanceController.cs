using Backend.Data;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AttendanceController : ControllerBase
    {
        private readonly AttendanceContext _context;
        private readonly ITimeService _timeService;

        public AttendanceController(AttendanceContext context, ITimeService timeService)
        {
            _context = context;
            _timeService = timeService;
        }

     [HttpPost]
public IActionResult RecordAttendance([FromBody] AttendanceRecord record)
{
    // Get CompanyId from header
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    record.CompanyId = companyId;
    
    // Get network validation configuration from database
    var allowedRouterMacSetting = _context.SystemSettings
        .FirstOrDefault(s => s.SettingKey == "AllowedRouterMac");
    var allowedGatewayIpSetting = _context.SystemSettings
        .FirstOrDefault(s => s.SettingKey == "AllowedGatewayIp");

    var allowedRouterMac = allowedRouterMacSetting?.SettingValue ?? "3C-64-CF-30-FC-2D";
    var allowedGatewayIp = allowedGatewayIpSetting?.SettingValue ?? "192.168.0.1";
    
    // Legacy SSID for backward compatibility
    var allowedSsid = "MARK AUDIO";

    // Check if this is a manual entry (admin recording attendance) OR auto-entry outside time window
    // Determine if a timestamp was provided by the client (manual/admin entry)
    bool isManualEntry = record.Timestamp != default(DateTime);

    // Frontend already sends UTC timestamps - store as-is
    // Just ensure the timestamp is marked as UTC for database storage
    // FIX: NO TIMEZONE CONVERSION - Frontend handles all conversions
    if (isManualEntry)
    {
        // Frontend sends ISO 8601 UTC timestamps (e.g., "2025-12-29T11:33:00.000Z")
        // .NET deserializes these correctly, but may mark as Unspecified
        // Simply ensure Kind is set to UTC without any conversion
        if (record.Timestamp.Kind == DateTimeKind.Unspecified)
        {
            record.Timestamp = DateTime.SpecifyKind(record.Timestamp, DateTimeKind.Utc);
        }
        else if (record.Timestamp.Kind == DateTimeKind.Local)
        {
            // Should never happen, but convert local to UTC if needed
            record.Timestamp = record.Timestamp.ToUniversalTime();
        }
        // If already UTC, leave as-is
    }
    
    // Check if user is admin (admins bypass all network checks)
    var user = _context.Users.FirstOrDefault(u => u.Email == record.EmployeeId && u.CompanyId == companyId);
    bool isAdmin = user?.Role == "Admin";

    // ADMINS: No network validation at all
    // MANUAL ENTRY: No network validation (admin recording for employee)
    // REAL-TIME EMPLOYEE: Network validation required
    if (isAdmin || isManualEntry)
    {
        // Admin or manual entry - skip all network checks
        record.WifiSsid = isAdmin ? "admin-entry" : "manual-entry";
        record.RouterMac = isAdmin ? "admin-entry" : "manual-entry";
        record.GatewayIp = isAdmin ? "admin-entry" : "manual-entry";

        // If admin didn't provide a timestamp, set current UTC time.
        if (!isManualEntry)
        {
            record.Timestamp = DateTime.UtcNow; // Set current time for admin self-attendance
        }
        // If manual entry provided a timestamp, we already converted it to UTC above.
    }
    else
    {
        // Employee real-time punch - enforce network validation
        // Validate Router MAC + Gateway IP for maximum security
        if (string.IsNullOrEmpty(record.RouterMac) || record.RouterMac.ToUpper() != allowedRouterMac.ToUpper())
        {
            return Unauthorized(new { message = "Invalid network. You must be connected to the office router." });
        }
        
        if (string.IsNullOrEmpty(record.GatewayIp) || record.GatewayIp != allowedGatewayIp)
        {
            return Unauthorized(new { message = "Invalid network. You must be connected to the office network." });
        }
        
        // Set timestamp to current UTC time for real-time punch
        record.Timestamp = DateTime.UtcNow;
        
        // Set legacy SSID for backward compatibility
        record.WifiSsid = allowedSsid;
    }
    
    record.Id = 0;  // reset id for DB insertion
    _context.AttendanceRecords.Add(record);
    _context.SaveChanges();
    return Ok(record);
}



        [HttpGet("{employeeId}")]
        public IActionResult GetAttendanceRecords(string employeeId)
        {
            // Get CompanyId from header
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var records = _context.AttendanceRecords
                                  .Where(r => r.EmployeeId == employeeId && r.CompanyId == companyId)
                                  .OrderByDescending(r => r.Timestamp)
                                  .ToList();
            return Ok(records);
        }
    }
}
