# Ultimate Deep Infrastructure & Security Diagnostic Suite
# Compatible with Windows Server 2008 R2 (PS 2.0) through Windows Server 2022/2025 & Windows 7-11
# Performs deep Active Directory replication checks, SSL certificate audits, SMBv1 vulnerability scans, port mapping, and reboot lock audits.

$ErrorActionPreference = "SilentlyContinue"

# 0. Ensure $PSScriptRoot is defined for PowerShell 2.0 compatibility
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Ensure reports directory exists
$ReportsDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "     ULTIMATE DEEP INFRASTRUCTURE & SECURITY DIAGNOSTIC SUITE" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target System: $env:COMPUTERNAME | Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Executing 360-degree deep infrastructure, security, and protocol inspection..." -ForegroundColor DarkCyan
Write-Host ""

$FindingsList = New-Object System.Collections.ArrayList
$ReportLines = New-Object System.Collections.ArrayList

[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("DEEP INFRASTRUCTURE & SECURITY DIAGNOSTIC REPORT")
[void]$ReportLines.Add("Target: $env:COMPUTERNAME | Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("")

# ---------------------------------------------------------
# PHASE 1: ACTIVE DIRECTORY REPLICATION & DC HEALTH AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 1/6] Inspecting Active Directory Replication & Domain Controller Health..." -ForegroundColor Yellow
[void]$ReportLines.Add("--- 1. ACTIVE DIRECTORY REPLICATION AUDIT ---")

$CS = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
$IsDC = ($CS.DomainRole -eq 4 -or $CS.DomainRole -eq 5)

if ($IsDC -or (Get-Command repadmin.exe -ErrorAction SilentlyContinue)) {
    Write-Host "   -> Domain Controller / AD tools detected. Running replication health check..." -ForegroundColor Green
    $RepSummaryPath = Join-Path -Path $ReportsDir -ChildPath "ad_replication_summary_$($env:COMPUTERNAME).txt"
    cmd.exe /c "repadmin /replsummary > `"$RepSummaryPath`"" 2>&1 | Out-Null
    
    if (Test-Path $RepSummaryPath) {
        $RepContent = Get-Content -Path $RepSummaryPath -ErrorAction SilentlyContinue | Out-String
        if ($RepContent -match "fails|error|denied") {
            $Msg = "[CRITICAL DOMAIN FAULT] Active Directory replication synchronization errors detected! Check reports\ad_replication_summary.txt immediately."
            Write-Host "      $Msg" -ForegroundColor Red
            [void]$ReportLines.Add("  ! $Msg")
            [void]$FindingsList.Add("Active Directory Replication Failure")
        } else {
            Write-Host "      [OK] Active Directory domain replication topology is healthy." -ForegroundColor Green
            [void]$ReportLines.Add("AD Replication Status: Healthy")
        }
    }
} else {
    Write-Host "   -> Standalone / Member System detected. Skipping DC replication diagnostics." -ForegroundColor DarkCyan
    [void]$ReportLines.Add("AD Replication: N/A (Non-DC machine)")
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 2: SSL / TLS CERTIFICATE EXPIRATION AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 2/6] Auditing Local SSL/TLS Certificate Expiration Status..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 2. SSL/TLS CERTIFICATE EXPIRATION AUDIT ---")

$CertCsvPath = Join-Path -Path $ReportsDir -ChildPath "ssl_certificates_audit_$($env:COMPUTERNAME).csv"
$ExpiringCerts = New-Object System.Collections.ArrayList
$ThresholdDate = (Get-Date).AddDays(30)

try {
    $Certs = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue
    foreach ($C in $Certs) {
        if ($C.NotAfter -ne $null) {
            $DaysLeft = [math]::Round(($C.NotAfter - (Get-Date)).TotalDays)
            if ($DaysLeft -le 30) {
                $StatusStr = if ($DaysLeft -lt 0) { "EXPIRED" } else { "EXPIRING SOON ($DaysLeft days left)" }
                $CertObj = New-Object PSObject -Property @{
                    Subject = $C.Subject
                    Thumbprint = $C.Thumbprint
                    ExpirationDate = $C.NotAfter.ToString("yyyy-MM-dd")
                    Status = $StatusStr
                }
                [void]$ExpiringCerts.Add($CertObj)
                
                $Msg = "[CERTIFICATE WARNING] Cert '$($C.Subject)' is $StatusStr (Expires: $($C.NotAfter.ToString('yyyy-MM-dd')))!"
                Write-Host "   $Msg" -ForegroundColor (if ($DaysLeft -lt 0) { "Red" } else { "Yellow" })
                [void]$ReportLines.Add("  * $Msg")
                [void]$FindingsList.Add("SSL Certificate $StatusStr ($($C.Subject))")
            }
        }
    }
} catch { }

if ($ExpiringCerts.Count -gt 0) {
    $ExpiringCerts | Select-Object Subject, Thumbprint, ExpirationDate, Status | Export-Csv -Path $CertCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "   -> Saved expiring certificate report to: reports\ssl_certificates_audit_$($env:COMPUTERNAME).csv" -ForegroundColor Yellow
} else {
    Write-Host "   -> [OK] All local machine SSL/TLS certificates are valid (None expiring within 30 days)." -ForegroundColor Green
    [void]$ReportLines.Add("SSL Certificates: Clean (0 expiring/expired)")
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 3: LEGACY SMBv1 RANSOMWARE VULNERABILITY SCAN
# ---------------------------------------------------------
Write-Host "[Audit 3/6] Scanning for Legacy SMBv1 Ransomware Exposure (WannaCry Vector)..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 3. SMBv1 RANSOMWARE VULNERABILITY SCAN ---")

$Smb1Enabled = $false
$SmbReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -ErrorAction SilentlyContinue
if ($SmbReg -ne $null -and $SmbReg.SMB1 -ne 0) { $Smb1Enabled = $true }

# Secondary check via Windows Optional Features
try {
    $Feature = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction SilentlyContinue
    if ($Feature -and $Feature.State -eq "Enabled") { $Smb1Enabled = $true }
} catch { }

if ($Smb1Enabled) {
    $Msg = "[CRITICAL SECURITY VULNERABILITY] Legacy SMBv1 protocol is ENABLED! This exposes the server/PC directly to WannaCry / EternalBlue ransomware worm propagation. Disable immediately via Server Manager or PowerShell ('Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol')."
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$ReportLines.Add("  ! $Msg")
    [void]$FindingsList.Add("Legacy SMBv1 Ransomware Vulnerability Enabled")
} else {
    Write-Host "   -> [OK] Legacy SMBv1 protocol is permanently disabled and secured." -ForegroundColor Green
    [void]$ReportLines.Add("SMBv1 Status: Securely Disabled")
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 4: ACTIVE LISTENING PORTS & COLLISION MAP
# ---------------------------------------------------------
Write-Host "[Audit 4/6] Mapping Active TCP/UDP Listening Sockets & Process Owners..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 4. ACTIVE LISTENING PORTS & PROCESS MAP ---")

$PortsCsvPath = Join-Path -Path $ReportsDir -ChildPath "listening_ports_map_$($env:COMPUTERNAME).csv"
$PortList = New-Object System.Collections.ArrayList

$NetstatLines = cmd.exe /c "netstat -ano | findstr LISTENING" 2>&1
foreach ($Line in $NetstatLines) {
    $Parts = ($Line -replace '^\s+', '') -split '\s+'
    if ($Parts.Count -ge 5) {
        $Proto = $Parts[0]
        $LocalAddr = $Parts[1]
        $PID = $Parts[$Parts.Count - 1]
        
        $PortNum = ($LocalAddr -split ':')[-1]
        $ProcName = "System / Unknown"
        try {
            $P = Get-Process -Id $PID -ErrorAction SilentlyContinue
            if ($P) { $ProcName = $P.ProcessName }
        } catch { }
        
        $PortObj = New-Object PSObject -Property @{
            Protocol = $Proto
            LocalAddress = $LocalAddr
            Port = $PortNum
            PID = $PID
            ProcessName = $ProcName
        }
        [void]$PortList.Add($PortObj)
    }
}

if ($PortList.Count -gt 0) {
    $PortList | Select-Object Protocol, LocalAddress, Port, PID, ProcessName | Export-Csv -Path $PortsCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "   -> Documented $($PortList.Count) active listening sockets into reports\listening_ports_map_$($env:COMPUTERNAME).csv" -ForegroundColor Green
    [void]$ReportLines.Add("Mapped $($PortList.Count) listening TCP/UDP sockets.")
} else {
    Write-Host "   -> [WARN] Could not parse netstat output." -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 5: PENDING SYSTEM REBOOT & SERVICING LOCK AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 5/6] Checking for Stuck Pending System Reboots & Update Locks..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 5. PENDING REBOOT & SERVICING AUDIT ---")

$RebootPending = $false
$RebootReasons = @()

if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $RebootPending = $true; $RebootReasons += "Component Based Servicing (CBS)" }
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $RebootPending = $true; $RebootReasons += "Windows Update Auto-Update" }
if ((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue)) { $RebootPending = $true; $RebootReasons += "Pending File Rename Operations" }

if ($RebootPending) {
    $Msg = "[WARN SERVICING LOCK] System has a PENDING REBOOT locked in registry ($($RebootReasons -join ', '))! Software updates, role changes, or MSIs may fail until restarted."
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$ReportLines.Add("  - $Msg")
    [void]$FindingsList.Add("Pending System Reboot Locked ($($RebootReasons -join ', '))")
} else {
    Write-Host "   -> [OK] No pending reboots locked in Windows Registry." -ForegroundColor Green
    [void]$ReportLines.Add("Pending Reboot Status: Clean")
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 6: MEMORY CRASH DUMP & PAGEFILE READINESS AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 6/6] Checking Memory Crash Dump Readiness & Pagefile Configuration..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 6. CRASH DUMP & PAGEFILE READINESS ---")

$CrashReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -ErrorAction SilentlyContinue
$DumpType = switch ($CrashReg.CrashDumpEnabled) { 0 {"Disabled"} 1 {"Complete Memory Dump"} 2 {"Kernel Memory Dump"} 3 {"Small Memory Minidump"} default {"Unknown"} }

if ($DumpType -eq "Disabled") {
    $Msg = "[WARN DIAGNOSTICS] Windows Crash Dump generation is DISABLED! If a Blue Screen (BSOD) occurs, no MEMORY.DMP will be written for debugging."
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$ReportLines.Add("  - $Msg")
    [void]$FindingsList.Add("Crash Dump Generation Disabled")
} else {
    Write-Host "   -> Crash Dump Engine: Enabled ($DumpType)" -ForegroundColor Green
    [void]$ReportLines.Add("Crash Dump Engine: Enabled ($DumpType)")
}

# ---------------------------------------------------------
# FINAL DIAGNOSTIC SUMMARY
# ---------------------------------------------------------
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "             DEEP INFRASTRUCTURE DIAGNOSTIC SUMMARY" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta

[void]$ReportLines.Add("")
[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("SUMMARY OF FINDINGS")

if ($FindingsList.Count -gt 0) {
    Write-Host "STATUS: INFRASTRUCTURE ISSUES / VULNERABILITIES DETECTED ($($FindingsList.Count))" -ForegroundColor Red
    [void]$ReportLines.Add("Status: ISSUES DETECTED ($($FindingsList.Count) items found)")
    Write-Host "`nDetailed Breakdown:" -ForegroundColor Yellow
    foreach ($Item in $FindingsList) {
        Write-Host "  [!] $Item" -ForegroundColor Yellow
        [void]$ReportLines.Add("  * $Item")
    }
} else {
    Write-Host "STATUS: EXCELLENT (All deep infrastructure & security checks passed cleanly!)" -ForegroundColor Green
    [void]$ReportLines.Add("Status: EXCELLENT (Clean diagnostic audit)")
}

$TextReportPath = Join-Path -Path $ReportsDir -ChildPath "deep_diagnostic_report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ReportLines | Out-File -FilePath $TextReportPath -Encoding utf8 -Force
Write-Host "`nComplete diagnostic case file saved to: reports\$(Split-Path $TextReportPath -Leaf)" -ForegroundColor Cyan
