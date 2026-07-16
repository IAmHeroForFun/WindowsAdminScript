@echo off
title Windows 11 Debloat & Privacy Optimizer
echo =========================================================
echo   Loading Windows 11 Privacy & Debloat Suite...
echo =========================================================
echo.

:: Elevate execution policy and run script
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0debloat.ps1\"' -Verb RunAs"

echo.
echo Process started in elevated PowerShell window.
pause
