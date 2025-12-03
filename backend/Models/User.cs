// Models/User.cs
namespace Backend.Models
{
   public class User
{
    public int Id { get; set; }
    public string CompanyId { get; set; } = "default"; // Multi-tenant support
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = "Employee";
    public bool IsApproved { get; set; } = false;  // Default to false for new registrations
    
    // Legacy network field - kept for backward compatibility
    public string? WifiSsid { get; set; }
    
    // New network security fields
    public string? AllowedGatewayIp { get; set; }   // Allowed router IP
    public string? AllowedRouterMac { get; set; }   // Allowed router MAC
    
    // Transient properties for login/attendance requests (not stored in DB)
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string? GatewayIp { get; set; }          // Current gateway IP during login
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string? RouterMac { get; set; }          // Current router MAC during login
    
    // Face Recognition fields
    public string? FaceDescriptor { get; set; }  // JSON array of 128-dimensional face descriptor
    public bool FaceRegistered { get; set; } = false;

}

}
