using Backend.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/admin")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly AttendanceContext _context;

        public AdminController(AttendanceContext context)
        {
            _context = context;
        }

        // GET api/admin/AttendanceRecords?start={start}&end={end}&employeeId={employeeId}
        [HttpGet("AttendanceRecords")]
        public IActionResult GetAttendanceRecords(DateTime? start, DateTime? end, string? employeeId)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var query = from record in _context.AttendanceRecords
            join user in _context.Users
            on record.EmployeeId equals user.Email
            where record.CompanyId == companyId && user.CompanyId == companyId
            select new
            {
                record.Id,
                record.EmployeeId,
                Name = user.Name,
                record.Timestamp,
                record.IsClockIn,
                record.WifiSsid
            };


            if (start.HasValue)
                query = query.Where(r => r.Timestamp >= start.Value);
            if (end.HasValue)
                query = query.Where(r => r.Timestamp <= end.Value);
            if (!string.IsNullOrEmpty(employeeId))
                query = query.Where(r => r.EmployeeId == employeeId);

            var records = query.OrderByDescending(r => r.Timestamp).ToList();

            return Ok(records);
        }

        // DELETE api/admin/AttendanceRecord/{id}
        [HttpDelete("AttendanceRecord/{id}")]
        public IActionResult DeleteAttendanceRecord(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var record = _context.AttendanceRecords.FirstOrDefault(r => r.Id == id && r.CompanyId == companyId);
            if (record == null)
                return NotFound();

            _context.AttendanceRecords.Remove(record);
            _context.SaveChanges();

            return NoContent();
        }

        // PUT api/admin/AttendanceRecord/{id}
        [HttpPut("AttendanceRecord/{id}")]
public IActionResult UpdateAttendanceRecord(int id, [FromBody] DateTime newTimestamp)
{
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    
    var record = _context.AttendanceRecords.FirstOrDefault(r => r.Id == id && r.CompanyId == companyId);
    if (record == null)
        return NotFound();

    // Frontend already sends UTC timestamps - store as-is
    // Just ensure the timestamp is marked as UTC for database storage
    if (newTimestamp.Kind == DateTimeKind.Unspecified)
    {
        newTimestamp = DateTime.SpecifyKind(newTimestamp, DateTimeKind.Utc);
    }
    else if (newTimestamp.Kind == DateTimeKind.Local)
    {
        newTimestamp = newTimestamp.ToUniversalTime();
    }
    
    record.Timestamp = newTimestamp;
    _context.SaveChanges();

    return NoContent();
}

    }
}
