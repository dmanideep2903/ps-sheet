namespace Backend.Models
{
    public class EmployeeSettingsUpdate
    {
        public string? EmployeeId { get; set; }
        public string? CurrentPassword { get; set; }
        public string? NewPassword { get; set; }
        public string? Address { get; set; }
        public string? PhoneNumber { get; set; }
    }
}
