@echo off
title Network Security, Scanner & Diagnostics Auditor - OmviHub IT Toolkit
echo ==========================================================================
echo   OmviHub IT Toolkit - Network Security, Scanner & Diagnostics Auditor
echo ==========================================================================
echo.
echo   Phases included:
echo     [1] Windows Defender Firewall Status
echo     [2] DNS Server Audit + Hosts File Integrity Check
echo     [3] Listening Port Inventory (SAFE / CAUTION / UNSAFE ratings)
echo     [4] Outbound Established Session Monitor
echo     [R] Interactive Remediation (Kill PID / Block Firewall)
echo     [5] Subnet IP and Port Scanner (Parallel Async Sweep)
echo     [6] Latency + DNS Benchmark Diagnostics + Traceroute
echo.
echo ==========================================================================
echo   Requesting Administrator elevation...
echo ==========================================================================
echo.

:: Elevate and run powershell script as Administrator
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0audit_network.ps1""' -Verb RunAs"

echo.
echo Script launched in elevated PowerShell window.
pause
