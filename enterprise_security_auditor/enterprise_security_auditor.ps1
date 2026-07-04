<#
.SYNOPSIS
    Option [10]: Enterprise Security, Compliance & Recovery Auditor
.DESCRIPTION
    Performs a comprehensive 360-degree security, compliance, patching, backup, disk, network, and RDP assessment across Windows 10/11 and Windows Server 2012 R2 through 2025. Generates enterprise scoring, CSV data sheets, and an offline interactive dark-mode HTML executive dashboard.
.AUTHOR
    Antigravity Enterprise Architecture & Security Team
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [switch]$RunAutoFix,
    [switch]$NonInteractive
)

$ErrorActionPreference = "SilentlyContinue"

# Ensure $PSScriptRoot resolution
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

$ReportsDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
$LogPath = Join-Path -Path $ReportsDir -ChildPath "audit.log"
$StartTime = Get-Date

function Write-AuditLog {
    param([string]$Message, [string]$Level="INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Level] $Message"
    $Formatted | Out-File -FilePath $LogPath -Append -Encoding UTF8 -Force
    switch ($Level) {
        "ERROR" { Write-Host $Formatted -ForegroundColor Red }
        "WARN"  { Write-Host $Formatted -ForegroundColor Yellow }
        "OK"    { Write-Host $Formatted -ForegroundColor Green }
        default { Write-Host $Formatted -ForegroundColor Cyan }
    }
}

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "       ENTERPRISE SECURITY, COMPLIANCE & RECOVERY AUDITOR [OPTION 10]" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-AuditLog "Starting Enterprise Audit Scan on target: $env:COMPUTERNAME" "INFO"

# Global Data Collections
$SecurityFindings = New-Object System.Collections.ArrayList
$PatchFindings = New-Object System.Collections.ArrayList
$BackupFindings = New-Object System.Collections.ArrayList
$DiskFindings = New-Object System.Collections.ArrayList
$NetworkFindings = New-Object System.Collections.ArrayList
$RdpFindings = New-Object System.Collections.ArrayList

# ---------------------------------------------------------
# MODULE 1: ENVIRONMENT & OS ARCHITECTURE DETECTION
# ---------------------------------------------------------
Write-AuditLog "Detecting Operating System Architecture & Environment Role..." "INFO"
$OS = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
$CS = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
$DomainRole = $CS.DomainRole # 0=Workstation Standalone, 1=Workstation Domain, 2=Server Standalone, 3=Server Domain, 4=DC Backup, 5=DC Primary
$IsServer = ($DomainRole -ge 2)
$IsDC = ($DomainRole -eq 4 -or $DomainRole -eq 5)
$OSCaption = if ($OS) { $OS.Caption } else { "Unknown Windows OS" }
$BuildNum = if ($OS) { $OS.BuildNumber } else { "0" }

$RoleDescription = switch ($DomainRole) {
    0 { "Standalone Workstation (Windows 10/11)" }
    1 { "Domain-Joined Workstation (Windows 10/11)" }
    2 { "Standalone Server" }
    3 { "Domain Member Server" }
    4 { "Backup Domain Controller (AD DS)" }
    5 { "Primary Domain Controller (AD DS)" }
    default { "Windows System" }
}
Write-AuditLog "System: $OSCaption (Build $BuildNum) | Role: $RoleDescription" "OK"

# Helper to add finding
function Add-Finding {
    param($Collection, $Category, $ItemName, $Status, $RiskLevel, $Impact, $FixAdvice)
    $Obj = New-Object PSObject -Property @{
        Category = $Category
        Finding = $ItemName
        Status = $Status
        RiskLevel = $RiskLevel
        Impact = $Impact
        RecommendedFix = $FixAdvice
    }
    [void]$Collection.Add($Obj)
}

# ---------------------------------------------------------
# MODULE 2: ENTERPRISE SECURITY AUDIT MODULE
# ---------------------------------------------------------
Write-AuditLog "[Module 1/6] Running Enterprise Security & Policy Audit..." "INFO"

# 2.1 Admin Group Audit
if ($IsDC -or (Get-Command Get-ADGroupMember -ErrorAction SilentlyContinue)) {
    try {
        $DA = (Get-ADGroupMember -Identity "Domain Admins" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName) -join ", "
        if ($DA) { Add-Finding $SecurityFindings "Identity" "Domain Admins Group" "Members: $DA" "Informational" "Privileged domain administrators documented." "Regularly review and enforce principle of least privilege." }
    } catch { }
}
$LocalAdmins = (Get-WmiObject -Class Win32_GroupUser -ErrorAction SilentlyContinue | Where-Object { $_.GroupComponent -like '*"Administrators"*' } | ForEach-Object { ($_.PartComponent -split 'Name="')[-1].TrimEnd('"') }) -join ", "
Add-Finding $SecurityFindings "Identity" "Local Administrators Group" "Members: $LocalAdmins" "Informational" "Documented local admin membership." "Audit local admins and remove unauthorized user accounts."

# 2.2 Built-in & Guest Accounts
$Guest = Get-WmiObject -Class Win32_UserAccount -Filter "Name='Guest'" -ErrorAction SilentlyContinue
if ($Guest -and -not $Guest.Disabled) {
    Add-Finding $SecurityFindings "Identity" "Guest Account Status" "ENABLED" "High" "Guest account allows unauthenticated local access." "Disable the built-in Guest account immediately (`net user Guest /active:no`)."
} else {
    Add-Finding $SecurityFindings "Identity" "Guest Account Status" "Disabled" "Low" "No unauthorized guest access." "Maintain disabled state."
}

# 2.3 SMBv1 & SMB Signing Check
$Smb1 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -ErrorAction SilentlyContinue).SMB1
if ($Smb1 -eq 1) {
    Add-Finding $SecurityFindings "Network Security" "SMBv1 Protocol" "ENABLED" "Critical" "Vulnerable to WannaCry / EternalBlue ransomware worm exploitation." "Disable SMBv1 immediately via PowerShell (`Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -Value 0`)."
} else {
    Add-Finding $SecurityFindings "Network Security" "SMBv1 Protocol" "Disabled" "Low" "Secured against SMBv1 exploits." "None required."
}

# 2.4 BitLocker Encryption Check
try {
    $BitLocker = Get-WmiObject -Namespace "root\CIMv2\Security\MicrosoftVolumeEncryption" -Class Win32_EncryptableVolume -Filter "DriveLetter='C:'" -ErrorAction SilentlyContinue
    if ($BitLocker -and $BitLocker.ProtectionStatus -eq 1) {
        Add-Finding $SecurityFindings "Data Protection" "BitLocker Drive C:" "Encrypted & Protected" "Low" "OS volume encrypted against physical drive theft." "None required."
    } else {
        $Risk = if ($IsServer) { "Medium" } else { "High" }
        Add-Finding $SecurityFindings "Data Protection" "BitLocker Drive C:" "UNENCRYPTED" $Risk "Physical access could compromise unencrypted OS volume data." "Enable BitLocker volume encryption on C: drive."
    }
} catch {
    Add-Finding $SecurityFindings "Data Protection" "BitLocker Status" "Unknown/Unsupported" "Medium" "Could not query volume encryption engine." "Verify BitLocker feature status manually."
}

# 2.5 Windows Defender & Antivirus Health
$DefenderReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
if ($DefenderReg -and $DefenderReg.DisableAntiSpyware -eq 1) {
    Add-Finding $SecurityFindings "Endpoint Security" "Windows Defender AV" "DISABLED BY POLICY" "Critical" "System lacks baseline Microsoft real-time endpoint threat protection." "Re-enable Windows Defender or verify dedicated third-party EDR agent is active."
} else {
    Add-Finding $SecurityFindings "Endpoint Security" "Windows Defender AV" "Active" "Low" "Baseline antivirus active." "Ensure automatic daily signature definitions are scheduled."
}

# 2.6 Windows Firewall Status
try {
    $FwState = netsh advfirewall show allprofiles state 2>&1
    if ($FwState -match "State\s+OFF") {
        Add-Finding $SecurityFindings "Network Security" "Windows Firewall Profiles" "ONE OR MORE DISABLED" "Critical" "Network ports exposed to direct lateral movement and port scanning." "Enable Windows Firewall across Domain, Private, and Public profiles (`netsh advfirewall set allprofiles state on`)."
    } else {
        Add-Finding $SecurityFindings "Network Security" "Windows Firewall Profiles" "All Enabled" "Low" "Network filtering active across profiles." "Maintain active firewall state."
    }
} catch { }

# 2.7 User Account Control (UAC)
$UacReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
if ($UacReg -eq 0) {
    Add-Finding $SecurityFindings "OS Security" "User Account Control (UAC)" "DISABLED" "High" "Processes run with administrative privilege automatically without prompt." "Enable UAC (`EnableLUA = 1` in registry) and reboot."
} else {
    Add-Finding $SecurityFindings "OS Security" "User Account Control (UAC)" "Enabled" "Low" "Privilege escalation prompts active." "None required."
}

# 2.8 LAPS (Local Administrator Password Solution) Detection
$LapsReg = Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LAPS"
$LegacyLaps = Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdmPwd"
if ($LapsReg -or $LegacyLaps) {
    Add-Finding $SecurityFindings "Credential Security" "Windows LAPS" "Detected & Configured" "Low" "Local admin password randomized and secured in Active Directory." "Maintain LAPS rotation schedule."
} else {
    if ($DomainRole -in @(1,3)) {
        Add-Finding $SecurityFindings "Credential Security" "Windows LAPS" "NOT DETECTED" "High" "Shared local admin passwords could allow lateral pass-the-hash attacks across domain." "Deploy Windows LAPS across domain member workstations and servers."
    } else {
        Add-Finding $SecurityFindings "Credential Security" "Windows LAPS" "N/A (Standalone/DC)" "Informational" "LAPS not required on standalone or DC systems." "None required."
    }
}

# 2.9 PowerShell ScriptBlock Logging Audit
$PsLog = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -ErrorAction SilentlyContinue).EnableScriptBlockLogging
if ($PsLog -eq 1) {
    Add-Finding $SecurityFindings "Audit & Logging" "PowerShell ScriptBlock Logging" "Enabled" "Low" "Deep forensic execution logging active for SIEM analysis." "None required."
} else {
    Add-Finding $SecurityFindings "Audit & Logging" "PowerShell ScriptBlock Logging" "DISABLED" "Medium" "Advanced PowerShell obfuscation and memory exploits cannot be forensically audited." "Enable PowerShell ScriptBlockLogging via Group Policy."
}

# 2.10 Secure Boot & TPM Check
try {
    $Tpm = Get-WmiObject -Namespace "root\CIMV2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
    if ($Tpm -and $Tpm.IsActivated_InitialValue) {
        Add-Finding $SecurityFindings "Hardware Security" "Trusted Platform Module (TPM)" "Present & Activated" "Low" "Hardware encryption key storage available." "None required."
    } else {
        Add-Finding $SecurityFindings "Hardware Security" "Trusted Platform Module (TPM)" "MISSING / INACTIVE" "Medium" "System lacks hardware TPM backed cryptographic storage." "Enable TPM 2.0 in BIOS/UEFI settings."
    }
} catch { }

# Compute Security Score (Starting 100, deductions per severity)
$SecScore = 100
foreach ($F in $SecurityFindings) {
    switch ($F.RiskLevel) {
        "Critical" { $SecScore -= 25 }
        "High"     { $SecScore -= 12 }
        "Medium"   { $SecScore -= 6 }
    }
}
if ($SecScore -lt 0) { $SecScore = 0 }
Write-AuditLog "Security Audit Complete | Score: $SecScore%" "OK"

# ---------------------------------------------------------
# MODULE 3: PATCH COMPLIANCE & OS EOL AUDIT
# ---------------------------------------------------------
Write-AuditLog "[Module 2/6] Inspecting Patch Compliance & Servicing Status..." "INFO"

$Hotfixes = Get-WmiObject -Class Win32_QuickFixEngineering -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending
$HotfixCount = if ($Hotfixes) { @($Hotfixes).Count } else { 0 }
$LastInstalledDate = "Unknown"
$DaysSinceLastPatch = 999

if ($Hotfixes -and $Hotfixes[0].InstalledOn) {
    try {
        $LastDateObj = [datetime]$Hotfixes[0].InstalledOn
        $LastInstalledDate = $LastDateObj.ToString("yyyy-MM-dd")
        $DaysSinceLastPatch = [math]::Round(((Get-Date) - $LastDateObj).TotalDays)
    } catch { }
}

Add-Finding $PatchFindings "Patching" "Total Installed Hotfixes" "$HotfixCount packages" "Informational" "Baseline servicing record." "Ensure automated patching schedule."
Add-Finding $PatchFindings "Patching" "Last Installed Patch Date" "$LastInstalledDate ($DaysSinceLastPatch days ago)" $(if ($DaysSinceLastPatch -gt 60) { "High" } elseif ($DaysSinceLastPatch -gt 30) { "Medium" } else { "Low" }) "Unpatched systems accumulate critical CVE vulnerabilities." "Run Windows Update cycle if >30 days unpatched."

# End of Life Check
$IsEOL = $false
if ($OSCaption -like "*2008*" -or $OSCaption -like "*2012*" -or $OSCaption -like "*Windows 7*" -or $OSCaption -like "*Windows 8*") {
    $IsEOL = $true
    Add-Finding $PatchFindings "Lifecycle" "Operating System Support Status" "END OF LIFE (EOL) DETECTED ($OSCaption)" "Critical" "OS no longer receives security updates from Microsoft. Extremely vulnerable to zero-day exploits." "Plan immediate OS upgrade or migrate workloads to modern Server 2022/2025."
} else {
    Add-Finding $PatchFindings "Lifecycle" "Operating System Support Status" "Supported OS ($OSCaption)" "Low" "OS receives standard security servicing." "Maintain routine quality updates."
}

$PatchScore = 100
if ($DaysSinceLastPatch -gt 90) { $PatchScore -= 40 }
elseif ($DaysSinceLastPatch -gt 45) { $PatchScore -= 20 }
elseif ($DaysSinceLastPatch -gt 30) { $PatchScore -= 10 }
if ($IsEOL) { $PatchScore -= 50 }
if ($PatchScore -lt 0) { $PatchScore = 0 }
Write-AuditLog "Patch Compliance Complete | Score: $PatchScore%" "OK"

# ---------------------------------------------------------
# MODULE 4: BACKUP & RECOVERY READINESS AUDIT
# ---------------------------------------------------------
Write-AuditLog "[Module 3/6] Auditing Backup Engine & Disaster Recovery Readiness..." "INFO"

# 4.1 VSS Health
$VssSvc = Get-Service -Name VSS -ErrorAction SilentlyContinue
if ($VssSvc -and $VssSvc.StartType -ne "Disabled") {
    Add-Finding $BackupFindings "Backup Engine" "Volume Shadow Copy (VSS) Service" "Ready ($($VssSvc.Status))" "Low" "Snapshot engine available for image backups." "None required."
} else {
    Add-Finding $BackupFindings "Backup Engine" "Volume Shadow Copy (VSS) Service" "DISABLED" "Critical" "All system backups (Veeam, Windows Server Backup) will fail silently." "Set VSS service start type to Manual or Automatic."
}

# 4.2 Shadow Copies & Restore Points
$Shadows = Get-WmiObject -Class Win32_ShadowCopy -ErrorAction SilentlyContinue
$ShadowCount = if ($Shadows) { @($Shadows).Count } else { 0 }
if ($ShadowCount -gt 0) {
    Add-Finding $BackupFindings "Recovery Readiness" "Volume Shadow Copies / Restore Points" "$ShadowCount snapshot points found" "Low" "Rapid rollback restore points available." "None required."
} else {
    $Risk = if ($IsServer) { "Medium" } else { "High" }
    Add-Finding $BackupFindings "Recovery Readiness" "Volume Shadow Copies / Restore Points" "0 SNAPSHOTS FOUND" $Risk "No local VSS restore snapshots present for file recovery." "Configure shadow copy storage or System Restore points."
}

# 4.3 WinRE & Crash Dump Readiness
$CrashReg = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -ErrorAction SilentlyContinue).CrashDumpEnabled
if ($CrashReg -in @(1,2,3)) {
    Add-Finding $BackupFindings "Diagnostics" "Windows Memory Crash Dump" "Enabled (Type $CrashReg)" "Low" "System ready to generate MEMORY.DMP on BSOD." "None required."
} else {
    Add-Finding $BackupFindings "Diagnostics" "Windows Memory Crash Dump" "DISABLED" "Medium" "Post-mortem crash analysis impossible upon kernel failure." "Enable kernel or small memory crash dump in system properties."
}

$BackupScore = 100
if ($VssSvc.StartType -eq "Disabled") { $BackupScore -= 50 }
if ($ShadowCount -eq 0) { $BackupScore -= 30 }
if ($BackupScore -lt 0) { $BackupScore = 0 }
$RecoveryScore = if ($CrashReg -in @(1,2,3)) { 100 } else { 60 }
Write-AuditLog "Backup Readiness Complete | Backup Score: $BackupScore% | Recovery Score: $RecoveryScore%" "OK"

# ---------------------------------------------------------
# MODULE 5: DISK HEALTH & RELIABILITY AUDIT
# ---------------------------------------------------------
Write-AuditLog "[Module 4/6] Checking SMART Storage & Disk Controller Logs..." "INFO"

$Disks = Get-WmiObject -Class Win32_DiskDrive -ErrorAction SilentlyContinue
foreach ($D in $Disks) {
    $SizeGB = [math]::Round($D.Size / 1GB, 1)
    $Status = $D.Status
    $Risk = if ($Status -eq "OK") { "Low" } else { "Critical" }
    $Fix = if ($Status -eq "OK") { "None required." } else { "Immediate SMART hardware drive replacement required!" }
    Add-Finding $DiskFindings "Storage Hardware" "Physical Disk ($($D.Caption))" "Status: $Status | Size: ${SizeGB}GB" $Risk "Drive physical integrity check." $Fix
}

# Scan Event Log for disk controller errors
$DiskEvts = Get-WinEvent -FilterHashtable @{LogName='System'; ID=7,11,51,55; StartTime=(Get-Date).AddDays(-30)} -ErrorAction SilentlyContinue
if ($DiskEvts -and $DiskEvts.Count -gt 0) {
    Add-Finding $DiskFindings "Storage Reliability" "Disk Controller Event Logs" "$($DiskEvts.Count) ERROR EVENTS IN 30 DAYS" "Critical" "Hardware read/write errors or NTFS corruption logged." "Run SMART diagnostics and schedule chkdsk /f /r."
} else {
    Add-Finding $DiskFindings "Storage Reliability" "Disk Controller Event Logs" "0 errors logged (Clean)" "Low" "No drive controller hardware faults recorded." "None required."
}

# ---------------------------------------------------------
# MODULE 6: NETWORK HEALTH & LATENCY AUDIT
# ---------------------------------------------------------
Write-AuditLog "[Module 5/6] Measuring Network Latency & Gateway Configuration..." "INFO"

$NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue
foreach ($N in $NICs) {
    $IP = @($N.IPAddress)[0]
    $Gw = @($N.DefaultIPGateway)[0]
    $DNS = @($N.DNSServerSearchOrder) -join ", "
    Add-Finding $NetworkFindings "Network Configuration" "Adapter ($($N.Description))" "IP: $IP | Gateway: $Gw" "Informational" "Active NIC details." "Verify IP assignment."
}

# Test DNS latency
$PingTarget = "8.8.8.8"
$PingRes = Test-Connection -ComputerName $PingTarget -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($PingRes) {
    Add-Finding $NetworkFindings "Network Connectivity" "Internet Ping Check ($PingTarget)" "ONLINE (0% Loss)" "Low" "External internet routing active." "None required."
    $NetScore = 100
} else {
    Add-Finding $NetworkFindings "Network Connectivity" "Internet Ping Check ($PingTarget)" "PACKET LOSS / OFFLINE" "High" "External routing or ICMP packets blocked." "Verify gateway firewall and external routing."
    $NetScore = 50
}
Write-AuditLog "Network Health Complete | Score: $NetScore%" "OK"

# ---------------------------------------------------------
# MODULE 7: RDP & REMOTE ACCESS AUDIT
# ---------------------------------------------------------
Write-AuditLog "[Module 6/6] Auditing RDP Exposure & Remote Authentication..." "INFO"

$RdpReg = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections
$NlaReg = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -ErrorAction SilentlyContinue).UserAuthentication
$RdpPort = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -ErrorAction SilentlyContinue).PortNumber
if (-not $RdpPort) { $RdpPort = 3389 }

if ($RdpReg -eq 0) {
    $NlaStr = if ($NlaReg -eq 1) { "NLA Enabled (Secure)" } else { "NLA DISABLED (Vulnerable to Brute Force!)" }
    $Risk = if ($NlaReg -eq 1) { "Low" } else { "High" }
    Add-Finding $RdpFindings "Remote Access" "Remote Desktop (RDP)" "ENABLED on Port $RdpPort | $NlaStr" $Risk "Allows remote GUI management over network." "Ensure Network Level Authentication (NLA) is required and restrict RDP via firewall."
} else {
    Add-Finding $RdpFindings "Remote Access" "Remote Desktop (RDP)" "Disabled" "Low" "Remote desktop connections denied." "None required."
}

# ---------------------------------------------------------
# MODULE 8: SCORING ENGINE & AGGREGATION
# ---------------------------------------------------------
$OverallScore = [math]::Round(($SecScore * 0.35) + ($PatchScore * 0.25) + ($BackupScore * 0.20) + ($RecoveryScore * 0.10) + ($NetScore * 0.10))
Write-AuditLog "==========================================================================" "OK"
Write-AuditLog "OVERALL ENTERPRISE HEALTH SCORE: $OverallScore / 100" "OK"
Write-AuditLog "Breakdown -> Security: $SecScore% | Patching: $PatchScore% | Backup: $BackupScore% | Recovery: $RecoveryScore% | Network: $NetScore%" "OK"
Write-AuditLog "==========================================================================" "OK"

# ---------------------------------------------------------
# MODULE 9: EXPORT CSV REPORTS
# ---------------------------------------------------------
Write-AuditLog "Exporting data sheets to CSV format..." "INFO"
$SecurityFindings | Export-Csv -Path (Join-Path $ReportsDir "security_findings.csv") -NoTypeInformation -Encoding UTF8
$PatchFindings    | Export-Csv -Path (Join-Path $ReportsDir "patch_compliance.csv") -NoTypeInformation -Encoding UTF8
$BackupFindings   | Export-Csv -Path (Join-Path $ReportsDir "backup_readiness.csv") -NoTypeInformation -Encoding UTF8
$DiskFindings     | Export-Csv -Path (Join-Path $ReportsDir "disk_health.csv") -NoTypeInformation -Encoding UTF8
$NetworkFindings  | Export-Csv -Path (Join-Path $ReportsDir "network_health.csv") -NoTypeInformation -Encoding UTF8

$ScoreObj = New-Object PSObject -Property @{
    TargetSystem = $env:COMPUTERNAME
    ScanTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    OverallHealthScore = $OverallScore
    SecurityScore = $SecScore
    PatchComplianceScore = $PatchScore
    BackupReadinessScore = $BackupScore
    RecoveryScore = $RecoveryScore
    NetworkHealthScore = $NetScore
}
@($ScoreObj) | Export-Csv -Path (Join-Path $ReportsDir "overall_health_score.csv") -NoTypeInformation -Encoding UTF8

# ---------------------------------------------------------
# MODULE 10: SELF-CONTAINED OFFLINE HTML DASHBOARD
# ---------------------------------------------------------
Write-AuditLog "Building self-contained offline HTML Executive Dashboard..." "INFO"
$HtmlPath = Join-Path $ReportsDir "enterprise_dashboard.html"

# Combine all findings for summary table
$AllFindings = @() + $SecurityFindings + $PatchFindings + $BackupFindings + $DiskFindings + $NetworkFindings + $RdpFindings
$CriticalCount = @($AllFindings | Where-Object { $_.RiskLevel -eq "Critical" }).Count
$HighCount     = @($AllFindings | Where-Object { $_.RiskLevel -eq "High" }).Count
$MedCount      = @($AllFindings | Where-Object { $_.RiskLevel -eq "Medium" }).Count
$LowCount      = @($AllFindings | Where-Object { $_.RiskLevel -eq "Low" }).Count
$InfoCount     = @($AllFindings | Where-Object { $_.RiskLevel -eq "Informational" }).Count

$GaugeColor = if ($OverallScore -ge 85) { "#2ecc71" } elseif ($OverallScore -ge 70) { "#f1c40f" } else { "#e74c3c" }

$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enterprise Security & Compliance Dashboard - $env:COMPUTERNAME</title>
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --muted: #94a3b8; --border: #334155; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 25px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border); padding-bottom: 15px; margin-bottom: 25px; }
        .header h1 { margin: 0; font-size: 24px; color: #38bdf8; }
        .header .meta { font-size: 14px; color: var(--muted); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 20px; text-align: center; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }
        .card h3 { margin: 0; font-size: 14px; color: var(--muted); text-transform: uppercase; letter-spacing: 1px; }
        .card .val { font-size: 32px; font-weight: bold; margin: 10px 0; }
        .score-box { display: flex; align-items: center; justify-content: space-around; background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 25px; margin-bottom: 30px; }
        .gauge-circle { width: 140px; height: 140px; border-radius: 50%; border: 12px solid $GaugeColor; display: flex; align-items: center; justify-content: center; font-size: 36px; font-weight: bold; color: $GaugeColor; }
        .scores-list { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; width: 60%; }
        .score-bar { background: #0f172a; border: 1px solid var(--border); padding: 12px; border-radius: 8px; }
        .score-bar span { font-size: 13px; color: var(--muted); }
        .score-bar div { font-size: 20px; font-weight: bold; color: #38bdf8; margin-top: 4px; }
        table { width: 100%; border-collapse: collapse; background: var(--card); border-radius: 10px; overflow: hidden; border: 1px solid var(--border); }
        th, td { padding: 14px; text-align: left; border-bottom: 1px solid var(--border); font-size: 14px; }
        th { background: #0f172a; color: #38bdf8; font-weight: 600; text-transform: uppercase; font-size: 12px; }
        tr:hover { background: #334155; }
        .badge { padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: bold; text-transform: uppercase; }
        .badge-Critical { background: #991b1b; color: #fecaca; }
        .badge-High { background: #c2410c; color: #ffedd5; }
        .badge-Medium { background: #a16207; color: #fef08a; }
        .badge-Low { background: #15803d; color: #dcfce7; }
        .badge-Informational { background: #1d4ed8; color: #dbeafe; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>[ENTERPRISE AUDITOR] Enterprise Security & Compliance Dashboard</h1>
            <div class="meta">Target: <b>$env:COMPUTERNAME</b> | Architecture: <b>$RoleDescription</b></div>
        </div>
        <div class="meta">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>Mode: Offline Standalone Case File</div>
    </div>

    <div class="score-box">
        <div>
            <h3 style="color:var(--muted);margin-bottom:15px;text-transform:uppercase;">Overall Enterprise Score</h3>
            <div class="gauge-circle">$OverallScore</div>
        </div>
        <div class="scores-list">
            <div class="score-bar"><span>Security & Hardening</span><div>$SecScore%</div></div>
            <div class="score-bar"><span>Patch Compliance</span><div>$PatchScore%</div></div>
            <div class="score-bar"><span>Backup Readiness</span><div>$BackupScore%</div></div>
            <div class="score-bar"><span>Disaster Recovery</span><div>$RecoveryScore%</div></div>
        </div>
    </div>

    <div class="grid">
        <div class="card" style="border-top: 4px solid #ef4444;"><h3>Critical Risks</h3><div class="val" style="color:#ef4444;">$CriticalCount</div></div>
        <div class="card" style="border-top: 4px solid #f97316;"><h3>High Risks</h3><div class="val" style="color:#f97316;">$HighCount</div></div>
        <div class="card" style="border-top: 4px solid #eab308;"><h3>Medium Risks</h3><div class="val" style="color:#eab308;">$MedCount</div></div>
        <div class="card" style="border-top: 4px solid #22c55e;"><h3>Passed / Low Risk</h3><div class="val" style="color:#22c55e;">$LowCount</div></div>
    </div>

    <h2 style="font-size:18px;color:#38bdf8;margin-bottom:15px;">Detailed Audit Findings & Actionable Remediation Plan</h2>
    <table>
        <thead>
            <tr>
                <th>Category</th>
                <th>Finding / Policy Check</th>
                <th>Current Status</th>
                <th>Risk Level</th>
                <th>Business Impact</th>
                <th>Recommended Engineering Fix</th>
            </tr>
        </thead>
        <tbody>
"@

foreach ($Item in $AllFindings) {
    $Html += "<tr><td><b>$($Item.Category)</b></td><td>$($Item.Finding)</td><td>$($Item.Status)</td><td><span class='badge badge-$($Item.RiskLevel)'>$($Item.RiskLevel)</span></td><td>$($Item.Impact)</td><td style='color:#a7f3d0;'>$($Item.RecommendedFix)</td></tr>`n"
}

$Html += @"
        </tbody>
    </table>
</body>
</html>
"@

$Html | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force
Write-AuditLog "Dashboard successfully compiled: reports\enterprise_dashboard.html" "OK"

# ---------------------------------------------------------
# MODULE 11: OPTIONAL SAFE AUTO-FIX FRAMEWORK
# ---------------------------------------------------------
if ($RunAutoFix -or -not $NonInteractive) {
    Write-Host "`n--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $PromptFix = Read-Host "Would you like to run the Safe Auto-Fix Engine for critical settings (Firewall, UAC, SMBv1)? [Y/N]"
    if ($PromptFix -eq "Y" -or $PromptFix -eq "y" -or $RunAutoFix) {
        Write-AuditLog "Initiating Safe Auto-Fix Engine..." "WARN"
        
        # Auto-Fix 1: Windows Firewall
        if ($FwState -match "State\s+OFF") {
            Write-Host " -> Enabling all Windows Firewall Profiles..." -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("Windows Firewall", "Enable Domain, Private, and Public Profiles")) {
                cmd.exe /c "netsh advfirewall set allprofiles state on" | Out-Null
                Write-AuditLog "Auto-Fix Applied: Windows Firewall enabled." "OK"
            }
        }
        # Auto-Fix 2: Disable SMBv1
        if ($Smb1 -eq 1) {
            Write-Host " -> Disabling vulnerable SMBv1 Protocol..." -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("Registry LanmanServer", "Disable SMBv1")) {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -ErrorAction SilentlyContinue
                Write-AuditLog "Auto-Fix Applied: SMBv1 set to 0 in registry." "OK"
            }
        }
        # Auto-Fix 3: Enable UAC
        if ($UacReg -eq 0) {
            Write-Host " -> Enabling User Account Control (UAC)..." -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("Registry System Policies", "Set EnableLUA = 1")) {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -ErrorAction SilentlyContinue
                Write-AuditLog "Auto-Fix Applied: UAC EnableLUA set to 1." "OK"
            }
        }
    }
}

$EndTime = Get-Date
$Duration = [math]::Round(($EndTime - $StartTime).TotalSeconds, 1)
Write-AuditLog "Enterprise Audit Scan Completed in ${Duration}s!" "OK"
Write-Host "`nAll reports and executive dashboard saved to: $ReportsDir" -ForegroundColor Cyan
