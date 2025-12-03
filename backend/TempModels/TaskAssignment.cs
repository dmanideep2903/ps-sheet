using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class TaskAssignment
{
    public int Id { get; set; }

    public string? AdminRemarks { get; set; }

    public string? ApprovedBy { get; set; }

    public string? ApprovedDate { get; set; }

    public string AssignedByEmail { get; set; } = null!;

    public string AssignedToEmail { get; set; } = null!;

    public string CompanyId { get; set; } = null!;

    public string? CompletedDate { get; set; }

    public string CreatedAt { get; set; } = null!;

    public string Description { get; set; } = null!;

    public string DueDate { get; set; } = null!;

    public string? EmployeeRemarks { get; set; }

    public string Priority { get; set; } = null!;

    public string? RejectedBy { get; set; }

    public string? RejectedDate { get; set; }

    public int RejectionCount { get; set; }

    public string Status { get; set; } = null!;

    public int SubmissionCount { get; set; }

    public string Title { get; set; } = null!;

    public string? UpdatedAt { get; set; }
}
