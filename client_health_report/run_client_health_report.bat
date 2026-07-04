@echo off
title MSP One-Click Client Health Report Generator [Option 13]
echo =========================================================
echo   Generating Executive Client Health & SLA Report...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_report.ps1"

echo.
pause
