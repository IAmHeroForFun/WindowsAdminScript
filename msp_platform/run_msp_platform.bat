@echo off
title Complete Self-Hosted MSP Monitoring Platform [Option 14]
echo =========================================================
echo   Launching 10-Module MSP Enterprise Ecosystem...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0msp_platform.ps1"

echo.
pause
