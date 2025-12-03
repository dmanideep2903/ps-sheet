# PS Sheet - Employee Attendance & Work Log Management

PS Sheet is a desktop application for managing employee attendance tracking and work log submissions with face recognition authentication.

## Features

- ✅ **Face Recognition** - Biometric attendance check-in/check-out
- 📊 **Work Log Management** - Task assignments, submissions, and approvals
- 👥 **Employee Management** - Comprehensive employee profiles and role management
- 📈 **Reports & Analytics** - Attendance tracking and productivity insights
- 🔒 **Secure** - Local biometric storage with encrypted data transmission
- 🌐 **Multi-tenant** - Support for multiple organizations

## Technology Stack

- **Frontend:** React 19.2.0
- **Desktop:** Electron 38.2.1
- **Backend:** ASP.NET Core 9.0
- **Database:** PostgreSQL
- **Face Recognition:** face-api.js (TensorFlow.js)

## Installation

### Download from Microsoft Store
Coming soon...

### Manual Installation
1. Download the latest release from [Releases](https://github.com/YOUR_USERNAME/ps-sheet/releases)
2. Run the installer (`.exe` or `.msix`)
3. Configure backend connection in `appConfig.json`

## Development Setup

### Prerequisites
- Node.js 18+ 
- .NET SDK 9.0
- PostgreSQL 14+

### Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/ps-sheet.git
cd ps-sheet
```

### Build React App
```bash
cd react-app
npm install
npm run build
```

### Run Electron App
```bash
cd ../electron-app
npm install
npm start
```

### Run Backend
```bash
cd ../backend
dotnet restore
dotnet run
```

## Configuration

### Backend Configuration (`backend/appsettings.json`)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=AttendanceDb;Username=postgres;Password=yourpassword"
  }
}
```

### Electron Configuration (`electron-app/appConfig.json`)
```json
{
  "companyId": "your-company",
  "companyName": "Your Company",
  "apiBaseUrl": "http://localhost:5001",
  "useRemoteBackend": false
}
```

## Building for Distribution

### Windows Installer
```bash
cd electron-app
npm run dist
```

Outputs:
- `dist/PS Sheet Setup.exe` - NSIS installer
- `dist/PS Sheet.msix` - Microsoft Store package

## Privacy & Security

- Biometric data stored **locally only** (never transmitted)
- HTTPS encryption for all server communication
- GDPR & CCPA compliant
- See [Privacy Policy](PRIVACY_POLICY.md)

## License

MIT License - See [LICENSE](LICENSE)

## Support

**Organization:** Pivot Soft  
**Email:** dmanideep2903@outlook.com  
**Location:** Lalapeta, Guntur, 522003

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## Changelog

### Version 1.0.0 (December 2025)
- Initial release
- Face recognition attendance
- Work log management
- Multi-tenant support
- Responsive design
