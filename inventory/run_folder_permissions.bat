@echo off
title Windows Shared Folder & Permissions Auditor
echo ===================================================
echo   Running Shared Folder & Permissions Auditor...
echo ===================================================
echo.
echo Please do not close this window while auditing is in progress.
echo The report will be generated as a CSV in the reports folder.
echo.

:: Run the PowerShell script relative to the batch file location
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit_folder_permissions.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] An error occurred while running the permissions audit script.
    echo.
    pause
)
