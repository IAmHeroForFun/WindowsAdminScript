@echo off
title Printer Diagnostic & Management Suite
echo =========================================================
echo   Loading Printer Diagnostic & Management Suite...
echo =========================================================
echo.

:: Run PowerShell script with administrative privileges
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0manage_printers.ps1\"' -Verb RunAs"

echo.
echo Process started in elevated PowerShell window.
pause
