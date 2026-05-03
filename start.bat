@echo off
REM Pits n' Giggles - One-Command Startup with F1 Race Engineer (Windows)
REM This script starts the telemetry app with MCP server

setlocal enabledelayedexpansion

echo ╔═══════════════════════════════════════════════════════════════╗
echo ║     Pits n' Giggles - F1 Race Engineer Starting...           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM Get script directory
cd /d "%~dp0"

echo [1/4] Checking prerequisites...

REM Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ✗ Python not found. Please install Python 3.8+ from python.org
    pause
    exit /b 1
)
echo ✓ Python found

REM Check if virtual environment exists
if not exist ".venv" (
    echo Creating virtual environment...
    python -m venv .venv
)

echo.
echo [2/4] Setting up Python environment...

REM Activate virtual environment
call .venv\Scripts\activate.bat

REM Install dependencies
echo Installing dependencies...
python -m pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

echo ✓ Dependencies installed

echo.
echo [3/4] Starting Pits n' Giggles backend...

REM Set PYTHONPATH
set PYTHONPATH=%CD%

REM Start the application
echo Starting backend...
start /B python -O -m apps.launcher > pits-n-giggles.log 2>&1
timeout /t 5 /nobreak >nul

echo ✓ Backend started

echo.
echo [4/4] Verifying services...

REM Wait for service to be ready
timeout /t 3 /nobreak >nul

REM Try to check if server is running
curl -s http://localhost:4768/race-info >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ HTTP telemetry server running
) else (
    echo ⚠ HTTP telemetry server not responding yet
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║     ✓ Pits n' Giggles is Running!                             ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo 🏎️  Access Points:
echo   • Telemetry Dashboard:  http://localhost:4768
echo   • Engineer View:        http://localhost:4768/eng-view
echo   • F1 Race Engineer:     http://localhost:4768/strategy-center
echo.
echo 🤖 AI Integration:
echo   • MCP Endpoint:         http://localhost:4768/mcp
echo.
echo 📚 Quick Setup:
echo   • ChatGPT Desktop:  Settings → Apps → Create New App
echo                       URL: http://localhost:4768/mcp (Transport: SSE)
echo   • Claude Desktop:   Add to claude_desktop_config.json:
echo                       See docs/AI_CLIENT_SETUP.md
echo   • Cursor IDE:       Settings → MCP → Add Server
echo                       URL: http://localhost:4768/mcp
echo.
echo 📊 Available F1 Race Engineer Tools:
echo   • Lap time consistency analysis
echo   • Performance issue diagnosis
echo   • Leader comparison
echo   • Sector performance breakdown
echo   • Tyre strategy analysis
echo.
echo 🎮 Next Steps:
echo   1. Start F1 23/24/25 game
echo   2. Enter a session (practice, qualifying, or race)
echo   3. Open: http://localhost:4768/strategy-center
echo   4. Ask AI: "Analyze my current performance"
echo.
echo 🛑 To Stop:
echo   Press Ctrl+C in this window, or run stop.bat
echo.
echo 📋 Logs:
echo   type pits-n-giggles.log
echo.
echo Press any key to open Strategy Center in browser...
pause >nul
start http://localhost:4768/strategy-center

REM Keep window open
echo.
echo Backend is running. Press Ctrl+C to stop.
pause
