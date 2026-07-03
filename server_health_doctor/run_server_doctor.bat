@echo off
title Windows Server Health & Misconfiguration Doctor
echo =========================================================
echo       Launching Server Health & Misconfiguration Scan...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0server_doctor.ps1"

echo.
pause
