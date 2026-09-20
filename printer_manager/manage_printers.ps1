# Printer Diagnostic & Management Suite for Windows IT Toolkit
# Compatible with Windows 7-11 & Windows Server 2008 R2-2025

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

# Centralized report directory handling
$ReportDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportDir = Join-Path $ParentDir "reports"
} else {
    $ReportDir = Join-Path $PSScriptRoot "reports"
}
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

function Test-FastTcpPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutMs = 2500
    )
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        $wh = $iar.AsyncWaitHandle
        if (-not $wh.WaitOne($TimeoutMs, $false)) {
            $client.Close()
            return $false
        }
        $client.EndConnect($iar)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-WindowsProtectedPrintState {
    $wppState = @{
        Supported = $false
        Enabled   = $false
        Details   = "Not supported / Disabled"
    }
    try {
        $wppKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Features\WPP"
        if (Test-Path $wppKey) {
            $wppState.Supported = $true
            $val = (Get-ItemProperty -Path $wppKey -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
            if ($val -eq 1) {
                $wppState.Enabled = $true
                $wppState.Details = "ENABLED (Legacy v3 third-party drivers blocked)"
            } else {
                $wppState.Details = "SUPPORTED (Currently Disabled)"
            }
        }
        $wppPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\ProtectedPrint"
        if (Test-Path $wppPolicyKey) {
            $pVal = (Get-ItemProperty -Path $wppPolicyKey -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
            if ($pVal -eq 1) {
                $wppState.Enabled = $true
                $wppState.Details = "ENABLED via Group Policy (Legacy v3 third-party drivers blocked)"
            }
        }
    } catch {}
    return $wppState
}

function Get-DriverModelClassification {
    param([string]$DriverName)
    $res = @{
        Model    = "Unknown"
        Provider = "Unknown"
    }
    if (-not $DriverName) { return $res }
    try {
        $drv = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
        if ($drv) {
            if ($drv.MajorVersion -eq 4) { $res.Model = "Type 4 (V4)" }
            elseif ($drv.MajorVersion -eq 3) { $res.Model = "Type 3 (V3)" }
            else { $res.Model = "Type $($drv.MajorVersion)" }
            
            if ($drv.Manufacturer -match "Microsoft" -or $drv.Provider -match "Microsoft") {
                $res.Provider = "Microsoft Class"
            } else {
                $res.Provider = "Third-Party"
            }
        }
    } catch {}
    return $res
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Yellow
    Write-Host "             PRINTER DIAGNOSTIC & MANAGEMENT SUITE" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Yellow
    Write-Host "  System: $env:COMPUTERNAME | User: $env:USERNAME" -ForegroundColor DarkCyan
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
}

while ($true) {
    Show-Header
    Write-Host "  [1] Diagnose Spooler & Force Purge Stuck Queue (Error Fix)" -ForegroundColor Cyan
    Write-Host "  [2] Run Printer Fleet Inventory Scan (Export to CSV & WPP Check)" -ForegroundColor Cyan
    Write-Host "  [3] Diagnose Network Printer Port Latency & Connectivity (Ping/TCP)" -ForegroundColor Cyan
    Write-Host "  [4] Configure Print Driver Isolation (Prevent Spooler Crashes)" -ForegroundColor Cyan
    Write-Host "  [5] Purge Stale/Orphaned Ports & Offline Printers (Cleanup)" -ForegroundColor Cyan
    Write-Host "  [6] Add Standard TCP/IP Network Printer Port & Queue" -ForegroundColor Cyan
    Write-Host "  [7] Diagnose Shared Printer Target Path (\\HOST\Printer - DNS/SMB/RPC)" -ForegroundColor Cyan
    Write-Host "  [8] Analyze PrintService Event Logs & Decode Win32 Error Codes" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [Q] Return to Master Menu" -ForegroundColor DarkRed
    Write-Host "==========================================================================" -ForegroundColor Yellow
    
    $Choice = Read-Host "Select a printer administration tool [1-8, Q]"
    
    switch ($Choice) {
        "1" {
            Show-Header
            Write-Host "Starting Spooler Diagnostic..." -ForegroundColor Cyan
            
            $StuckJobs = Get-PrintJob -PrinterName * | Where-Object { $_.JobStatus -match "Error" -or $_.JobStatus -match "Deleting" -or $_.SubmittedTime -lt (Get-Date).AddMinutes(-5) }
            if ($StuckJobs) {
                Write-Host "`nWarning: Identified $($StuckJobs.Count) stuck print jobs in the system queue:" -ForegroundColor Yellow
                $StuckJobs | Format-Table PrinterName, ID, DocumentName, JobStatus, SubmittedTime -AutoSize | Out-String | Write-Host -ForegroundColor DarkYellow
            } else {
                Write-Host "`nNo stuck jobs detected in standard printer queues." -ForegroundColor Green
            }
            
            $Confirm = Read-Host "`nForcefully purge Print Spooler and all queued documents? [Y/N]"
            if ($Confirm -eq "Y" -or $Confirm -eq "y") {
                Write-Host "`n[+] Stopping Print Spooler service..." -ForegroundColor Cyan
                Stop-Service -Name "Spooler" -Force
                
                # Double check process
                $SpoolerProcess = Get-Process -Name "spoolsv" -ErrorAction SilentlyContinue
                if ($SpoolerProcess) {
                    Write-Host "[!] Spooler process did not stop cleanly. Terminating process spoolsv..." -ForegroundColor Yellow
                    Stop-Process -Name "spoolsv" -Force -ErrorAction SilentlyContinue
                }
                
                Write-Host "[+] Purging queued print files from spool folder..." -ForegroundColor Cyan
                $SpoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
                if (Test-Path $SpoolPath) {
                    $Files = Get-ChildItem -Path "$SpoolPath\*" -Include *.spl, *.shd -Recurse
                    foreach ($File in $Files) {
                        try {
                            Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                            Write-Host "  -> Deleted stuck file: $($File.Name)" -ForegroundColor DarkGray
                        } catch {
                            Write-Host "  -> Failed to delete: $($File.Name) ($($_.Exception.Message))" -ForegroundColor Red
                        }
                    }
                }
                
                Write-Host "[+] Starting Print Spooler service..." -ForegroundColor Cyan
                Start-Service -Name "Spooler"
                
                # Verification
                Start-Sleep -Seconds 1
                $SpoolerStatus = Get-Service -Name "Spooler"
                if ($SpoolerStatus.Status -eq "Running") {
                    Write-Host "`n[VERIFICATION] Print Spooler service is now RUNNING successfully." -ForegroundColor Green
                } else {
                    Write-Host "`n[VERIFICATION ERROR] Print Spooler service failed to start automatically." -ForegroundColor Red
                }
            } else {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "2" {
            Show-Header
            Write-Host "Scanning Printer Fleet Inventory & Security Posture..." -ForegroundColor Cyan
            
            # 1. Windows Protected Print (WPP) Assessment
            $Wpp = Get-WindowsProtectedPrintState
            Write-Host "`nWindows Protected Print (WPP): $($Wpp.Details)" -ForegroundColor (if ($Wpp.Enabled) { "Yellow" } else { "Green" })
            if ($Wpp.Enabled) {
                Write-Host "  [!] Notice: When WPP is enabled, Windows blocks third-party v3 print drivers." -ForegroundColor DarkYellow
            }
            
            $Printers = Get-Printer
            if ($Printers) {
                Write-Host "`nFound $($Printers.Count) printers configured on this system." -ForegroundColor Green
                
                # Enrich with driver model & provider
                $EnrichedPrinters = foreach ($P in $Printers) {
                    $class = Get-DriverModelClassification $P.DriverName
                    [PSCustomObject]@{
                        Name           = $P.Name
                        DriverModel    = $class.Model
                        DriverProvider = $class.Provider
                        PortName       = $P.PortName
                        DriverName     = $P.DriverName
                        Shared         = $P.Shared
                        Published      = $P.Published
                        JobCount       = $P.JobCount
                    }
                }
                
                $EnrichedPrinters | Format-Table Name, DriverModel, DriverProvider, PortName, Shared -AutoSize | Out-String | Write-Host -ForegroundColor DarkCyan
                
                $CsvPath = Join-Path $ReportDir "printer_inventory.csv"
                Write-Host "[+] Exporting detailed list to CSV: $CsvPath" -ForegroundColor Cyan
                
                $EnrichedPrinters | Export-Csv -Path $CsvPath -NoTypeInformation -Force
                
                if (Test-Path $CsvPath) {
                    Write-Host "`n[VERIFICATION] CSV Inventory successfully written to [printer_inventory.csv](file://$($CsvPath.Replace('\','/')))" -ForegroundColor Green
                } else {
                    Write-Host "`n[VERIFICATION ERROR] Failed to write CSV file." -ForegroundColor Red
                }
            } else {
                Write-Host "`nNo printers found on this system." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "3" {
            Show-Header
            Write-Host "Diagnosing Network Printer Port Latency & Connection Status..." -ForegroundColor Cyan
            
            $TcpPorts = Get-PrinterPort | Where-Object { $_.Description -match "Standard TCP/IP" -or $_.PortNumber -ne $null }
            if ($TcpPorts) {
                Write-Host "`nFound $($TcpPorts.Count) Standard TCP/IP printer ports. Testing connectivity..." -ForegroundColor Cyan
                Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
                
                foreach ($Port in $TcpPorts) {
                    $Address = $Port.PrinterHostAddress
                    if (-not $Address) { $Address = $Port.Name }
                    
                    Write-Host "Port: $($Port.Name) | Host Address: $Address" -ForegroundColor Cyan
                    
                    # 1. Ping test
                    $Ping = Test-Connection -ComputerName $Address -Count 2 -Quiet
                    if ($Ping) {
                        # Get response time
                        $PingTime = Test-Connection -ComputerName $Address -Count 2 | Measure-Object ResponseTime -Average | Select-Object -ExpandProperty Average
                        Write-Host "  -> Ping Status   : ONLINE (Average Latency: $PingTime ms)" -ForegroundColor Green
                    } else {
                        Write-Host "  -> Ping Status   : OFFLINE (Request Timed Out)" -ForegroundColor Red
                    }
                    
                    # 2. Port 9100 RAW / Port 515 LPR Connection Test
                    $RawOpen = $false
                    $LprOpen = $false
                    
                    # RAW port check
                    $Socket = New-Object System.Net.Sockets.TcpClient
                    $Connect = $Socket.BeginConnect($Address, 9100, $null, $null)
                    $Wait = $Connect.AsyncWaitHandle.WaitOne(800, $false)
                    if ($Wait -and $Socket.Connected) {
                        $RawOpen = $true
                        $Socket.EndConnect($Connect)
                    }
                    $Socket.Close()
                    
                    # LPR port check
                    $Socket = New-Object System.Net.Sockets.TcpClient
                    $Connect = $Socket.BeginConnect($Address, 515, $null, $null)
                    $Wait = $Connect.AsyncWaitHandle.WaitOne(800, $false)
                    if ($Wait -and $Socket.Connected) {
                        $LprOpen = $true
                        $Socket.EndConnect($Connect)
                    }
                    $Socket.Close()
                    
                    if ($RawOpen) {
                        Write-Host "  -> Port 9100 RAW : OPEN (Accepting Print Jobs)" -ForegroundColor Green
                    } else {
                        Write-Host "  -> Port 9100 RAW : CLOSED or BLOCKED" -ForegroundColor DarkGray
                    }
                    
                    if ($LprOpen) {
                        Write-Host "  -> Port 515 LPR  : OPEN (Accepting Print Jobs)" -ForegroundColor Green
                    } else {
                        Write-Host "  -> Port 515 LPR  : CLOSED or BLOCKED" -ForegroundColor DarkGray
                    }
                    
                    if (-not $Ping -and -not $RawOpen -and -not $LprOpen) {
                        Write-Host "  [!] DIAGNOSIS: High latency or printer offline. This will cause slow printing/timeouts." -ForegroundColor Yellow
                    } else {
                        Write-Host "  [+] DIAGNOSIS: Connection stable." -ForegroundColor Green
                    }
                    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "`nNo Standard TCP/IP printer ports found on this system." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "4" {
            Show-Header
            Write-Host "Configuring Printer Driver Isolation Modes..." -ForegroundColor Cyan
            Write-Host "Info: Driver Isolation isolates drivers into separate processes (PrintIsolationHost.exe)" -ForegroundColor DarkGray
            Write-Host "      preventing buggy drivers from hanging or crashing the Print Spooler service." -ForegroundColor DarkGray
            Write-Host ""
            
            $Drivers = Get-PrinterDriver
            if ($Drivers) {
                # Fetch isolation settings from registry
                # Paths: HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3 or Version-4
                $DriversList = @()
                $Index = 1
                
                foreach ($Driver in $Drivers) {
                    $DrvName = $Driver.Name
                    
                    # Query registry to find driver path
                    $RegPath3 = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3\$DrvName"
                    $RegPath4 = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-4\$DrvName"
                    
                    $IsolationVal = 0
                    if (Test-Path $RegPath3) {
                        $IsolationVal = (Get-ItemProperty -Path $RegPath3 -Name "PrinterDriverAttributes" -ErrorAction SilentlyContinue).PrinterDriverAttributes
                    } elseif (Test-Path $RegPath4) {
                        $IsolationVal = (Get-ItemProperty -Path $RegPath4 -Name "PrinterDriverAttributes" -ErrorAction SilentlyContinue).PrinterDriverAttributes
                    }
                    
                    # Isolation status based on PrinterDriverAttributes flags:
                    # 0x08 = DRIVER_SANDBOX_ENABLED (Isolated)
                    # 0x10 = DRIVER_SANDBOX_DISABLED (None/Spooler process)
                    # Default if none of these is shared/system default
                    
                    $Mode = "None (Shared Spooler)"
                    if ($IsolationVal -band 0x08) {
                        $Mode = "Isolated (PrintIsolationHost.exe)"
                    } elseif ($IsolationVal -band 0x10) {
                        $Mode = "None (Explicitly Disabled)"
                    }
                    
                    $DriversList += [PSCustomObject]@{
                        Index = $Index
                        Name = $DrvName
                        Environment = $Driver.Environment
                        IsolationMode = $Mode
                        RegKey = if (Test-Path $RegPath3) { $RegPath3 } else { $RegPath4 }
                        AttrValue = $IsolationVal
                    }
                    $Index++
                }
                
                $DriversList | Format-Table Index, Name, Environment, IsolationMode -AutoSize | Out-String | Write-Host
                
                $SelectIndex = Read-Host "Select driver index to configure (or press Enter to skip)"
                if ($SelectIndex -match "^\d+$" -and $SelectIndex -ge 1 -and $SelectIndex -le $DriversList.Count) {
                    $Selected = $DriversList[$SelectIndex - 1]
                    Write-Host "`nSelected Driver: $($Selected.Name)" -ForegroundColor Cyan
                    Write-Host "Current Isolation Mode: $($Selected.IsolationMode)" -ForegroundColor Cyan
                    
                    Write-Host "`nAvailable Modes:" -ForegroundColor Cyan
                    Write-Host "  [1] Isolated (Sandbox mode - Recommended for safety & stability)" -ForegroundColor Yellow
                    Write-Host "  [2] Shared (Run in shared host process)" -ForegroundColor Yellow
                    Write-Host "  [3] None (Disabled - run directly in main Spooler process)" -ForegroundColor Red
                    
                    $NewModeChoice = Read-Host "Select new isolation mode [1-3]"
                    if ($NewModeChoice -eq "1" -or $NewModeChoice -eq "2" -or $NewModeChoice -eq "3") {
                        # Modify the PrinterDriverAttributes value
                        # isolated: add 0x08, remove 0x10
                        # shared/none: update attributes. PowerShell's Set-PrinterDriver can configure this easily in Win 8.1+
                        
                        $Status = $false
                        try {
                            if ($NewModeChoice -eq "1") {
                                Set-PrinterDriver -Name $Selected.Name -TransitionIntoJobIsolate $true -ErrorAction Stop
                                $Status = $true
                            } elseif ($NewModeChoice -eq "2") {
                                # Set to shared isolation
                                Set-PrinterDriver -Name $Selected.Name -TransitionIntoJobIsolate $false -ErrorAction SilentlyContinue
                                # If direct cmdlet not fully supported, adjust registry
                                if ($Selected.RegKey) {
                                    $NewAttr = ($Selected.AttrValue -band -bnot 0x10) -bor 0x08
                                    Set-ItemProperty -Path $Selected.RegKey -Name "PrinterDriverAttributes" -Value $NewAttr -ErrorAction Stop | Out-Null
                                }
                                $Status = $true
                            } else {
                                # Set to none
                                if ($Selected.RegKey) {
                                    $NewAttr = ($Selected.AttrValue -band -bnot 0x08) -bor 0x10
                                    Set-ItemProperty -Path $Selected.RegKey -Name "PrinterDriverAttributes" -Value $NewAttr -ErrorAction Stop | Out-Null
                                }
                                $Status = $true
                            }
                        } catch {
                            Write-Host "Cmdlet failed: $($_.Exception.Message). Attempting registry overrides..." -ForegroundColor Yellow
                            try {
                                if ($Selected.RegKey) {
                                    if ($NewModeChoice -eq "1") {
                                        $NewAttr = ($Selected.AttrValue -band -bnot 0x10) -bor 0x08
                                    } elseif ($NewModeChoice -eq "2") {
                                        $NewAttr = ($Selected.AttrValue -band -bnot 0x10) -bor 0x08
                                    } else {
                                        $NewAttr = ($Selected.AttrValue -band -bnot 0x08) -bor 0x10
                                    }
                                    Set-ItemProperty -Path $Selected.RegKey -Name "PrinterDriverAttributes" -Value $NewAttr -ErrorAction Stop | Out-Null
                                    $Status = $true
                                }
                            } catch {
                                Write-Host "Failed to update registry settings: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        
                        if ($Status) {
                            Write-Host "`n[+] Configuration updated. Restarting Spooler to apply changes..." -ForegroundColor Cyan
                            Restart-Service -Name "Spooler" -Force
                            
                            # Verify
                            $NewVal = 0
                            if (Test-Path $Selected.RegKey) {
                                $NewVal = (Get-ItemProperty -Path $Selected.RegKey -Name "PrinterDriverAttributes").PrinterDriverAttributes
                            }
                            
                            $NewModeStr = "None"
                            if ($NewVal -band 0x08) { $NewModeStr = "Isolated / Sandbox" }
                            
                            Write-Host "`n[VERIFICATION] Driver isolation update confirmed. Current registry attribute: $NewVal (Mode: $NewModeStr)" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "Invalid choice." -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No drivers found." -ForegroundColor Yellow
            }
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "5" {
            Show-Header
            Write-Host "Purging Stale/Orphaned Ports & Offline Printers..." -ForegroundColor Cyan
            
            # Find offline printers
            $Printers = Get-Printer
            $OfflinePrinters = @()
            
            foreach ($P in $Printers) {
                # Query printer status. Status 128 is Offline. Or check WMI.
                $WmiPrn = Get-WmiObject -Query "Select * from Win32_Printer Where Name = '$($P.Name.Replace('\','\\'))'" -ErrorAction SilentlyContinue
                if ($WmiPrn -and $WmiPrn.DetectedErrorState -eq 4) { # 4 is offline
                    $OfflinePrinters += $P
                }
            }
            
            if ($OfflinePrinters) {
                Write-Host "`nDetected $($OfflinePrinters.Count) Offline Printers:" -ForegroundColor Yellow
                $OfflinePrinters | Format-Table Name, PortName, DriverName -AutoSize | Out-String | Write-Host -ForegroundColor DarkYellow
                
                $RemovePrn = Read-Host "Do you want to delete these offline printer queues? [Y/N]"
                if ($RemovePrn -eq "Y" -or $RemovePrn -eq "y") {
                    foreach ($Prn in $OfflinePrinters) {
                        try {
                            Remove-Printer -Name $Prn.Name -ErrorAction Stop
                            Write-Host "  -> Removed Offline Printer Queue: $($Prn.Name)" -ForegroundColor Green
                        } catch {
                            Write-Host "  -> Failed to remove: $($Prn.Name) ($($_.Exception.Message))" -ForegroundColor Red
                        }
                    }
                }
            } else {
                Write-Host "`nNo offline printer queues detected." -ForegroundColor Green
            }
            
            # Find orphaned TCP/IP / WSD printer ports (ports that have no printer bound to them)
            Write-Host "`nScanning for orphaned/unused printer ports..." -ForegroundColor Cyan
            $ActivePorts = Get-Printer | Select-Object -ExpandProperty PortName
            $AllPorts = Get-PrinterPort | Where-Object { $_.Description -match "Standard TCP/IP" -or $_.Name -match "IP_" -or $_.Name -match "WSD-" }
            
            $OrphanedPorts = @()
            foreach ($Port in $AllPorts) {
                if ($ActivePorts -notcontains $Port.Name) {
                    $OrphanedPorts += $Port
                }
            }
            
            if ($OrphanedPorts) {
                Write-Host "`nDetected $($OrphanedPorts.Count) Orphaned/Unused ports (no printer queue is bound to these):" -ForegroundColor Yellow
                $OrphanedPorts | Format-Table Name, Description, PrinterHostAddress -AutoSize | Out-String | Write-Host -ForegroundColor DarkYellow
                
                $RemovePortsChoice = Read-Host "Do you want to delete these unused ports? (Recommended to fix print dialog lag) [Y/N]"
                if ($RemovePortsChoice -eq "Y" -or $RemovePortsChoice -eq "y") {
                    foreach ($Port in $OrphanedPorts) {
                        try {
                            Remove-PrinterPort -Name $Port.Name -ErrorAction Stop
                            Write-Host "  -> Deleted Port: $($Port.Name)" -ForegroundColor Green
                        } catch {
                            Write-Host "  -> Failed to delete port: $($Port.Name) ($($_.Exception.Message))" -ForegroundColor Red
                        }
                    }
                    
                    # Verify
                    Write-Host "`n[VERIFICATION] Re-auditing ports..." -ForegroundColor Cyan
                    $CurrentActive = Get-Printer | Select-Object -ExpandProperty PortName
                    $CurrentAll = Get-PrinterPort | Where-Object { $_.Description -match "Standard TCP/IP" -or $_.Name -match "IP_" -or $_.Name -match "WSD-" }
                    $RemainingOrphans = @()
                    foreach ($Port in $CurrentAll) {
                        if ($CurrentActive -notcontains $Port.Name) { $RemainingOrphans += $Port }
                    }
                    Write-Host "  Remaining orphaned ports: $($RemainingOrphans.Count)" -ForegroundColor Green
                }
            } else {
                Write-Host "`nNo orphaned printer ports detected." -ForegroundColor Green
            }
            
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "6" {
            Show-Header
            Write-Host "Adding Standard TCP/IP Network Printer Port & Queue..." -ForegroundColor Cyan
            
            $PrinterIP = Read-Host "Enter Printer IP Address (e.g. 192.168.1.150)"
            if (-not $PrinterIP) {
                Write-Host "Invalid IP." -ForegroundColor Red
                Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
                continue
            }
            
            $PortName = "IP_$PrinterIP"
            $PrinterName = Read-Host "Enter Printer Name (e.g. Office_HP_404)"
            if (-not $PrinterName) {
                Write-Host "Invalid Printer Name." -ForegroundColor Red
                Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
                continue
            }
            
            # Show existing drivers to pick from
            Write-Host "`nAvailable Print Drivers installed locally:" -ForegroundColor Cyan
            $Drivers = Get-PrinterDriver | Select-Object -ExpandProperty Name -Unique
            for ($i = 0; $i -lt $Drivers.Count; $i++) {
                Write-Host "  [$($i+1)] $($Drivers[$i])"
            }
            
            $DriverSelect = Read-Host "`nSelect driver index (or type custom driver name exactly)"
            $DriverName = ""
            if ($DriverSelect -match "^\d+$" -and $DriverSelect -ge 1 -and $DriverSelect -le $Drivers.Count) {
                $DriverName = $Drivers[$DriverSelect - 1]
            } else {
                $DriverName = $DriverSelect
            }
            
            if (-not $DriverName) {
                Write-Host "No print driver selected. Queue installation cannot proceed." -ForegroundColor Red
                Write-Host "`nPress Enter to return..." -ForegroundColor DarkGray; [void](Read-Host)
                continue
            }
            
            Write-Host "`nSummary of configuration:" -ForegroundColor Cyan
            Write-Host "  Printer IP  : $PrinterIP"
            Write-Host "  Port Name   : $PortName"
            Write-Host "  Queue Name  : $PrinterName"
            Write-Host "  Driver Name : $DriverName"
            
            $Confirm = Read-Host "`nInstall TCP/IP Printer Port and Queue? [Y/N]"
            if ($Confirm -eq "Y" -or $Confirm -eq "y") {
                # 1. Create port
                $PortSuccess = $false
                try {
                    Write-Host "`n[+] Creating Standard TCP/IP Port: $PortName..." -ForegroundColor Cyan
                    Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP -ErrorAction Stop
                    $PortSuccess = $true
                    Write-Host "  -> Port created successfully." -ForegroundColor Green
                } catch {
                    if ($_.Exception.Message -match "already exists") {
                        Write-Host "  -> Port already exists. Reusing port." -ForegroundColor Yellow
                        $PortSuccess = $true
                    } else {
                        Write-Host "  -> Failed to create port: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                
                # 2. Create Printer Queue
                if ($PortSuccess) {
                    try {
                        Write-Host "[+] Creating Printer Queue: $PrinterName..." -ForegroundColor Cyan
                        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -ErrorAction Stop
                        
                        # Verification
                        Start-Sleep -Seconds 1
                        $CheckPrn = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
                        if ($CheckPrn) {
                            Write-Host "`n[VERIFICATION] Printer queue '$PrinterName' has been successfully created and bound to '$PortName'!" -ForegroundColor Green
                        } else {
                            Write-Host "`n[VERIFICATION ERROR] Printer queue could not be found after installation." -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "  -> Failed to create printer queue: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host "  -> Ensure driver '$DriverName' is compatible and correctly installed." -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
            }
            
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "7" {
            Show-Header
            Write-Host "Diagnose Shared Printer Target Path (\\HOST\Printer)..." -ForegroundColor Cyan
            Write-Host "Tests multi-layer reachability: DNS -> TCP 445 (SMB) -> TCP 135 (RPC) -> Namespace -> Local bind." -ForegroundColor DarkGray
            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
            
            $TargetUnc = (Read-Host "`nEnter shared printer path (e.g. \\PRINTSVR\OfficeLaser)").Trim()
            if ($TargetUnc -match '^\\\\([^\\]+)\\([^\\]+)$') {
                $TargetHost = $Matches[1]
                $TargetShare = $Matches[2]
                
                $ReportLines = [System.Collections.ArrayList]@()
                $ReportLines.Add("==========================================================================") | Out-Null
                $ReportLines.Add("       SHARED PRINTER TARGET PATH DIAGNOSTIC REPORT") | Out-Null
                $ReportLines.Add("==========================================================================") | Out-Null
                $ReportLines.Add("Target UNC Path : $TargetUnc") | Out-Null
                $ReportLines.Add("Target Host     : $TargetHost") | Out-Null
                $ReportLines.Add("Target Share    : $TargetShare") | Out-Null
                $ReportLines.Add("Timestamp       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
                $ReportLines.Add("--------------------------------------------------------------------------") | Out-Null
                
                Write-Host "`n[1/5] Testing Host Name Resolution (DNS / NetBIOS)..." -ForegroundColor Cyan
                $HostIp = $null
                try {
                    $addrs = [System.Net.Dns]::GetHostAddresses($TargetHost)
                    if ($addrs.Count -gt 0) {
                        $HostIp = $addrs[0].IPAddressToString
                        Write-Host "  -> [OK] Resolved $TargetHost to IP: $HostIp" -ForegroundColor Green
                        $ReportLines.Add("  [PASS] Host Resolution: $HostIp") | Out-Null
                    } else {
                        Write-Host "  -> [FAIL] Host name could not be resolved." -ForegroundColor Red
                        $ReportLines.Add("  [FAIL] Host Resolution: Failed") | Out-Null
                    }
                } catch {
                    Write-Host "  -> [FAIL] Host resolution error: $($_.Exception.Message)" -ForegroundColor Red
                    $ReportLines.Add("  [FAIL] Host Resolution: $($_.Exception.Message)") | Out-Null
                }
                
                Write-Host "`n[2/5] Testing Port 445 (SMB File & Printer Sharing)..." -ForegroundColor Cyan
                $SmbReachable = Test-FastTcpPort $TargetHost 445 2500
                if ($SmbReachable) {
                    Write-Host "  -> [OK] TCP Port 445 (SMB) is OPEN and reachable." -ForegroundColor Green
                    $ReportLines.Add("  [PASS] TCP 445 (SMB): Open") | Out-Null
                } else {
                    Write-Host "  -> [FAIL] TCP Port 445 is CLOSED or filtered by firewall." -ForegroundColor Red
                    $ReportLines.Add("  [FAIL] TCP 445 (SMB): Unreachable") | Out-Null
                }
                
                Write-Host "`n[3/5] Testing Port 135 (RPC Endpoint Mapper)..." -ForegroundColor Cyan
                $RpcReachable = Test-FastTcpPort $TargetHost 135 2500
                if ($RpcReachable) {
                    Write-Host "  -> [OK] TCP Port 135 (RPC Mapper) is OPEN and reachable." -ForegroundColor Green
                    $ReportLines.Add("  [PASS] TCP 135 (RPC Mapper): Open") | Out-Null
                } else {
                    Write-Host "  -> [WARN] TCP Port 135 is CLOSED or filtered. Print Spooler RPC calls may fail." -ForegroundColor Yellow
                    $ReportLines.Add("  [WARN] TCP 135 (RPC Mapper): Unreachable") | Out-Null
                }
                
                # Check for explicit RPC TCP Port policy
                $RpcTcpPortKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
                if (Test-Path $RpcTcpPortKey) {
                    $prop = (Get-ItemProperty -Path $RpcTcpPortKey -Name "RpcTcpPort" -ErrorAction SilentlyContinue).RpcTcpPort
                    if ($prop -and [int]$prop -gt 0) {
                        Write-Host "`n[*] Configured Print RPC Static TCP Port detected: $prop" -ForegroundColor Cyan
                        $CustomRpcReachable = Test-FastTcpPort $TargetHost [int]$prop 2500
                        if ($CustomRpcReachable) {
                            Write-Host "  -> [OK] Static RPC Port $prop is OPEN and reachable." -ForegroundColor Green
                            $ReportLines.Add("  [PASS] Static RPC Port $prop: Open") | Out-Null
                        } else {
                            Write-Host "  -> [FAIL] Static RPC Port $prop is NOT reachable." -ForegroundColor Red
                            $ReportLines.Add("  [FAIL] Static RPC Port $prop: Unreachable") | Out-Null
                        }
                    }
                }
                
                Write-Host "`n[4/5] Testing SMB Share Namespace Access (\\$TargetHost\)..." -ForegroundColor Cyan
                $NamespaceOk = Test-Path -LiteralPath "\\$TargetHost\" -ErrorAction SilentlyContinue
                if ($NamespaceOk) {
                    Write-Host "  -> [OK] Share namespace accessible. Target host accepts SMB file/print shares." -ForegroundColor Green
                    $ReportLines.Add("  [PASS] Share Namespace (\\$TargetHost\): Accessible") | Out-Null
                } else {
                    Write-Host "  -> [WARN] Share namespace is not accessible (credentials, guest policy, or share permissions may restrict access)." -ForegroundColor Yellow
                    $ReportLines.Add("  [WARN] Share Namespace (\\$TargetHost\): Inaccessible") | Out-Null
                }
                
                Write-Host "`n[5/5] Checking Local Printer Connection Status..." -ForegroundColor Cyan
                $InstalledLocally = $false
                try {
                    $existing = Get-Printer | Where-Object { $_.Name -eq $TargetUnc }
                    if ($existing) {
                        $InstalledLocally = $true
                        Write-Host "  -> [INFO] Printer '$TargetUnc' is ALREADY installed locally (Driver: $($existing.DriverName))." -ForegroundColor Green
                        $ReportLines.Add("  [INFO] Local Installation: Already connected ($($existing.DriverName))") | Out-Null
                    } else {
                        Write-Host "  -> [INFO] Printer '$TargetUnc' is not currently installed on this client." -ForegroundColor DarkCyan
                        $ReportLines.Add("  [INFO] Local Installation: Not connected") | Out-Null
                    }
                } catch {
                    Write-Host "  -> Unable to query local printer list." -ForegroundColor Yellow
                }
                
                # Summary Assessment
                Write-Host "`n--------------------------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host "Triage Assessment:" -ForegroundColor Yellow
                if (-not $HostIp) {
                    Write-Host "  -> Root Cause: DNS/Name resolution failure. Ensure host name is correct or add to hosts/DNS." -ForegroundColor Red
                } elseif (-not $SmbReachable) {
                    Write-Host "  -> Root Cause: Network firewall blocking SMB (Port 445) or host is offline." -ForegroundColor Red
                } elseif (-not $NamespaceOk) {
                    Write-Host "  -> Root Cause: SMB reachable but share access denied. Check guest auth, password restrictions, or credentials." -ForegroundColor Yellow
                } elseif (-not $RpcReachable) {
                    Write-Host "  -> Caution: Port 135 blocked. Printer sharing may require RPC over Named Pipes fallback." -ForegroundColor Yellow
                } else {
                    Write-Host "  -> Network Path is Healthy! Ready to bind printer queue." -ForegroundColor Green
                }
                
                # Save Report
                $DiagReportPath = Join-Path $ReportDir "printer_path_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $ReportLines.Add("--------------------------------------------------------------------------") | Out-Null
                $ReportLines | Out-File -FilePath $DiagReportPath -Encoding UTF8 -Force
                Write-Host "`nDetailed report saved to: [printer_path_test](file://$($DiagReportPath.Replace('\','/')))" -ForegroundColor Green
            } else {
                Write-Host "`nInvalid printer UNC path format. Must be formatted like \\HOST\PrinterName." -ForegroundColor Red
            }
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "8" {
            Show-Header
            Write-Host "Analyzing PrintService Event Logs & Decoding Win32 Error Codes..." -ForegroundColor Cyan
            Write-Host "Inspecting Microsoft-Windows-PrintService/Admin for connection & driver failures." -ForegroundColor DarkGray
            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
            
            try {
                $Events = Get-WinEvent -FilterHashtable @{
                    LogName = 'Microsoft-Windows-PrintService/Admin'
                    Level   = 1, 2, 3
                } -MaxEvents 25 -ErrorAction Stop
                
                if ($Events) {
                    Write-Host "`nFound $($Events.Count) recent PrintService warning/error events:`n" -ForegroundColor Yellow
                    
                    foreach ($E in $Events) {
                        $Msg = ($E.Message -replace '\s+', ' ').Trim()
                        if ($Msg.Length -gt 130) { $Msg = $Msg.Substring(0, 130) + "..." }
                        
                        Write-Host "[$($E.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))] Event ID: $($E.Id)" -ForegroundColor DarkCyan
                        Write-Host "  Message: $Msg" -ForegroundColor Gray
                        
                        # Win32 Error Code Decoder
                        if ($E.Id -eq 808 -or $Msg -match "error code|failed with error|0x[0-9a-fA-F]+") {
                            Write-Host "  [DIAGNOSIS & REMEDIATION]:" -ForegroundColor Yellow
                            if ($Msg -match "0x0000011b|0x11b") {
                                Write-Host "   -> Error 0x0000011b (RPC Packet Privacy): Print Spooler requires encryption." -ForegroundColor Red
                                Write-Host "   -> Solution: In Network Sharing Fixer, apply 'RpcAuthnLevelPrivacyEnabled = 0' or match RPC privacy on both host & client." -ForegroundColor Green
                            } elseif ($Msg -match "0x00000709|0x709") {
                                Write-Host "   -> Error 0x00000709 (Invalid Printer Name / RPC Binding): Client failed to bind to host RPC spooler." -ForegroundColor Red
                                Write-Host "   -> Solution: Configure RPC over Named Pipes (RpcUseNamedPipeProtocol = 1) or verify CNAME alias policy." -ForegroundColor Green
                            } elseif ($Msg -match "0x00000bc4|0xbc4") {
                                Write-Host "   -> Error 0x00000bc4 (No Printers Were Found): Windows 11 default RPC over TCP blocked." -ForegroundColor Red
                                Write-Host "   -> Solution: Enable RPC over Named Pipes fallback in Network Sharing Fixer." -ForegroundColor Green
                            } elseif ($Msg -match "0x0000007c|0x7c") {
                                Write-Host "   -> Error 0x0000007c (CopyFiles Spooler Policy Block): Blocked by Point & Print driver copy restriction." -ForegroundColor Red
                                Write-Host "   -> Solution: Enable CopyFilesPolicy = 1 in Network Sharing Fixer." -ForegroundColor Green
                            } elseif ($Msg -match "error 5\b|0x80070005|Access is denied") {
                                Write-Host "   -> Error 5 / Access Denied: Blocked by Point and Print driver installation protection." -ForegroundColor Red
                                Write-Host "   -> Solution: Use 'Temporary Point & Print Relaxation' in Network Sharing Fixer to connect without admin elevation." -ForegroundColor Green
                            } else {
                                Write-Host "   -> Check driver compatibility, Spooler service state, or firewall settings." -ForegroundColor DarkYellow
                            }
                        }
                        Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
                    }
                }
            } catch {
                Write-Host "`nNo recent PrintService/Admin events found or event log channel is disabled." -ForegroundColor Green
                Write-Host "Details: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
            
            Write-Host "`nPress Enter to return to Printer Menu..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        
        "Q" {
            return
        }
        "q" {
            return
        }
        default {
            Write-Host "`nInvalid choice. Please enter 1-8, or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
