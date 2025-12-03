using System.ComponentModel.DataAnnotations;

namespace Backend.Models
{
    public class UserProfile
    {
        [Key]
        public int Id { get; set; }

        public string CompanyId { get; set; } = "default"; // Multi-tenant support

        [Required]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string FirstName { get; set; } = string.Empty;

        public string MiddleName { get; set; } = string.Empty;

        [Required]
        public string LastName { get; set; } = string.Empty;

        [Required]
        public DateTime DateOfBirth { get; set; }

        [Required]
        [Phone]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        public string Address { get; set; } = string.Empty;

        public string ProfilePicture { get; set; } = string.Empty; // Base64 or file path

        // Face Recognition fields
        public string? FaceDescriptor { get; set; }  // JSON array of 128-dimensional face descriptor
        public bool FaceRegistered { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
