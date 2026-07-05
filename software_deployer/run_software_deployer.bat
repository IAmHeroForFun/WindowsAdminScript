@echo off
title OmviHub Cloud Software Deployer (WPF Engine)
echo Launching OmviHub Cloud Software Deployer...

:: Attempt to launch under PowerShell 7 (pwsh.exe) first
where pwsh.exe >nul 2>nul
if %errorlevel% equ 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_software.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_software.ps1"
)
