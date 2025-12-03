using Microsoft.EntityFrameworkCore;
using Backend.Models;
using backend.Models;

namespace Backend.Data
{
    public class AttendanceContext : DbContext
    {
        public AttendanceContext(DbContextOptions<AttendanceContext> options) : base(options) { }

        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<WorkLog> WorkLogs { get; set; }
        public DbSet<UserProfile> UserProfiles { get; set; }
        public DbSet<TaskAssignment> TaskAssignments { get; set; }
        public DbSet<SystemSettings> SystemSettings { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            var adminUser = new User
            {
                Id = 1003,
                Email = "pivotadmin@gmail.com",
                Name = "PIVOT ADMIN",
                Role = "Admin",
                IsApproved = true,
                Password = "Admin123",
                WifiSsid = ""
            };

            modelBuilder.Entity<User>().HasData(adminUser);
        }
    }
}
