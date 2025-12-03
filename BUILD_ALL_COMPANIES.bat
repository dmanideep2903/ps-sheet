@echo off
echo ========================================
echo   Building All Company Installers
echo ========================================
echo.
echo Ensuring electron-updater is installed...
cd electron-app
call npm install
echo.

REM Build Mark Audio
echo [1/3] Building MarkAudio...
copy /Y appConfig-MarkAudio.json appConfig.json
powershell -Command "(Get-Content package.json) -replace '\"productName\": \".*\"', '\"productName\": \"MarkAudio\"' | Set-Content package.json"
call npm run dist
echo.

REM Build Pivot
echo [2/3] Building Pivot...
copy /Y appConfig-Pivot.json appConfig.json
powershell -Command "(Get-Content package.json) -replace '\"productName\": \".*\"', '\"productName\": \"Pivot\"' | Set-Content package.json"
call npm run dist
echo.

REM Build Revit
echo [3/3] Building Revit...
copy /Y appConfig-Revit.json appConfig.json
powershell -Command "(Get-Content package.json) -replace '\"productName\": \".*\"', '\"productName\": \"Revit\"' | Set-Content package.json"
call npm run dist
echo.

REM Restore original
powershell -Command "(Get-Content package.json) -replace '\"productName\": \".*\"', '\"productName\": \"Company Attendance\"' | Set-Content package.json"

echo ========================================
echo   BUILD COMPLETE!
echo ========================================
echo.
echo Installers created:
dir dist\*.exe /B
echo.
echo Located in: electron-app\dist\
echo.
pause
