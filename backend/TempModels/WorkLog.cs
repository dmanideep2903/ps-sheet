using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class WorkLog
{
    public int Id { get; set; }

    public string? ApprovedAt { get; set; }

    public string ApprovedBy { get; set; } = null!;

    public string CompanyId { get; set; } = null!;

    public string? CompletedTaskIds { get; set; }

    public string CreatedAt { get; set; } = null!;

    public string Date { get; set; } = null!;

    public string EmployeeId { get; set; } = null!;

    public string EmployeeName { get; set; } = null!;

    public string LogText { get; set; } = null!;

    public string? PendingTaskIds { get; set; }

    public string Status { get; set; } = null!;
}
