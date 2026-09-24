@echo off
title [UNIVERSAL] Shared Printer All-in-One Fix (Host + Client)
echo ==========================================================================
echo   UNIVERSAL ALL-IN-ONE FIX (Safe for Any Windows 10/11 PC)
echo ==========================================================================
echo.
echo   Applies both Host (Server) and Client remediations simultaneously.
echo   Recommended for peer-to-peer offices where PCs share each other's printers.
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrative privileges.
    goto :RunUniversal
) else (
    echo [WARN] Elevation required. Requesting Administrator access...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~dp03_UNIVERSAL_ALL_IN_ONE_FIX.bat\"\"' -Verb RunAs"
    exit /b
)

:RunUniversal
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-Shared-Printers.ps1" -Mode Universal
echo.
echo ==========================================================================
echo   Universal configuration completed.
echo ==========================================================================
pause
