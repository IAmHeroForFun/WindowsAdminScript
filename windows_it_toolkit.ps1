# ==========================================================================
#   OmviHub Windows & Windows Server Master IT Administration Toolkit
#   Massgrave (MAS) Minimalist High-Contrast Interface
#   Compatible with Windows 7-11 & Windows Server 2008 R2-2025
# ==========================================================================

$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for the current session/process
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

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
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $AdminBadge = if ($IsAdmin) { "Elevated / Administrator" } else { "Standard User (Elevation Recommended)" }
    $OSCaption = (Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    if (-not $OSCaption) { $OSCaption = "Windows Operating System" }

    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " :: OmviHub Windows & Windows Server Master IT Toolkit (v2.5)" -ForegroundColor White
    Write-Host " :: Host: $env:COMPUTERNAME | OS: $OSCaption" -ForegroundColor DarkCyan
    Write-Host " :: User: $env:USERNAME | Privileges: $AdminBadge" -ForegroundColor DarkCyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [AUDIT & INVENTORY]" -ForegroundColor DarkYellow
    Write-Host "  [1]  Local Hardware & Installed Software Inventory Scanner" -ForegroundColor White
    Write-Host "  [2]  Local Network Subnet IP & Active Host Discovery (Ping Sweep)" -ForegroundColor White
    Write-Host "  [3]  Agentless Remote Network PC Inventory (WMI / CIM)" -ForegroundColor White
    Write-Host "  [4]  Network Security, Open Port Exposure & Socket Auditor (6-Phases)" -ForegroundColor White
    Write-Host ""
    Write-Host " [SYSTEM TUNE-UP & DEBLOAT]" -ForegroundColor DarkYellow
    Write-Host "  [5]  Sherlock Slow PC Performance Debugger & Turbo Tune-Up" -ForegroundColor Green
    Write-Host "  [6]  Windows Search & Indexing Repair Suite (EDB, UWP & MAPI)" -ForegroundColor Green
    Write-Host "  [7]  Windows 11 Enterprise Debloat & Privacy Optimizer" -ForegroundColor Green
    Write-Host ""
    Write-Host " [INFRASTRUCTURE & SERVER ADMIN]" -ForegroundColor DarkYellow
    Write-Host "  [8]  Server Security & Configuration Audit (GPOs, Accounts, Shares)" -ForegroundColor Magenta
    Write-Host "  [9]  Local Print Spooler, Queue & Driver Manager" -ForegroundColor Magenta
    Write-Host "  [10] Windows 10/11 Network Folder & SMB Sharing Fixer" -ForegroundColor Magenta
    Write-Host "  [11] Remote Desktop (RDP) & CredSSP Connection Fixer" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " [APPLICATION & DATABASE SUITES]" -ForegroundColor DarkYellow
    Write-Host "  [12] MS Office General Diagnostic & Configuration Reset Suite" -ForegroundColor Yellow
    Write-Host "  [13] Outlook PST / OST Recovery, SCANPST Locator & 100GB Expander" -ForegroundColor Yellow
    Write-Host "  [14] SQL Database Port & Protocol Diagnostic Fixer (1433, 3306, 5432)" -ForegroundColor Yellow
    Write-Host "  [15] Windows Defender Signature Reset & Exclusion Engine" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [Q]  Exit Toolkit" -ForegroundColor DarkRed
    Write-Host "==========================================================================" -ForegroundColor Cyan
    
    $Choice = Read-Host "Select a tool to execute [1-15, Q]"
    
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
            Write-Host "Launching Network Security, Socket Auditor & Diagnostics Suite..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "network_auditor\audit_network.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "5" {
            Clear-Host
            Write-Host "Launching Sherlock Slow PC Diagnostics Suite..." -ForegroundColor Yellow
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "slowness_debug\slowness_detective.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "6" {
            Clear-Host
            Write-Host "Launching Windows Search & Indexing Repair Suite..." -ForegroundColor Green
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "search_fixer\fix_search.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "7" {
            Clear-Host
            Write-Host "Launching Windows 11 Enterprise Debloat & Privacy Suite..." -ForegroundColor Green
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "win11_debloater\debloat.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "8" {
            Clear-Host
            Write-Host "Executing Main Server Forensic & Configuration Audit..." -ForegroundColor Magenta
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "server_audit\audit_server.ps1"
            if (Test-Path $ScriptPath) { & $ScriptPath } else { Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "9" {
            Clear-Host
            Write-Host "Launching Printer Diagnostic & Management Suite..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "printer_manager\manage_printers.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "10" {
            Clear-Host
            Write-Host "Launching Windows 10/11 Shared Drive & USB Shared Printer Repair Suite..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "network_sharing_fixer\fix_sharing.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "11" {
            Clear-Host
            Write-Host "Launching Remote Desktop (RDP) & CredSSP Encryption Oracle Repair Suite..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "rdp_fixer\fix_rdp.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "12" {
            Clear-Host
            Write-Host "Launching MS Office General Diagnostic & Repair Suite..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "office_fixer\Repair-Office.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "13" {
            Clear-Host
            Write-Host "Launching Outlook PST / OST Recovery & 100GB Limit Expander..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "office_fixer\Repair-PST.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "14" {
            Clear-Host
            Write-Host "Launching SQL Database Port & Protocol Diagnostic & Repair Suite..." -ForegroundColor Cyan
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "sql_database_fixer\fix_sql.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "15" {
            Clear-Host
            Write-Host "Launching Windows Defender Signature Reset & Exclusion Repair Suite..." -ForegroundColor Green
            $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "antivirus_fixer\fix_antivirus.ps1"
            if (Test-Path $ScriptPath) {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            } else {
                Write-Host "Error: Cannot locate $ScriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Master Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        { $_ -eq "Q" -or $_ -eq "q" } {
            Write-Host "`nExiting IT Toolkit. Have a productive day!" -ForegroundColor Cyan
            
            # Post-execution footprint cleanup (preserving reports)
            $InstallDir = $PSScriptRoot
            if (Test-Path $InstallDir) {
                Write-Host "`n[+] Cleaning up script files to leave no footprint (preserving reports)..." -ForegroundColor Cyan
                $TargetExtensions = @(".ps1", ".bat", ".cmd", ".md", ".conf")
                
                $Files = Get-ChildItem -Path $InstallDir -Recurse -File -Force -ErrorAction SilentlyContinue
                foreach ($File in $Files) {
                    if ($TargetExtensions -contains $File.Extension.ToLower()) {
                        Remove-Item -Path $File.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
                
                # Recursively clean up empty directories
                do {
                    $Dirs = Get-ChildItem -Path $InstallDir -Recurse -Directory -Force -ErrorAction SilentlyContinue
                    $DeletedAny = $false
                    foreach ($Dir in $Dirs) {
                        $Items = Get-ChildItem -Path $Dir.FullName -Force -ErrorAction SilentlyContinue
                        if ($Items.Count -eq 0) {
                            Remove-Item -Path $Dir.FullName -Force -ErrorAction SilentlyContinue
                            $DeletedAny = $true
                        }
                    }
                } while ($DeletedAny)
            }
            exit
        }
        default {
            Write-Host "`nInvalid choice. Please enter 1-15, or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
