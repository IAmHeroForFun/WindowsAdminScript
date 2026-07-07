@echo off
title Windows Security & Forensic Auditor [Batch Launcher]
color 0B
echo ==========================================================================
echo        ENTERPRISE WINDOWS SECURITY & FORENSIC AUDIT TOOLKIT
echo ==========================================================================
echo.

:: 1. Verify Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ELEVATION REQUIRED] This security audit requires Administrator privileges
    echo to inspect listening ports, Defender threat history, and persistence keys.
    echo.
    echo Requesting UAC Elevation...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [+] Running as Administrator: YES
echo [+] Initializing Audit Output Directory...
set "REPORTS_DIR=%~dp0Reports"
if not exist "%REPORTS_DIR%" mkdir "%REPORTS_DIR%"

echo [+] Launching 10-Phase PowerShell Forensic Security Engine...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enterprise_security_auditor.ps1" -OutputDir "%REPORTS_DIR%"

echo.
echo ==========================================================================
echo   [+] Audit Complete! Reports saved to: %REPORTS_DIR%
echo ==========================================================================
echo.
pause
