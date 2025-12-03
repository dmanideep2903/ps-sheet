using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Linq;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/employees")]
    [Authorize(Roles = "Admin")]
    public class EmployeesController : ControllerBase
    {
        private readonly AttendanceContext _context;

        public EmployeesController(AttendanceContext context)
        {
            _context = context;
        }

        // GET: api/employees
        [HttpGet]
        public IActionResult GetAllEmployees()
        {
          // Get CompanyId from header
          var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
          
          var employees = _context.Users
            .Where(u => u.IsApproved == true && u.CompanyId == companyId)
            .Select(u => new {
                u.Id,
                u.Name,
                u.Email,
                u.Role,
                u.IsApproved
            }).ToList();
            return Ok(employees);
        }
       
        // POST: api/employees
        [HttpPost]
        public IActionResult AddEmployee([FromBody] User newEmployee)
        {
            try
            {
                // Get CompanyId from header
                var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
                newEmployee.CompanyId = companyId;
                
                if (string.IsNullOrWhiteSpace(newEmployee.Email))
                    return BadRequest(new { message = "Email is required" });

                if (string.IsNullOrWhiteSpace(newEmployee.Name))
                    return BadRequest(new { message = "Name is required" });

                if (string.IsNullOrWhiteSpace(newEmployee.Password))
                    return BadRequest(new { message = "Password is required" });

                if (_context.Users.Any(u => u.Email == newEmployee.Email && u.CompanyId == companyId))
                    return BadRequest(new { message = "Email already exists" });

                // Ensure defaults
                if (string.IsNullOrWhiteSpace(newEmployee.Role))
                    newEmployee.Role = "Employee";

                // Set WifiSsid to empty string if null (database doesn't allow nulls)
                if (string.IsNullOrEmpty(newEmployee.WifiSsid))
                    newEmployee.WifiSsid = string.Empty;

                _context.Users.Add(newEmployee);
                _context.SaveChanges();

                return CreatedAtAction(nameof(GetEmployeeById), new { id = newEmployee.Id }, newEmployee);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Failed to add employee", error = ex.Message });
            }
        }

        // GET: api/employees/{id}
        [HttpGet("{id}")]
        public IActionResult GetEmployeeById(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            var employee = _context.Users.FirstOrDefault(u => u.Id == id && u.CompanyId == companyId);
            if (employee == null)
                return NotFound();
            return Ok(employee);
        }

        // PUT: api/employees/{id}
        [HttpPut("{id}")]
        public IActionResult UpdateEmployee(int id, [FromBody] User updatedEmployee)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            var employee = _context.Users.FirstOrDefault(u => u.Id == id && u.CompanyId == companyId);
            if (employee == null)
                return NotFound();

            // Update fields (except Id)
            employee.Name = updatedEmployee.Name;
            employee.Email = updatedEmployee.Email;
            employee.Role = updatedEmployee.Role;
            
            // Only update password if provided (not empty)
            if (!string.IsNullOrWhiteSpace(updatedEmployee.Password))
            {
                employee.Password = updatedEmployee.Password;
            }
            
            employee.IsApproved = updatedEmployee.IsApproved;
            _context.SaveChanges();

            return NoContent();
        }

        // DELETE: api/employees/{id}
        [HttpDelete("{id}")]
        public IActionResult DeleteEmployee(int id)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            var employee = _context.Users.FirstOrDefault(u => u.Id == id && u.CompanyId == companyId);
            if (employee == null)
                return NotFound();

            _context.Users.Remove(employee);
            _context.SaveChanges();

            return NoContent();
        }
        // GET: api/employees/unapproved
[HttpGet("unapproved")]
public IActionResult GetUnapprovedEmployees()
{
    // Get CompanyId from header
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    
    var unapprovedEmployees = _context.Users
        .Where(u => u.Role == "Employee" && !u.IsApproved && u.CompanyId == companyId)
        .Select(u => new
        {
            u.Id,
            u.Name,
            u.Email,
            u.IsApproved
        })
        .ToList();

    return Ok(unapprovedEmployees);
}

// POST: api/employees/approve/{id}
[HttpPost("approve/{id}")]
public IActionResult ApproveEmployee(int id)
{
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    var employee = _context.Users.FirstOrDefault(u => u.Id == id && u.Role == "Employee" && u.CompanyId == companyId);
    if (employee == null)
        return NotFound(new { message = "Employee not found" });

    employee.IsApproved = true;
    _context.SaveChanges();

    return Ok(new { message = "Employee approved successfully" });
}

    }
}
