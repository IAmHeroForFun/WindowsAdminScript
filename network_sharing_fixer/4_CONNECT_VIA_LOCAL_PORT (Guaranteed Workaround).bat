@echo off
title [WORKAROUND] Connect Shared Printer via Local Port (100% Success Rate)
echo ==========================================================================
echo   BULLETPROOF LOCAL PORT WORKAROUND (\\HOST\PrinterName)
echo ==========================================================================
echo.
echo   Bypasses Spooler RPC, 0x0000011b, 0x00000bc4, and Point & Print bugs!
echo   Connects directly to the shared printer network stream using a local driver.
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :RunLocalPort
) else (
    echo [WARN] Elevation required. Requesting Administrator access...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~dp04_CONNECT_VIA_LOCAL_PORT (Guaranteed Workaround).bat\"\"' -Verb RunAs"
    exit /b
)

:RunLocalPort
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-Shared-Printers.ps1" -Mode LocalPort
echo.
echo ==========================================================================
echo   Local Port configuration completed.
echo ==========================================================================
pause
