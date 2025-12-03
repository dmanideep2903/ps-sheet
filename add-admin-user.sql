-- Add admin user for revit2025 company
INSERT INTO "Users" ("Email", "Name", "Password", "Role", "CompanyId", "IsApproved", "WifiSsid")
VALUES ('revit@markaudio.com', 'Revit Admin', 'Admin@123', 'Admin', 'revit2025', true, '')
ON CONFLICT ("Email", "CompanyId") 
DO UPDATE SET 
    "Password" = 'Admin@123',
    "IsApproved" = true,
    "Role" = 'Admin';
