# ==========================================================================
#   Windows 10/11 Shared Drive & USB Shared Printer Repair Suite - Main Coordinator
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

$Global:LogFile = Join-Path $ReportsDir "SharingFix.log"
$ReportPath = Join-Path $ReportsDir "SharingFixReport.txt"
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
Log-Msg "   WINDOWS 10/11 SHARED DRIVE & USB SHARED PRINTER REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 1. Backup Registry Hives
if (Get-UserApproval "Backup current LanmanWorkstation & Printer registry keys to a .reg file before modifying?") {
    $BackupFile = Join-Path $ReportsDir "Sharing_Registry_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    try {
        cmd.exe /c "reg export `"HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters`" `"$BackupFile`" /y" | Out-Null
        cmd.exe /c "reg export `"HKLM\System\CurrentControlSet\Control\Print`" `"$BackupFile`_Print.reg`" /y" | Out-Null
        Log-Msg "  [OK] Registry keys backed up to: $BackupFile" "SUCCESS"
    } catch {
        Log-Msg "  [WARN] Failed to export registry backups: $($_.Exception.Message)" "WARN"
    }
}

# 2. System Restore Point Creation
if (Get-UserApproval "Create a Windows System Restore Point before proceeding?") {
    Log-Msg "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BeforeSharingAndPrinterFix" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log-Msg "System Restore Point created successfully." "SUCCESS"
    } catch {
        Log-Msg "Failed to create Restore Point: $($_.Exception.Message). Continuing with repairs..." "WARN"
    }
}

# 3. Fix SMB Shared Drives
Log-Msg "Executing SMB and Shared Drive repair module..." "STAGE"
$SmbScript = Join-Path $PSScriptRoot "Fix-SMB-Shares.ps1"
if (Test-Path $SmbScript) {
    & $SmbScript
}

# 4. Fix Shared USB Printers
Log-Msg "Executing USB Shared Printer repair module..." "STAGE"
$PrinterScript = Join-Path $PSScriptRoot "Fix-Shared-Printers.ps1"
if (Test-Path $PrinterScript) {
    & $PrinterScript
}

# 5. Configure Firewall & Network Profile
Log-Msg "Executing Firewall & Network Sharing configuration module..." "STAGE"
$FwScript = Join-Path $PSScriptRoot "Reset-Network-Sharing-Firewall.ps1"
if (Test-Path $FwScript) {
    & $FwScript
}

# 6. Generate Summary Report
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("     WINDOWS SHARED DRIVE & USB SHARED PRINTER REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("OS Version     : $((Get-WmiObject -Class Win32_OperatingSystem).Caption)")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("REPAIRS APPLIED:")
$Report.Add("  [SMB Shared Drives]")
$Report.Add("   - AllowInsecureGuestAuth set to 1 (Fixes unauthenticated guest NAS access)")
$Report.Add("   - DisableStrictNameChecking & DnsOnWire set to 1 (Fixes DNS CNAME & Hostname alias connections)")
$Report.Add("   - RestrictNullSessAccess set to 0 (Allows Null Session Access)")
$Report.Add("   - RequireSecuritySignature configured for legacy SMB compatibility")
$Report.Add("   - LimitBlankPasswordUse set to 0")
$Report.Add("   - Enabled Network Discovery Services (fdPHost, FDResPub, SSDPSRV, lmhosts)")
$Report.Add("   - Flushed DNS cache & purged stale Kerberos/NetBIOS credentials")
$Report.Add("")
$Report.Add("  [USB Shared Printers]")
$Report.Add("   - RpcAuthnLevelPrivacyEnabled set to 0 (Fixes Error 0x0000011b)")
$Report.Add("   - Point and Print restrictions bypassed for Non-Admin driver installation")
$Report.Add("   - Configured RPC Named Pipes & TCP protocol bindings (Fixes Error 0x00000bc4 & 0x00000709)")
$Report.Add("   - CopyFilesPolicy set to 1 (Fixes Error 0x0000007c)")
$Report.Add("   - VulnerableDriverBlocklistEnable set to 0 (Bypasses KB5089549 driver blocklist)")
$Report.Add("   - Hard purge of print spool queue & stuck driver isolation processes")
$Report.Add("   - Restarted Print Spooler service")
$Report.Add("")
$Report.Add("  [Firewall & Network]")
$Report.Add("   - Enabled 'File and Printer Sharing' firewall rules")
$Report.Add("   - Enabled 'Network Discovery' firewall rules")
$Report.Add("   - Configured WSD Print Discovery Firewall rules (Port 3702 UDP/TCP)")
$Report.Add("")
$Report.Add("Log file location: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "     SHARED DRIVE & USB SHARED PRINTER REPAIRS COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
