@echo off
title Remote Desktop (RDP) & CredSSP Repair Suite Launcher
echo ==========================================================================
echo   OmviHub IT Toolkit - RDP & CredSSP Repair Suite
echo ==========================================================================
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrative privileges.
    goto :RunScript
) else (
    echo [WARN] Elevation required. Requesting Administrator access...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"%~dp0Run-As-Administrator.bat\"' -Verb RunAs"
    exit /b
)

:RunScript
echo.
echo Launching fix_rdp.ps1...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_rdp.ps1"
echo.
echo ==========================================================================
echo   Process completed.
echo ==========================================================================
pause
