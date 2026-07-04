# Windows & Windows Server Master IT Administration Toolkit Menu
# Compatible with Windows 7-11 & Windows Server 2008 R2-2025

$ErrorActionPreference = "SilentlyContinue"

# Ensure $PSScriptRoot is defined for PowerShell 2.0 compatibility
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

while ($true) {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Magenta
    Write-Host "       WINDOWS & WINDOWS SERVER MASTER IT ADMINISTRATION TOOLKIT" -ForegroundColor Magenta
    Write-Host "==========================================================================" -ForegroundColor Magenta
    Write-Host "  System: $env:COMPUTERNAME | User: $env:USERNAME" -ForegroundColor DarkCyan
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [1] Run Local PC Inventory Scan (Hardware & Software)" -ForegroundColor Cyan
    Write-Host "  [2] Run Network Subnet Discovery Scan (Ping Sweep)" -ForegroundColor Cyan
    Write-Host "  [3] Run Remote WMI Network Inventory (Domain & Workgroup PCs)" -ForegroundColor Cyan
    Write-Host "  [4] Launch Sherlock Slow PC Diagnostics & Turbo Tune-Up Suite" -ForegroundColor Yellow
    Write-Host "  [5] Launch Windows Search & Indexing Diagnostic & Repair Suite" -ForegroundColor Green
    Write-Host "  [6] Run Main Server Forensic & Configuration Audit (Users, GPOs, Shares)" -ForegroundColor Magenta
    Write-Host "  [7] Run Server Health & Misconfiguration Doctor (DNS, NTP, Firewall)" -ForegroundColor Yellow
    Write-Host "  [8] Run Server Crash, Reboot & Error Detective (Live Web Lookup)" -ForegroundColor Red
    Write-Host "  [9] Run Deep Infrastructure & Security Scan (AD, SSL, SMBv1, Ports)" -ForegroundColor Cyan
    Write-Host "  [10] Run Enterprise Security, Compliance & Recovery Auditor" -ForegroundColor Magenta
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [Q] Exit Toolkit" -ForegroundColor DarkRed
    Write-Host "==========================================================================" -ForegroundColor Magenta
    
    $Choice = Read-Host "Select a tool to execute [1-10, Q]"
    
    switch ($Choice) {
        "1" {
            Clear-Host
            Write-Host "Executing Local PC Inventory Scan..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "inventory\get_inventory.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "2" {
            Clear-Host
            Write-Host "Executing Network Subnet Discovery Scan..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "inventory\scan_network.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "3" {
            Clear-Host
            Write-Host "Executing Remote WMI Network Inventory..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "inventory\remote_inventory.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "4" {
            Clear-Host
            Write-Host "Launching Sherlock Slow PC Diagnostics Suite..." -ForegroundColor Yellow
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "slowness_debug\slowness_detective.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "5" {
            Clear-Host
            Write-Host "Launching Windows Search & Indexing Repair Suite..." -ForegroundColor Green
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "search_fixer\fix_search.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "6" {
            Clear-Host
            Write-Host "Executing Main Server Forensic & Configuration Audit..." -ForegroundColor Magenta
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "server_audit\audit_server.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "7" {
            Clear-Host
            Write-Host "Executing Windows Server Health & Misconfiguration Scan..." -ForegroundColor Yellow
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "server_health_doctor\server_doctor.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "8" {
            Clear-Host
            Write-Host "Executing Server Crash, Reboot & Error Forensic Scan..." -ForegroundColor Red
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "crash_and_error_detective\crash_detective.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "9" {
            Clear-Host
            Write-Host "Executing Ultimate Deep Infrastructure & Security Scan..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "deep_infrastructure_audit\deep_diagnostic.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "10" {
            Clear-Host
            Write-Host "Executing Enterprise Security, Compliance & Recovery Auditor..." -ForegroundColor Magenta
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "enterprise_security_auditor\enterprise_security_auditor.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        { $_ -eq "Q" -or $_ -eq "q" } {
            Write-Host "`nExiting IT Toolkit. Have a productive day!" -ForegroundColor Cyan
            exit
        }
        default {
            Write-Host "`nInvalid choice. Please enter 1-10, or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
