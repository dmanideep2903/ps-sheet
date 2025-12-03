using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class AttendanceRecord
{
    public int Id { get; set; }

    public string CompanyId { get; set; } = null!;

    public string? DeviceIp { get; set; }

    public string? DeviceMac { get; set; }

    public string EmployeeId { get; set; } = null!;

    public string? GatewayIp { get; set; }

    public int IsClockIn { get; set; }

    public string? RouterMac { get; set; }

    public string Timestamp { get; set; } = null!;

    public string WifiSsid { get; set; } = null!;
}
