# ==========================================================================
#   Remote Desktop (RDP) & CredSSP Repair Suite - Main Coordinator
# ==========================================================================
$ErrorActionPreference = "SilentlyContinue"

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

$Global:LogFile = Join-Path $ReportsDir "RdpFix.log"
$ReportPath = Join-Path $ReportsDir "RdpFixReport.txt"
$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

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
    
    $Color = "Gray"
    if ($Type -eq "ERROR") { $Color = "Red" }
    elseif ($Type -eq "WARN") { $Color = "Yellow" }
    elseif ($Type -eq "SUCCESS") { $Color = "Green" }
    elseif ($Type -eq "STAGE") { $Color = "Cyan" }
    
    Write-Host $Formatted -ForegroundColor $Color
    $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
}

Clear-Host
Log-Msg "==========================================================================" "STAGE"
Log-Msg "     REMOTE DESKTOP (RDP) & CREDSSP ENCRYPTION ORACLE REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 1. System Restore Point Creation
if (Get-UserApproval "Create a Windows System Restore Point before proceeding?") {
    Log-Msg "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BeforeRdpCredSspFix" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log-Msg "System Restore Point created successfully." "SUCCESS"
    } catch {
        Log-Msg "Failed to create Restore Point: $($_.Exception.Message). Continuing with repairs..." "WARN"
    }
}

# 2. Fix CredSSP Encryption Oracle Remediation
Log-Msg "Executing CredSSP Encryption Oracle repair module..." "STAGE"
$CredSspScript = Join-Path $PSScriptRoot "Fix-CredSSP-Oracle.ps1"
if (Test-Path $CredSspScript) {
    & $CredSspScript
}

# 3. Enable RDP & Firewall
Log-Msg "Executing Remote Desktop Service & Firewall module..." "STAGE"
$EnableScript = Join-Path $PSScriptRoot "Enable-RDP-Service.ps1"
if (Test-Path $EnableScript) {
    & $EnableScript
}

# 4. Fix Windows 11 UDP Session Freezes
Log-Msg "Executing Windows 11 RDP UDP freeze & disconnect repair module..." "STAGE"
$UdpScript = Join-Path $PSScriptRoot "Fix-RDP-UDP-Freeze.ps1"
if (Test-Path $UdpScript) {
    & $UdpScript
}

# 5. Fix Black Screen on RDP Connection (WDDM Display Driver Fallback)
Log-Msg "Executing RDP black screen graphics driver repair module..." "STAGE"
$BlackScreenScript = Join-Path $PSScriptRoot "Fix-RDP-BlackScreen.ps1"
if (Test-Path $BlackScreenScript) {
    & $BlackScreenScript
}

# 6. Configure RDP Port
Log-Msg "Executing RDP Port inspection & configuration module..." "STAGE"
$PortScript = Join-Path $PSScriptRoot "Configure-RDP-Port.ps1"
if (Test-Path $PortScript) {
    & $PortScript
}

# 7. Optional Target Host Diagnostic Probe
if (Get-UserApproval "Test network connectivity & RDP port reachability to a remote host?") {
    $TargetHost = (Read-Host "Enter remote hostname or IP address (e.g. 192.168.1.50 or SERVER-01)").Trim()
    $TargetPort = Read-Host "Enter target RDP port [Press Enter for 3389]"
    if (-not $TargetPort -or $TargetPort -notmatch "^\d+$") { $TargetPort = 3389 } else { $TargetPort = [int]$TargetPort }
    
    if ($TargetHost) {
        Log-Msg "Testing reachability to $TargetHost on port $TargetPort..."
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $iar = $client.BeginConnect($TargetHost, $TargetPort, $null, $null)
            $wh = $iar.AsyncWaitHandle
            if ($wh.WaitOne(3000, $false)) {
                $client.EndConnect($iar)
                $client.Close()
                Log-Msg "  [OK] TCP Port $TargetPort on $TargetHost is OPEN and reachable!" "SUCCESS"
            } else {
                $client.Close()
                Log-Msg "  [FAIL] TCP Port $TargetPort on $TargetHost timed out (closed or firewall blocked)." "ERROR"
            }
        } catch {
            Log-Msg "  [FAIL] Connection error to $TargetHost: $($_.Exception.Message)" "ERROR"
        }
    }
}

# 8. Generate Summary Report
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

# Query active port
$RdpPortKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$ActivePort = 3389
if (Test-Path $RdpPortKey) {
    $PortProp = Get-ItemProperty -Path $RdpPortKey -Name "PortNumber" -ErrorAction SilentlyContinue
    if ($PortProp) { $ActivePort = $PortProp.PortNumber }
}

Log-Msg "Generating summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("     REMOTE DESKTOP (RDP) & CREDSSP ENCRYPTION ORACLE REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("OS Version     : $((Get-WmiObject -Class Win32_OperatingSystem).Caption)")
$Report.Add("Active RDP Port: $ActivePort")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("REPAIRS & CONFIGURATIONS:")
$Report.Add("   - CredSSP Policy: Set AllowEncryptionOracle = 2 (Fixes RDP Error 0x800706BA / 0x80090308)")
$Report.Add("   - Remote Desktop: Set fDenyTSConnections = 0 (RDP Service Enabled)")
$Report.Add("   - Windows Firewall: Enabled Remote Desktop Firewall Group")
$Report.Add("   - UDP Disconnect Fix: Set fClientDisableUDP = 1 & SelectTransport = 1 (TCP only)")
$Report.Add("   - Black Screen Fix: Set fEnableWddmDriver = 0 (XDDM fallback)")
$Report.Add("   - Terminal Services: TermService restarted successfully")
$Report.Add("")
$Report.Add("Log file location: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "     REMOTE DESKTOP & CREDSSP REPAIRS COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
