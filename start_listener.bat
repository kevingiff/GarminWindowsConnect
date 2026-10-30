@echo off
:: Automatically changes directory to wherever this batch file lives (the cloned repo folder)
cd /d "%~dp0"

echo Starting Garmin Geofence Listener...
python -u listener.py

:: Check if Python exited successfully (sys.exit(0))
if %errorlevel% equ 0 (
    echo Task complete. Closing terminal.
    exit
) else (
    echo.
    echo [ERROR] Listener crashed or dropped out. Press any key to close.
    pause
)