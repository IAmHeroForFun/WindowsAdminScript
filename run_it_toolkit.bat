@echo off
title Master IT Administration Toolkit
echo =========================================================
echo         Loading Master IT Toolkit Menu...
echo =========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0it_toolkit_menu.ps1"

echo.
pause
