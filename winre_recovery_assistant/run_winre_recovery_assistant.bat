@echo off
title WinRE Recovery Assistant [Option 15] - Boot Repair & Diagnostics
echo ====================================================================
echo   Launching Windows Recovery & Boot Repair Assistant...
echo   Mode: Interactive (Ask Before Repair)
echo ====================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0winre_recovery_assistant.ps1" -Mode AskBeforeRepair

echo.
pause
