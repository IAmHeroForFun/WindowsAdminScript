@echo off
title NOC Uptime & Availability Monitoring [Option 12]
echo =========================================================
echo   Launching Uptime Kuma & PRTG Availability Monitor...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uptime_monitor.ps1"

echo.
pause
