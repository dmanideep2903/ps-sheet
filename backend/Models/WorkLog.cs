namespace Backend.Models
{
    public class WorkLog
    {
        public int Id { get; set; }
        public string CompanyId { get; set; } = "default"; // Multi-tenant support
        public string EmployeeId { get; set; } = string.Empty;
        public string EmployeeName { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public string LogText { get; set; } = string.Empty;
        
        // Task-based work log fields
        public string? CompletedTaskIds { get; set; } // JSON array of completed task IDs
        public string? PendingTaskIds { get; set; } // JSON array of pending task IDs
        
        public string Status { get; set; } = "Pending"; // Pending, Approved
        public DateTime CreatedAt { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public string ApprovedBy { get; set; } = string.Empty;
    }
}
