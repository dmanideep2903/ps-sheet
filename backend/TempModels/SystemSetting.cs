using System;
using System.Collections.Generic;

namespace backend.TempModels;

public partial class SystemSetting
{
    public int Id { get; set; }

    public string Description { get; set; } = null!;

    public string SettingKey { get; set; } = null!;

    public string SettingValue { get; set; } = null!;

    public DateTime UpdatedAt { get; set; }

    public string UpdatedBy { get; set; } = null!;
}
