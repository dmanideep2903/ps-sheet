using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class User
{
    public int Id { get; set; }

    public string? AllowedGatewayIp { get; set; }

    public string? AllowedRouterMac { get; set; }

    public string CompanyId { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? FaceDescriptor { get; set; }

    public int FaceRegistered { get; set; }

    public int IsApproved { get; set; }

    public string Name { get; set; } = null!;

    public string Password { get; set; } = null!;

    public string Role { get; set; } = null!;

    public string? WifiSsid { get; set; }
}
