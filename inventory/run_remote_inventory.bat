@echo off
title Remote Network Inventory Tool
echo ===================================================
echo       Running Remote Network Inventory Tool...
echo ===================================================
echo.
echo Scanning network and querying remote Windows PCs...
echo Please do not close this window.
echo.

:: Run the remote inventory PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0remote_inventory.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] An error occurred while running remote inventory.
    echo.
    pause
) else (
    echo.
    pause
)
