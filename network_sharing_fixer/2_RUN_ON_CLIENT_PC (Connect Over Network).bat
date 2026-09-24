@echo off
title [CLIENT PC] Shared Printer Repair (Run on Workstation Connecting Over Network)
echo ==========================================================================
echo   RUN ON: CLIENT PC (Workstation / Connecting Across Network)
echo ==========================================================================
echo.
echo   This fixes Error 0x00000bc4 ('No printers found'), Error 0x00000709,
echo   Point and Print Non-Admin driver installation blocks (0x00000bcb),
echo   CopyFiles restrictions (0x0000007c), and Windows 11 24H2 WPP.
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrative privileges.
    goto :RunClient
) else (
    echo [WARN] Elevation required. Requesting Administrator access...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~dp02_RUN_ON_CLIENT_PC (Connect Over Network).bat\"\"' -Verb RunAs"
    exit /b
)

:RunClient
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-Shared-Printers.ps1" -Mode Client
echo.
echo ==========================================================================
echo   CLIENT PC configuration completed.
echo ==========================================================================
pause
