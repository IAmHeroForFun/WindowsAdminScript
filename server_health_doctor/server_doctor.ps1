# Windows Server Health & Misconfiguration Doctor
# Compatible with Windows Server 2008 R2 (PS 2.0) through Windows Server 2022/2025 (PS 5.1 & 7+)
# Deep inspection tool that hunts for out-of-the-ordinary server misconfigurations (DNS errors, Time drift, Firewall vulnerabilities, Disk faults).

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
Write-Host "         WINDOWS SERVER HEALTH & MISCONFIGURATION DOCTOR" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target Server: $env:COMPUTERNAME | Scan Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Hunting for out-of-the-ordinary network, domain, and system faults..." -ForegroundColor DarkCyan
Write-Host ""

$MisconfigsFound = New-Object System.Collections.ArrayList
$ReportLines = New-Object System.Collections.ArrayList

[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("WINDOWS SERVER HEALTH & MISCONFIGURATION CASE REPORT")
[void]$ReportLines.Add("Server: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("")

# Check Server Role / Domain Membership
$CS = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
$DomainRole = $CS.DomainRole # 0=Standalone Workstation, 1=Member Workstation, 2=Standalone Server, 3=Member Server, 4=Backup DC, 5=Primary DC
$IsDC = ($DomainRole -eq 4 -or $DomainRole -eq 5)
$IsDomainJoined = ($DomainRole -eq 1 -or $DomainRole -eq 3 -or $IsDC)
$RoleStr = switch ($DomainRole) { 2 {"Standalone Server"} 3 {"Domain Member Server"} 4 {"Backup Domain Controller (DC)"} 5 {"Primary Domain Controller (DC)"} default {"Windows Computer"} }

Write-Host "Detected Architecture: $RoleStr (Domain: $($CS.Domain))" -ForegroundColor Cyan
[void]$ReportLines.Add("Server Classification: $RoleStr | Domain: $($CS.Domain)")
Write-Host ""

# ---------------------------------------------------------
# CHECK 1: NETWORK ADAPTER & DNS RESOLVER MISCONFIGURATIONS
# ---------------------------------------------------------
Write-Host "[Audit 1/6] Scanning Network Adapter & DNS Resolver Configurations..." -ForegroundColor Yellow
[void]$ReportLines.Add("--- 1. NETWORK & DNS AUDIT ---")

$Adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue
foreach ($NIC in $Adapters) {
    $IP = @($NIC.IPAddress)[0]
    $Gateway = @($NIC.DefaultIPGateway)[0]
    $DNSList = @($NIC.DNSServerSearchOrder)
    $DHCP = $NIC.DHCPEnabled
    
    Write-Host "   -> NIC: $($NIC.Description) | IP: $IP" -ForegroundColor DarkCyan
    [void]$ReportLines.Add("NIC: $($NIC.Description) | IP: $IP | DHCP: $DHCP")
    
    # Check 1A: DHCP on Production Server
    if ($DHCP -eq $true -and ($DomainRole -ge 2)) {
        $Msg = "[WARN MISCONFIG] Server is using DHCP auto-assigned IP address ($IP)! Production servers should always use fixed Static IP addresses."
        Write-Host "      $Msg" -ForegroundColor Yellow
        [void]$ReportLines.Add("  - $Msg")
        [void]$MisconfigsFound.Add("Server NIC using DHCP dynamic IP address")
    }
    
    # Check 1B: DNS Audit (The #1 Active Directory Killer!)
    if ($DNSList.Count -gt 0) {
        Write-Host "      Configured DNS Servers: $($DNSList -join ', ')" -ForegroundColor DarkGray
        [void]$ReportLines.Add("      DNS Servers: $($DNSList -join ', ')")
        
        foreach ($DnsIP in $DNSList) {
            # Check if public DNS is entered directly on adapter
            if ($DnsIP -in @("8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1", "9.9.9.9", "208.67.222.222")) {
                if ($IsDomainJoined) {
                    $Msg = "[CRITICAL MISCONFIG] Public DNS ($DnsIP) is set directly on network adapter! On Domain Controllers and domain servers, putting public DNS breaks Kerberos auth, group policy, and AD replication! (Use local AD DNS IPs on NIC, and put 8.8.8.8 inside DNS Server Forwarders instead)."
                    Write-Host "      $Msg" -ForegroundColor Red
                    [void]$ReportLines.Add("  ! $Msg")
                    [void]$MisconfigsFound.Add("Public DNS ($DnsIP) configured on domain network adapter")
                } else {
                    Write-Host "      [INFO] Public DNS ($DnsIP) detected on standalone server." -ForegroundColor DarkGray
                }
            }
            # Check if Gateway router IP is set as DNS on domain server
            if ($Gateway -ne $null -and $DnsIP -eq $Gateway -and $IsDomainJoined) {
                $Msg = "[CRITICAL MISCONFIG] Router/Gateway IP ($DnsIP) is configured as primary DNS! Domain servers must point exclusively to Active Directory Domain Controller DNS servers."
                Write-Host "      $Msg" -ForegroundColor Red
                [void]$ReportLines.Add("  ! $Msg")
                [void]$MisconfigsFound.Add("Gateway IP ($DnsIP) configured as DNS on domain server")
            }
        }
    } else {
        $Msg = "[CRITICAL MISCONFIG] No DNS servers configured on active network adapter!"
        Write-Host "      $Msg" -ForegroundColor Red
        [void]$ReportLines.Add("  ! $Msg")
        [void]$MisconfigsFound.Add("No DNS servers configured on active adapter")
    }
}
Write-Host ""

# ---------------------------------------------------------
# CHECK 2: WINDOWS TIME & NTP SYNCHRONIZATION HEALTH
# ---------------------------------------------------------
Write-Host "[Audit 2/6] Inspecting Time Synchronization & NTP Health..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 2. TIME SYNCHRONIZATION AUDIT ---")

$W32Time = Get-Service -Name w32time -ErrorAction SilentlyContinue
if ($W32Time) {
    if ($W32Time.Status -ne "Running") {
        $Msg = "[CRITICAL MISCONFIG] Windows Time Service (w32time) is NOT Running ($($W32Time.Status))! If server time drifts >5 minutes, all Active Directory authentication & Kerberos logins will fail!"
        Write-Host "   $Msg" -ForegroundColor Red
        [void]$ReportLines.Add("  ! $Msg")
        [void]$MisconfigsFound.Add("Windows Time Service ($($W32Time.Status))")
    } else {
        $TimeSource = "Unknown"
        try {
            $TimeOut = w32tm /query /source 2>&1
            if ($TimeOut -and $TimeOut -notmatch "error") { $TimeSource = $TimeOut }
        } catch { }
        
        Write-Host "   -> Time Service Status: Running | Active NTP Source: $TimeSource" -ForegroundColor Green
        [void]$ReportLines.Add("Time Service: Running | NTP Source: $TimeSource")
        if ($TimeSource -like "*FreeRunning*" -or $TimeSource -like "*Local CMOS*") {
            if ($IsDomainJoined -and -not $IsDC) {
                $Msg = "[WARN MISCONFIG] Server is using local internal CMOS clock instead of syncing with domain hierarchy!"
                Write-Host "      $Msg" -ForegroundColor Yellow
                [void]$ReportLines.Add("  - $Msg")
                [void]$MisconfigsFound.Add("Server time uncoordinated (FreeRunningLocalClock)")
            }
        }
    }
}
Write-Host ""

# ---------------------------------------------------------
# CHECK 3: WINDOWS FIREWALL SECURITY PROFILE AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 3/6] Auditing Windows Firewall Profiles & Exposure..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 3. FIREWALL SECURITY AUDIT ---")

try {
    $Profiles = Get-WmiObject -Namespace "root\StandardCimv2" -Class "MSFT_NetFirewallProfile" -ErrorAction SilentlyContinue
    if (-not $Profiles) {
        $Profiles = netsh advfirewall show allprofiles state 2>&1
    }
    
    $DisabledProfiles = @()
    if ($Profiles -is [System.Array] -and $Profiles[0].Name) {
        foreach ($P in $Profiles) {
            $StateStr = if ($P.Enabled -eq 1 -or $P.Enabled -eq "True") { "Enabled" } else { "Disabled" }
            Write-Host "   -> Firewall Profile ($($P.Name)): $StateStr" -ForegroundColor (if ($StateStr -eq "Enabled") { "Green" } else { "Red" })
            [void]$ReportLines.Add("Firewall Profile ($($P.Name)): $StateStr")
            if ($StateStr -eq "Disabled") { $DisabledProfiles += $P.Name }
        }
    } else {
        Write-Host "   -> Firewall status inspected via Netsh fallback." -ForegroundColor DarkCyan
    }
    
    if ($DisabledProfiles.Count -gt 0) {
        $Msg = "[CRITICAL vulnerability] Windows Firewall is completely DISABLED on profiles: $($DisabledProfiles -join ', ')! This exposes server ports (SMB 445, RDP 3389) directly to network attacks and ransomware."
        Write-Host "      $Msg" -ForegroundColor Red
        [void]$ReportLines.Add("  ! $Msg")
        [void]$MisconfigsFound.Add("Windows Firewall Disabled ($($DisabledProfiles -join ', '))")
    }
} catch { }
Write-Host ""

# ---------------------------------------------------------
# CHECK 4: VOLUME SHADOW COPY (VSS) & DISK CONTROLLER FAULTS
# ---------------------------------------------------------
Write-Host "[Audit 4/6] Checking Volume Shadow Copy (VSS) & Storage Controller Errors..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 4. STORAGE HEALTH & BACKUP ENGINE AUDIT ---")

$VSS = Get-Service -Name VSS -ErrorAction SilentlyContinue
if ($VSS -and $VSS.StartType -eq "Disabled") {
    $Msg = "[CRITICAL MISCONFIG] Volume Shadow Copy (VSS) service is DISABLED! Server backups (Veeam, Windows Server Backup) will fail silently."
    Write-Host "   $Msg" -ForegroundColor Red
    [void]$ReportLines.Add("  ! $Msg")
    [void]$MisconfigsFound.Add("Volume Shadow Copy (VSS) service disabled")
} else {
    Write-Host "   -> VSS Backup Engine Status: Ready ($($VSS.Status))" -ForegroundColor Green
    [void]$ReportLines.Add("VSS Engine Status: Ready")
}

# Scan System Event Log for Disk Controller Errors (Last 7 Days)
Write-Host "   -> Scanning Windows System Event Log for disk/NTFS hardware errors..." -ForegroundColor DarkCyan
$DiskErrors = Get-WinEvent -FilterHashtable @{LogName='System'; ID=7,11,51,55; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue
if ($DiskErrors.Count -gt 0) {
    $Msg = "[CRITICAL HARDWARE FAULT] Found $($DiskErrors.Count) Disk Controller / NTFS corruption events logged in the last 7 days! Immediate hard drive SMART diagnostic or array rebuild required."
    Write-Host "      $Msg" -ForegroundColor Red
    [void]$ReportLines.Add("  ! $Msg")
    [void]$MisconfigsFound.Add("Hardware Disk/NTFS errors in System Event Log ($($DiskErrors.Count) events)")
} else {
    Write-Host "      [OK] No disk controller hardware errors logged in the past 7 days." -ForegroundColor Green
    [void]$ReportLines.Add("Disk Controller Logs: Clean (0 errors)")
}
Write-Host ""

# ---------------------------------------------------------
# CHECK 5: TLS 1.2 SECURITY PROTOCOL AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 5/6] Checking TLS 1.2 Modern Security Protocol Status..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 5. TLS SECURITY AUDIT ---")

$Tls12Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
if (Test-Path $Tls12Key) {
    $TlsDisabled = (Get-ItemProperty -Path $Tls12Key -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    if ($TlsDisabled -eq 0) {
        $Msg = "[WARN MISCONFIG] TLS 1.2 Client protocol is explicitly disabled in registry! Modern cloud APIs (Azure AD Connect, Office 365, secure HTTPS requests) will fail."
        Write-Host "   $Msg" -ForegroundColor Yellow
        [void]$ReportLines.Add("  - $Msg")
        [void]$MisconfigsFound.Add("TLS 1.2 protocol disabled in registry")
    } else {
        Write-Host "   -> TLS 1.2 Security Protocol: Enabled & Active" -ForegroundColor Green
        [void]$ReportLines.Add("TLS 1.2 Protocol: Enabled")
    }
} else {
    Write-Host "   -> TLS 1.2 Registry Keys: Default OS Configuration" -ForegroundColor DarkCyan
    [void]$ReportLines.Add("TLS 1.2 Protocol: Default OS state")
}
Write-Host ""

# ---------------------------------------------------------
# CHECK 6: SYSTEM CRASH & UNEXPECTED REBOOT AUDIT
# ---------------------------------------------------------
Write-Host "[Audit 6/6] Checking for Unexpected Server Shutdowns & Crash Dumps..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 6. STABILITY & SHUTDOWN AUDIT ---")

$CrashEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ID=6008,41; StartTime=(Get-Date).AddDays(-14)} -ErrorAction SilentlyContinue
if ($CrashEvents.Count -gt 0) {
    $Msg = "[WARN STABILITY] Detected $($CrashEvents.Count) unexpected server reboots/power failures (Event ID 6008/41) in the last 14 days!"
    Write-Host "   $Msg" -ForegroundColor Yellow
    [void]$ReportLines.Add("  - $Msg")
    [void]$MisconfigsFound.Add("Unexpected Server Shutdowns ($($CrashEvents.Count) events in 14 days)")
} else {
    Write-Host "   -> Server Power Stability: Excellent (No unexpected crashes logged in 14 days)" -ForegroundColor Green
    [void]$ReportLines.Add("Server Stability: Excellent (0 crashes)")
}
Write-Host ""

# ---------------------------------------------------------
# FINAL DIAGNOSTIC SUMMARY
# ---------------------------------------------------------
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "                SERVER DOCTOR DIAGNOSTIC SUMMARY" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta

[void]$ReportLines.Add("")
[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("DIAGNOSTIC SUMMARY & FINDINGS")

if ($MisconfigsFound.Count -gt 0) {
    Write-Host "SERVER HEALTH STATUS: MISCONFIGURATIONS / FAULTS DETECTED ($($MisconfigsFound.Count))" -ForegroundColor Red
    [void]$ReportLines.Add("Status: FAULTS DETECTED ($($MisconfigsFound.Count) issues found)")
    Write-Host "`nDetailed Anomaly Breakdown:" -ForegroundColor Yellow
    foreach ($Fault in $MisconfigsFound) {
        Write-Host "  [!] $Fault" -ForegroundColor Yellow
        [void]$ReportLines.Add("  * $Fault")
    }
} else {
    Write-Host "SERVER HEALTH STATUS: EXCELLENT (No out-of-the-ordinary misconfigurations found!)" -ForegroundColor Green
    [void]$ReportLines.Add("Status: EXCELLENT (Clean audit)")
}

# Save Report File
$ReportPath = Join-Path -Path $ReportsDir -ChildPath "server_doctor_report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ReportLines | Out-File -FilePath $ReportPath -Encoding utf8 -Force
Write-Host "`nComplete diagnostic case file saved to: reports\$(Split-Path $ReportPath -Leaf)" -ForegroundColor Cyan
