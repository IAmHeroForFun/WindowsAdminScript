<#
.SYNOPSIS
    Windows Security Auditor & Forensic Incident Response Toolkit (PowerShell + Batch)
.DESCRIPTION
    A professional-grade, read-only Windows Security Audit Toolkit designed for digital forensics, SOC triage, incident response, and deep defensive assessment across Windows 10/11 and Windows Server environments.
    
    Performs a 10-Phase deep forensic audit without modifying system state:
      - Phase 1: System Information & Hardware Architecture
      - Phase 2: Network Analysis & DNS Routing Audit
      - Phase 3: Port Audit & Listener Mapping
      - Phase 4: Process & LOLBins Analysis (Rozena.A / PowerShell TrojanDownloader hunting)
      - Phase 5: Persistence Audit (Run Keys, Startup, Tasks, Services)
      - Phase 6: Windows Defender & Exclusion Triage
      - Phase 7: Firewall Profile Health
      - Phase 8: User & Privilege Review
      - Phase 9: Installed Software & KMS / Crack Detection
      - Phase 10: Security Hardening & Encryption Posture
      
    Outputs colored terminal triage, JSON telemetry, text reports, and an interactive dark-mode HTML Executive Dashboard.
.AUTHOR
    Senior Windows Security Engineer & Digital Forensics Analyst
#>

[CmdletBinding()]
param (
    [string]$OutputDir = "",
    [switch]$Silent
)

$ErrorActionPreference = "SilentlyContinue"

# 0. RESOLVE WORKING DIRECTORY & SETUP REPORTING
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}
if (-not $OutputDir) { $OutputDir = Join-Path -Path $PSScriptRoot -ChildPath "Reports" }
if (-not (Test-Path -Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$TxtReportPath  = Join-Path -Path $OutputDir -ChildPath "AuditReport.txt"
$JsonReportPath = Join-Path -Path $OutputDir -ChildPath "AuditReport.json"
$HtmlReportPath = Join-Path -Path $OutputDir -ChildPath "AuditReport.html"

# Initialize Report File
"==========================================================================" | Out-File -FilePath $TxtReportPath -Encoding UTF8 -Force
"   WINDOWS SECURITY AUDIT & FORENSIC TRIAGE REPORT" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
"   Target System: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
"==========================================================================" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8

function Write-Log {
    param([string]$Message, [string]$Level="INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $LogLine = "[$Timestamp] [$Level] $Message"
    $LogLine | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8 -Force
    if (-not $Silent) {
        switch ($Level) {
            "CRITICAL" { Write-Host "[$Timestamp] [CRITICAL] $Message" -ForegroundColor Red -BackgroundColor Black }
            "HIGH"     { Write-Host "[$Timestamp] [HIGH]     $Message" -ForegroundColor Red }
            "WARN"     { Write-Host "[$Timestamp] [WARN]     $Message" -ForegroundColor Yellow }
            "OK"       { Write-Host "[$Timestamp] [OK]       $Message" -ForegroundColor Green }
            "HEADER"   { Write-Host "`n==========================================================================" -ForegroundColor Magenta; Write-Host " $Message" -ForegroundColor Magenta; Write-Host "==========================================================================" -ForegroundColor Magenta }
            default    { Write-Host "[$Timestamp] [INFO]     $Message" -ForegroundColor Cyan }
        }
    }
}

# Master Findings Collection
$Findings = New-Object System.Collections.ArrayList
$SystemInfo = @{}
$NetworkStats = @{}
$PortStats = @{}
$DefenderStats = @{}

function Add-Finding {
    param(
        [string]$Category,
        [string]$Title,
        [string]$Status,
        [string]$RiskLevel, # Informational, Low, Medium, High, Critical
        [string]$Evidence,
        [string]$Explanation,
        [string]$Recommendation
    )
    $Obj = [PSCustomObject]@{
        Category       = $Category
        Title          = $Title
        Status         = $Status
        RiskLevel      = $RiskLevel
        Evidence       = $Evidence
        Explanation    = $Explanation
        Recommendation = $Recommendation
    }
    [void]$Findings.Add($Obj)
    
    # Mirror high-severity findings immediately to console
    if ($RiskLevel -in @("Critical", "High")) {
        Write-Log "ALERT ($RiskLevel): $Title -> $Evidence" $RiskLevel.ToUpper()
    } elseif ($RiskLevel -eq "Medium") {
        Write-Log "WARNING: $Title -> $Evidence" "WARN"
    }
}

Clear-Host
Write-Log "ENTERPRISE WINDOWS SECURITY AUDITOR & INCIDENT RESPONDER" "HEADER"
Write-Log "Starting Read-Only Forensic Triage on $env:COMPUTERNAME..." "INFO"

# ==========================================================================
# PHASE 1: SYSTEM INFORMATION & HARDWARE ARCHITECTURE
# ==========================================================================
Write-Log "PHASE 1: System Information & Hardware Architecture" "HEADER"

$OS = Get-CimInstance Win32_OperatingSystem
$CS = Get-CimInstance Win32_ComputerSystem
$BIOS = Get-CimInstance Win32_BIOS
$CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
$Board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue

$BootTime = $OS.LastBootUpTime
$Uptime = (Get-Date) - $BootTime
$UptimeStr = "$($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m"
$TotalRamGB = [math]::Round($CS.TotalPhysicalMemory / 1GB, 2)

$SystemInfo["ComputerName"] = $env:COMPUTERNAME
$SystemInfo["Username"]     = $env:USERNAME
$SystemInfo["OS"]           = "$($OS.Caption) (Build $($OS.BuildNumber))"
$SystemInfo["Architecture"] = $OS.OSArchitecture
$SystemInfo["LastBoot"]     = $BootTime.ToString("yyyy-MM-dd HH:mm:ss")
$SystemInfo["Uptime"]       = $UptimeStr
$SystemInfo["BIOS"]         = "$($BIOS.Manufacturer) $($BIOS.SMBIOSBIOSVersion) ($($BIOS.ReleaseDate))"
$SystemInfo["Motherboard"]  = if ($Board) { "$($Board.Manufacturer) $($Board.Product)" } else { "N/A" }
$SystemInfo["CPU"]          = $CPU.Name
$SystemInfo["RAM"]          = "${TotalRamGB} GB"
$SystemInfo["TimeZone"]     = (Get-TimeZone).Id

Write-Log "OS: $($SystemInfo['OS']) | RAM: $($SystemInfo['RAM']) | Uptime: $UptimeStr" "OK"
Write-Log "CPU: $($SystemInfo['CPU']) | BIOS: $($SystemInfo['BIOS'])" "INFO"
Add-Finding "System Info" "OS Baseline" "Active" "Informational" "$($SystemInfo['OS'])" "Operating system and build version recorded." "Ensure OS is within Microsoft servicing support lifecycle."

# ==========================================================================
# PHASE 2: NETWORK ANALYSIS & DNS ROUTING AUDIT
# ==========================================================================
Write-Log "PHASE 2: Network Analysis & DNS Routing Audit" "HEADER"

$NICs = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
$ActiveIPs = @()
$ActiveDNS = @()
$Gateways  = @()
$VpnDetected = $false

foreach ($Nic in $NICs) {
    $IPList  = @($Nic.IPAddress) -join ", "
    $GwList  = @($Nic.DefaultIPGateway) -join ", "
    $DnsList = @($Nic.DNSServerSearchOrder)
    
    $ActiveIPs += $IPList
    if ($GwList) { $Gateways += $GwList }
    if ($DnsList) { $ActiveDNS += $DnsList }
    
    if ($Nic.Description -match "VPN|TAP|Tun|WireGuard|OpenVPN|Cisco|Forti|AnyConnect|Tailscale") {
        $VpnDetected = $true
        Add-Finding "Network" "VPN / Virtual Adapter Detected" "Active" "Informational" "$($Nic.Description) ($IPList)" "Virtual private network or tunnel interface active." "Verify that VPN connection is authorized."
    }
}

$UniqueDNS = $ActiveDNS | Select-Object -Unique
$NetworkStats["IPAddresses"] = $ActiveIPs -join "; "
$NetworkStats["Gateways"]    = $Gateways -join "; "
$NetworkStats["DNSServers"]  = $UniqueDNS -join ", "

Write-Log "Active IP Addresses: $($NetworkStats['IPAddresses'])" "INFO"
Write-Log "Default Gateways:    $($NetworkStats['Gateways'])" "INFO"
Write-Log "DNS Servers:         $($NetworkStats['DNSServers'])" "INFO"

# Check for suspicious / unknown DNS servers
$KnownPublicDNS = @("8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1", "9.9.9.9", "208.67.222.222", "208.67.220.220", "94.140.14.14", "94.140.15.15") # Includes AdGuard
foreach ($Dns in $UniqueDNS) {
    if ($Dns -match "^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|127\.0\.0\.1|::1)") {
        Add-Finding "Network" "Local / Gateway DNS Server" "Configured" "Low" "DNS: $Dns" "System uses local router or internal DNS gateway." "None required."
    } elseif ($Dns -in $KnownPublicDNS) {
        Add-Finding "Network" "Known Public DNS Provider" "Configured" "Low" "DNS: $Dns" "System uses reputable public DNS (Google, Cloudflare, Quad9, or AdGuard)." "None required."
    } else {
        Add-Finding "Network" "Unclassified / External DNS Server" "Configured" "Medium" "DNS: $Dns" "DNS queries are routed to an unclassified external resolver." "Verify if $Dns is a trusted ISP or organizational DNS server to prevent DNS hijacking."
    }
}

# Check Established Outbound Connections via netstat
try {
    $NetstatOut = netstat -ano | Select-String "ESTABLISHED"
    $EstCount = if ($NetstatOut) { @($NetstatOut).Count } else { 0 }
    $NetworkStats["EstablishedConnections"] = $EstCount
    Write-Log "Total Established Network Connections: $EstCount" "INFO"
    
    if ($EstCount -gt 150) {
        Add-Finding "Network" "High Outbound Connection Volume" "Elevated" "High" "$EstCount established connections" "An unusually high number of active network connections detected." "Check running processes for peer-to-peer software, crypto miners, or C2 beaconing."
    } else {
        Add-Finding "Network" "Outbound Connection Volume" "Normal" "Low" "$EstCount established connections" "Connection count within normal operational parameters." "None required."
    }
} catch { }

# ==========================================================================
# PHASE 3: PORT AUDIT & LISTENER MAPPING
# ==========================================================================
Write-Log "PHASE 3: Port Audit & Listener Mapping" "HEADER"

$TCPListeners = @()
try {
    $NetstatListen = netstat -ano | Select-String "LISTENING"
    foreach ($Line in $NetstatListen) {
        $Parts = ($Line.ToString() -replace '\s+', ' ').Trim() -split ' '
        if ($Parts.Count -ge 4) {
            $LocalAddr = $Parts[1]
            $PID = $Parts[-1]
            $Port = ($LocalAddr -split ':')[-1]
            if ($Port -match '^\d+$') {
                $ProcName = (Get-Process -Id $PID -ErrorAction SilentlyContinue).ProcessName
                if (-not $ProcName) { $ProcName = "Unknown (PID $PID)" }
                $TCPListeners += [PSCustomObject]@{ Port = [int]$Port; PID = $PID; Process = $ProcName; Address = $LocalAddr }
            }
        }
    }
} catch { }

$UniquePorts = $TCPListeners | Sort-Object Port -Unique
$PortStats["TotalListeningPorts"] = $UniquePorts.Count
Write-Log "Detected $($UniquePorts.Count) listening TCP endpoints." "INFO"

$SensitivePorts = @{
    21   = @{ Name = "FTP"; Risk = "High"; Advice = "Unencrypted file transfer. Disable FTP service." }
    23   = @{ Name = "Telnet"; Risk = "Critical"; Advice = "Unencrypted remote administration. Disable immediately!" }
    445  = @{ Name = "SMB (File Sharing)"; Risk = "High"; Advice = "Ensure SMB signing is required and block port 445 at firewall boundary." }
    3389 = @{ Name = "RDP (Remote Desktop)"; Risk = "High"; Advice = "Ensure NLA is enabled and restrict RDP access via firewall rules." }
    5800 = @{ Name = "VNC HTTP"; Risk = "High"; Advice = "Remote desktop protocol exposed." }
    5900 = @{ Name = "VNC Server"; Risk = "High"; Advice = "Remote desktop protocol exposed." }
    5985 = @{ Name = "WinRM HTTP"; Risk = "Medium"; Advice = "Windows Remote Management listener active." }
    5986 = @{ Name = "WinRM HTTPS"; Risk = "Low"; Advice = "Secure Windows Remote Management listener active." }
}

foreach ($L in $UniquePorts) {
    $P = $L.Port
    if ($SensitivePorts.ContainsKey($P)) {
        $Info = $SensitivePorts[$P]
        Add-Finding "Port Audit" "Sensitive Port Exposed: $($Info.Name) ($P)" "Listening" $Info.Risk "Port $P bound by process '$($L.Process)' (PID $($L.PID))" "Service '$($Info.Name)' allows remote management or file access." $Info.Advice
    } elseif ($P -gt 49152) {
        # Ephemeral high ports (RPC dynamic range / IIS / internal services)
        Add-Finding "Port Audit" "Dynamic High Port Listener ($P)" "Listening" "Informational" "Port $P bound by '$($L.Process)' (PID $($L.PID))" "Standard Windows dynamic RPC or local service endpoint." "None required unless process is unfamiliar."
    } elseif ($P -notin @(80, 443, 135, 139, 5357, 7680)) {
        Add-Finding "Port Audit" "Uncommon Listening Port ($P)" "Listening" "Medium" "Port $P bound by '$($L.Process)' (PID $($L.PID))" "Uncommon TCP listening port detected." "Verify that process '$($L.Process)' is a legitimate business application."
    }
}

# ==========================================================================
# PHASE 4: PROCESS & LOLBINS ANALYSIS (ROZENA.A / TROJAN HUNTING)
# ==========================================================================
Write-Log "PHASE 4: Process & LOLBins Analysis (Rozena.A / Trojan Hunting)" "HEADER"

$Processes = Get-CimInstance Win32_Process
$LolBins = @("powershell.exe", "pwsh.exe", "cmd.exe", "wscript.exe", "cscript.exe", "mshta.exe", "rundll32.exe", "regsvr32.exe", "certutil.exe", "bitsadmin.exe", "wmic.exe")

$PsCount = 0
foreach ($Proc in $Processes) {
    $Name = $Proc.Name.ToLower()
    $CmdLine = $Proc.CommandLine
    $PID = $Proc.ProcessId
    $Path = $Proc.ExecutablePath
    
    # 1. PowerShell Specific Triage (Rozena.A & Downloader Hunting)
    if ($Name -in @("powershell.exe", "pwsh.exe")) {
        $PsCount++
        if ($CmdLine -like "*enterprise_security_auditor.ps1*" -or $CmdLine -like "*RunAudit.bat*") {
            Add-Finding "Process Analysis" "Security Audit Process Active" "Running" "Informational" "PID $($PID): $CmdLine" "Authorized Windows Security & Forensic Auditor process." "None required."
        } elseif ($CmdLine -match "-EncodedCommand|-enc |-e |FromBase64String|DownloadString|DownloadFile|IEX|Invoke-Expression|Net\.WebClient|BitTransfer|Hidden|-WindowStyle Hidden|-NoP|-NoProfile|-Exec Bypass") {
            Add-Finding "Process Analysis" "SUSPICIOUS POWERSHELL EXECUTION DETECTED!" "ACTIVE TROJAN INDICATOR" "Critical" "PID $($PID): $CmdLine" "PowerShell is running with obfuscated arguments, hidden windows, or web download commands typical of TrojanDownloader:PowerShell/Rozena.A or C2 beacons." "IMMEDIATELY terminate PID $PID, isolate network, and run a full Defender offline scan!"
        } else {
            Add-Finding "Process Analysis" "PowerShell Process Active" "Running" "Low" "PID $($PID): $CmdLine" "Standard PowerShell execution detected." "Verify that script or terminal was launched intentionally."
        }
    }
    
    # 2. LOLBins & Script Engine Abuse
    elseif ($Name -in @("wscript.exe", "cscript.exe", "mshta.exe", "regsvr32.exe", "certutil.exe", "bitsadmin.exe")) {
        if ($CmdLine -match "http://|https://|ftp://|\.ps1|\.vbs|\.js|\.bat|urlcache|decode|scrobj") {
            Add-Finding "Process Analysis" "EXPLOITED LOLBIN DETECTED ($Name)" "ACTIVE EXPLOIT INDICATOR" "Critical" "PID $($PID): $CmdLine" "A legitimate Windows binary ($Name) is being abused to download or execute external payloads (Living Off The Land attack)." "Terminate PID $PID immediately and investigate parent process!"
        } else {
            Add-Finding "Process Analysis" "LOLBin Process Active ($Name)" "Running" "Medium" "PID $($PID): $CmdLine" "Windows administrative tool active." "Verify that administrative tool is being used by an authorized admin."
        }
    }
    
    # 3. Execution from Suspicious Paths (Temp, AppData, Public)
    if ($Path -and $Path -match "\\Temp\\|\\AppData\\Local\\Temp\\|\\Users\\Public\\|\\Windows\\Tasks\\") {
        Add-Finding "Process Analysis" "Execution from Temporary / Public Folder" "Suspicious Path" "High" "PID $PID ($Name): $Path" "Malware and droppers frequently execute from temporary or public user directories to bypass permissions." "Verify digital signature and file integrity of $Path."
    }
}

Write-Log "Scanned $($Processes.Count) active processes. Found $PsCount running PowerShell instances." "INFO"

# ==========================================================================
# PHASE 5: PERSISTENCE AUDIT (RUN KEYS, STARTUP, TASKS, SERVICES)
# ==========================================================================
Write-Log "PHASE 5: Persistence Audit (Run Keys, Startup, Tasks, Services)" "HEADER"

# 1. Registry Run Keys
$RunKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

foreach ($Key in $RunKeys) {
    if (Test-Path $Key) {
        $Props = Get-ItemProperty -Path $Key -ErrorAction SilentlyContinue
        foreach ($PropName in $Props.PSObject.Properties.Name) {
            if ($PropName -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                $Val = $Props.$PropName
                if ($Val -match "powershell|pwsh|cmd\.exe|wscript|cscript|mshta|rundll32|\\Temp\\|\\AppData\\") {
                    Add-Finding "Persistence" "Suspicious Registry Autorun ($PropName)" "Configured" "High" "Key: $Key -> $Val" "Autorun entry launches scripts, interpreters, or temp executables upon login." "Inspect and remove unauthorized autorun entry."
                } else {
                    Add-Finding "Persistence" "Registry Autorun Entry ($PropName)" "Configured" "Informational" "Value: $Val" "Standard startup application registered in Windows Registry." "None required."
                }
            }
        }
    }
}

# 2. Startup Folders
$StartupFolders = @(
    [Environment]::GetFolderPath("Startup"),
    [Environment]::GetFolderPath("CommonStartup")
)
foreach ($Fldr in $StartupFolders) {
    if (Test-Path $Fldr) {
        $Items = Get-ChildItem -Path $Fldr -File -ErrorAction SilentlyContinue
        foreach ($Itm in $Items) {
            if ($Itm.Extension -in @(".bat", ".cmd", ".vbs", ".js", ".ps1")) {
                Add-Finding "Persistence" "Script in Startup Folder ($($Itm.Name))" "Present" "High" "Path: $($Itm.FullName)" "Script file placed in Startup folder will execute automatically on login." "Review script contents and remove if unauthorized."
            } else {
                Add-Finding "Persistence" "Startup Folder Item ($($Itm.Name))" "Present" "Low" "Path: $($Itm.FullName)" "Application shortcut in Startup folder." "None required."
            }
        }
    }
}

# 3. Scheduled Tasks (Hunting for PowerShell launchers & Encoded commands)
$Tasks = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" -and $_.TaskPath -notlike "\Microsoft\Windows\*" }
foreach ($Task in $Tasks) {
    $Actions = $Task.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }
    $ActionStr = $Actions -join " | "
    if ($ActionStr -match "powershell|pwsh|cmd\.exe|wscript|cscript|mshta|rundll32|-EncodedCommand|hidden|\\Temp\\|\\AppData\\") {
        Add-Finding "Persistence" "SUSPICIOUS SCHEDULED TASK: $($Task.TaskName)" "Active Task" "High" "Path: $($Task.TaskPath) | Action: $ActionStr" "Scheduled task is configured to launch script engines or obfuscated commands." "Disable task (`Disable-ScheduledTask -TaskName '$($Task.TaskName)'`) and investigate script target."
    } else {
        Add-Finding "Persistence" "Third-Party Scheduled Task ($($Task.TaskName))" "Active Task" "Informational" "Action: $ActionStr" "Standard application maintenance or updater task." "None required."
    }
}

# 4. Windows Services
$Services = Get-CimInstance Win32_Service | Where-Object { $_.State -eq "Running" -and $_.PathName -notlike "*C:\Windows\system32\*" -and $_.PathName -notlike "*C:\Windows\SysWOW64\*" }
foreach ($Svc in $Services) {
    if ($Svc.PathName -match "powershell|cmd\.exe|wscript|cscript|\\Temp\\|\\AppData\\") {
        Add-Finding "Persistence" "SUSPICIOUS RUNNING SERVICE: $($Svc.DisplayName)" "Running Service" "Critical" "Service: $($Svc.Name) | Path: $($Svc.PathName)" "Service binary path points to scripting engine or temporary directory!" "Stop and disable service immediately (`Stop-Service $($Svc.Name) -Force; Set-Service $($Svc.Name) -StartupType Disabled`)."
    }
}

Write-Log "Persistence audit completed across Registry, Startup folders, Tasks, and Services." "OK"

# ==========================================================================
# PHASE 6: WINDOWS DEFENDER & EXCLUSION TRIAGE
# ==========================================================================
Write-Log "PHASE 6: Windows Defender & Exclusion Triage" "HEADER"

try {
    $MpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $MpPref   = Get-MpPreference -ErrorAction SilentlyContinue
    
    if ($MpStatus) {
        $DefenderStats["RealTimeProtection"] = $MpStatus.RealTimeProtectionEnabled
        $DefenderStats["AntivirusEnabled"]   = $MpStatus.AntivirusEnabled
        $DefenderStats["BehaviorMonitor"]    = $MpStatus.BehaviorMonitorEnabled
        $DefenderStats["SignatureUpdated"]   = $MpStatus.AntivirusSignatureLastUpdated
        
        if ($MpStatus.RealTimeProtectionEnabled) {
            Add-Finding "Defender AV" "Real-Time Protection" "ENABLED" "Low" "Microsoft Defender Real-Time Protection is active." "Baseline endpoint monitoring operational." "None required."
            Write-Log "Windows Defender Real-Time Protection: ENABLED" "OK"
        } else {
            Add-Finding "Defender AV" "Real-Time Protection" "DISABLED" "Critical" "Microsoft Defender Real-Time Protection is OFF!" "System is completely exposed to malware execution without real-time interception." "Enable Defender Real-Time Protection immediately via Windows Security or PowerShell (`Set-MpPreference -DisableRealtimeMonitoring `$false`)."
            Write-Log "Windows Defender Real-Time Protection: DISABLED!" "CRITICAL"
        }
    }
    
    # Check Exclusions (Malware like Rozena.A often adds drive or folder exclusions!)
    if ($MpPref) {
        $ExclPaths = @($MpPref.ExclusionPath)
        $ExclExts  = @($MpPref.ExclusionExtension)
        $ExclProcs = @($MpPref.ExclusionProcess)
        
        if ($ExclPaths.Count -gt 0 -or $ExclExts.Count -gt 0 -or $ExclProcs.Count -gt 0) {
            $ExclSummary = "Paths: $($ExclPaths -join ', ') | Exts: $($ExclExts -join ', ') | Procs: $($ExclProcs -join ', ')"
            Add-Finding "Defender AV" "Active Defender Exclusions Detected!" "Configured" "High" "Exclusions: $ExclSummary" "Malware frequently adds C:, Temp, or PowerShell to Defender exclusions to evade detection!" "Review all exclusions in Windows Security and remove any unauthorized paths or file extensions immediately!"
            Write-Log "WARNING: Active Defender Exclusions found: $ExclSummary" "WARN"
        } else {
            Add-Finding "Defender AV" "Defender Exclusions" "Clean (0 Exclusions)" "Low" "No path, extension, or process exclusions configured." "Defender scans all file paths without blind spots." "None required."
        }
    }
    
    # Check Recent Threat Detections (Hunting for Rozena.A history!)
    $Threats = Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 5
    if ($Threats -and @($Threats).Count -gt 0) {
        foreach ($T in $Threats) {
            $ThreatName = $T.Resources -join ", "
            Add-Finding "Defender AV" "Recent Malware Detection History" "Threat Recorded" "High" "Date: $($T.InitialDetectionTime) | Threat ID: $($T.ThreatID) | Target: $ThreatName" "Microsoft Defender intercepted a malware execution attempt (e.g., TrojanDownloader:PowerShell/Rozena.A)." "Verify in Protection History that the threat status is Quarantined or Removed, and perform an Offline Scan."
            Write-Log "Threat Detected in History: $ThreatName on $($T.InitialDetectionTime)" "WARN"
        }
    } else {
        Add-Finding "Defender AV" "Recent Threat History" "Clean" "Low" "No active or recent threat detections logged in WMI query." "Endpoint history clean." "None required."
    }
} catch {
    Add-Finding "Defender AV" "Defender Status Query" "Failed / Third-Party AV" "Medium" "Could not query Get-MpComputerStatus." "System may be using a third-party EDR/AV solution or Defender WMI provider is disabled." "Verify active endpoint protection manually."
}

# ==========================================================================
# PHASE 7: FIREWALL PROFILE HEALTH
# ==========================================================================
Write-Log "PHASE 7: Firewall Profile Health" "HEADER"

try {
    $FwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    if ($FwProfiles) {
        foreach ($Fw in $FwProfiles) {
            if ($Fw.Enabled -eq "True") {
                Add-Finding "Firewall" "Windows Firewall Profile ($($Fw.Name))" "ENABLED" "Low" "Profile: $($Fw.Name) | Default Inbound: $($Fw.DefaultInboundAction)" "Network boundary filtering active." "None required."
            } else {
                Add-Finding "Firewall" "Windows Firewall Profile ($($Fw.Name))" "DISABLED" "Critical" "Profile '$($Fw.Name)' is currently OFF!" "System is vulnerable to direct network intrusion, port scanning, and lateral worm propagation." "Enable firewall profile immediately (`Set-NetFirewallProfile -Profile $($Fw.Name) -Enabled True`)."
                Write-Log "Windows Firewall Profile ($($Fw.Name)) is DISABLED!" "CRITICAL"
            }
        }
    }
} catch {
    Add-Finding "Firewall" "Firewall Status" "Query Failed" "Medium" "Could not query NetFirewallProfile." "Verify firewall status via netsh or GUI." "None required."
}

# ==========================================================================
# PHASE 8: USER & PRIVILEGE REVIEW
# ==========================================================================
Write-Log "PHASE 8: User & Privilege Review" "HEADER"

try {
    $Users = Get-LocalUser -ErrorAction SilentlyContinue
    if ($Users) {
        foreach ($U in $Users) {
            if ($U.Enabled) {
                $AdminCheck = (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*\$($U.Name)" })
                $RoleStr = if ($AdminCheck) { "Administrator" } else { "Standard User" }
                
                if ($U.Name -eq "Guest") {
                    Add-Finding "User Audit" "Built-in Guest Account" "ENABLED" "High" "Account: Guest ($RoleStr)" "Enabled Guest account allows unauthenticated local access." "Disable Guest account (`Disable-LocalUser -Name 'Guest'`)."
                } elseif ($U.PasswordNeverExpires -and $AdminCheck) {
                    Add-Finding "User Audit" "Admin Password Never Expires ($($U.Name))" "Configured" "Medium" "Account: $($U.Name) (Admin) | Last Logon: $($U.LastLogon)" "Privileged account has non-expiring password policy." "Ensure strong passphrase or enforce periodic password rotation."
                } else {
                    Add-Finding "User Audit" "Active Local Account ($($U.Name))" "Enabled ($RoleStr)" "Informational" "Account: $($U.Name) | Last Logon: $($U.LastLogon)" "Authorized local user account." "None required."
                }
            }
        }
    }
} catch { }

# ==========================================================================
# PHASE 9: INSTALLED SOFTWARE & KMS / CRACK DETECTION
# ==========================================================================
Write-Log "PHASE 9: Installed Software & KMS / Crack Detection" "HEADER"

$UninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledApps = Get-ItemProperty -Path $UninstallKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Sort-Object DisplayName -Unique

$SuspiciousKeywords = @("kms", "activator", "crack", "patcher", "keygen", "autokms", "kmspico", "rstrui", "cheatengine", "torrent", "megasync", "anydesk", "teamviewer", "screenconnect", "remotepc")

$AppCount = 0
$FlaggedApps = 0
foreach ($App in $InstalledApps) {
    $AppCount++
    $Name = $App.DisplayName
    $Pub  = $App.Publisher
    
    foreach ($Kw in $SuspiciousKeywords) {
        if ($Name -match $Kw) {
            $FlaggedApps++
            $Risk = if ($Kw -in @("kms", "activator", "crack", "patcher", "keygen", "autokms", "kmspico")) { "High" } else { "Medium" }
            Add-Finding "Software Audit" "Potentially Unwanted / Risky Software ($Name)" "Installed" $Risk "Publisher: $Pub | Version: $($App.DisplayVersion) | Path: $($App.InstallLocation)" "Software matches keywords associated with software cracks, KMS activators, or remote access tools (RATs). Cracks/KMS tools are the #1 vector for TrojanDownloader:PowerShell/Rozena.A!" "Uninstall '$Name' immediately if unauthorized and scan system with Defender Offline."
            Write-Log "FLAGGED SOFTWARE: $Name ($Pub)" $Risk.ToUpper()
            break
        }
    }
}
Write-Log "Enumerate $AppCount installed applications. Flagged $FlaggedApps suspicious packages." "INFO"

# ==========================================================================
# PHASE 10: SECURITY HARDENING & ENCRYPTION POSTURE
# ==========================================================================
Write-Log "PHASE 10: Security Hardening & Encryption Posture" "HEADER"

# 1. UAC Status
$UacReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
if ($UacReg -eq 0) {
    Add-Finding "Hardening" "User Account Control (UAC)" "DISABLED" "High" "Registry EnableLUA = 0" "Admin processes execute silently without user confirmation prompt." "Enable UAC (`Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -Value 1`) and reboot."
} else {
    Add-Finding "Hardening" "User Account Control (UAC)" "Enabled" "Low" "Registry EnableLUA = 1" "Privilege escalation prompts active." "None required."
}

# 2. BitLocker Drive Encryption
try {
    $BitLocker = Get-CimInstance -Namespace "root\CIMv2\Security\MicrosoftVolumeEncryption" -ClassName Win32_EncryptableVolume -Filter "DriveLetter='C:'" -ErrorAction SilentlyContinue
    if ($BitLocker -and $BitLocker.ProtectionStatus -eq 1) {
        Add-Finding "Hardening" "BitLocker Drive Encryption (C:)" "Encrypted & Protected" "Low" "Volume C: protection status active." "OS drive protected against offline physical theft." "None required."
    } else {
        Add-Finding "Hardening" "BitLocker Drive Encryption (C:)" "UNENCRYPTED" "Medium" "Volume C: protection status inactive / unencrypted." "Physical access to drive allows data extraction without credentials." "Enable BitLocker drive encryption on system volume."
    }
} catch {
    Add-Finding "Hardening" "BitLocker Status" "Not Queryable" "Informational" "CIMv2 Encryption namespace not available." "Verify BitLocker status manually." "None required."
}

# 3. Secure Boot Status
try {
    $SecureBoot = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
    if ($SecureBoot -eq $true) {
        Add-Finding "Hardening" "UEFI Secure Boot" "Enabled" "Low" "UEFI firmware signature verification active." "Prevents bootkits and unauthorized kernel drivers from loading at boot." "None required."
    } else {
        Add-Finding "Hardening" "UEFI Secure Boot" "DISABLED" "Medium" "UEFI firmware signature verification inactive." "System is susceptible to boot-level rootkits and pre-OS tampering." "Enable Secure Boot in motherboard BIOS/UEFI settings."
    }
} catch {
    Add-Finding "Hardening" "UEFI Secure Boot" "Legacy BIOS / Unsupported" "Informational" "Could not query Confirm-SecureBootUEFI." "System may be running in Legacy BIOS mode or virtual machine." "None required."
}

# 4. PowerShell ScriptBlock Logging
$PsLog = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -ErrorAction SilentlyContinue).EnableScriptBlockLogging
if ($PsLog -eq 1) {
    Add-Finding "Hardening" "PowerShell ScriptBlock Logging" "Enabled" "Low" "Registry EnableScriptBlockLogging = 1" "Full PowerShell execution payloads are logged to Event Viewer (Event ID 4104) for forensic investigation." "None required."
} else {
    Add-Finding "Hardening" "PowerShell ScriptBlock Logging" "DISABLED" "Medium" "Registry EnableScriptBlockLogging is not enabled." "Obfuscated or memory-only PowerShell attacks cannot be forensically reconstructed from logs." "Enable PowerShell ScriptBlock Logging via Group Policy or Registry."
}

# ==========================================================================
# RISK ENGINE & SECURITY SCORE CALCULATION
# ==========================================================================
Write-Log "Calculating Enterprise Risk Score..." "INFO"

$Score = 100
$CritCount = 0
$HighCount = 0
$MedCount  = 0
$LowCount  = 0
$InfoCount = 0

foreach ($F in $Findings) {
    switch ($F.RiskLevel) {
        "Critical"      { $Score -= 25; $CritCount++ }
        "High"          { $Score -= 12; $HighCount++ }
        "Medium"        { $Score -= 5;  $MedCount++ }
        "Low"           { $LowCount++ }
        "Informational" { $InfoCount++ }
    }
}
if ($Score -lt 0) { $Score = 0 }

$Rating = switch ($Score) {
    { $_ -ge 90 } { "Secure" }
    { $_ -ge 70 } { "Good" }
    { $_ -ge 50 } { "Needs Attention" }
    { $_ -ge 30 } { "High Risk" }
    default       { "Critical" }
}

$ScoreColor = switch ($Rating) {
    "Secure"          { "#22c55e" }
    "Good"            { "#3b82f6" }
    "Needs Attention" { "#eab308" }
    "High Risk"       { "#f97316" }
    default           { "#ef4444" }
}

Write-Log "==========================================================================" "HEADER"
Write-Log "OVERALL SECURITY SCORE: $Score / 100 ($Rating)" "OK"
Write-Log "Risk Distribution -> Critical: $CritCount | High: $HighCount | Medium: $MedCount | Low: $LowCount | Info: $InfoCount" "INFO"
Write-Log "==========================================================================" "HEADER"

# ==========================================================================
# REPORT GENERATION (JSON, TEXT, HTML DASHBOARD)
# ==========================================================================
Write-Log "Exporting reports to $OutputDir..." "INFO"

# 1. JSON Report
$JsonObj = [PSCustomObject]@{
    SystemInfo       = $SystemInfo
    NetworkStats     = $NetworkStats
    PortStats        = $PortStats
    DefenderStats    = $DefenderStats
    SecurityScore    = $Score
    SecurityRating   = $Rating
    RiskDistribution = @{ Critical = $CritCount; High = $HighCount; Medium = $MedCount; Low = $LowCount; Informational = $InfoCount }
    Findings         = $Findings
}
$JsonObj | ConvertTo-Json -Depth 5 | Out-File -FilePath $JsonReportPath -Encoding UTF8 -Force
Write-Log "JSON Telemetry saved: $JsonReportPath" "OK"

# 2. Text Report Append Findings
"\nDETAILED AUDIT FINDINGS:" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
foreach ($F in $Findings) {
    "--------------------------------------------------------------------------" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
    "Category:       $($F.Category)" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
    "Title:          $($F.Title)" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
    "Status:         $($F.Status) | Risk Level: $($F.RiskLevel)" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
    "Evidence:       $($F.Evidence)" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
    "Explanation:    $($F.Explanation)" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
    "Recommendation: $($F.Recommendation)" | Out-File -FilePath $TxtReportPath -Append -Encoding UTF8
}
Write-Log "Text Audit Log saved: $TxtReportPath" "OK"

# 3. HTML Executive Dashboard
$HtmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Audit Dashboard - $($SystemInfo['ComputerName'])</title>
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --muted: #94a3b8; --border: #334155; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 30px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border); padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { margin: 0; font-size: 26px; color: #38bdf8; }
        .header .meta { font-size: 14px; color: var(--muted); line-height: 1.6; }
        .score-panel { display: flex; align-items: center; justify-content: space-between; background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 30px; margin-bottom: 30px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }
        .gauge-wrap { text-align: center; }
        .gauge { width: 150px; height: 150px; border-radius: 50%; border: 12px solid $ScoreColor; display: flex; flex-direction: column; align-items: center; justify-content: center; margin: 0 auto 10px auto; }
        .gauge .val { font-size: 40px; font-weight: bold; color: $ScoreColor; line-height: 1; }
        .gauge .lbl { font-size: 12px; color: var(--muted); text-transform: uppercase; margin-top: 4px; }
        .rating-tag { font-size: 18px; font-weight: bold; color: $ScoreColor; text-transform: uppercase; letter-spacing: 1px; }
        .stats-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 15px; width: 70%; }
        .stat-box { background: #0f172a; border: 1px solid var(--border); border-radius: 8px; padding: 15px; text-align: center; }
        .stat-box .num { font-size: 28px; font-weight: bold; margin-bottom: 5px; }
        .stat-box .lbl { font-size: 12px; color: var(--muted); text-transform: uppercase; }
        .sys-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .sys-card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 20px; }
        .sys-card h3 { margin: 0 0 15px 0; font-size: 16px; color: #38bdf8; border-bottom: 1px solid var(--border); padding-bottom: 8px; }
        .sys-card p { margin: 8px 0; font-size: 14px; }
        .sys-card b { color: var(--muted); display: inline-block; width: 120px; }
        table { width: 100%; border-collapse: collapse; background: var(--card); border-radius: 10px; overflow: hidden; border: 1px solid var(--border); margin-bottom: 30px; }
        th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid var(--border); font-size: 14px; vertical-align: top; }
        th { background: #0f172a; color: #38bdf8; font-weight: 600; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; }
        tr:hover { background: #334155; }
        .badge { padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: bold; text-transform: uppercase; display: inline-block; }
        .badge-Critical { background: #991b1b; color: #fecaca; border: 1px solid #ef4444; }
        .badge-High { background: #c2410c; color: #ffedd5; border: 1px solid #f97316; }
        .badge-Medium { background: #a16207; color: #fef08a; border: 1px solid #eab308; }
        .badge-Low { background: #15803d; color: #dcfce7; border: 1px solid #22c55e; }
        .badge-Informational { background: #1d4ed8; color: #dbeafe; border: 1px solid #3b82f6; }
        .rec-text { color: #a7f3d0; font-weight: 500; }
        .ev-text { font-family: monospace; font-size: 12px; background: #0f172a; padding: 4px 8px; border-radius: 4px; color: #f8fafc; display: block; margin-top: 6px; word-break: break-all; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>🛡️ Windows Security & Forensic Audit Dashboard</h1>
            <div class="meta">Target System: <b>$($SystemInfo['ComputerName'])</b> | User: <b>$($SystemInfo['Username'])</b></div>
        </div>
        <div class="meta" style="text-align: right;">
            Scan Date: <b>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</b><br>
            Mode: <b>Read-Only Forensic Triage</b>
        </div>
    </div>

    <div class="score-panel">
        <div class="gauge-wrap">
            <div class="gauge">
                <div class="val">$Score</div>
                <div class="lbl">Score</div>
            </div>
            <div class="rating-tag">$Rating</div>
        </div>
        <div class="stats-grid">
            <div class="stat-box" style="border-top: 4px solid #ef4444;"><div class="num" style="color:#ef4444;">$CritCount</div><div class="lbl">Critical</div></div>
            <div class="stat-box" style="border-top: 4px solid #f97316;"><div class="num" style="color:#f97316;">$HighCount</div><div class="lbl">High Risk</div></div>
            <div class="stat-box" style="border-top: 4px solid #eab308;"><div class="num" style="color:#eab308;">$MedCount</div><div class="lbl">Medium</div></div>
            <div class="stat-box" style="border-top: 4px solid #22c55e;"><div class="num" style="color:#22c55e;">$LowCount</div><div class="lbl">Low Risk</div></div>
            <div class="stat-box" style="border-top: 4px solid #3b82f6;"><div class="num" style="color:#3b82f6;">$InfoCount</div><div class="lbl">Info</div></div>
        </div>
    </div>

    <div class="sys-grid">
        <div class="sys-card">
            <h3>💻 System Architecture</h3>
            <p><b>OS:</b> $($SystemInfo['OS'])</p>
            <p><b>Architecture:</b> $($SystemInfo['Architecture'])</p>
            <p><b>CPU:</b> $($SystemInfo['CPU'])</p>
            <p><b>RAM:</b> $($SystemInfo['RAM'])</p>
            <p><b>Uptime:</b> $($SystemInfo['Uptime'])</p>
        </div>
        <div class="sys-card">
            <h3>🌐 Network & DNS Posture</h3>
            <p><b>IP Address:</b> $($NetworkStats['IPAddresses'])</p>
            <p><b>Gateway:</b> $($NetworkStats['Gateways'])</p>
            <p><b>DNS Servers:</b> $($NetworkStats['DNSServers'])</p>
            <p><b>Active TCP Ports:</b> $($PortStats['TotalListeningPorts']) listeners</p>
            <p><b>Outbound Conns:</b> $($NetworkStats['EstablishedConnections']) established</p>
        </div>
        <div class="sys-card">
            <h3>🛡️ Microsoft Defender Health</h3>
            <p><b>Real-Time AV:</b> $(if ($DefenderStats['RealTimeProtection']) { '<span style="color:#22c55e;">ENABLED</span>' } else { '<span style="color:#ef4444;">DISABLED / UNKNOWN</span>' })</p>
            <p><b>Antivirus Engine:</b> $(if ($DefenderStats['AntivirusEnabled']) { 'Active' } else { 'Inactive / 3rd Party' })</p>
            <p><b>Behavior Monitor:</b> $(if ($DefenderStats['BehaviorMonitor']) { 'Active' } else { 'Disabled' })</p>
            <p><b>Signature Update:</b> $($DefenderStats['SignatureUpdated'])</p>
        </div>
    </div>

    <h2 style="font-size: 20px; color: #38bdf8; margin-bottom: 15px;">🔍 Detailed Forensic Findings & Remediation Plan</h2>
    <table>
        <thead>
            <tr>
                <th style="width: 12%;">Category</th>
                <th style="width: 23%;">Finding & Evidence</th>
                <th style="width: 10%;">Status</th>
                <th style="width: 10%;">Severity</th>
                <th style="width: 23%;">Risk Explanation</th>
                <th style="width: 22%;">Recommended Fix</th>
            </tr>
        </thead>
        <tbody>
"@

# Sort findings by severity (Critical -> High -> Medium -> Low -> Informational)
$SeverityOrder = @{ "Critical" = 1; "High" = 2; "Medium" = 3; "Low" = 4; "Informational" = 5 }
$SortedFindings = $Findings | Sort-Object { $SeverityOrder[$_.RiskLevel] }

foreach ($F in $SortedFindings) {
    $HtmlContent += @"
            <tr>
                <td><b>$($F.Category)</b></td>
                <td>
                    <div style="font-weight: 600; color: #f8fafc;">$($F.Title)</div>
                    <span class="ev-text">$($F.Evidence)</span>
                </td>
                <td>$($F.Status)</td>
                <td><span class="badge badge-$($F.RiskLevel)">$($F.RiskLevel)</span></td>
                <td style="color: #cbd5e1;">$($F.Explanation)</td>
                <td class="rec-text">$($F.Recommendation)</td>
            </tr>
"@
}

$HtmlContent += @"
        </tbody>
    </table>
    <div style="text-align: center; color: var(--muted); font-size: 13px; margin-top: 40px; border-top: 1px solid var(--border); padding-top: 20px;">
        Windows Security Audit Toolkit | Generated by Enterprise IT & Forensic Response Engine
    </div>
</body>
</html>
"@

$HtmlContent | Out-File -FilePath $HtmlReportPath -Encoding UTF8 -Force
Write-Log "HTML Executive Dashboard saved: $HtmlReportPath" "OK"

Write-Log "AUDIT COMPLETE! All reports generated in: $OutputDir" "HEADER"

# Auto-open HTML Dashboard if running interactively
if (-not $Silent -and (Test-Path $HtmlReportPath)) {
    try { Start-Process -FilePath $HtmlReportPath } catch { }
}
