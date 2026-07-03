@echo off
title Ultimate Deep Infrastructure & Security Diagnostic Suite
echo =========================================================
echo    Launching Deep Infrastructure & Security Scan...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deep_diagnostic.ps1"

echo.
pause
