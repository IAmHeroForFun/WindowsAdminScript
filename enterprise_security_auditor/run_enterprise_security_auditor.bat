@echo off
title Enterprise Security, Compliance & Recovery Auditor [Option 10]
echo =========================================================
echo   Launching Enterprise Security & Compliance Auditor...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enterprise_security_auditor.ps1"

echo.
pause
