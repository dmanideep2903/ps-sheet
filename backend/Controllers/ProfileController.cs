using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProfileController : ControllerBase
    {
        private readonly AttendanceContext _context;

        public ProfileController(AttendanceContext context)
        {
            _context = context;
        }

        // GET: api/Profile/{email}
        [HttpGet("{email}")]
        public IActionResult GetProfile(string email)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var profile = _context.UserProfiles.FirstOrDefault(p => p.Email == email && p.CompanyId == companyId);
            if (profile == null)
                return NotFound(new { message = "Profile not found" });

            return Ok(profile);
        }

        // POST: api/Profile
        [HttpPost]
        public IActionResult CreateProfile([FromBody] UserProfile profile)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Validate mobile number: exactly 10 digits
            if (!string.IsNullOrWhiteSpace(profile.PhoneNumber))
            {
                var digitsOnly = new string(profile.PhoneNumber.Where(char.IsDigit).ToArray());
                if (digitsOnly.Length != 10)
                {
                    return BadRequest(new { message = "Mobile number must be exactly 10 digits" });
                }
            }

            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var existing = _context.UserProfiles.FirstOrDefault(p => p.Email == profile.Email && p.CompanyId == companyId);
            if (existing != null)
                return BadRequest(new { message = "Profile already exists for this email" });

            profile.CompanyId = companyId;
            profile.CreatedAt = DateTime.UtcNow;
            profile.UpdatedAt = DateTime.UtcNow;
            
            _context.UserProfiles.Add(profile);
            _context.SaveChanges();

            return Ok(profile);
        }

        // PUT: api/Profile/{email}
        [HttpPut("{email}")]
        public IActionResult UpdateProfile(string email, [FromBody] UserProfile updatedProfile)
        {
            // Validate mobile number: exactly 10 digits
            if (!string.IsNullOrWhiteSpace(updatedProfile.PhoneNumber))
            {
                var digitsOnly = new string(updatedProfile.PhoneNumber.Where(char.IsDigit).ToArray());
                if (digitsOnly.Length != 10)
                {
                    return BadRequest(new { message = "Mobile number must be exactly 10 digits" });
                }
            }

            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var profile = _context.UserProfiles.FirstOrDefault(p => p.Email == email && p.CompanyId == companyId);
            if (profile == null)
                return NotFound(new { message = "Profile not found" });

            profile.FirstName = updatedProfile.FirstName;
            profile.MiddleName = updatedProfile.MiddleName;
            profile.LastName = updatedProfile.LastName;
            profile.DateOfBirth = updatedProfile.DateOfBirth;
            profile.PhoneNumber = updatedProfile.PhoneNumber;
            profile.Address = updatedProfile.Address;
            profile.ProfilePicture = updatedProfile.ProfilePicture;
            
            // Update face recognition data
            profile.FaceDescriptor = updatedProfile.FaceDescriptor;
            profile.FaceRegistered = updatedProfile.FaceRegistered;
            
            profile.UpdatedAt = DateTime.UtcNow;

            _context.SaveChanges();
            return Ok(profile);
        }

        // Check if profile exists
        [HttpGet("exists/{email}")]
        public IActionResult ProfileExists(string email)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            var exists = _context.UserProfiles.Any(p => p.Email == email && p.CompanyId == companyId);
            return Ok(new { exists });
        }

        // PUT: api/Profile/update-settings - Employee settings update
        [HttpPut("update-settings")]
        public IActionResult UpdateSettings([FromBody] EmployeeSettingsUpdate settings)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            // First, verify user exists in Users table
            var user = _context.Users.FirstOrDefault(u => 
                u.Email == settings.EmployeeId && u.CompanyId == companyId);
            
            if (user == null)
                return NotFound(new { message = "User account not found" });

            // Find profile by email (EmployeeId is actually the email)
            var profile = _context.UserProfiles.FirstOrDefault(p => 
                p.Email == settings.EmployeeId && p.CompanyId == companyId);
            
            // If profile doesn't exist, create it from user data
            if (profile == null)
            {
                profile = new UserProfile
                {
                    Email = settings.EmployeeId,
                    CompanyId = companyId,
                    FirstName = user.Name ?? "",
                    LastName = "",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.UserProfiles.Add(profile);
            }

            // Verify current password if password change requested
            if (!string.IsNullOrWhiteSpace(settings.CurrentPassword) && 
                !string.IsNullOrWhiteSpace(settings.NewPassword))
            {
                if (user.Password != settings.CurrentPassword)
                {
                    return BadRequest(new { message = "Current password is incorrect" });
                }
                
                // Update password in Users table
                user.Password = settings.NewPassword;
            }

            // Update address if provided
            if (!string.IsNullOrWhiteSpace(settings.Address))
            {
                profile.Address = settings.Address;
            }

            // Update phone number if provided
            if (!string.IsNullOrWhiteSpace(settings.PhoneNumber))
            {
                var digitsOnly = new string(settings.PhoneNumber.Where(char.IsDigit).ToArray());
                if (digitsOnly.Length != 10)
                {
                    return BadRequest(new { message = "Mobile number must be exactly 10 digits" });
                }
                profile.PhoneNumber = digitsOnly;
            }

            profile.UpdatedAt = DateTime.UtcNow;
            _context.SaveChanges();

            return Ok(new { message = "Settings updated successfully", profile });
        }
    }
}
