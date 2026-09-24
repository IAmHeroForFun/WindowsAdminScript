@echo off
title [HOST PC] Shared Printer Repair (Run on PC with USB Printer Attached)
echo ==========================================================================
echo   RUN ON: HOST PC (Print Server / Computer with USB Cable Attached)
echo ==========================================================================
echo.
echo   This fixes Error 0x0000011b, unblocks Windows Firewall, switches the
echo   network from Public to Private, enables Network Discovery services,
echo   and configures printer share permissions for other PCs.
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrative privileges.
    goto :RunHost
) else (
    echo [WARN] Elevation required. Requesting Administrator access...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~dp01_RUN_ON_HOST_PC (Printer Attached).bat\"\"' -Verb RunAs"
    exit /b
)

:RunHost
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-Shared-Printers.ps1" -Mode Host
echo.
echo ==========================================================================
echo   HOST PC configuration completed.
echo ==========================================================================
pause
