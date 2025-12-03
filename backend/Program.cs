using Backend.Data;
using Backend.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Configure DbContext with PostgreSQL for both Dev and Production
// TIMEZONE FIX: Store UTC in database, frontend handles IST conversion
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);
AppContext.SetSwitch("Npgsql.DisableDateTimeInfinityConversions", true);
builder.Services.AddDbContext<AttendanceContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
    .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning)));

// Register HttpClientFactory for TimeService
builder.Services.AddHttpClient();

// Register TimeService as Singleton (caches time sync)
builder.Services.AddSingleton<ITimeService, TimeService>();

// Add controllers with JSON options to ensure UTC format in JSON responses
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Serialize DateTime in ISO 8601 UTC format (with 'Z' suffix)
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
        // Write DateTimes as ISO 8601 strings with UTC indicator
        // This ensures timestamps are sent as "2025-12-14T07:16:00.000Z" instead of "2025-12-14T07:16:00"
    });

// Configure CORS - Allow Electron app and production clients
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp",
        policy => policy.AllowAnyOrigin()  // Allow all origins for desktop app
                        .AllowAnyHeader()
                        .AllowAnyMethod());
});

// Configure Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes("YourSecretSigningKeyHereMustBeLongAndSecuremanideep7287"))
        };
    });

// Configure Authorization
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
});

// Swagger for development
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Initialize database with default settings
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AttendanceContext>();
    
    // Ensure database is created and migrations are applied
    context.Database.Migrate();
    
    // Seed default network settings if they don't exist
    if (!context.SystemSettings.Any())
    {
        context.SystemSettings.AddRange(
            new Backend.Models.SystemSettings
            {
                SettingKey = "AllowedRouterMac",
                SettingValue = "3C-64-CF-30-FC-2D",
                Description = "Default router MAC address for network validation",
                UpdatedAt = DateTime.UtcNow,
                UpdatedBy = "System"
            },
            new Backend.Models.SystemSettings
            {
                SettingKey = "AllowedGatewayIp",
                SettingValue = "192.168.0.1",
                Description = "Default gateway IP address for network validation",
                UpdatedAt = DateTime.UtcNow,
                UpdatedBy = "System"
            },
            new Backend.Models.SystemSettings
            {
                SettingKey = "ValidationMode",
                SettingValue = "Strict",
                Description = "Network validation mode: Strict or Relaxed",
                UpdatedAt = DateTime.UtcNow,
                UpdatedBy = "System"
            }
        );
        context.SaveChanges();
    }
}

// Health check endpoint for Electron
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

// Ensure routing middleware is enabled
app.UseRouting();

// Enable CORS, Authentication, and Authorization
app.UseCors("AllowReactApp");
app.UseAuthentication();
app.UseAuthorization();

// Swagger UI in development
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Map controller routes
app.MapControllers();

// Listen on all interfaces for production deployment
app.Urls.Add("http://0.0.0.0:5001");

app.Run();
