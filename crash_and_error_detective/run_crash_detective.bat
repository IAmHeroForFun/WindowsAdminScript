@echo off
title Windows Server Crash, Reboot & Error Forensic Detective
echo =========================================================
echo    Launching Crash & Error Forensic Detective Scan...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0crash_detective.ps1"

echo.
pause
