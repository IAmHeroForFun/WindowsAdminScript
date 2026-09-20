# Repairs USB Shared Printers, Point & Print restrictions, and RPC 0x0000011b errors
# Incorporates diagnosis-first and temporary-relaxation patterns
$ErrorActionPreference = "SilentlyContinue"

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Helper function for user prompts
function Get-UserApproval ($Message) {
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    $Response = Read-Host "Proceed? (Y/N, Q to Cancel)"
    if ($Response -eq "Q" -or $Response -eq "q") {
        Write-Host "Operation cancelled by user. Returning..." -ForegroundColor Yellow
        exit 0
    }
    return ($Response -eq "Y" -or $Response -eq "y")
}

# Logger helper
function Log-Msg ($Msg, $Type="INFO") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Type] $Msg"
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } elseif ($Type -eq "SUCCESS") { "Green" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

# Domain GPO detection helper
function Test-IsDomainJoined {
    try {
        $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
        return [bool]$cs.PartOfDomain
    } catch {
        return $false
    }
}

# TCP port reachability probe (PS 2.0+ compatible via System.Net.Sockets)
function Test-PrinterPortConnectivity ($HostName, $Port, $TimeoutMs=2500) {
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

if (-not (Get-UserApproval "Repair USB Shared Printers & Point-and-Print connection restrictions (0x0000011b / 0x00000709)?")) {
    Log-Msg "Shared Printer repairs skipped by user." "WARN"
    return 0
}

Log-Msg "Starting USB Shared Printer repairs..."

# Check Domain GPO status
if (Test-IsDomainJoined) {
    Log-Msg "  [NOTICE] Machine is Domain-joined. Local registry policy changes may be reverted by Group Policy (GPO)." "WARN"
}

# 0. Pre-Flight Diagnostic: Test Shared Printer UNC Target Path
if (Get-UserApproval "Test network connectivity to a specific shared printer (e.g. \\HOST\PrinterName)?") {
    $TargetUnc = (Read-Host "Enter shared printer UNC path (e.g. \\PRINTSVR\OfficeLaser)").Trim()
    if ($TargetUnc -match '^\\\\([^\\]+)\\([^\\]+)$') {
        $TargetHost = $Matches[1]
        $PrinterShare = $Matches[2]
        Log-Msg "Diagnosing target path for host: $TargetHost, share: $PrinterShare..."
        
        # Test 1: DNS / Name resolution
        $HostResolves = $false
        try {
            $addrs = [System.Net.Dns]::GetHostAddresses($TargetHost)
            if ($addrs.Count -gt 0) {
                $HostResolves = $true
                Log-Msg "  [OK] Host DNS resolved: $($addrs[0].IPAddressToString)" "SUCCESS"
            }
        } catch {
            Log-Msg "  [FAIL] Host DNS resolution failed for '$TargetHost': $($_.Exception.Message)" "ERROR"
        }
        
        # Test 2: SMB Port 445
        if ($HostResolves) {
            $SmbOk = Test-PrinterPortConnectivity $TargetHost 445 2500
            if ($SmbOk) {
                Log-Msg "  [OK] TCP 445 (SMB) is reachable." "SUCCESS"
            } else {
                Log-Msg "  [FAIL] TCP 445 (SMB) not reachable. Check host firewall and file sharing service." "ERROR"
            }
            
            # Test 3: RPC Port 135 (Endpoint Mapper)
            $RpcOk = Test-PrinterPortConnectivity $TargetHost 135 2500
            if ($RpcOk) {
                Log-Msg "  [OK] TCP 135 (RPC Endpoint Mapper) is reachable." "SUCCESS"
            } else {
                Log-Msg "  [WARN] TCP 135 (RPC Endpoint Mapper) not reachable. Print Spooler RPC may fail." "WARN"
            }
            
            # Test 4: Share namespace reachability
            $ShareOk = Test-Path -LiteralPath "\\$TargetHost\" -ErrorAction SilentlyContinue
            if ($ShareOk) {
                Log-Msg "  [OK] Host share namespace is accessible (\\$TargetHost\)." "SUCCESS"
            } else {
                Log-Msg "  [WARN] Host share namespace is not accessible. Verify sharing permissions and credentials." "WARN"
            }
        }
    } else {
        Log-Msg "Invalid printer UNC path format. Skipping pre-flight diagnostic." "WARN"
    }
}

# 1. Connect Shared Printer with Temporary Point & Print Relaxation (Safe Auto-Rollback)
$PointAndPrintKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
if (Get-UserApproval "Connect a Shared Printer with Temporary Point & Print Relaxation (Auto-restores security after install)?") {
    $TargetUnc = (Read-Host "Enter shared printer UNC path to install (e.g. \\PRINTSVR\OfficeLaser)").Trim()
    if ($TargetUnc -match '^\\\\[^\\]+\\[^\\]+$') {
        Log-Msg "Initiating temporary Point & Print relaxation for: $TargetUnc"
        $OriginalValue = $null
        $ValueExists = $false
        
        try {
            if (-not (Test-Path $PointAndPrintKey)) {
                New-Item -Path $PointAndPrintKey -Force | Out-Null
            }
            $currentProp = Get-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -ErrorAction SilentlyContinue
            if ($null -ne $currentProp) {
                $OriginalValue = $currentProp.RestrictDriverInstallationToAdministrators
                $ValueExists = $true
            }
            
            # Temporarily relax driver installation restriction
            Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [+] Point & Print restriction temporarily relaxed (RestrictDriverInstallationToAdministrators = 0)."
            
            # Attempt printer connection
            Log-Msg "  [+] Connecting to shared printer: $TargetUnc..."
            $ConnectSuccess = $false
            if (Get-Command Add-Printer -ErrorAction SilentlyContinue) {
                try {
                    Add-Printer -ConnectionName $TargetUnc -ErrorAction Stop
                    $ConnectSuccess = $true
                } catch {
                    Log-Msg "  [WARN] Add-Printer cmdlet failed: $($_.Exception.Message). Trying printui fallback..." "WARN"
                }
            }
            
            if (-not $ConnectSuccess) {
                $p = Start-Process rundll32.exe -ArgumentList "printui.dll,PrintUIEntry /in /n `"$TargetUnc`"" -Wait -PassThru
                if ($p.ExitCode -eq 0) {
                    $ConnectSuccess = $true
                } else {
                    Log-Msg "  [FAIL] PrintUI connection exited with code $($p.ExitCode)." "ERROR"
                }
            }
            
            if ($ConnectSuccess) {
                Log-Msg "  [OK] Successfully connected to shared printer: $TargetUnc" "SUCCESS"
            }
        } catch {
            Log-Msg "  [ERROR] Error during temporary Point & Print connection: $($_.Exception.Message)" "ERROR"
        } finally {
            # Rollback to original state
            try {
                if ($ValueExists -and $null -ne $OriginalValue) {
                    Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value $OriginalValue -PropertyType DWord -Force | Out-Null
                    Log-Msg "  [SECURITY] RestrictDriverInstallationToAdministrators restored to original value ($OriginalValue)." "SUCCESS"
                } elseif ($ValueExists) {
                    Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value 1 -PropertyType DWord -Force | Out-Null
                    Log-Msg "  [SECURITY] RestrictDriverInstallationToAdministrators reset to default hardened state (1)." "SUCCESS"
                } else {
                    Remove-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -ErrorAction SilentlyContinue
                    Log-Msg "  [SECURITY] Temporary RestrictDriverInstallationToAdministrators key removed." "SUCCESS"
                }
            } catch {
                Log-Msg "  [WARN] Failed to automatically restore RestrictDriverInstallationToAdministrators: $($_.Exception.Message)" "WARN"
            }
        }
    } else {
        Log-Msg "Invalid printer UNC path format." "WARN"
    }
}

# 2. Fix 0x0000011b Print Spooler RPC Privacy Constraint
$PrintControlKey = "HKLM:\System\CurrentControlSet\Control\Print"
if (Test-Path $PrintControlKey) {
    if (Get-UserApproval "Disable Print Spooler RPC Authentication Privacy (RpcAuthnLevelPrivacyEnabled = 0) to fix error 0x0000011b?") {
        try {
            Set-ItemProperty -Path $PrintControlKey -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully set RpcAuthnLevelPrivacyEnabled = 0." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to set RpcAuthnLevelPrivacyEnabled: $($_.Exception.Message)" "ERROR"
        }
    }
}

# 3. Permanent Point and Print Restrictions Bypass (For Persistent Non-Admin Driver Installs)
if (Get-UserApproval "Permanently allow Non-Admin Users to install USB Shared Printer drivers (Point & Print bypass)?") {
    try {
        if (-not (Test-Path $PointAndPrintKey)) { New-Item -Path $PointAndPrintKey -Force | Out-Null }
        Set-ItemProperty -Path $PointAndPrintKey -Name "Restricted" -Value 0 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "TrustedServers" -Value 0 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "NoWarningNoElevationOnInstall" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "UpdatePromptSettings" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value 0 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully configured permanent Point & Print bypass policy keys." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set Point & Print keys: $($_.Exception.Message)" "ERROR"
    }
}

# 4. Configure RPC Connection Protocol Types (Named Pipes & TCP - Fixes Error 0x00000bc4 & 0x00000709)
$RpcPrinterKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
if (Get-UserApproval "Enable RPC over Named Pipes & TCP protocol bindings (Fixes Error 0x00000bc4 & 0x00000709)?") {
    try {
        if (-not (Test-Path $RpcPrinterKey)) { New-Item -Path $RpcPrinterKey -Force | Out-Null }
        
        # Legacy/Compatibility keys
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcOverNamedPipes" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcOverTcp" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcUseNamedPipesAsDefault" -Value 1 -PropertyType DWord -Force | Out-Null
        
        # Modern Windows 11 / Server 2022+ RPC keys
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcUseNamedPipeProtocol" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcProtocols" -Value 7 -PropertyType DWord -Force | Out-Null
        
        Log-Msg "  [OK] Successfully configured RPC over Named Pipes & TCP (RpcUseNamedPipeProtocol=1, RpcProtocols=7)." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set RPC protocol keys: $($_.Exception.Message)" "ERROR"
    }
}

# 5. Configure CopyFiles Policy Fix (Error 0x0000007c)
$PrintersPolicyKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers"
if (Get-UserApproval "Enable Legacy CopyFiles Spooler Policy (Fixes Error 0x0000007c)?") {
    try {
        if (-not (Test-Path $PrintersPolicyKey)) { New-Item -Path $PrintersPolicyKey -Force | Out-Null }
        Set-ItemProperty -Path $PrintersPolicyKey -Name "CopyFilesPolicy" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully configured CopyFilesPolicy = 1." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set CopyFilesPolicy: $($_.Exception.Message)" "ERROR"
    }
}

# 6. KB5089549 Driver Blocklist & Code Integrity Bypass
$CiConfigKey = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config"
if (Get-UserApproval "Bypass Cumulative Update Driver Blocklist Restrictions (Fix KB5089549 print driver blocks)?") {
    try {
        if (-not (Test-Path $CiConfigKey)) { New-Item -Path $CiConfigKey -Force | Out-Null }
        Set-ItemProperty -Path $CiConfigKey -Name "VulnerableDriverBlocklistEnable" -Value 0 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully disabled VulnerableDriverBlocklistEnable." "SUCCESS"
    } catch {
        Log-Msg "  [WARN] Failed to set VulnerableDriverBlocklistEnable: $($_.Exception.Message)" "WARN"
    }
}

# 7. Hard Purge Print Queue & Force Stop Stuck Isolation Host Processes
if (Get-UserApproval "Hard Purge Print Queue (.spl/.shd) & force-stop stuck print processes (splwow64, PrintIsolationHost)?") {
    try {
        Stop-Service -Name "spooler" -Force -ErrorAction SilentlyContinue
        Get-Process -Name "splwow64","PrintIsolationHost","printfilterpipelinesvc" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $SpoolPath = Join-Path $env:SystemRoot "System32\spool\PRINTERS"
        if (Test-Path $SpoolPath) {
            Remove-Item -Path "$SpoolPath\*" -Force -Recurse -ErrorAction SilentlyContinue
        }
        Start-Service -Name "spooler" -ErrorAction SilentlyContinue
        Log-Msg "  [OK] Hard purge of print queue completed and Spooler restarted." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to hard purge print queue: $($_.Exception.Message)" "ERROR"
    }
}

# 8. Restart Print Spooler Service to apply changes
if (Get-UserApproval "Restart the Print Spooler service to apply printer registry changes?") {
    try {
        Restart-Service -Name "spooler" -Force -ErrorAction Stop
        Log-Msg "  [OK] Print Spooler service restarted successfully." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to restart Print Spooler: $($_.Exception.Message)" "ERROR"
    }
}

Log-Msg "USB Shared Printer repairs completed." "SUCCESS"
return 0
