namespace Backend.Models
{
    public class AttendanceRecord
    {
        public int Id { get; set; }
        public string CompanyId { get; set; } = "default"; // Multi-tenant support
        public string EmployeeId { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
        public bool IsClockIn { get; set; }
        
        // Legacy field - kept for backward compatibility
        public string WifiSsid { get; set; } = string.Empty;
        
        // New network security fields
        public string? GatewayIp { get; set; }        // Router IP address
        public string? RouterMac { get; set; }        // Router MAC address (hardware ID)
        public string? DeviceIp { get; set; }         // Employee device IP
        public string? DeviceMac { get; set; }        // Employee device MAC
    }
}
