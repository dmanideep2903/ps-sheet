@echo off
echo ========================================
echo   Starting Backend Server
echo ========================================
echo.

cd /d "%~dp0backend"
echo Current directory: %CD%
echo.

echo Checking for existing backend processes...
taskkill /F /IM backend.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Starting backend on http://localhost:5001...
echo.
dotnet run

pause
