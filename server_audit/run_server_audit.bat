@echo off
title Main Server Forensic & Configuration Auditor
echo =========================================================
echo       Launching Main Server Audit Extraction...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit_server.ps1"

echo.
pause
