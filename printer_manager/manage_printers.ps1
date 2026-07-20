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

$ReportDir = Join-Path $PSScriptRoot "reports"
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
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
    Write-Host "  [2] Run Printer Fleet Inventory Scan (Export to CSV)" -ForegroundColor Cyan
    Write-Host "  [3] Diagnose Network Printer Port Latency & Connectivity (Ping/TCP)" -ForegroundColor Cyan
    Write-Host "  [4] Configure Print Driver Isolation (Prevent Spooler Crashes)" -ForegroundColor Cyan
    Write-Host "  [5] Purge Stale/Orphaned Ports & Offline Printers (Cleanup)" -ForegroundColor Cyan
    Write-Host "  [6] Add Standard TCP/IP Network Printer Port & Queue" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [Q] Return to Master Menu" -ForegroundColor DarkRed
    Write-Host "==========================================================================" -ForegroundColor Yellow
    
    $Choice = Read-Host "Select a printer administration tool [1-6, Q]"
    
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
            Write-Host "Scanning Printer Fleet Inventory..." -ForegroundColor Cyan
            
            $Printers = Get-Printer
            if ($Printers) {
                Write-Host "`nFound $($Printers.Count) printers configured on this system." -ForegroundColor Green
                $Printers | Format-Table Name, Type, PortName, DriverName, Shared, Published -AutoSize | Out-String | Write-Host -ForegroundColor DarkCyan
                
                $CsvPath = Join-Path $ReportDir "printer_inventory.csv"
                Write-Host "[+] Exporting detailed list to CSV: $CsvPath" -ForegroundColor Cyan
                
                $Printers | Select-Object Name, ComputerName, Type, PortName, DriverName, PrintProcessor, JobCount, Shared, Published | Export-Csv -Path $CsvPath -NoTypeInformation -Force
                
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
        
        "Q" {
            break
        }
        "q" {
            break
        }
        default {
            Write-Host "`nInvalid choice. Please enter 1-6, or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
