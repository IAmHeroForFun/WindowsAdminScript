@echo off
:: ==========================================================================
:: OMVIHUB CLOUD SOFTWARE & UTILITY DEPLOYER - LAUNCHER
:: ==========================================================================
title OmviHub Cloud Software & Utility Deployer [Ninite Style]
color 0B

echo.
echo ==========================================================================
echo   OMVIHUB CLOUD SOFTWARE & UTILITY DEPLOYER [NINITE-STYLE HYBRID CDN]
echo ==========================================================================
echo.
echo Launching Interactive Ninite-Style Package Deployer...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_software.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Software deployer encountered an error or was cancelled.
    pause
)
