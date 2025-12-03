using Backend.Models;
using Backend.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Linq;
using System;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AttendanceContext _context;

        public AuthController(AttendanceContext context)
        {
            _context = context;
        }

        [HttpGet("health")]
        public IActionResult Health()
        {
            return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
        }

        [HttpGet("debug/users")]
        public IActionResult DebugUsers()
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            var users = _context.Users
                .Where(u => u.CompanyId == companyId)
                .Select(u => new { u.Email, u.CompanyId, u.IsApproved, u.Role })
                .ToList();
            return Ok(new { companyId, userCount = users.Count, users });
        }

        [HttpPost("debug/create-admin")]
        public IActionResult CreateTestAdmin([FromBody] User testUser)
        {
            var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
            
            // Check if user exists
            var existing = _context.Users.FirstOrDefault(u => u.Email == testUser.Email && u.CompanyId == companyId);
            if (existing != null)
            {
                // Update existing user
                existing.Password = testUser.Password;
                existing.IsApproved = true;
                existing.Role = testUser.Role ?? "Admin";
                existing.Name = testUser.Name ?? existing.Name;
                _context.SaveChanges();
                return Ok(new { message = "User updated", email = existing.Email, companyId });
            }
            
            // Create new user
            testUser.CompanyId = companyId;
            testUser.IsApproved = true;
            testUser.Role = testUser.Role ?? "Admin";
            testUser.WifiSsid = testUser.WifiSsid ?? string.Empty;
            _context.Users.Add(testUser);
            _context.SaveChanges();
            return Ok(new { message = "User created", email = testUser.Email, companyId });
        }

        [HttpPost("register")]
public IActionResult Register([FromBody] User newUser)
{
    // Get CompanyId from header
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    newUser.CompanyId = companyId;
    
    // Ensure WifiSsid is not null
    newUser.WifiSsid = newUser.WifiSsid ?? string.Empty;

    if (_context.Users.Any(u => u.Email == newUser.Email && u.CompanyId == companyId))
        return BadRequest(new { message = "Email already exists" });

    // Auto-approve if this is the first user for this company (will be admin)
    var isFirstUser = !_context.Users.Any(u => u.CompanyId == companyId);
    newUser.IsApproved = isFirstUser;
    
    // Set role to Admin if first user
    if (isFirstUser && string.IsNullOrEmpty(newUser.Role))
    {
        newUser.Role = "Admin";
    }

    Console.WriteLine($"📝 Registering user: {newUser.Email} (CompanyId: {companyId}, IsFirstUser: {isFirstUser}, AutoApproved: {newUser.IsApproved})");

    // Plaintext password (insecure)
    _context.Users.Add(newUser);
    _context.SaveChanges();

    return Ok(new { newUser.Id, newUser.Email, newUser.Name, newUser.Role, IsApproved = newUser.IsApproved });
}


        [HttpPost("login")]
public IActionResult Login([FromBody] User loginRequest)
{
    // Get CompanyId from header
    var companyId = Request.Headers["X-Company-Id"].FirstOrDefault() ?? "default";
    
    Console.WriteLine($"🔐 Login attempt: Email={loginRequest.Email}, CompanyId={companyId}");
    
    // First, validate user credentials (filter by CompanyId)
    var user = _context.Users.FirstOrDefault(u => u.Email == loginRequest.Email && u.CompanyId == companyId);
    if (user == null)
    {
        Console.WriteLine($"❌ User not found: Email={loginRequest.Email}, CompanyId={companyId}");
        return Unauthorized(new { message = "Invalid email or password" });
    }
    
    if (user.Password != loginRequest.Password)
    {
        Console.WriteLine($"❌ Wrong password for: {loginRequest.Email}");
        return Unauthorized(new { message = "Invalid email or password" });
    }

    if (!user.IsApproved)
    {
        Console.WriteLine($"⏳ User not approved: {loginRequest.Email}");
        return Unauthorized(new { message = "Your account is awaiting admin approval." });
    }

    Console.WriteLine($"✅ Login successful: {user.Email} ({user.Role})");

    // NO network validation for login - both admins and employees can login from anywhere
    // Network validation is ONLY enforced for:
    // 1. Punch In/Out (AttendanceController)
    // 2. WorkLog submission (WorkLogController)

    var token = GenerateJwtToken(user);

    return Ok(new
    {
        Id = user.Id,
        Email = user.Email,
        Name = user.Name,
        Role = user.Role,
        token = token
    });
}


        private string GenerateJwtToken(User user)
        {
            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Name, user.Name),
                new Claim(ClaimTypes.Role, user.Role)
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("YourSecretSigningKeyHereMustBeLongAndSecuremanideep7287"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: null,
                audience: null,
                claims: claims,
                expires: DateTime.UtcNow.AddHours(1),
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
