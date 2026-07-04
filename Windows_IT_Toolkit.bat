@echo off
title Windows & Windows Server Master IT Toolkit
echo =========================================================
echo   Loading Windows & Server IT Administration Toolkit...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows_it_toolkit.ps1"

echo.
pause
