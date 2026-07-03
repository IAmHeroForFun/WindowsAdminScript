@echo off
title Windows Search & Indexing Repair Tool
echo =========================================================
echo       Launching Windows Search Repair Tool...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_search.ps1"

echo.
pause
