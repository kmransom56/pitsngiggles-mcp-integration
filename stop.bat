@echo off
REM Stop Pits n' Giggles

echo Stopping Pits n' Giggles...

REM Kill Python processes running the launcher
taskkill /F /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *apps.launcher*" >nul 2>&1

REM Also try to kill by command line pattern
wmic process where "commandline like '%%apps.launcher%%'" delete >nul 2>&1

echo ✓ Pits n' Giggles stopped

pause
