@echo off
title Advanced Network Mapper & Topology Discovery [Option 11]
echo =========================================================
echo   Launching Subnet Discovery & Network Mapper...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0network_mapper.ps1"

echo.
pause
