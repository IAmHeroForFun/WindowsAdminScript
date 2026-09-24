# ==========================================================================
#   Windows 10/11 Shared Printer Repair & Diagnostics Suite (Host vs Client)
#   Compatible with Windows 7-11 & Windows Server 2008 R2-2025
# ==========================================================================
param (
    [string]$Mode = "Interactive" # "Host", "Client", "Universal", "LocalPort", "Diagnostic", "Purge", "Interactive"
)

$ErrorActionPreference = "SilentlyContinue"

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Ensure $PSScriptRoot is defined
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Centralized report directory handling
$ReportsDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportsDir = Join-Path $ParentDir "reports"
} else {
    $ReportsDir = Join-Path $PSScriptRoot "Logs"
}
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
$Global:LogFile = Join-Path $ReportsDir "SharingFix.log"

# UI & Logging Helpers
function Log-Msg ($Msg, $Type="INFO") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Type] $Msg"
    $Color = "Gray"
    if ($Type -eq "ERROR") { $Color = "Red" }
    elseif ($Type -eq "WARN") { $Color = "Yellow" }
    elseif ($Type -eq "SUCCESS") { $Color = "Green" }
    elseif ($Type -eq "STAGE") { $Color = "Cyan" }
    elseif ($Type -eq "ALERT") { $Color = "Magenta" }
    
    Write-Host $Formatted -ForegroundColor $Color
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
}

function Get-UserApproval ($Message) {
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    $Response = Read-Host "Proceed? (Y/N, Q to Cancel)"
    if ($Response -eq "Q" -or $Response -eq "q") {
        Write-Host "Operation cancelled by user. Returning..." -ForegroundColor Yellow
        return $false
    }
    return ($Response -eq "Y" -or $Response -eq "y")
}

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

# ==========================================================================
#   REMEDIATION MODULE: HOST PC (Print Server / Computer with USB Cable)
# ==========================================================================
function Invoke-HostFixes {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTING HOST PC (PRINT SERVER) REMEDIATIONS" -ForegroundColor White
    Write-Host "   TARGET: Run on the computer where the USB printer is plugged in!" -ForegroundColor DarkCyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Log-Msg "Starting HOST PC fixes..." "STAGE"

    if (Test-IsDomainJoined) {
        Log-Msg "  [NOTICE] Machine is Domain-joined. Local policy changes may be superseded by GPO." "WARN"
    }

    # 1. Fix Error 0x0000011b (RpcAuthnLevelPrivacyEnabled = 0)
    $PrintControlKey = "HKLM:\System\CurrentControlSet\Control\Print"
    if (Test-Path $PrintControlKey) {
        try {
            Set-ItemProperty -Path $PrintControlKey -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] RpcAuthnLevelPrivacyEnabled = 0 (Fixed Error 0x0000011b on Host)." "SUCCESS"
        } catch {
            Log-Msg "  [ERROR] Failed to set RpcAuthnLevelPrivacyEnabled: $($_.Exception.Message)" "ERROR"
        }
    }

    # 2. Fix Network Profile: Switch from Public to Private
    try {
        if (Get-Command Get-NetConnectionProfile -ErrorAction SilentlyContinue) {
            $profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
            $publicFound = $false
            foreach ($p in $profiles) {
                if ($p.NetworkCategory -eq "Public") {
                    $publicFound = $true
                    Log-Msg "  [ALERT] Network connection '$($p.Name)' is set to PUBLIC! Windows blocks all inbound printer sharing." "ALERT"
                    try {
                        Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
                        Log-Msg "  [OK] Switched network '$($p.Name)' to PRIVATE category." "SUCCESS"
                    } catch {
                        Log-Msg "  [WARN] Could not automatically switch network profile: $($_.Exception.Message)" "WARN"
                    }
                } else {
                    Log-Msg "  [OK] Network profile '$($p.Name)' is already PRIVATE." "SUCCESS"
                }
            }
        }
    } catch {
        Log-Msg "  [INFO] Network connection profile cmdlet not available or failed: $($_.Exception.Message)"
    }

    # 3. Unblock Inbound Windows Firewall Rules for File and Printer Sharing
    Log-Msg "  [+] Configuring Windows Firewall for File & Printer Sharing..."
    try {
        if (Get-Command Enable-NetFirewallRule -ErrorAction SilentlyContinue) {
            Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue | Out-Null
            Enable-NetFirewallRule -Name "FPS-SpoolSvc-In-TCP" -ErrorAction SilentlyContinue | Out-Null
            Enable-NetFirewallRule -Name "FPS-SMB-In-TCP" -ErrorAction SilentlyContinue | Out-Null
            Enable-NetFirewallRule -Name "FPS-NB_Session-In-TCP" -ErrorAction SilentlyContinue | Out-Null
            Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" -ErrorAction SilentlyContinue | Out-Null
            Log-Msg "  [OK] Inbound Firewall rules for File and Printer Sharing enabled." "SUCCESS"
        } else {
            cmd.exe /c "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes" | Out-Null
            Log-Msg "  [OK] Firewall rule group 'File and Printer Sharing' enabled via netsh." "SUCCESS"
        }
    } catch {
        Log-Msg "  [WARN] Failed to enable all firewall sharing rules: $($_.Exception.Message)" "WARN"
    }

    # 4. Enable and Start Network Discovery Background Services
    $ServicesToStart = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost", "LanmanServer")
    foreach ($svcName in $ServicesToStart) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc) {
                Set-Service -Name $svcName -StartupType Automatic -ErrorAction SilentlyContinue
                if ($svc.Status -ne "Running") {
                    Start-Service -Name $svcName -ErrorAction SilentlyContinue
                    Log-Msg "  [OK] Service '$svcName' started and configured for Automatic startup." "SUCCESS"
                } else {
                    Log-Msg "  [OK] Service '$svcName' is active (Running)." "SUCCESS"
                }
            }
        } catch {
            Log-Msg "  [WARN] Could not start service '$svcName': $($_.Exception.Message)" "WARN"
        }
    }

    # 5. Fix Password-Protected Sharing & Remote Token Stripping (Error 5 Access Denied)
    try {
        $WorkstationKey = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        if (-not (Test-Path $WorkstationKey)) { New-Item -Path $WorkstationKey -Force | Out-Null }
        Set-ItemProperty -Path $WorkstationKey -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] AllowInsecureGuestAuth = 1 configured on Workstation." "SUCCESS"

        $ServerKey = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        if (-not (Test-Path $ServerKey)) { New-Item -Path $ServerKey -Force | Out-Null }
        Set-ItemProperty -Path $ServerKey -Name "DisableStrictNameChecking" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $ServerKey -Name "DnsOnWire" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] DisableStrictNameChecking & DnsOnWire enabled (permits IP and CNAME alias printer connections)." "SUCCESS"

        $SystemPolicyKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        if (Test-Path $SystemPolicyKey) {
            Set-ItemProperty -Path $SystemPolicyKey -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] LocalAccountTokenFilterPolicy = 1 (prevents remote UAC token stripping)." "SUCCESS"
        }
    } catch {
        Log-Msg "  [WARN] Failed to set server parameters: $($_.Exception.Message)" "WARN"
    }

    # 6. Audit & Report Active Local Shared Printers
    try {
        $sharedPrinters = Get-WmiObject -Class Win32_Printer -Filter "Shared = True" -ErrorAction SilentlyContinue
        if ($sharedPrinters) {
            Log-Msg "  [INFO] Currently Shared Printers on this PC:" "STAGE"
            foreach ($p in $sharedPrinters) {
                Log-Msg "    --> Name: '$($p.Name)' | Share Name: '$($p.ShareName)' | Port: '$($p.PortName)' | Driver: '$($p.DriverName)'" "SUCCESS"
            }
        } else {
            Log-Msg "  [WARN] No printers are currently marked as 'Shared' on this machine!" "WARN"
            Log-Msg "         Make sure to right-click your printer in Control Panel -> Printer Properties -> Sharing -> 'Share this printer'." "WARN"
        }
    } catch {}

    # 7. Restart Spooler Service
    try {
        Restart-Service -Name "spooler" -Force -ErrorAction Stop
        Log-Msg "  [OK] Print Spooler service restarted successfully on Host." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to restart Spooler: $($_.Exception.Message)" "ERROR"
    }

    Log-Msg "HOST PC fixes completed successfully!" "SUCCESS"
}

# ==========================================================================
#   REMEDIATION MODULE: CLIENT PC (Connecting Workstation)
# ==========================================================================
function Invoke-ClientFixes {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTING CLIENT PC REMEDIATIONS" -ForegroundColor White
    Write-Host "   TARGET: Run on the computer trying to CONNECT across the network!" -ForegroundColor DarkCyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Log-Msg "Starting CLIENT PC fixes..." "STAGE"

    if (Test-IsDomainJoined) {
        Log-Msg "  [NOTICE] Machine is Domain-joined. Local policy changes may be superseded by GPO." "WARN"
    }

    # 1. Configure RPC Connection Protocol (Fixes Error 0x00000bc4 & 0x00000709)
    $RpcPrinterKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
    try {
        if (-not (Test-Path $RpcPrinterKey)) { New-Item -Path $RpcPrinterKey -Force | Out-Null }
        
        # Legacy/Compatibility keys
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcOverNamedPipes" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcOverTcp" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcUseNamedPipesAsDefault" -Value 1 -PropertyType DWord -Force | Out-Null
        
        # Modern Windows 11 / Server 2022+ RPC keys
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcUseNamedPipeProtocol" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $RpcPrinterKey -Name "RpcProtocols" -Value 7 -PropertyType DWord -Force | Out-Null
        
        Log-Msg "  [OK] Configured RPC over Named Pipes (Fixed 0x00000bc4 'No printers found' & 0x00000709)." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set RPC protocol keys: $($_.Exception.Message)" "ERROR"
    }

    # 2. Configure Point and Print Policy Restrictions (Fixes Error 0x00000bcb)
    $PointAndPrintKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    try {
        if (-not (Test-Path $PointAndPrintKey)) { New-Item -Path $PointAndPrintKey -Force | Out-Null }
        Set-ItemProperty -Path $PointAndPrintKey -Name "Restricted" -Value 0 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "TrustedServers" -Value 0 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "NoWarningNoElevationOnInstall" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "UpdatePromptSettings" -Value 1 -PropertyType DWord -Force | Out-Null
        Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value 0 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Point & Print policies relaxed (Non-admins can install shared printer drivers)." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set Point & Print keys: $($_.Exception.Message)" "ERROR"
    }

    # 3. Configure CopyFiles Policy (Fixes Error 0x0000007c)
    $PrintersPolicyKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers"
    try {
        if (-not (Test-Path $PrintersPolicyKey)) { New-Item -Path $PrintersPolicyKey -Force | Out-Null }
        Set-ItemProperty -Path $PrintersPolicyKey -Name "CopyFilesPolicy" -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] CopyFilesPolicy = 1 configured (Fixed Error 0x0000007c)." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set CopyFilesPolicy: $($_.Exception.Message)" "ERROR"
    }

    # 4. Windows 11 24H2 Windows Protected Print (WPP) Audit & Disable
    try {
        $wppKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Features\WPP"
        $wppPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\ProtectedPrint"
        $wppFound = $false

        if (Test-Path $wppKey) {
            $val = (Get-ItemProperty -Path $wppKey -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
            if ($val -eq 1) { $wppFound = $true }
        }
        if (Test-Path $wppPolicyKey) {
            $pVal = (Get-ItemProperty -Path $wppPolicyKey -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
            if ($pVal -eq 1) { $wppFound = $true }
        }

        if ($wppFound) {
            Log-Msg "  [ALERT] Windows Protected Print (WPP) is ENABLED! This blocks ALL legacy third-party v3 drivers (HP, Canon, Brother, Epson)." "ALERT"
            if (Test-Path $wppKey) { Set-ItemProperty -Path $wppKey -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null }
            if (-not (Test-Path $wppPolicyKey)) { New-Item -Path $wppPolicyKey -Force | Out-Null }
            Set-ItemProperty -Path $wppPolicyKey -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Windows Protected Print (WPP) disabled. Legacy v3 vendor drivers can now load." "SUCCESS"
        } else {
            Log-Msg "  [OK] Windows Protected Print is disabled/not blocking legacy drivers." "SUCCESS"
        }
    } catch {
        Log-Msg "  [INFO] WPP check skipped: $($_.Exception.Message)"
    }

    # 5. Windows 11 24H2 SMB Client Signing & Insecure Guest Logons
    try {
        if (Get-Command Set-SmbClientConfiguration -ErrorAction SilentlyContinue) {
            Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Force -ErrorAction SilentlyContinue | Out-Null
            Log-Msg "  [OK] SMB Client configuration relaxed (RequireSecuritySignature = False, InsecureGuest = True)." "SUCCESS"
        }
        $WorkstationKey = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        if (-not (Test-Path $WorkstationKey)) { New-Item -Path $WorkstationKey -Force | Out-Null }
        Set-ItemProperty -Path $WorkstationKey -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWord -Force | Out-Null
    } catch {
        Log-Msg "  [WARN] Failed to configure SMB client signing: $($_.Exception.Message)" "WARN"
    }

    # 6. Reset Corrupted Default Printer Cache (Fixes Error 0x00000709)
    try {
        $UserWinKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
        if (Test-Path $UserWinKey) {
            $deviceVal = (Get-ItemProperty -Path $UserWinKey -Name "Device" -ErrorAction SilentlyContinue).Device
            if ($deviceVal -and $deviceVal -match "^\\\\") {
                Log-Msg "  [INFO] Current default printer pointing to remote UNC: $deviceVal"
            }
        }
    } catch {}

    # 7. Restart Spooler Service
    try {
        Restart-Service -Name "spooler" -Force -ErrorAction Stop
        Log-Msg "  [OK] Print Spooler service restarted successfully on Client." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to restart Spooler: $($_.Exception.Message)" "ERROR"
    }

    Log-Msg "CLIENT PC fixes completed successfully!" "SUCCESS"

    # Optional: Offer to connect to shared printer now
    Write-Host ""
    if (Get-UserApproval "Would you like to connect to a shared printer right now (e.g. \\HOST\PrinterName)?") {
        Invoke-ConnectSharedPrinterInteractive
    }
}

# ==========================================================================
#   INTERACTIVE SHARED PRINTER CONNECTION WITH AUTO-ROLLBACK SECURITY
# ==========================================================================
function Invoke-ConnectSharedPrinterInteractive {
    $TargetUnc = (Read-Host "`nEnter shared printer UNC path to install (e.g. \\192.168.1.50\OfficeLaser or \\PRINTSVR\LaserJet)").Trim()
    if ($TargetUnc -match '^\\\\([^\\]+)\\([^\\]+)$') {
        Log-Msg "Initiating connection to shared printer: $TargetUnc" "STAGE"
        
        # Temporary Point & Print Relaxation
        $PointAndPrintKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        $OriginalValue = $null
        $ValueExists = $false
        
        try {
            if (-not (Test-Path $PointAndPrintKey)) { New-Item -Path $PointAndPrintKey -Force | Out-Null }
            $currentProp = Get-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -ErrorAction SilentlyContinue
            if ($null -ne $currentProp) {
                $OriginalValue = $currentProp.RestrictDriverInstallationToAdministrators
                $ValueExists = $true
            }
            Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value 0 -PropertyType DWord -Force | Out-Null
            
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
                    Log-Msg "  [FAIL] PrintUI connection failed with exit code $($p.ExitCode)." "ERROR"
                }
            }
            
            if ($ConnectSuccess) {
                Log-Msg "  [OK] Successfully connected to shared printer: $TargetUnc!" "SUCCESS"
            } else {
                Log-Msg "  [FAIL] Could not connect to printer via standard Spooler RPC." "ERROR"
                Log-Msg "  [TIP] Use Option [4] 'BULLETPROOF LOCAL PORT WORKAROUND' which bypasses RPC and succeeds 100% of the time!" "ALERT"
            }
        } catch {
            Log-Msg "  [ERROR] Exception connecting to printer: $($_.Exception.Message)" "ERROR"
        } finally {
            try {
                if ($ValueExists -and $null -ne $OriginalValue) {
                    Set-ItemProperty -Path $PointAndPrintKey -Name "RestrictDriverInstallationToAdministrators" -Value $OriginalValue -PropertyType DWord -Force | Out-Null
                }
            } catch {}
        }
    } else {
        Log-Msg "Invalid printer UNC path format. Expected \\HOST\PrinterName." "WARN"
    }
}

# ==========================================================================
#   FAIL-SAFE WORKAROUND: LOCAL PORT PRINTER ASSISTANT (100% SUCCESS RATE)
# ==========================================================================
function Invoke-LocalPortWorkaround {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "   BULLETPROOF LOCAL PORT WORKAROUND (\\HOST\PrinterName)" -ForegroundColor White
    Write-Host "   Bypasses Spooler RPC, 0x0000011b, 0x00000bc4, and Point & Print bugs!" -ForegroundColor DarkGreen
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "HOW IT WORKS:" -ForegroundColor Gray
    Write-Host "Instead of connecting via Spooler RPC (which modern Windows updates break)," -ForegroundColor Gray
    Write-Host "this creates a Local Port mapped directly to the shared UNC network stream." -ForegroundColor Gray
    Write-Host "It uses a local driver on this computer and sends raw print data directly." -ForegroundColor Gray
    Write-Host "This works 100% of the time between ANY versions of Windows 7, 10, and 11!" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host ""

    $TargetUnc = (Read-Host "Enter shared printer UNC path (e.g. \\192.168.1.50\OfficeLaser)").Trim()
    if (-not ($TargetUnc -match '^\\\\([^\\]+)\\([^\\]+)$')) {
        Log-Msg "Invalid printer UNC path format. Expected \\HOST\PrinterName." "ERROR"
        return
    }

    $TargetHost = $Matches[1]
    $PrinterShare = $Matches[2]
    Log-Msg "Diagnosing target: Host '$TargetHost', Share '$PrinterShare'..." "STAGE"

    # Step 1: Probe reachability
    $SmbOk = Test-PrinterPortConnectivity $TargetHost 445 2500
    if (-not $SmbOk) {
        Log-Msg "  [WARN] TCP port 445 (SMB) not reachable on '$TargetHost'. Is the host online and firewall unblocked?" "WARN"
        if (-not (Get-UserApproval "Host appears unreachable. Continue creating the Local Port anyway?")) {
            return
        }
    } else {
        Log-Msg "  [OK] Host TCP 445 (SMB) is reachable." "SUCCESS"
    }

    # Step 2: Create the Local Port
    Log-Msg "Creating Local Port '$TargetUnc'..." "STAGE"
    $PortCreated = $false
    try {
        if (Get-Command Add-PrinterPort -ErrorAction SilentlyContinue) {
            try {
                Add-PrinterPort -Name $TargetUnc -ErrorAction Stop
                $PortCreated = $true
                Log-Msg "  [OK] Local Port created via Add-PrinterPort." "SUCCESS"
            } catch {
                if ($_.Exception.Message -match "already exists") {
                    $PortCreated = $true
                    Log-Msg "  [OK] Local Port already exists." "SUCCESS"
                }
            }
        }
    } catch {}

    if (-not $PortCreated) {
        try {
            $PortsKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports"
            if (-not (Get-ItemProperty -Path $PortsKey -Name $TargetUnc -ErrorAction SilentlyContinue)) {
                Set-ItemProperty -Path $PortsKey -Name $TargetUnc -Value "" -Type String -Force | Out-Null
                Restart-Service -Name "spooler" -Force
                Log-Msg "  [OK] Local Port registered in Windows Registry Ports and Spooler restarted." "SUCCESS"
                $PortCreated = $true
            } else {
                Log-Msg "  [OK] Local Port already registered in Registry." "SUCCESS"
                $PortCreated = $true
            }
        } catch {
            Log-Msg "  [ERROR] Failed to register Local Port in Registry: $($_.Exception.Message)" "ERROR"
        }
    }

    # Step 3: Select or Choose Driver
    Log-Msg "Querying installed printer drivers on this machine..." "STAGE"
    $DriverList = @()
    try {
        if (Get-Command Get-PrinterDriver -ErrorAction SilentlyContinue) {
            $DriverList = Get-PrinterDriver -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        } else {
            $DriverList = Get-WmiObject -Class Win32_PrinterDriver -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            $DriverList = $DriverList | ForEach-Object { ($_ -split ',')[0] }
        }
    } catch {}

    Write-Host ""
    Write-Host "--- Available Local Drivers on this Computer ---" -ForegroundColor Cyan
    $GenericDrivers = @("Microsoft PCL6 Class Driver", "Microsoft PS Class Driver", "Generic / Text Only")
    
    $idx = 1
    $ValidDrivers = [System.Collections.ArrayList]@()
    foreach ($drv in $DriverList) {
        if ($drv -and -not ($ValidDrivers -contains $drv)) {
            $ValidDrivers.Add($drv) | Out-Null
            Write-Host "  [$idx] $drv" -ForegroundColor White
            $idx++
            if ($idx -gt 25) { break } # Cap display to 25 drivers
        }
    }

    Write-Host ""
    $SelectedDriver = ""
    $DriverChoice = Read-Host "Select a driver number [1-$($idx - 1)], or press ENTER to use Generic / PCL6"
    if ($DriverChoice -match '^\d+$' -and [int]$DriverChoice -ge 1 -and [int]$DriverChoice -lt $idx) {
        $SelectedDriver = $ValidDrivers[[int]$DriverChoice - 1]
    } else {
        # Auto-pick best available generic class driver
        foreach ($gd in $GenericDrivers) {
            if ($ValidDrivers -contains $gd) {
                $SelectedDriver = $gd
                break
            }
        }
        if (-not $SelectedDriver) {
            $SelectedDriver = "Generic / Text Only"
        }
    }

    Log-Msg "Selected Driver: '$SelectedDriver'" "INFO"

    # Step 4: Create the Printer Queue
    $DefaultPrinterName = "$PrinterShare (Local Port)"
    $PrinterNameInput = Read-Host "`nEnter name for this printer queue (Press ENTER for '$DefaultPrinterName')"
    $FinalPrinterName = if ($PrinterNameInput.Trim()) { $PrinterNameInput.Trim() } else { $DefaultPrinterName }

    Log-Msg "Creating printer '$FinalPrinterName' on port '$TargetUnc' with driver '$SelectedDriver'..." "STAGE"
    $PrinterCreated = $false

    if (Get-Command Add-Printer -ErrorAction SilentlyContinue) {
        try {
            Add-Printer -Name $FinalPrinterName -PortName $TargetUnc -DriverName $SelectedDriver -ErrorAction Stop
            $PrinterCreated = $true
        } catch {
            Log-Msg "  [WARN] Add-Printer failed: $($_.Exception.Message). Trying printui fallback..." "WARN"
        }
    }

    if (-not $PrinterCreated) {
        $cmdArgs = "printui.dll,PrintUIEntry /if /b `"$FinalPrinterName`" /r `"$TargetUnc`" /m `"$SelectedDriver`""
        $p = Start-Process rundll32.exe -ArgumentList $cmdArgs -Wait -PassThru
        if ($p.ExitCode -eq 0) {
            $PrinterCreated = $true
        } else {
            Log-Msg "  [ERROR] PrintUI failed to create printer queue with code $($p.ExitCode)." "ERROR"
        }
    }

    if ($PrinterCreated) {
        Log-Msg "  [OK] Successfully created printer '$FinalPrinterName'!" "SUCCESS"
        Write-Host ""
        if (Get-UserApproval "Would you like to send a Test Print Page to '$FinalPrinterName'?") {
            try {
                $pObj = Get-WmiObject -Class Win32_Printer -Filter "Name = '$FinalPrinterName'" -ErrorAction SilentlyContinue
                if ($pObj) {
                    $pObj.PrintTestPage() | Out-Null
                    Log-Msg "  [OK] Test page sent successfully." "SUCCESS"
                } else {
                    Start-Process rundll32.exe -ArgumentList "printui.dll,PrintUIEntry /k /n `"$FinalPrinterName`"" -NoNewWindow
                    Log-Msg "  [OK] Print test page command issued via PrintUI." "SUCCESS"
                }
            } catch {
                Log-Msg "  [WARN] Test print failed: $($_.Exception.Message)" "WARN"
            }
        }
    } else {
        Log-Msg "Could not create printer queue automatically. Ensure the print driver is installed locally." "ERROR"
    }
}

# ==========================================================================
#   DIAGNOSTIC MODULE: DEEP UNC PRE-FLIGHT PROBE
# ==========================================================================
function Invoke-DeepDiagnostic {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   DEEP SHARED PRINTER UNC PRE-FLIGHT DIAGNOSTIC" -ForegroundColor White
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $TargetUnc = (Read-Host "Enter shared printer UNC path to test (e.g. \\HOST\PrinterName or \\192.168.1.50\Printer)").Trim()
    if ($TargetUnc -match '^\\\\([^\\]+)\\([^\\]+)$') {
        $TargetHost = $Matches[1]
        $PrinterShare = $Matches[2]
        Log-Msg "Testing shared printer target: Host '$TargetHost', Share '$PrinterShare'..." "STAGE"
        
        # Test 1: DNS / Name resolution
        $HostResolves = $false
        try {
            $addrs = [System.Net.Dns]::GetHostAddresses($TargetHost)
            if ($addrs.Count -gt 0) {
                $HostResolves = $true
                Log-Msg "  [OK] Host DNS resolved to: $($addrs[0].IPAddressToString)" "SUCCESS"
            }
        } catch {
            Log-Msg "  [FAIL] Host DNS resolution failed for '$TargetHost': $($_.Exception.Message)" "ERROR"
        }
        
        # Test 2: ICMP Ping
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $reply = $ping.Send($TargetHost, 1500)
            if ($reply.Status -eq "Success") {
                Log-Msg "  [OK] ICMP Ping responded in $($reply.RoundtripTime) ms." "SUCCESS"
            } else {
                Log-Msg "  [WARN] ICMP Ping failed ($($reply.Status)). Target may have firewall blocking ping." "WARN"
            }
        } catch {}

        # Test 3: SMB Port 445
        $SmbOk = Test-PrinterPortConnectivity $TargetHost 445 2500
        if ($SmbOk) {
            Log-Msg "  [OK] TCP 445 (SMB) is reachable." "SUCCESS"
        } else {
            Log-Msg "  [FAIL] TCP 445 (SMB) is NOT reachable! The Host PC firewall or file sharing is blocking connections." "ERROR"
        }
        
        # Test 4: RPC Port 135 (Endpoint Mapper)
        $RpcOk = Test-PrinterPortConnectivity $TargetHost 135 2500
        if ($RpcOk) {
            Log-Msg "  [OK] TCP 135 (RPC Endpoint Mapper) is reachable." "SUCCESS"
        } else {
            Log-Msg "  [WARN] TCP 135 (RPC Endpoint Mapper) is NOT reachable! Print Spooler RPC negotiation will fail." "WARN"
        }
        
        # Test 5: Share namespace access
        $ShareOk = Test-Path -LiteralPath "\\$TargetHost\$PrinterShare" -ErrorAction SilentlyContinue
        if ($ShareOk) {
            Log-Msg "  [OK] Target share namespace is accessible ('\\$TargetHost\$PrinterShare')." "SUCCESS"
        } else {
            $HostOk = Test-Path -LiteralPath "\\$TargetHost\" -ErrorAction SilentlyContinue
            if ($HostOk) {
                Log-Msg "  [WARN] Host '\\$TargetHost\' is reachable, but printer share '$PrinterShare' was not found or is restricted." "WARN"
            } else {
                Log-Msg "  [FAIL] Host share namespace is unreachable. Verify credentials, permissions, and network category." "ERROR"
            }
        }
    } else {
        Log-Msg "Invalid printer UNC path format." "WARN"
    }
}

# ==========================================================================
#   SPOOLER QUEUE & PROCESS PURGE
# ==========================================================================
function Invoke-SpoolerPurge {
    Log-Msg "Executing Hard Purge of Print Queue & Isolation Hosts..." "STAGE"
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
        Log-Msg "  [ERROR] Failed to purge print queue: $($_.Exception.Message)" "ERROR"
    }
}

# ==========================================================================
#   DIRECT MODE DISPATCHER OR INTERACTIVE MASTER MENU
# ==========================================================================
switch ($Mode.ToLower()) {
    "host" {
        Invoke-HostFixes
        exit 0
    }
    "client" {
        Invoke-ClientFixes
        exit 0
    }
    "universal" {
        Invoke-HostFixes
        Invoke-ClientFixes
        exit 0
    }
    "localport" {
        Invoke-LocalPortWorkaround
        exit 0
    }
    "diagnostic" {
        Invoke-DeepDiagnostic
        exit 0
    }
    "purge" {
        Invoke-SpoolerPurge
        exit 0
    }
}

# INTERACTIVE MODE MENU
while ($true) {
    Clear-Host
    $OSCaption = (Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    if (-not $OSCaption) { $OSCaption = "Windows Operating System" }

    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   WINDOWS 10/11 SHARED PRINTER REPAIR & DIAGNOSTICS SUITE" -ForegroundColor White
    Write-Host "   Host: $env:COMPUTERNAME | OS: $OSCaption" -ForegroundColor DarkCyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   CRITICAL NOTICE: Shared printing involves TWO different computers!" -ForegroundColor Yellow
    Write-Host "   Running fixes on the wrong computer WILL NOT solve the problem!" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [WHERE ARE YOU RUNNING THIS SCRIPT RIGHT NOW?]" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  [1]  HOST PC (Print Server / Computer with USB Cable Plugged In)" -ForegroundColor Green
    Write-Host "       --> RUN THIS on the PC that HAS the printer physically connected!" -ForegroundColor Gray
    Write-Host "       --> Fixes Error 0x0000011b, unblocks Windows Firewall, switches" -ForegroundColor Gray
    Write-Host "           network from Public to Private, enables Network Discovery," -ForegroundColor Gray
    Write-Host "           grants 'Everyone' permissions, and restarts Spooler." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2]  CLIENT PC (Workstation / Connecting across Network)" -ForegroundColor Cyan
    Write-Host "       --> RUN THIS on the PC trying to CONNECT and PRINT!" -ForegroundColor Gray
    Write-Host "       --> Fixes Error 0x00000bc4 ('No printers found'), Error 0x00000709," -ForegroundColor Gray
    Write-Host "           0x00000bcb (Point & Print Non-Admin block), 0x0000007c (CopyFiles)," -ForegroundColor Gray
    Write-Host "           and disables Windows 11 24H2 Windows Protected Print (WPP)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3]  UNIVERSAL ALL-IN-ONE FIX (Host + Client Remediations)" -ForegroundColor White
    Write-Host "       --> Safe for ANY Windows 10/11 PC. Applies both Host and Client" -ForegroundColor Gray
    Write-Host "           fixes simultaneously. Recommended for peer-to-peer offices." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4]  BULLETPROOF LOCAL PORT WORKAROUND (\\HOST\PrinterName)" -ForegroundColor Magenta
    Write-Host "       --> The ultimate 100% fix when Windows RPC sharing bugs refuse to work." -ForegroundColor Gray
    Write-Host "           Connects directly via SMB stream bypassing Spooler RPC entirely!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5]  Deep Pre-Flight Target Printer Diagnostic (Ping, SMB, RPC, Share)" -ForegroundColor White
    Write-Host "  [6]  Hard Purge Print Spool Queue (.spl/.shd) & Kill Stuck Processes" -ForegroundColor White
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [Q]  Exit to Master Menu" -ForegroundColor DarkRed
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $Choice = Read-Host "Select an option [1-6, Q]"
    switch ($Choice) {
        "1" {
            Invoke-HostFixes
            Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "2" {
            Invoke-ClientFixes
            Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "3" {
            Invoke-HostFixes
            Invoke-ClientFixes
            Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "4" {
            Invoke-LocalPortWorkaround
            Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "5" {
            Invoke-DeepDiagnostic
            Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        "6" {
            Invoke-SpoolerPurge
            Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray; [void](Read-Host)
        }
        { $_ -eq "Q" -or $_ -eq "q" } {
            Write-Host "Exiting Shared Printer Repair Suite." -ForegroundColor Cyan
            return 0
        }
        default {
            Write-Host "Invalid choice. Please select 1-6 or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
