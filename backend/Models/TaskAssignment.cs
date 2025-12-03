using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class TaskAssignment
    {
        [Key]
        public int Id { get; set; }

        public string CompanyId { get; set; } = "default"; // Multi-tenant support

        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Description { get; set; } = string.Empty;

        [Required]
        public string AssignedToEmail { get; set; } = string.Empty;

        [Required]
        public DateTime DueDate { get; set; }

        [Required]
        public string Priority { get; set; } = "Medium"; // Low, Medium, High

        [Required]
        public string Status { get; set; } = "Pending"; // Pending, Completed, Approved, Rejected, Overdue

        public string? EmployeeRemarks { get; set; }

        public string? AdminRemarks { get; set; }

        public DateTime? CompletedDate { get; set; }

        public DateTime? ApprovedDate { get; set; }

        public string? ApprovedBy { get; set; } // Email of admin who approved

        public DateTime? RejectedDate { get; set; }

        public string? RejectedBy { get; set; } // Email of admin who rejected

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public DateTime? UpdatedAt { get; set; }

        public int SubmissionCount { get; set; } = 0;

        public int RejectionCount { get; set; } = 0; // Track how many times task was rejected

        public string AssignedByEmail { get; set; } = string.Empty; // Admin who assigned the task
    }
}
