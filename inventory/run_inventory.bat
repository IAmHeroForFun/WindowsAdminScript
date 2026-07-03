@echo off
title System Inventory Tool
echo ===================================================
echo          Running System Inventory Tool...
echo ===================================================
echo.
echo Please do not close this window. It will close
echo automatically once the inventory process is complete.
echo.

:: Run the PowerShell script relative to the batch file location
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0get_inventory.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] An error occurred while running the inventory script.
    echo.
    pause
)
