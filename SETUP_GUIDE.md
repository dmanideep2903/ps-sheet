# 📚 DeskAttendance App - Complete Setup Guide

## 🚀 Quick Start

### For Development (Your Current Setup)

```powershell
# 1. Start Docker Desktop (if not running)

# 2. Start PostgreSQL
docker start attendance-postgres

# 3. Start Electron App (includes backend + frontend)
cd P:\SourceCode-HM\DeskAttendanceApp\electron-app
npm start
```

**Login Credentials:**
- **Email:** pivotadmin@gmail.com
- **Password:** Admin123

---

## 📦 What's Installed

### Your Development Machine:
✅ Docker Desktop (PostgreSQL container)  
✅ PostgreSQL 16 in Docker (database)  
✅ .NET 9.0 SDK (backend)  
✅ Node.js + npm (frontend)  
✅ Electron (desktop app wrapper)  
✅ VS Code (your IDE)

### Database Migration Complete:
✅ Migrated from SQL Server to PostgreSQL  
✅ Connection pooling configured (10-100 connections)  
✅ UTC timestamp handling enabled  
✅ All tables created (6 tables)  
✅ Admin user seeded  

---

## 🗄️ Database Information

**Type:** PostgreSQL 16  
**Host:** localhost (Docker container)  
**Port:** 5432  
**Database Name:** AttendanceDb  
**Username:** postgres  
**Password:** postgres  *(Change for production!)*  

**Connection String:**
```
Host=localhost;Database=AttendanceDb;Username=postgres;Password=postgres;Port=5432;Pooling=true;MinPoolSize=10;MaxPoolSize=100;
```

**Tables:**
1. `AttendanceRecords` - Employee punch in/out records
2. `Users` - Employee accounts
3. `WorkLogs` - Daily work logs
4. `UserProfiles` - Employee profiles
5. `TaskAssignments` - Task management
6. `SystemSettings` - App configuration

---

## 🔧 Common Commands

### Docker Commands

```powershell
# Check if PostgreSQL is running
docker ps | findstr attendance-postgres

# Start PostgreSQL
docker start attendance-postgres

# Stop PostgreSQL
docker stop attendance-postgres

# View PostgreSQL logs
docker logs attendance-postgres

# Access PostgreSQL shell
docker exec -it attendance-postgres psql -U postgres -d AttendanceDb

# Remove PostgreSQL container (WARNING: Deletes all data!)
docker rm -f attendance-postgres
```

### Database Commands

```powershell
cd backend

# Create new migration
dotnet ef migrations add MigrationName

# Apply migrations
dotnet ef database update

# Remove last migration
dotnet ef migrations remove

# View migrations
dotnet ef migrations list
```

### Backup & Restore

```powershell
# Backup database (automated script)
.\backup-database.ps1

# Manual backup
docker exec attendance-postgres pg_dump -U postgres AttendanceDb > backup.sql

# Restore from backup
docker exec -i attendance-postgres psql -U postgres AttendanceDb < backup.sql

# Backup with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
docker exec attendance-postgres pg_dump -U postgres AttendanceDb > "backup_$timestamp.sql"
```

### Backend Commands

```powershell
cd backend

# Run backend only
dotnet run

# Build for production
dotnet publish -c Release

# Run tests
dotnet test
```

### Frontend Commands

```powershell
cd react-app

# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

### Electron Commands

```powershell
cd electron-app

# Start desktop app (includes backend)
npm start

# Build Windows installer
npm run dist

# Build for all platforms
npm run dist -- --win --mac --linux
```

---

## 🏗️ Project Structure

```
DeskAttendanceApp/
├── backend/                    # ASP.NET Core API
│   ├── Controllers/            # API endpoints
│   ├── Models/                 # Database models
│   ├── Data/                   # DbContext
│   ├── Services/               # Business logic
│   ├── Migrations/             # Database migrations
│   ├── appsettings.json        # Production config
│   └── Program.cs              # Main entry point
│
├── react-app/                  # React frontend
│   ├── src/
│   │   ├── components/         # UI components
│   │   ├── utils/              # Helper functions
│   │   └── App.js              # Main app component
│   └── public/                 # Static assets
│
├── electron-app/               # Desktop app wrapper
│   ├── main.js                 # Electron main process
│   ├── preload.js              # Preload scripts
│   └── package.json            # Electron config
│
├── DatabaseBackups/            # Automated backups
│   └── AttendanceDb_*.sql
│
├── backup-database.ps1         # Backup script
├── TESTING_CHECKLIST.md        # This file
└── README.md                   # Project documentation
```

---

## 🔐 Security Notes

### Development (Current):
- Password: `postgres` (default)
- JWT Secret: Hardcoded in Program.cs
- CORS: localhost:3000, 3001
- HTTPS: Disabled

### Production (Before Selling):
```powershell
# Change these BEFORE production:

# 1. PostgreSQL password
docker run -d --name attendance-postgres \
  -e POSTGRES_PASSWORD=SecureRandomPassword123! \
  -e POSTGRES_DB=AttendanceDb \
  -p 5432:5432 postgres:16

# 2. Update appsettings.Production.json with new password

# 3. Generate new JWT secret (min 32 characters)

# 4. Enable HTTPS in Program.cs

# 5. Configure firewall rules
New-NetFirewallRule -DisplayName "Attendance Backend" -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow
```

---

## 🌐 Deployment Options

### Option 1: Local Server (Recommended for Companies)
**1 Server + 50 Employee Laptops**

**Server Setup:**
```powershell
# Install Docker Desktop on server
# Start PostgreSQL
docker run -d --name attendance-postgres \
  --restart=always \
  -e POSTGRES_PASSWORD=SecurePassword123! \
  -e POSTGRES_DB=AttendanceDb \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

# Run backend as Windows Service (use NSSM or Task Scheduler)
cd backend\bin\Release\net9.0\publish
.\backend.exe
```

**Employee Laptops:**
- Just install DeskAttendance.exe
- No Docker needed
- No PostgreSQL needed
- Connects to server at: `http://server-ip:5001`

### Option 2: Oracle Cloud Always Free
**Cost:** $0/month forever

1. Create Oracle Cloud account
2. Create Compute Instance (2 OCPU, 16GB RAM)
3. Install Docker
4. Deploy PostgreSQL + Backend
5. Configure firewall (port 5001, 5432)
6. Point employee laptops to cloud URL

---

## 🐛 Troubleshooting

### Backend won't start

**Error:** `Port 5001 already in use`

**Solution:**
```powershell
Get-Process | Where-Object {$_.ProcessName -eq "dotnet"} | Stop-Process -Force
```

### Database connection failed

**Error:** `Failed to connect to PostgreSQL`

**Check:**
```powershell
# Is Docker running?
docker ps

# Is PostgreSQL container running?
docker start attendance-postgres

# Test connection
docker exec attendance-postgres psql -U postgres -c "SELECT version();"
```

### Electron app won't open

**Error:** Backend crash loop

**Solution:**
```powershell
cd electron-app
# Delete node_modules and reinstall
rm -r node_modules
npm install
npm start
```

### Migrations error

**Error:** `Pending model changes`

**Solution:**
```powershell
cd backend
dotnet ef migrations add FixModelChanges
dotnet ef database update
```

### Face recognition not working

**Missing models folder**
```powershell
# Download face-api.js models
cd react-app\public
mkdir models
# Download from: https://github.com/justadudewhohacks/face-api.js/tree/master/weights
```

---

## 📊 Performance Optimization

### Current Configuration:
- Connection Pool: 10-100 connections
- Database: PostgreSQL 16 (optimized for concurrency)
- Backend: ASP.NET Core 9.0 (high performance)
- Frontend: React 18 (virtual DOM)

### For 50+ Users:
```sql
-- Add database indexes (run in PostgreSQL)
CREATE INDEX idx_attendance_employee ON AttendanceRecords(EmployeeId);
CREATE INDEX idx_attendance_date ON AttendanceRecords(Timestamp);
CREATE INDEX idx_users_email ON Users(Email);
CREATE INDEX idx_worklog_employee ON WorkLogs(EmployeeId);
```

### For 500+ Users:
- Deploy to cloud with autoscaling
- Use Redis for caching
- Enable CDN for static assets
- Implement load balancing

---

## 📞 Support & Maintenance

### Weekly Tasks:
- [ ] Run backup: `.\backup-database.ps1`
- [ ] Check disk space: `docker system df`
- [ ] Review logs: `docker logs attendance-postgres`

### Monthly Tasks:
- [ ] Update Docker images: `docker pull postgres:16`
- [ ] Update .NET SDK: `winget upgrade Microsoft.DotNet.SDK.9`
- [ ] Update npm packages: `npm update` (in each folder)

### Quarterly Tasks:
- [ ] Review security updates
- [ ] Test disaster recovery procedure
- [ ] Performance audit

---

## 📝 Quick Reference

### Admin Account
- Email: pivotadmin@gmail.com
- Password: Admin123
- Employee ID: 1003

### API Endpoints
- Login: POST `/api/auth/login`
- Punch In: POST `/api/attendance/punch-in`
- Punch Out: POST `/api/attendance/punch-out`
- Get Attendance: GET `/api/attendance`
- Health Check: GET `/health`

### Default Settings
- Router MAC: 3C-64-CF-30-FC-2D
- Gateway IP: 192.168.0.1
- Validation Mode: Strict

### Ports
- Backend API: 5001
- React Dev: 3000
- PostgreSQL: 5432
- Electron: Dynamic

---

## 🎯 Next Steps

### To Test:
1. ✅ Complete TESTING_CHECKLIST.md
2. ✅ Test with multiple users
3. ✅ Run backup script
4. ✅ Test restore from backup

### To Deploy:
1. ⏳ Build production installer
2. ⏳ Set up Oracle Cloud (optional)
3. ⏳ Configure network restrictions
4. ⏳ Create user documentation

### To Sell:
1. ⏳ Create demo video
2. ⏳ Build landing page
3. ⏳ Set pricing tiers
4. ⏳ Prepare deployment guide for customers

---

**Last Updated:** November 12, 2025  
**Version:** 2.0 (PostgreSQL Migration Complete)  
**Status:** ✅ Ready for Testing
