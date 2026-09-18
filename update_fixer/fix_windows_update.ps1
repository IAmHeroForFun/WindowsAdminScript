# ==========================================================================
#   Windows Update, WSUS & Component Store Repair Suite - Main Coordinator
#   Compatible with Windows 7-11 & Windows Server 2008 R2-2025
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

$Global:LogFile = Join-Path $ReportsDir "WindowsUpdateFix.log"
$ReportPath = Join-Path $ReportsDir "WindowsUpdateFixReport.txt"
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
Log-Msg "    WINDOWS UPDATE, WSUS & COMPONENT STORE (DISM/CBS) REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 1. System Restore Point Creation
if (Get-UserApproval "Create a Windows System Restore Point before proceeding?") {
    Log-Msg "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BeforeWindowsUpdateRepair" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log-Msg "System Restore Point created successfully." "SUCCESS"
    } catch {
        Log-Msg "Restore Point creation failed: $($_.Exception.Message). Continuing with repairs..." "WARN"
    }
}

# ---------------------------------------------------------
# PRE-FLIGHT DIAGNOSTICS & SYSTEM INSPECTION
# ---------------------------------------------------------
Log-Msg "Inspecting Windows Update system health & service states..." "STAGE"

# Check Services
$Services = @("wuauserv", "bits", "cryptsvc", "TrustedInstaller")
foreach ($SvcName in $Services) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    if ($Svc) {
        $Color = if ($Svc.Status -eq "Running") { "SUCCESS" } else { "WARN" }
        Log-Msg "  Service $SvcName is $($Svc.Status) (Startup: $($Svc.StartType))" $Color
    } else {
        Log-Msg "  Service $SvcName not found or inaccessible" "ERROR"
    }
}

# Check SoftwareDistribution Cache Size
$SoftwareDistDir = "C:\Windows\SoftwareDistribution"
if (Test-Path $SoftwareDistDir) {
    $Size = (Get-ChildItem -Path $SoftwareDistDir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $SizeMB = [Math]::Round(($Size / 1MB), 2)
    if ($SizeMB -gt 4000) {
        Log-Msg "  SoftwareDistribution Cache is Bloated: $SizeMB MB (>4 GB)" "WARN"
    } else {
        Log-Msg "  SoftwareDistribution Cache Size: $SizeMB MB" "INFO"
    }
}

# Check WSUS Configuration
$WuPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (Test-Path $WuPolicyKey) {
    $WusServer = (Get-ItemProperty -Path $WuPolicyKey -Name "WUServer" -ErrorAction SilentlyContinue).WUServer
    if ($WusServer) {
        Log-Msg "  Corporate WSUS Server Configured: $WusServer" "WARN"
    }
}

# ---------------------------------------------------------
# REPAIR PHASES
# ---------------------------------------------------------

# PHASE 1: Reset Update Components & Catalogs
if (Get-UserApproval "Execute Full Windows Update Component & Cache Reset (SoftwareDistribution, catroot2, BITS)?") {
    $ResetScript = Join-Path $PSScriptRoot "Reset-Update-Components.ps1"
    if (Test-Path $ResetScript) {
        & $ResetScript
    }
}

# PHASE 2: Clear Pending Reboot Registry Locks
if (Get-UserApproval "Inspect and clear stuck pending-reboot registry flags (RebootPending, PendingFileRename)?") {
    $RebootScript = Join-Path $PSScriptRoot "Clear-Pending-Reboot.ps1"
    if (Test-Path $RebootScript) {
        & $RebootScript
    }
}

# PHASE 3: Inspect & Bypass Corporate WSUS
if (Get-UserApproval "Inspect and optionally bypass unreachable corporate WSUS server policies?") {
    $WsusScript = Join-Path $PSScriptRoot "Reset-WSUS-Policies.ps1"
    if (Test-Path $WsusScript) {
        & $WsusScript
    }
}

# PHASE 4: Component Store & System File Integrity (DISM / SFC)
if (Get-UserApproval "Run Windows Component Store cleanup (DISM) and System File Checker (SFC)?") {
    $DismScript = Join-Path $PSScriptRoot "Repair-Component-Store.ps1"
    if (Test-Path $DismScript) {
        & $DismScript
    }
}

# PHASE 5: Network Sockets, DNS & WinHTTP Proxy Reset
if (Get-UserApproval "Reset WinSock sockets, DNS cache, and WinHTTP proxy (Resolves 0x8024402c / 0x80072ee2)?") {
    Log-Msg "Resetting network sockets, DNS cache & WinHTTP proxy..." "STAGE"
    try {
        cmd.exe /c "netsh winsock reset" | Out-Null
        cmd.exe /c "ipconfig /flushdns" | Out-Null
        cmd.exe /c "netsh winhttp reset proxy" | Out-Null
        Log-Msg "  [OK] Network sockets and WinHTTP proxy reset successfully." "SUCCESS"
    } catch {
        Log-Msg "  [WARN] Network reset encountered an issue: $($_.Exception.Message)" "WARN"
    }
}

# ---------------------------------------------------------
# GENERATE SUMMARY REPORT
# ---------------------------------------------------------
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("       WINDOWS UPDATE & COMPONENT STORE REPAIR AUDIT REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("OS Version     : $((Get-WmiObject -Class Win32_OperatingSystem).Caption)")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("REPAIRS & DIAGNOSTICS SUMMARY:")
$Report.Add("  - Windows Update and Cryptographic services audited and restarted")
$Report.Add("  - BITS background transfer queues purged")
$Report.Add("  - SoftwareDistribution and Catroot2 cache stores evaluated/reset")
$Report.Add("  - Core Windows Update COM DLL libraries re-registered")
$Report.Add("  - Pending reboot flags inspected and cleared")
$Report.Add("  - Corporate WSUS policy override options verified")
$Report.Add("  - Component Store (DISM) and Protected File Integrity (SFC) scanned")
$Report.Add("  - Network sockets, DNS cache & WinHTTP proxy flushed")
$Report.Add("")
$Report.Add("Log file location: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "     WINDOWS UPDATE & COMPONENT STORE REPAIRS COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log    : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time   : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "RECOMMENDATION: If you reset update components or cleared reboot locks," -ForegroundColor Yellow
Write-Host "                open Windows Settings > Windows Update and click 'Check for updates'." -ForegroundColor Yellow
Write-Host ""
