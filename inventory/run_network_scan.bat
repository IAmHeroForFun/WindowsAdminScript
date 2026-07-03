@echo off
title Network Discovery Scan
echo ===================================================
echo          Running Network Discovery Scan...
echo ===================================================
echo.
echo Scanning local network for online devices.
echo Please do not close this window.
echo.

:: Run the network scanning PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scan_network.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] An error occurred while scanning the network.
    echo.
    pause
)
