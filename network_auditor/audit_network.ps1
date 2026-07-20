# Network Security & Port Exposure Auditor
# Compatible with Windows 7-11 & Windows Server 2008 R2-2025
# Analyzes active sockets, safety profiles, subnet inventory, and network performance.

$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for the current session/process
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Check if running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "  [ERROR] Administrative privileges are required to map ports to processes" -ForegroundColor Red
    Write-Host "  and create firewall block rules." -ForegroundColor Red
    Write-Host "  Please run this script as an Administrator." -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
    exit 1
}

# Ensure $PSScriptRoot is defined
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Centralized report directory handling
$ReportDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportDir = Join-Path $ParentDir "reports"
} else {
    $ReportDir = Join-Path $PSScriptRoot "reports"
}
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "       NETWORK SECURITY, SCANNER & DIAGNOSTICS AUDITOR" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  System: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
}

function Show-SectionHeader ($Title) {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "            $Title" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
}

# Helper to categorize security risks
function Get-SecurityProfile ($Port, $Protocol, $BindingAddress) {
    $InsecurePorts = @{
        21  = "FTP (Plaintext credentials transfer)"
        23  = "Telnet (Unencrypted remote terminal)"
        137 = "NetBIOS Name Service (Legacy spoofing-prone)"
        138 = "NetBIOS Datagram Service (Legacy spoofing-prone)"
        139 = "NetBIOS Session Service (Legacy spoofing-prone)"
    }

    $CautionPorts = @{
        22   = "SSH Remote Management"
        25   = "SMTP Mail Relay (Verify open relay)"
        80   = "HTTP Web service (Plaintext - upgrade to HTTPS)"
        135  = "RPC Endpoint Mapper (Exposed RPC services)"
        445  = "Microsoft-DS SMB (High ransomware vector)"
        1433 = "MSSQL Database Server"
        3389 = "Remote Desktop Protocol (RDP)"
        5985 = "WinRM HTTP remote management"
        5986 = "WinRM HTTPS remote management"
    }

    if ($InsecurePorts.ContainsKey($Port)) {
        return [PSCustomObject]@{
            Rating      = "UNSAFE"
            Color       = "Red"
            Description = $InsecurePorts[$Port]
            Suggestion  = "Disable legacy service or migrate to encrypted equivalents (e.g. SSH/SFTP)."
        }
    }

    if ($CautionPorts.ContainsKey($Port)) {
        if ($BindingAddress -match "127\.0\.0\.1|::1|localhost") {
            return [PSCustomObject]@{
                Rating      = "SAFE"
                Color       = "Green"
                Description = "$($CautionPorts[$Port]) (Localhost Bound)"
                Suggestion  = "Operating securely. Access restricted to loopback adapter only."
            }
        }
        return [PSCustomObject]@{
            Rating      = "CAUTION"
            Color       = "Yellow"
            Description = $CautionPorts[$Port]
            Suggestion  = "Restrict access to trusted IPs in Windows Firewall or use a secure VPN."
        }
    }

    if ($BindingAddress -match "127\.0\.0\.1|::1|localhost") {
        return [PSCustomObject]@{
            Rating      = "SAFE"
            Color       = "Green"
            Description = "Custom local application service"
            Suggestion  = "No external exposure. Securely restricted to this local system."
        }
    } else {
        return [PSCustomObject]@{
            Rating      = "CAUTION"
            Color       = "Yellow"
            Description = "Custom exposed application port"
            Suggestion  = "Verify process authenticity. Close or firewall-restrict if unrecognized."
        }
    }
}

Show-Header

# ===========================================================================
#  PARSE SOCKETS VIA NETSTAT (Guarantees backward compatibility)
# ===========================================================================
Write-Host "[+] Fetching current network connections state..." -ForegroundColor Cyan
$NetstatLines = cmd.exe /c "netstat -ano"

$ListeningPorts = @()
$OutboundConns  = @()

foreach ($Line in $NetstatLines) {
    $Tokens = $Line.Trim() -split "\s+"
    if ($Tokens.Count -ge 4 -and ($Tokens[0] -eq "TCP" -or $Tokens[0] -eq "UDP")) {
        $Proto          = $Tokens[0]
        $LocalAddress   = $Tokens[1]
        $ForeignAddress = $Tokens[2]
        $State  = "N/A"
        $Pid    = $null

        if ($Proto -eq "TCP") {
            $State = $Tokens[3]
            $Pid   = $Tokens[4]
        } else {
            $Pid = $Tokens[3]
        }

        $LocalPort = $null; $LocalIP = ""
        if ($LocalAddress -match "(\[[0-9a-fA-F:]+\]|[^:]+):(\d+)$") {
            $LocalIP   = $Matches[1]
            $LocalPort = [int]$Matches[2]
        }

        $RemotePort = $null; $RemoteIP = ""
        if ($ForeignAddress -match "(\[[0-9a-fA-F:]+\]|[^:]+):(\d+)$") {
            $RemoteIP   = $Matches[1]
            $RemotePort = [int]$Matches[2]
        }

        if (-not $LocalPort) { continue }

        $ProcName = "Unknown"
        if ($Pid -match "^\d+$" -and $Pid -ne 0) {
            $Proc = Get-Process -Id $Pid -ErrorAction SilentlyContinue
            if ($Proc) { $ProcName = $Proc.ProcessName }
        } elseif ($Pid -eq 0) {
            $ProcName = "Idle (System)"
        }

        if ($State -eq "LISTENING" -or ($Proto -eq "UDP" -and ($RemotePort -eq 0 -or $RemoteIP -match "0.0.0.0|\*|\[::\]"))) {
            $Key = "$Proto-$LocalPort-$LocalIP"
            if ($ListeningPorts.Key -notcontains $Key) {
                $Sec = Get-SecurityProfile $LocalPort $Proto $LocalIP
                $ListeningPorts += [PSCustomObject]@{
                    Key            = $Key
                    Protocol       = $Proto
                    Port           = $LocalPort
                    BindingAddress = $LocalIP
                    PID            = $Pid
                    ProcessName    = $ProcName
                    Rating         = $Sec.Rating
                    Description    = $Sec.Description
                    Suggestion     = $Sec.Suggestion
                    Color          = $Sec.Color
                }
            }
        } elseif ($State -eq "ESTABLISHED" -and $RemoteIP -notmatch "0.0.0.0|\*|::") {
            $OutboundConns += [PSCustomObject]@{
                Protocol    = $Proto
                LocalPort   = $LocalPort
                RemoteIP    = $RemoteIP
                RemotePort  = $RemotePort
                PID         = $Pid
                ProcessName = $ProcName
            }
        }
    }
}

Show-Header

# ===========================================================================
# AUDIT PHASE 1: WINDOWS DEFENDER FIREWALL STATUS
# ===========================================================================
Show-SectionHeader "AUDIT PHASE 1: WINDOWS DEFENDER FIREWALL STATUS"
try {
    $FwState = cmd.exe /c "netsh advfirewall show allprofiles state"
    $FwState | ForEach-Object {
        if ($_ -match "State\s+(ON|OFF|Active|Inactive)") {
            $Color = "Green"
            if ($_ -match "OFF") { $Color = "Red" }
            Write-Host "  $_" -ForegroundColor $Color
        } elseif ($_ -match "Profile") {
            Write-Host "  $_" -ForegroundColor White
        }
    }
} catch {
    Write-Host "  [WARN] Failed to query firewall state." -ForegroundColor Yellow
}
Write-Host ""

# ===========================================================================
# AUDIT PHASE 2: DNS & HOSTS FILE INTEGRITY CHECK
# ===========================================================================
Show-SectionHeader "AUDIT PHASE 2: DNS & HOSTS FILE INTEGRITY CHECK"
$DnsServers = @()
try {
    $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue
    foreach ($Adp in $Adapters) {
        if ($Adp.DNSServerSearchOrder) { $DnsServers += $Adp.DNSServerSearchOrder }
    }
} catch {}
$UniqueDns = $DnsServers | Select-Object -Unique
Write-Host "  Active DNS Servers:" -ForegroundColor White
$SafeDnsPatterns = "^8\.8\.8\.8|^8\.8\.4\.4|^1\.1\.1\.1|^1\.0\.0\.1|^9\.9\.9\.9|^149\.112\.112\.112|^208\.67\.222\.222|^208\.67\.220\.220|^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^169\.254\.|^::1|^127\.0\.0\.1"
foreach ($Dns in $UniqueDns) {
    if ($Dns -match $SafeDnsPatterns) {
        Write-Host "    -> $Dns [SAFE / RECOGNIZED]" -ForegroundColor Green
    } else {
        Write-Host "    -> $Dns [CAUTION / UNKNOWN PUBLIC SERVER]" -ForegroundColor Yellow
    }
}

$HostsPath = "C:\Windows\System32\drivers\etc\hosts"
if (Test-Path $HostsPath) {
    Write-Host "`n  Auditing Hosts File Override Mappings ($HostsPath):" -ForegroundColor White
    $HostsLines  = Get-Content $HostsPath
    $ActiveRules = @()
    foreach ($Line in $HostsLines) {
        $TLine = $Line.Trim()
        if ($TLine -and -not $TLine.StartsWith("#")) { $ActiveRules += $TLine }
    }
    if ($ActiveRules.Count -gt 0) {
        Write-Host "    [CAUTION] Custom redirection mappings found in hosts file:" -ForegroundColor Yellow
        foreach ($Rule in $ActiveRules) { Write-Host "      * $Rule" -ForegroundColor Yellow }
    } else {
        Write-Host "    [OK] Hosts file is clean (no active redirect mappings)." -ForegroundColor Green
    }
}
Write-Host ""

# ===========================================================================
# AUDIT PHASE 3: INCOMING LISTENING PORTS INVENTORY
# ===========================================================================
Show-SectionHeader "AUDIT PHASE 3: INCOMING LISTENING PORTS INVENTORY"
Write-Host ("{0,-6} {1,-6} {2,-20} {3,-20} {4,-10} {5,-10}" -f "Proto", "Port", "Binding IP", "Process Name", "PID", "Rating") -ForegroundColor White
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

foreach ($P in $ListeningPorts) {
    $Color = "White"
    if ($P.Rating -eq "UNSAFE")      { $Color = "Red" }
    elseif ($P.Rating -eq "CAUTION") { $Color = "Yellow" }
    elseif ($P.Rating -eq "SAFE")    { $Color = "Green" }
    Write-Host ("{0,-6} {1,-6} {2,-20} {3,-20} {4,-10} " -f $P.Protocol, $P.Port, $P.BindingAddress, $P.ProcessName, $P.PID) -NoNewline
    Write-Host ("{0,-10}" -f $P.Rating) -ForegroundColor $Color
}

# ===========================================================================
# AUDIT PHASE 4: ACTIVE OUTBOUND ESTABLISHED SESSIONS
# ===========================================================================
Show-SectionHeader "AUDIT PHASE 4: ACTIVE OUTBOUND ESTABLISHED SESSIONS"
Write-Host ("{0,-6} {1,-10} {2,-22} {3,-10} {4,-15} {5,-25}" -f "Proto", "LocalPort", "Remote IP", "RemotePort", "Process Name", "Resolved Hostname") -ForegroundColor White
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

if (-not $Script:ResolvedCache) { $Script:ResolvedCache = @{} }

$OutboundConns | Select-Object -First 15 | ForEach-Object {
    $RemoteIP     = $_.RemoteIP
    $ResolvedHost = "Unresolved"
    if ($Script:ResolvedCache.ContainsKey($RemoteIP)) {
        $ResolvedHost = $Script:ResolvedCache[$RemoteIP]
    } else {
        try {
            $AsyncResult = [System.Net.Dns]::BeginGetHostEntry($RemoteIP, $null, $null)
            $Wait = $AsyncResult.AsyncWaitHandle.WaitOne(800)
            if ($Wait) {
                $HostEntry    = [System.Net.Dns]::EndGetHostEntry($AsyncResult)
                $ResolvedHost = $HostEntry.HostName
            } else {
                $ResolvedHost = "DNS Timeout"
            }
        } catch { $ResolvedHost = "Unresolved" }
        $Script:ResolvedCache[$RemoteIP] = $ResolvedHost
    }
    $DispHost = if ($ResolvedHost.Length -gt 25) { $ResolvedHost.Substring(0, 22) + "..." } else { $ResolvedHost }
    Write-Host ("{0,-6} {1,-10} {2,-22} {3,-10} {4,-15} {5,-25}" -f $_.Protocol, $_.LocalPort, $_.RemoteIP, $_.RemotePort, $_.ProcessName, $DispHost) -ForegroundColor DarkCyan
}
if ($OutboundConns.Count -gt 15) {
    Write-Host "  ... and $($OutboundConns.Count - 15) more outbound sessions." -ForegroundColor DarkGray
}

# Export port audit to CSV
$CsvPath = Join-Path $ReportDir "network_security_report_$($env:COMPUTERNAME).csv"
$ListeningPorts | Select-Object Protocol, Port, BindingAddress, PID, ProcessName, Rating, Description, Suggestion |
    Export-Csv -Path $CsvPath -NoTypeInformation -Force -Encoding UTF8
Write-Host "`n[+] Full port audit report exported to: $CsvPath" -ForegroundColor Green

# ===========================================================================
# REMEDIATION PHASE: INTERACTIVE PORT REMEDIATION
# ===========================================================================
Show-SectionHeader "REMEDIATION: INTERACTIVE PORT REMEDIATION"
$NonSafePorts = $ListeningPorts | Where-Object { $_.Rating -ne "SAFE" }

if ($NonSafePorts) {
    Write-Host "Found $($NonSafePorts.Count) exposed/caution/unsafe port bindings." -ForegroundColor Yellow

    foreach ($P in $NonSafePorts) {
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Exposed Socket: $($P.Protocol) Local Port $($P.Port) (PID: $($P.PID) | Process: $($P.ProcessName))" -ForegroundColor Cyan
        Write-Host "Security Rating: $($P.Rating)" -ForegroundColor Yellow
        Write-Host "Description    : $($P.Description)" -ForegroundColor DarkGray
        Write-Host "Recommendation : $($P.Suggestion)" -ForegroundColor DarkGray
        Write-Host ""

        $CloseAns = Read-Host "Do you want to close/remediate Port $($P.Port)? (Y/N)"
        if ($CloseAns -eq "Y" -or $CloseAns -eq "y") {
            $IsSystemProc = $false
            if ($P.ProcessName -match "System|lsass|svchost|services|wininit|csrss|smss") {
                $IsSystemProc = $true
                Write-Host "`n[!] CRITICAL WARNING: This port is owned by a core Windows System process ($($P.ProcessName))." -ForegroundColor Red
                Write-Host "    Terminating this process WILL cause a system crash or reboot." -ForegroundColor Red
                Write-Host "    It is strongly advised to choose FIREWALL BLOCK [B] instead." -ForegroundColor Red
            }

            $Action = Read-Host "`nChoose remediation: [K]ill Process, [B]lock in Firewall, or [C]ancel"

            if ($Action -eq "K" -or $Action -eq "k") {
                if ($IsSystemProc) {
                    $ConfirmSystem = Read-Host "Type 'CONFIRM' to force-terminate system process"
                    if ($ConfirmSystem -ne "CONFIRM") { Write-Host "Aborted." -ForegroundColor Yellow; continue }
                }
                Write-Host "[+] Stopping PID $($P.PID) ($($P.ProcessName))..." -ForegroundColor Cyan
                Stop-Process -Id $P.PID -Force
                Start-Sleep -Seconds 1
                $ProcCheck = Get-Process -Id $P.PID -ErrorAction SilentlyContinue
                if (-not $ProcCheck) {
                    Write-Host "`n[OK] Process terminated. Port $($P.Port) is closed." -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Process still running." -ForegroundColor Red
                }
            } elseif ($Action -eq "B" -or $Action -eq "b") {
                Write-Host "[+] Creating inbound firewall block for Port $($P.Port)..." -ForegroundColor Cyan
                $RuleName = "IT-Toolkit-Blocked-Port-$($P.Port)"
                $Status   = $false
                if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
                    try {
                        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -LocalPort $P.Port `
                            -Protocol $P.Protocol -Action Block -ErrorAction Stop | Out-Null
                        $Status = $true
                    } catch {
                        Write-Host "Cmdlet failed. Trying legacy netsh..." -ForegroundColor Yellow
                    }
                }
                if (-not $Status) {
                    try {
                        cmd.exe /c "netsh advfirewall firewall add rule name=`"$RuleName`" dir=in action=block protocol=$($P.Protocol) localport=$($P.Port)" | Out-Null
                        $Status = $true
                    } catch { Write-Host "Firewall modification failed: $($_.Exception.Message)" -ForegroundColor Red }
                }
                if ($Status) {
                    Write-Host "`n[OK] Firewall block rule '$RuleName' applied!" -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Failed to create firewall rule." -ForegroundColor Red
                }
            } else {
                Write-Host "Remediation cancelled." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Skipped." -ForegroundColor DarkYellow
        }
    }
} else {
    Write-Host "`n[+] No exposed or unsafe ports detected. Network profile looks solid!" -ForegroundColor Green
}

# ===========================================================================
# AUDIT PHASE 5: SUBNET IP & PORT SCANNER
# ===========================================================================
Show-SectionHeader "AUDIT PHASE 5: SUBNET IP & PORT SCANNER"
Write-Host "  Discovers live hosts in a subnet and checks management port exposure." -ForegroundColor DarkGray
Write-Host ""

# Auto-detect local subnet
$LocalSubnet = $null
try {
    $ActiveAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -match "^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" } |
        Select-Object -First 1
    if ($ActiveAdapters -and $ActiveAdapters.IPAddress) {
        $LocalIP     = ($ActiveAdapters.IPAddress | Where-Object { $_ -match "\." } | Select-Object -First 1)
        $Parts       = $LocalIP -split "\."
        $LocalSubnet = "$($Parts[0]).$($Parts[1]).$($Parts[2]).0/24"
    }
} catch {}
if (-not $LocalSubnet) { $LocalSubnet = "192.168.1.0/24" }

Write-Host "  Auto-detected Subnet: $LocalSubnet" -ForegroundColor Cyan
$SubnetInput = Read-Host "  Enter subnet to scan (or press Enter for detected subnet)"
if ($SubnetInput.Trim() -ne "") { $LocalSubnet = $SubnetInput.Trim() }

# Parse subnet base
$SubnetBase   = $LocalSubnet -replace "/\d+$", ""
$SubnetParts  = $SubnetBase -split "\."
$SubnetPrefix = "$($SubnetParts[0]).$($SubnetParts[1]).$($SubnetParts[2])"
$Cidr         = 24
if ($LocalSubnet -match "/(\d+)$") { $Cidr = [int]$Matches[1] }
$HostBits   = 32 - $Cidr
$TotalHosts = [math]::Pow(2, $HostBits) - 2
if ($TotalHosts -gt 254) { $TotalHosts = 254 }

# Management ports to check
$ManagementPorts = @{
    22   = "SSH"
    23   = "Telnet"
    80   = "HTTP"
    443  = "HTTPS"
    445  = "SMB"
    3389 = "RDP"
    5985 = "WinRM"
    8080 = "HTTP-Alt"
    1433 = "MSSQL"
    3306 = "MySQL"
}

Write-Host ""
Write-Host "  [+] Launching parallel ping sweep across $TotalHosts hosts in $LocalSubnet..." -ForegroundColor Cyan
Write-Host "  [*] This may take 5-20 seconds..." -ForegroundColor DarkGray
Write-Host ""

# Parallel async ping sweep
$PingTasks = @{}
$PingObjs  = @{}
for ($i = 1; $i -le $TotalHosts; $i++) {
    $TargetIP          = "$SubnetPrefix.$i"
    $PingObj           = New-Object System.Net.NetworkInformation.Ping
    $PingObjs[$TargetIP] = $PingObj
    try { $PingTasks[$TargetIP] = $PingObj.SendPingAsync($TargetIP, 1500) } catch {}
}

# Collect alive hosts
$AliveHosts = @()
foreach ($IP in $PingTasks.Keys) {
    try {
        $Task = $PingTasks[$IP]
        $Task.Wait(2000) | Out-Null
        $Reply = $Task.Result
        if ($Reply -and $Reply.Status -eq "Success") { $AliveHosts += $IP }
    } catch {}
}

# Sort IPs numerically
$AliveHosts = $AliveHosts | Sort-Object { [version]$_ }

Write-Host ("  {0,-18} {1,-30} {2}" -f "IP Address", "Hostname", "Open Ports") -ForegroundColor White
Write-Host "  --------------------------------------------------------------------------" -ForegroundColor DarkGray

$ScanResults = @()

foreach ($HostIP in $AliveHosts) {
    # Reverse DNS
    $HostName = "Unresolved"
    try {
        $DnsResult = [System.Net.Dns]::GetHostEntry($HostIP)
        $HostName  = $DnsResult.HostName
    } catch {}

    # TCP port probes
    $OpenPortLabels = @()
    foreach ($PortNum in ($ManagementPorts.Keys | Sort-Object)) {
        try {
            $Tcp  = New-Object System.Net.Sockets.TcpClient
            $Conn = $Tcp.BeginConnect($HostIP, $PortNum, $null, $null)
            $Wait = $Conn.AsyncWaitHandle.WaitOne(300)
            if ($Wait -and $Tcp.Connected) { $OpenPortLabels += "$PortNum/$($ManagementPorts[$PortNum])" }
            $Tcp.Close()
        } catch {}
    }

    $OpenPortsStr  = if ($OpenPortLabels.Count -gt 0) { $OpenPortLabels -join ", " } else { "None detected" }
    $HostNameShort = if ($HostName.Length -gt 28) { $HostName.Substring(0, 25) + "..." } else { $HostName }

    $PortColor = "DarkGray"
    if ($OpenPortLabels -match "23/Telnet")   { $PortColor = "Red" }
    elseif ($OpenPortLabels.Count -gt 0)      { $PortColor = "Yellow" }

    Write-Host ("  {0,-18} {1,-30} " -f $HostIP, $HostNameShort) -NoNewline -ForegroundColor Cyan
    Write-Host $OpenPortsStr -ForegroundColor $PortColor

    $ScanResults += [PSCustomObject]@{
        IPAddress = $HostIP
        Hostname  = $HostName
        OpenPorts = $OpenPortsStr
    }
}

Write-Host ""
if ($AliveHosts.Count -eq 0) {
    Write-Host "  [!] No live hosts found in $LocalSubnet (ICMP may be blocked by host firewalls)." -ForegroundColor Yellow
} else {
    Write-Host "  [+] Found $($AliveHosts.Count) live host(s) in subnet $LocalSubnet." -ForegroundColor Green
}

# Export subnet scan CSV
$ScanCsvPath = Join-Path $ReportDir "subnet_scan_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
$ScanResults | Export-Csv -Path $ScanCsvPath -NoTypeInformation -Force -Encoding UTF8
Write-Host "  [+] Subnet scan report saved to: $ScanCsvPath" -ForegroundColor Green

# ===========================================================================
# AUDIT PHASE 6: NETWORK LATENCY & DNS PERFORMANCE DIAGNOSTICS
# ===========================================================================
Show-SectionHeader "AUDIT PHASE 6: NETWORK LATENCY & DNS PERFORMANCE DIAGNOSTICS"
Write-Host "  Benchmarks ping latency, packet loss, and DNS query speeds." -ForegroundColor DarkGray
Write-Host ""

# Detect default gateway
$DefaultGateway = $null
try {
    $GwAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue |
        Where-Object { $_.DefaultIPGateway } | Select-Object -First 1
    if ($GwAdapter) { $DefaultGateway = ($GwAdapter.DefaultIPGateway | Select-Object -First 1) }
} catch {}
if (-not $DefaultGateway) { $DefaultGateway = "192.168.1.1" }

$LanDns = ($UniqueDns | Select-Object -First 1)
if (-not $LanDns) { $LanDns = "8.8.8.8" }

$PingTargets = [ordered]@{
    "Default Gateway" = $DefaultGateway
    "LAN DNS"         = $LanDns
    "Google DNS"      = "8.8.8.8"
    "Cloudflare DNS"  = "1.1.1.1"
    "Quad9 DNS"       = "9.9.9.9"
}

Write-Host "  [+] Running 10-packet ping audit against key endpoints..." -ForegroundColor Cyan
Write-Host ""
Write-Host ("  {0,-20} {1,-18} {2,-10} {3,-10} {4,-12} {5}" -f "Target", "IP", "Min(ms)", "Max(ms)", "Avg(ms)", "Packet Loss") -ForegroundColor White
Write-Host "  --------------------------------------------------------------------------" -ForegroundColor DarkGray

$DiagResults = @()

foreach ($TargetName in $PingTargets.Keys) {
    $TargetAddr = $PingTargets[$TargetName]
    $Latencies  = @()
    $Lost       = 0
    $PingInst   = New-Object System.Net.NetworkInformation.Ping

    for ($p = 1; $p -le 10; $p++) {
        try {
            $Reply = $PingInst.Send($TargetAddr, 2000)
            if ($Reply -and $Reply.Status -eq "Success") {
                $Latencies += $Reply.RoundtripTime
            } else { $Lost++ }
        } catch { $Lost++ }
        Start-Sleep -Milliseconds 100
    }

    if ($Latencies.Count -gt 0) {
        $Min  = ($Latencies | Measure-Object -Minimum).Minimum
        $Max  = ($Latencies | Measure-Object -Maximum).Maximum
        $Avg  = [math]::Round(($Latencies | Measure-Object -Average).Average, 1)
        $Loss = "$Lost/10 ($([math]::Round($Lost * 10, 0))%)"
        $Color = "Green"
        if ($Lost -ge 5)               { $Color = "Red" }
        elseif ($Avg -gt 100 -or $Lost -ge 1) { $Color = "Yellow" }
        Write-Host ("  {0,-20} {1,-18} {2,-10} {3,-10} {4,-12} {5}" -f $TargetName, $TargetAddr, $Min, $Max, $Avg, $Loss) -ForegroundColor $Color
        $DiagResults += [PSCustomObject]@{ Target = $TargetName; IP = $TargetAddr; Min_ms = $Min; Max_ms = $Max; Avg_ms = $Avg; PacketLoss = $Loss }
    } else {
        Write-Host ("  {0,-20} {1,-18} {2,-10} {3,-10} {4,-12} {5}" -f $TargetName, $TargetAddr, "N/A", "N/A", "N/A", "10/10 (100%)") -ForegroundColor Red
        $DiagResults += [PSCustomObject]@{ Target = $TargetName; IP = $TargetAddr; Min_ms = "N/A"; Max_ms = "N/A"; Avg_ms = "N/A"; PacketLoss = "10/10 (100%)" }
    }
}

# ---- DNS Benchmark ----
Write-Host ""
Write-Host "  [+] DNS Resolution Speed Benchmark (5 queries per resolver)..." -ForegroundColor Cyan
Write-Host ""

$DnsResolvers = [ordered]@{
    "Local DNS"      = $LanDns
    "Google DNS"     = "8.8.8.8"
    "Cloudflare DNS" = "1.1.1.1"
    "Quad9 DNS"      = "9.9.9.9"
    "OpenDNS"        = "208.67.222.222"
}

$DnsTestDomains = @("google.com", "microsoft.com", "github.com", "cloudflare.com", "amazon.com")

Write-Host ("  {0,-20} {1,-16} {2}" -f "DNS Resolver", "IP", "Avg Resolution (ms)") -ForegroundColor White
Write-Host "  --------------------------------------------------------------------------" -ForegroundColor DarkGray

$DnsBenchResults = @()

foreach ($ResolverName in $DnsResolvers.Keys) {
    $ResolverIP = $DnsResolvers[$ResolverName]
    $QueryTimes = @()

    foreach ($Domain in $DnsTestDomains) {
        $Watch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $NsOutput = cmd.exe /c "nslookup $Domain $ResolverIP 2>&1"
            $Watch.Stop()
            if ($NsOutput -match "Address") { $QueryTimes += $Watch.ElapsedMilliseconds }
        } catch { $Watch.Stop() }
    }

    if ($QueryTimes.Count -gt 0) {
        $AvgMs = [math]::Round(($QueryTimes | Measure-Object -Average).Average, 1)
        $Color = "Green"
        if ($AvgMs -gt 200) { $Color = "Red" }
        elseif ($AvgMs -gt 80) { $Color = "Yellow" }
        Write-Host ("  {0,-20} {1,-16} {2} ms" -f $ResolverName, $ResolverIP, $AvgMs) -ForegroundColor $Color
        $DnsBenchResults += [PSCustomObject]@{ Resolver = $ResolverName; IP = $ResolverIP; Avg_ms = $AvgMs }
    } else {
        Write-Host ("  {0,-20} {1,-16} UNREACHABLE" -f $ResolverName, $ResolverIP) -ForegroundColor Red
        $DnsBenchResults += [PSCustomObject]@{ Resolver = $ResolverName; IP = $ResolverIP; Avg_ms = "UNREACHABLE" }
    }
}

# ---- Traceroute (first 6 hops) ----
Write-Host ""
Write-Host "  [+] Quick Traceroute to 8.8.8.8 (first 6 hops)..." -ForegroundColor Cyan
Write-Host ""
$TraceLines = cmd.exe /c "tracert -d -h 6 8.8.8.8 2>&1"
foreach ($TL in $TraceLines) {
    if ($TL -match "^\s+\d+") {
        if ($TL -match "\*\s+\*\s+\*")  { Write-Host "  $TL" -ForegroundColor DarkGray }
        elseif ($TL -match "(\d+)\s+ms") { Write-Host "  $TL" -ForegroundColor Cyan }
        else                             { Write-Host "  $TL" -ForegroundColor DarkGray }
    }
}

# Save diagnostics text report
$DiagTxtPath = Join-Path $ReportDir "network_diagnostics_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
$DiagReport  = @()
$DiagReport += "NETWORK DIAGNOSTICS REPORT"
$DiagReport += "System: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$DiagReport += "======================================================================"
$DiagReport += ""
$DiagReport += "LATENCY AUDIT:"
$DiagResults | ForEach-Object { $DiagReport += "  $($_.Target) [$($_.IP)] | Avg: $($_.Avg_ms)ms | Loss: $($_.PacketLoss)" }
$DiagReport += ""
$DiagReport += "DNS BENCHMARK:"
$DnsBenchResults | ForEach-Object { $DiagReport += "  $($_.Resolver) [$($_.IP)] | Avg: $($_.Avg_ms)ms" }
$DiagReport | Set-Content -Path $DiagTxtPath -Encoding UTF8 -Force
Write-Host ""
Write-Host "  [+] Diagnostics report saved to: $DiagTxtPath" -ForegroundColor Green

# ===========================================================================
# COMPLETION
# ===========================================================================
Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "         NETWORK SECURITY & DIAGNOSTICS AUDIT COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Reports generated in: $ReportDir" -ForegroundColor DarkCyan
Write-Host "    -> network_security_report_$($env:COMPUTERNAME).csv" -ForegroundColor DarkGray
Write-Host "    -> subnet_scan_$($env:COMPUTERNAME)_*.csv" -ForegroundColor DarkGray
Write-Host "    -> network_diagnostics_$($env:COMPUTERNAME)_*.txt" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor DarkGray; [void](Read-Host)
