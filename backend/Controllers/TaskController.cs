using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend.Data;
using Backend.Services;
using backend.Models;
using System.Text.Json;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TaskController : ControllerBase
    {
        private readonly AttendanceContext _context;
        private readonly ITimeService _timeService;

        public TaskController(AttendanceContext context, ITimeService timeService)
        {
            _context = context;
            _timeService = timeService;
        }

        // Admin: Assign new task to employee
        [HttpPost("assign")]
        public async Task<IActionResult> AssignTask([FromBody] TaskAssignment task)
        {
            if (string.IsNullOrEmpty(task.Title) || string.IsNullOrEmpty(task.AssignedToEmail))
            {
                return BadRequest("Title and AssignedToEmail are required.");
            }

            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            task.CompanyId = companyId;
            task.CreatedAt = DateTime.UtcNow;
            task.Status = "Pending";
            
            _context.TaskAssignments.Add(task);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Task assigned successfully", taskId = task.Id });
        }

        // Employee: Get all tasks assigned to them
        [HttpGet("employee/{email}")]
        public async Task<IActionResult> GetEmployeeTasks(string email)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var tasks = await _context.TaskAssignments
                .Where(t => t.AssignedToEmail == email && t.CompanyId == companyId)
                .OrderBy(t => t.DueDate)
                .ToListAsync();

            // Check for overdue tasks
            var today = _timeService.GetIndianStandardToday();
            foreach (var task in tasks)
            {
                if (task.Status == "Pending" && task.DueDate.Date < today)
                {
                    task.Status = "Overdue";
                    task.UpdatedAt = DateTime.UtcNow;
                }
            }
            await _context.SaveChangesAsync();

            return Ok(tasks);
        }

        // Admin: Get all tasks (with optional filters)
        [HttpGet("all")]
        public async Task<IActionResult> GetAllTasks(string? employeeEmail = null, string? status = null)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var query = _context.TaskAssignments.Where(t => t.CompanyId == companyId);

            if (!string.IsNullOrEmpty(employeeEmail))
            {
                query = query.Where(t => t.AssignedToEmail == employeeEmail);
            }

            if (!string.IsNullOrEmpty(status))
            {
                query = query.Where(t => t.Status == status);
            }

            var tasks = await query
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();

            return Ok(tasks);
        }

        // Employee: Submit completed tasks (creates work log)
        [HttpPost("submit")]
        public async Task<IActionResult> SubmitTasks([FromBody] SubmitTasksRequest request)
        {
            // Check submission limit (2 per day) - PAUSED
            // var today = _timeService.GetIndianStandardToday();
            // var todaySubmissions = await _context.WorkLogs
            //     .Where(w => w.EmployeeId == request.EmployeeEmail && w.Date.Date == today)
            //     .CountAsync();

            // if (todaySubmissions >= 2)
            // {
            //     return BadRequest("You have reached the maximum of 2 submissions per day.");
            // }

            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            var utcNow = DateTime.UtcNow;

            // Update task statuses - ONLY update tasks that are in CompletedTaskIds
            foreach (var taskId in request.CompletedTaskIds)
            {
                var task = await _context.TaskAssignments
                    .FirstOrDefaultAsync(t => t.Id == taskId && t.CompanyId == companyId);
                if (task != null && task.Status != "Approved") // Don't change Approved tasks
                {
                    task.Status = "Completed";
                    task.CompletedDate = utcNow; // This serves as "Submitted On"
                    
                    // Only update remarks if provided in this submission
                    if (request.TaskRemarks?.ContainsKey(taskId) == true)
                    {
                        task.EmployeeRemarks = request.TaskRemarks[taskId];
                    }
                    // If no remarks in this submission, keep existing remarks
                    
                    task.SubmissionCount++;
                    task.UpdatedAt = utcNow;
                }
            }

            // Create work log entry
            var workLog = new Backend.Models.WorkLog
            {
                EmployeeId = request.EmployeeEmail,
                EmployeeName = request.EmployeeName,
                Date = utcNow,
                CompletedTaskIds = JsonSerializer.Serialize(request.CompletedTaskIds),
                PendingTaskIds = JsonSerializer.Serialize(request.PendingTaskIds),
                LogText = $"Submitted {request.CompletedTaskIds.Count} completed tasks, {request.PendingTaskIds.Count} pending tasks",
                Status = "Completed", // Changed from "Pending" to "Completed" - employee has submitted, awaiting admin review
                CreatedAt = utcNow,
                CompanyId = companyId
            };

            _context.WorkLogs.Add(workLog);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tasks submitted successfully", workLogId = workLog.Id });
        }

        // Employee: Submit single task (NEW - individual submission)
        [HttpPost("submit-single")]
        public async Task<IActionResult> SubmitSingleTask([FromBody] SubmitSingleTaskRequest request)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            var utcNow = DateTime.UtcNow;

            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == request.TaskId && t.CompanyId == companyId);
            
            if (task == null)
            {
                return NotFound(new { message = "Task not found" });
            }

            // Verify task belongs to this employee
            if (task.AssignedToEmail != request.EmployeeEmail)
            {
                return Forbid();
            }

            // Don't allow resubmission of approved tasks
            if (task.Status == "Approved")
            {
                return BadRequest(new { message = "Cannot resubmit an approved task" });
            }

            // Don't allow resubmission of already completed tasks
            if (task.Status == "Completed")
            {
                return BadRequest(new { message = "This task is already submitted and awaiting approval" });
            }

            // Update task status to Completed
            task.Status = "Completed";
            task.CompletedDate = utcNow;
            task.EmployeeRemarks = request.Remarks ?? "";
            task.SubmissionCount++;
            task.UpdatedAt = utcNow;

            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "Task submitted successfully",
                taskId = task.Id,
                status = task.Status
            });
        }

        // Admin: Get all work log submissions
        [HttpGet("submissions")]
        public async Task<IActionResult> GetSubmissions()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var workLogs = await _context.WorkLogs
                .Where(w => w.CompanyId == companyId)
                .OrderByDescending(w => w.CreatedAt)
                .ToListAsync();

            var submissions = new List<object>();

            foreach (var log in workLogs)
            {
                var completedIds = string.IsNullOrEmpty(log.CompletedTaskIds) 
                    ? new List<int>() 
                    : JsonSerializer.Deserialize<List<int>>(log.CompletedTaskIds);
                
                var pendingIds = string.IsNullOrEmpty(log.PendingTaskIds) 
                    ? new List<int>() 
                    : JsonSerializer.Deserialize<List<int>>(log.PendingTaskIds);

                var completedTasks = await _context.TaskAssignments
                    .Where(t => completedIds != null && completedIds.Contains(t.Id) && t.CompanyId == companyId)
                    .ToListAsync();

                var pendingTasks = await _context.TaskAssignments
                    .Where(t => pendingIds != null && pendingIds.Contains(t.Id) && t.CompanyId == companyId)
                    .ToListAsync();

                submissions.Add(new
                {
                    workLog = log,
                    completedTasks,
                    pendingTasks
                });
            }

            return Ok(submissions);
        }

        // Admin: Approve a task
        [HttpPost("approve/{id}")]
        public async Task<IActionResult> ApproveTask(int id, [FromBody] ApproveTaskRequest? request)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == id && t.CompanyId == companyId);
            if (task == null)
            {
                return NotFound("Task not found.");
            }

            task.Status = "Approved";
            task.ApprovedDate = DateTime.UtcNow;
            task.ApprovedBy = request?.AdminEmail; // Store who approved
            task.AdminRemarks = request?.AdminRemarks; // Optional remarks for approval
            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Task approved successfully" });
        }

        // Admin: Reject a task with remarks
        [HttpPost("reject/{id}")]
        public async Task<IActionResult> RejectTask(int id, [FromBody] RejectTaskRequest request)
        {
            if (string.IsNullOrEmpty(request.AdminRemarks))
            {
                return BadRequest("Admin remarks are mandatory for rejection.");
            }

            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == id && t.CompanyId == companyId);
            if (task == null)
            {
                return NotFound("Task not found.");
            }

            task.Status = "Pending"; // Back to pending for resubmission
            task.AdminRemarks = request.AdminRemarks;
            task.RejectedDate = DateTime.UtcNow;
            task.RejectedBy = request.AdminEmail; // Store who rejected
            task.UpdatedAt = DateTime.UtcNow;
            task.CompletedDate = null; // Reset completion date
            task.RejectionCount++; // Increment rejection count

            await _context.SaveChangesAsync();

            return Ok(new { message = "Task rejected and sent back to pending" });
        }

        // Admin: Reverse a decision (Approved or Rejected back to Completed)
        [HttpPost("reverse/{id}")]
        public async Task<IActionResult> ReverseDecision(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == id && t.CompanyId == companyId);
            if (task == null)
            {
                return NotFound("Task not found.");
            }

            // Only allow reversing Approved or Rejected tasks
            if (task.Status != "Approved" && task.Status != "Rejected")
            {
                return BadRequest("Can only reverse Approved or Rejected tasks.");
            }

            // Reset to Completed status for re-review
            task.Status = "Completed";
            task.ApprovedDate = null;
            task.ApprovedBy = null;
            task.RejectedDate = null;
            task.RejectedBy = null;
            task.AdminRemarks = null;
            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Decision reversed successfully. Task returned to Completed status." });
        }

        // Employee: Revoke task submission (change from Completed back to Pending)
        [HttpPost("revoke/{id}")]
        public async Task<IActionResult> RevokeTaskSubmission(int id, [FromBody] RevokeTaskRequest request)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == id && t.CompanyId == companyId);
            if (task == null)
            {
                return NotFound("Task not found.");
            }

            // Only allow revoking Completed tasks (awaiting approval)
            if (task.Status != "Completed")
            {
                return BadRequest("Can only revoke tasks that are awaiting approval (Completed status).");
            }

            // Verify the employee owns this task
            if (task.AssignedToEmail != request.EmployeeEmail)
            {
                return Unauthorized("You can only revoke your own task submissions.");
            }

            // Reset to Pending status
            task.Status = "Pending";
            task.CompletedDate = null;
            task.EmployeeRemarks = null;
            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Task submission revoked successfully. Task returned to Pending status." });
        }

        // Admin: Edit a task
        [HttpPut("edit/{id}")]
        public async Task<IActionResult> EditTask(int id, [FromBody] TaskAssignment updatedTask)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == id && t.CompanyId == companyId);
            if (task == null)
            {
                return NotFound("Task not found.");
            }

            task.Title = updatedTask.Title;
            task.Description = updatedTask.Description;
            task.AssignedToEmail = updatedTask.AssignedToEmail;
            task.DueDate = updatedTask.DueDate;
            task.Priority = updatedTask.Priority;
            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Task updated successfully" });
        }

        // Admin: Delete a task
        [HttpDelete("delete/{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var task = await _context.TaskAssignments
                .FirstOrDefaultAsync(t => t.Id == id && t.CompanyId == companyId);
            if (task == null)
            {
                return NotFound("Task not found.");
            }

            _context.TaskAssignments.Remove(task);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Task deleted successfully" });
        }

        // Background job: Mark overdue tasks (called by scheduled job or on-demand)
        [HttpPost("check-overdue")]
        public async Task<IActionResult> CheckOverdueTasks()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var today = _timeService.GetIndianStandardToday();
            var tasks = await _context.TaskAssignments
                .Where(t => t.Status == "Pending" && t.DueDate.Date < today && t.CompanyId == companyId)
                .ToListAsync();

            foreach (var task in tasks)
            {
                task.Status = "Overdue";
                task.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = $"Marked {tasks.Count} tasks as overdue" });
        }
    }

    // Request models
    public class SubmitTasksRequest
    {
        public string EmployeeEmail { get; set; } = string.Empty;
        public string EmployeeName { get; set; } = string.Empty;
        public List<int> CompletedTaskIds { get; set; } = new List<int>();
        public List<int> PendingTaskIds { get; set; } = new List<int>();
        public Dictionary<int, string>? TaskRemarks { get; set; }
    }

    public class SubmitSingleTaskRequest
    {
        public int TaskId { get; set; }
        public string EmployeeEmail { get; set; } = string.Empty;
        public string? Remarks { get; set; }
    }

    public class RejectTaskRequest
    {
        public string AdminRemarks { get; set; } = string.Empty;
        public string? AdminEmail { get; set; }
    }

    public class ApproveTaskRequest
    {
        public string? AdminEmail { get; set; }
        public string? AdminRemarks { get; set; } // Optional remarks for approval
    }

    public class RevokeTaskRequest
    {
        public string EmployeeEmail { get; set; } = string.Empty;
    }
}
