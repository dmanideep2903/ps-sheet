using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class UserProfile
{
    public int Id { get; set; }

    public string Address { get; set; } = null!;

    public string CompanyId { get; set; } = null!;

    public string CreatedAt { get; set; } = null!;

    public string DateOfBirth { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? FaceDescriptor { get; set; }

    public int FaceRegistered { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string MiddleName { get; set; } = null!;

    public string PhoneNumber { get; set; } = null!;

    public string ProfilePicture { get; set; } = null!;

    public string UpdatedAt { get; set; } = null!;
}
