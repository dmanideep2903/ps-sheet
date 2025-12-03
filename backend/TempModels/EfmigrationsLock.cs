using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class EfmigrationsLock
{
    public int Id { get; set; }

    public string Timestamp { get; set; } = null!;
}
