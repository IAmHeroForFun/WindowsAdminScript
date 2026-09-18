@echo off
title Windows Update & WSUS Repair Suite
echo =========================================================
echo   Requesting Administrator Privileges...
echo =========================================================
echo.

:: Elevate to Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Elevating privileges via UAC...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

:: Run the script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_windows_update.ps1"

echo.
pause
