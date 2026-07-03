@echo off
title Sherlock Slow: PC Slowness Detective & Turbo Fixer
echo =========================================================
echo       Launching Sherlock Slow PC Diagnostic Tool...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0slowness_detective.ps1"

echo.
pause
