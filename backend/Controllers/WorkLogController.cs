using Backend.Data;
using Backend.Models;
using backend.Models; // TaskAssignment
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WorkLogController : ControllerBase
    {
        private readonly AttendanceContext _context;
        private readonly ITimeService _timeService;

        public WorkLogController(AttendanceContext context, ITimeService timeService)
        {
            _context = context;
            _timeService = timeService;
        }

        // Employee: Submit work log (max 2 per day)
        [HttpPost]
        public IActionResult SubmitWorkLog([FromBody] WorkLog workLog)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var today = _timeService.GetIndianStandardToday();
            var existingLogsToday = _context.WorkLogs
                .Count(w => w.EmployeeId == workLog.EmployeeId && w.Date.Date == today && w.CompanyId == companyId);

            if (existingLogsToday >= 2)
                return BadRequest(new { message = "Maximum 2 work logs per day allowed" });

            workLog.Id = 0; // Reset ID for new entry
            workLog.Date = today;
            workLog.CreatedAt = DateTime.UtcNow;
            workLog.Status = "Completed"; // Changed from "Pending" to "Completed" upon submission
            workLog.ApprovedAt = null;
            workLog.ApprovedBy = string.Empty;
            workLog.CompanyId = companyId;

            _context.WorkLogs.Add(workLog);
            _context.SaveChanges();

            return Ok(workLog);
        }

        // Employee: Get own work logs
        [HttpGet("employee/{employeeId}")]
        public IActionResult GetEmployeeWorkLogs(string employeeId)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var logs = _context.WorkLogs
                .Where(w => w.EmployeeId == employeeId && w.CompanyId == companyId)
                .OrderByDescending(w => w.CreatedAt)
                .ToList();

            return Ok(logs);
        }

        // Admin: Get unapproved work logs
        [HttpGet("unapproved")]
        public IActionResult GetUnapprovedWorkLogs()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var unapprovedLogs = _context.WorkLogs
                .Where(w => w.Status == "Pending" && w.CompanyId == companyId)
                .OrderByDescending(w => w.CreatedAt)
                .ToList();

            return Ok(unapprovedLogs);
        }

        // Admin: Get all approved work logs
        [HttpGet("approved")]
        public IActionResult GetApprovedWorkLogs()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var approvedLogs = _context.WorkLogs
                .Where(w => w.Status == "Approved" && w.CompanyId == companyId)
                .OrderByDescending(w => w.ApprovedAt)
                .ToList();

            return Ok(approvedLogs);
        }

        // Admin: Approve work log
        [HttpPost("approve/{id}")]
        public IActionResult ApproveWorkLog(int id, [FromBody] ApprovalRequest request)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var workLog = _context.WorkLogs.FirstOrDefault(w => w.Id == id && w.CompanyId == companyId);
            if (workLog == null)
                return NotFound(new { message = "Work log not found" });

            if (workLog.Status == "Approved")
                return BadRequest(new { message = "Work log is already approved" });

            workLog.Status = "Approved";
            workLog.ApprovedAt = DateTime.UtcNow;
            workLog.ApprovedBy = request.ApprovedBy ?? "Admin";

            // Update the tasks statuses to "Approved"
            if (!string.IsNullOrEmpty(workLog.CompletedTaskIds))
            {
                var completedIds = JsonSerializer.Deserialize<List<int>>(workLog.CompletedTaskIds);
                if (completedIds != null)
                {
                    var tasks = _context.TaskAssignments.Where(t => completedIds.Contains(t.Id) && t.CompanyId == companyId).ToList();
                    foreach (var task in tasks)
                    {
                        task.Status = "Approved";
                        task.UpdatedAt = DateTime.UtcNow;
                    }
                }
            }

            _context.SaveChanges();
            return Ok(workLog);
        }

        // Admin: Reject work log (change status from Completed to Pending)
        [HttpPost("reject/{id}")]
        public IActionResult RejectWorkLog(int id, [FromBody] RejectRequest request)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var workLog = _context.WorkLogs.FirstOrDefault(w => w.Id == id && w.CompanyId == companyId);
            if (workLog == null)
                return NotFound(new { message = "Work log not found" });

            if (workLog.Status != "Completed")
                return BadRequest(new { message = "Only completed work logs can be rejected" });

            workLog.Status = "Pending";
            workLog.ApprovedAt = null;
            workLog.ApprovedBy = string.Empty;

            // Update the tasks statuses back to "Pending"
            if (!string.IsNullOrEmpty(workLog.CompletedTaskIds))
            {
                var completedIds = JsonSerializer.Deserialize<List<int>>(workLog.CompletedTaskIds);
                if (completedIds != null)
                {
                    var tasks = _context.TaskAssignments.Where(t => completedIds.Contains(t.Id) && t.CompanyId == companyId).ToList();
                    foreach (var task in tasks)
                    {
                        task.Status = "Pending";
                        task.UpdatedAt = DateTime.UtcNow;
                    }
                }
            }

            _context.SaveChanges();
            return Ok(workLog);
        }

        // Admin: Revoke approval (change status from Approved to Completed)
        [HttpPost("revoke/{id}")]
        public IActionResult RevokeApproval(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var workLog = _context.WorkLogs.FirstOrDefault(w => w.Id == id && w.CompanyId == companyId);
            if (workLog == null)
                return NotFound(new { message = "Work log not found" });

            if (workLog.Status != "Approved")
                return BadRequest(new { message = "Only approved work logs can be revoked" });

            workLog.Status = "Completed";
            workLog.ApprovedAt = null;
            workLog.ApprovedBy = string.Empty;

            // Update the tasks statuses back to "Completed"
            if (!string.IsNullOrEmpty(workLog.CompletedTaskIds))
            {
                var completedIds = JsonSerializer.Deserialize<List<int>>(workLog.CompletedTaskIds);
                if (completedIds != null)
                {
                    var tasks = _context.TaskAssignments.Where(t => completedIds.Contains(t.Id) && t.CompanyId == companyId).ToList();
                    foreach (var task in tasks)
                    {
                        task.Status = "Completed";
                        task.UpdatedAt = DateTime.UtcNow;
                    }
                }
            }

            _context.SaveChanges();
            return Ok(workLog);
        }

        // Admin: Get worklogs grouped by employee with status counts
        [HttpGet("grouped")]
        public IActionResult GetGroupedWorkLogs()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var allLogs = _context.WorkLogs
                .Where(w => w.CompanyId == companyId)
                .OrderByDescending(w => w.CreatedAt)
                .ToList();

            var grouped = allLogs
                .GroupBy(w => new { w.EmployeeId, w.EmployeeName })
                .Select(g => new
                {
                    employeeId = g.Key.EmployeeId,
                    employeeName = g.Key.EmployeeName,
                    pendingCount = g.Count(w => w.Status == "Pending"),
                    completedCount = g.Count(w => w.Status == "Completed"),
                    approvedCount = g.Count(w => w.Status == "Approved"),
                    pendingLogs = g.Where(w => w.Status == "Pending").ToList(),
                    completedLogs = g.Where(w => w.Status == "Completed").ToList(),
                    approvedLogs = g.Where(w => w.Status == "Approved").ToList()
                })
                .OrderBy(g => g.employeeName)
                .ToList();

            return Ok(grouped);
        }

        // Admin: Get all work logs (both pending and approved)
        [HttpGet("all")]
        public IActionResult GetAllWorkLogs()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var allLogs = _context.WorkLogs
                .Where(w => w.CompanyId == companyId)
                .OrderByDescending(w => w.CreatedAt)
                .ToList();

            return Ok(allLogs);
        }

        // Admin: Delete work log
        [HttpDelete("{id}")]
        public IActionResult DeleteWorkLog(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var workLog = _context.WorkLogs.FirstOrDefault(w => w.Id == id && w.CompanyId == companyId);
            if (workLog == null)
                return NotFound(new { message = "Work log not found" });

            _context.WorkLogs.Remove(workLog);
            _context.SaveChanges();

            return Ok(new { message = "Work log deleted successfully" });
        }

        // Employee: Update/Edit work log (only if status is Pending)
        [HttpPut("{id}")]
        public IActionResult UpdateWorkLog(int id, [FromBody] WorkLogUpdateRequest request)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var workLog = _context.WorkLogs.FirstOrDefault(w => w.Id == id && w.CompanyId == companyId);
            if (workLog == null)
                return NotFound(new { message = "Work log not found" });

            // Only allow editing pending work logs
            if (workLog.Status != "Pending")
                return BadRequest(new { message = "Only pending work logs can be edited" });

            // Update the log text
            if (!string.IsNullOrWhiteSpace(request.LogText))
            {
                workLog.LogText = request.LogText;
                _context.SaveChanges();
                return Ok(workLog);
            }

            return BadRequest(new { message = "Log text cannot be empty" });
        }
    }

    public class WorkLogUpdateRequest
    {
        public string LogText { get; set; } = string.Empty;
    }

    public class ApprovalRequest
    {
        public string ApprovedBy { get; set; } = string.Empty;
    }

    public class RejectRequest
    {
        public string RejectedBy { get; set; } = string.Empty;
    }
}
