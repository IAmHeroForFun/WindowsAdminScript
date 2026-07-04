<#
.SYNOPSIS
    Option [11]: Advanced Network Mapper & Topology Discovery Tool
.DESCRIPTION
    SolarWinds & PRTG-style subnet discovery tool. Performs multi-threaded ICMP sweeps, DNS resolution, MAC address OUI vendor lookup, TCP port scanning (12 core ports), and heuristic OS fingerprinting (Windows, Linux, Router, Printer, NAS). Exports CSV, JSON, and an interactive HTML network topology diagram.
.AUTHOR
    Antigravity Network Architecture Team
#>

[CmdletBinding()]
param (
    [string]$Subnet,
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

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       ADVANCED NETWORK MAPPER & TOPOLOGY DISCOVERY TOOL [OPTION 11]" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Target System: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan

# Auto-detect local subnet if not provided
if (-not $Subnet) {
    $NIC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Where-Object { $_.DefaultIPGateway -ne $null } | Select-Object -First 1
    if ($NIC -and $NIC.IPAddress[0]) {
        $LocalIP = $NIC.IPAddress[0]
        $IPParts = $LocalIP -split '\.'
        $Subnet = "$($IPParts[0]).$($IPParts[1]).$($IPParts[2])"
    } else {
        $Subnet = "192.168.1"
    }
}

if (-not $NonInteractive) {
    $InputSubnet = Read-Host "`nEnter target subnet prefix (e.g., 192.168.1 or 10.0.0) [$Subnet]"
    if ($InputSubnet -match '^\d{1,3}\.\d{1,3}\.\d{1,3}$') { $Subnet = $InputSubnet }
}

Write-Host "`n[Phase 1/4] Initiating Multi-Threaded ICMP Ping Sweep across $Subnet.1 - $Subnet.254..." -ForegroundColor Yellow

# Built-in OUI Vendor Dictionary
$OUIMap = @{
    "00-05-69" = "VMware"; "00-0C-29" = "VMware"; "00-50-56" = "VMware"; "00-15-5D" = "Microsoft Hyper-V"
    "00-14-22" = "Dell"; "00-1E-4F" = "Dell"; "18-66-DA" = "Dell"; "F8-BC-12" = "Dell"
    "00-17-A4" = "HP / Hewlett-Packard"; "00-1E-0B" = "HP"; "3C-D9-2B" = "HP"; "94-57-A5" = "HP"
    "00-03-47" = "Intel"; "00-1B-21" = "Intel"; "A0-36-9F" = "Intel"; "88-AE-1D" = "Intel"
    "00-01-42" = "Cisco"; "00-03-6B" = "Cisco"; "00-1A-A1" = "Cisco"; "64-D9-89" = "Cisco"
    "00-1D-AA" = "Apple"; "28-CF-E9" = "Apple"; "A8-66-7F" = "Apple"; "F0-18-98" = "Apple"
    "00-11-32" = "Synology NAS"; "00-08-9B" = "QNAP NAS"; "00-26-BA" = "Netgear"; "C0-3F-0E" = "Netgear"
    "24-A4-3C" = "Ubiquiti Networks"; "74-83-C2" = "Ubiquiti"; "E0-63-DA" = "Ubiquiti"; "F0-9F-C2" = "Ubiquiti"
    "00-00-48" = "Epson Printer"; "00-01-E6" = "HP Printer"; "00-80-77" = "Brother Printer"; "00-20-6B" = "Konica Minolta"
}

# Multi-threaded ping sweep using PowerShell background jobs
$Jobs = @()
for ($i = 1; $i -le 254; $i++) {
    $TargetIP = "$Subnet.$i"
    $Jobs += Test-Connection -ComputerName $TargetIP -Count 1 -BufferSize 32 -TimeoutSeconds 1 -AsJob
}

Write-Host " -> Waiting for 254 concurrent ping threads to finish..." -ForegroundColor DarkGray
$PingResults = $Jobs | Receive-Job -Wait -AutoRemoveJob

$LiveHosts = @()
foreach ($Res in $PingResults) {
    if ($Res.ResponseTime -ne $null) {
        $LiveHosts += [PSCustomObject]@{
            IP = $Res.Address
            ResponseTimeMs = $Res.ResponseTime
        }
    }
}

# Always ensure local machine and gateway are in list if missed
if ($NIC -and $NIC.IPAddress[0] -notin $LiveHosts.IP) {
    $LiveHosts += [PSCustomObject]@{ IP = $NIC.IPAddress[0]; ResponseTimeMs = 0 }
}

Write-Host " -> Discovered $($LiveHosts.Count) active devices online!" -ForegroundColor Green

# ---------------------------------------------------------
# PHASE 2: HOSTNAME RESOLUTION, MAC DISCOVERY & PORT SCAN
# ---------------------------------------------------------
Write-Host "`n[Phase 2/4] Resolving Hostnames, MAC Address OUI Vendors & Scanning 12 Core TCP Ports..." -ForegroundColor Yellow

$CorePorts = @(21, 22, 25, 53, 80, 135, 139, 443, 445, 3389, 5985, 1433)
$PortNames = @{
    21="FTP"; 22="SSH"; 25="SMTP"; 53="DNS"; 80="HTTP"; 135="RPC"; 139="NetBIOS"; 443="HTTPS"; 445="SMB"; 3389="RDP"; 5985="WinRM"; 1433="SQL"
}

# Populate ARP table by sending ping
$ArpTable = cmd.exe /c "arp -a"

function Get-MacFromArp($IPAddr) {
    foreach ($Line in $ArpTable) {
        if ($Line -match "^\s+$([regex]::Escape($IPAddr))\s+([0-9a-fA-F\-]{17})\s+") {
            return $Matches[2].ToUpper()
        }
    }
    return "N/A"
}

$DiscoveredDevices = New-Object System.Collections.ArrayList

foreach ($HostObj in $LiveHosts) {
    $IP = $HostObj.IP
    $PingMs = $HostObj.ResponseTimeMs
    
    # Hostname & Reverse DNS
    $Hostname = "Unknown"
    try {
        $DnsRes = [System.Net.Dns]::GetHostEntry($IP)
        if ($DnsRes -and $DnsRes.HostName) { $Hostname = $DnsRes.HostName }
    } catch { }
    
    # MAC & Vendor
    $MAC = Get-MacFromArp $IP
    if ($IP -eq $NIC.IPAddress[0] -and $NIC.MACAddress) { $MAC = $NIC.MACAddress }
    $Vendor = "Unknown Vendor"
    if ($MAC -ne "N/A" -and $MAC.Length -ge 8) {
        $Prefix = $MAC.Substring(0, 8)
        if ($OUIMap.ContainsKey($Prefix)) {
            $Vendor = $OUIMap[$Prefix]
        } else {
            $Vendor = "Standard IEEE Device"
        }
    }
    
    # TCP Port Scan
    $OpenPorts = @()
    foreach ($Port in $CorePorts) {
        try {
            $Socket = New-Object System.Net.Sockets.TcpClient
            $Connect = $Socket.BeginConnect($IP, $Port, $null, $null)
            $Success = $Connect.AsyncWaitHandle.WaitOne(150, $false)
            if ($Success -and $Socket.Connected) {
                $OpenPorts += "$Port ($($PortNames[$Port]))"
            }
            $Socket.Close()
        } catch { }
    }
    $OpenPortsStr = if ($OpenPorts.Count -gt 0) { $OpenPorts -join ", " } else { "None detected" }
    
    # Heuristic OS Fingerprinting
    $DeviceType = "Unknown Device"
    if ($OpenPortsStr -like "*445*" -or $OpenPortsStr -like "*3389*" -or $OpenPortsStr -like "*5985*") {
        $DeviceType = if ($OpenPortsStr -like "*1433*" -or $OpenPortsStr -like "*53*") { "Windows Server" } else { "Windows Workstation / Server" }
    } elseif ($OpenPortsStr -like "*22*" -and $OpenPortsStr -notlike "*445*") {
        $DeviceType = "Linux / Unix System"
    } elseif ($OpenPortsStr -like "*80*" -or $OpenPortsStr -like "*443*") {
        if ($Vendor -like "*Cisco*" -or $Vendor -like "*Ubiquiti*" -or $Vendor -like "*Netgear*") {
            $DeviceType = "Network Router / Access Point / Switch"
        } elseif ($Vendor -like "*Synology*" -or $Vendor -like "*QNAP*") {
            $DeviceType = "NAS Storage Appliance"
        } elseif ($Vendor -like "*HP*" -or $Vendor -like "*Epson*" -or $Vendor -like "*Brother*") {
            $DeviceType = "Network Printer"
        } else {
            $DeviceType = "Web Enabled Device / IoT"
        }
    } elseif ($Vendor -like "*VMware*" -or $Vendor -like "*Hyper-V*") {
        $DeviceType = "Virtual Machine Guest"
    }
    
    if ($IP -eq $NIC.IPAddress[0]) { $DeviceType = "Local Administration System ($DeviceType)" }
    
    Write-Host "   [$IP] -> $Hostname | $MAC ($Vendor) | Type: $DeviceType | Ports: $OpenPortsStr" -ForegroundColor Cyan
    
    $DevObj = New-Object PSObject -Property @{
        IPAddress = $IP
        Hostname = $Hostname
        MACAddress = $MAC
        Vendor = $Vendor
        DeviceType = $DeviceType
        PingLatencyMs = $PingMs
        OpenTCPPorts = $OpenPortsStr
    }
    [void]$DiscoveredDevices.Add($DevObj)
}

# ---------------------------------------------------------
# PHASE 3: EXPORT CSV & JSON TOPOLOGY DATA
# ---------------------------------------------------------
Write-Host "`n[Phase 3/4] Exporting Data Sheets to CSV & JSON Topology Format..." -ForegroundColor Yellow

$CsvPath = Join-Path $ReportsDir "discovered_devices.csv"
$JsonPath = Join-Path $ReportsDir "topology.json"

$DiscoveredDevices | Select-Object IPAddress, Hostname, MACAddress, Vendor, DeviceType, PingLatencyMs, OpenTCPPorts | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
$DiscoveredDevices | ConvertTo-Json -Depth 3 | Out-File -FilePath $JsonPath -Encoding UTF8 -Force

Write-Host " -> Saved spreadsheet: reports\discovered_devices.csv" -ForegroundColor Green
Write-Host " -> Saved JSON topology: reports\topology.json" -ForegroundColor Green

# ---------------------------------------------------------
# PHASE 4: INTERACTIVE HTML TOPOLOGY DASHBOARD
# ---------------------------------------------------------
Write-Host "`n[Phase 4/4] Generating Interactive HTML Network Topology Dashboard..." -ForegroundColor Yellow
$HtmlPath = Join-Path $ReportsDir "network_dashboard.html"

$WinCount = @($DiscoveredDevices | Where-Object { $_.DeviceType -like "*Windows*" }).Count
$LinCount = @($DiscoveredDevices | Where-Object { $_.DeviceType -like "*Linux*" }).Count
$NetCount = @($DiscoveredDevices | Where-Object { $_.DeviceType -like "*Router*" -or $_.DeviceType -like "*Switch*" }).Count
$OthCount = $DiscoveredDevices.Count - ($WinCount + $LinCount + $NetCount)

$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Network Topology & Subnet Map - $Subnet.0/24</title>
    <style>
        :root { --bg: #0b0f19; --card: #151e32; --text: #f1f5f9; --muted: #94a3b8; --border: #2a3756; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 25px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border); padding-bottom: 15px; margin-bottom: 25px; }
        .header h1 { margin: 0; font-size: 24px; color: #38bdf8; }
        .header .meta { font-size: 14px; color: var(--muted); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin-bottom: 30px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 15px; text-align: center; }
        .card h3 { margin: 0; font-size: 12px; color: var(--muted); text-transform: uppercase; }
        .card .val { font-size: 28px; font-weight: bold; margin: 8px 0; color: #38bdf8; }
        .topology-box { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 30px; }
        .topology-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 15px; margin-top: 15px; }
        .node-card { background: #0f172a; border: 2px solid var(--border); border-radius: 8px; padding: 15px; position: relative; transition: transform 0.2s; }
        .node-card:hover { transform: translateY(-3px); border-color: #38bdf8; }
        .node-ip { font-size: 16px; font-weight: bold; color: #38bdf8; display: flex; justify-content: space-between; align-items: center; }
        .node-host { font-size: 13px; color: #e2e8f0; margin-top: 5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .node-meta { font-size: 11px; color: var(--muted); margin-top: 8px; line-height: 1.5; }
        .type-tag { font-size: 10px; padding: 2px 6px; border-radius: 4px; font-weight: bold; text-transform: uppercase; }
        .type-Windows { background: #1e40af; color: #dbeafe; border-color: #3b82f6; }
        .type-Linux { background: #854d0e; color: #fef08a; border-color: #eab308; }
        .type-Router { background: #166534; color: #dcfce7; border-color: #22c55e; }
        .type-Other { background: #475569; color: #f8fafc; border-color: #94a3b8; }
        table { width: 100%; border-collapse: collapse; background: var(--card); border-radius: 10px; overflow: hidden; border: 1px solid var(--border); }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid var(--border); font-size: 13px; }
        th { background: #0f172a; color: #38bdf8; font-weight: 600; text-transform: uppercase; font-size: 11px; }
        tr:hover { background: #1e293b; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>[NETWORK MAPPER] Subnet Topology & Asset Discovery</h1>
            <div class="meta">Subnet Scanned: <b>$Subnet.0/24</b> | Total Active Devices: <b>$($DiscoveredDevices.Count)</b></div>
        </div>
        <div class="meta">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>Mode: Offline Interactive Map</div>
    </div>

    <div class="grid">
        <div class="card"><h3>Total Online</h3><div class="val">$($DiscoveredDevices.Count)</div></div>
        <div class="card"><h3>Windows Systems</h3><div class="val" style="color:#60a5fa;">$WinCount</div></div>
        <div class="card"><h3>Linux / Unix</h3><div class="val" style="color:#facc15;">$LinCount</div></div>
        <div class="card"><h3>Routers / Switches</h3><div class="val" style="color:#4ade80;">$NetCount</div></div>
        <div class="card"><h3>Printers / IoT / NAS</h3><div class="val" style="color:#cbd5e1;">$OthCount</div></div>
    </div>

    <div class="topology-box">
        <h2 style="font-size:16px;color:#38bdf8;margin:0;">Visual Network Topology Map (Subnet $Subnet.x)</h2>
        <div class="topology-grid">
"@

foreach ($Dev in $DiscoveredDevices) {
    $TagClass = if ($Dev.DeviceType -like "*Windows*") { "type-Windows" } elseif ($Dev.DeviceType -like "*Linux*") { "type-Linux" } elseif ($Dev.DeviceType -like "*Router*" -or $Dev.DeviceType -like "*Switch*") { "type-Router" } else { "type-Other" }
    $Html += @"
            <div class="node-card">
                <div class="node-ip"><span>$($Dev.IPAddress)</span><span class="type-tag $TagClass">$($Dev.PingLatencyMs)ms</span></div>
                <div class="node-host" title="$($Dev.Hostname)">$($Dev.Hostname)</div>
                <div class="node-meta">
                    <b>MAC:</b> $($Dev.MACAddress)<br>
                    <b>Vendor:</b> $($Dev.Vendor)<br>
                    <b>Type:</b> <span style="color:#38bdf8;">$($Dev.DeviceType)</span><br>
                    <b>Open Ports:</b> $($Dev.OpenTCPPorts)
                </div>
            </div>
"@
}

$Html += @"
        </div>
    </div>

    <h2 style="font-size:16px;color:#38bdf8;margin-bottom:15px;">Discovered Network Devices Inventory Table</h2>
    <table>
        <thead>
            <tr>
                <th>IP Address</th>
                <th>Hostname</th>
                <th>MAC Address</th>
                <th>Hardware Vendor</th>
                <th>Heuristic Device Type</th>
                <th>Ping Latency</th>
                <th>Detected Open TCP Ports</th>
            </tr>
        </thead>
        <tbody>
"@

foreach ($Dev in $DiscoveredDevices) {
    $Html += "<tr><td><b>$($Dev.IPAddress)</b></td><td>$($Dev.Hostname)</td><td>$($Dev.MACAddress)</td><td>$($Dev.Vendor)</td><td><b>$($Dev.DeviceType)</b></td><td>$($Dev.PingLatencyMs) ms</td><td style='color:#60a5fa;'>$($Dev.OpenTCPPorts)</td></tr>`n"
}

$Html += @"
        </tbody>
    </table>
</body>
</html>
"@

$Html | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force
Write-Host " -> Saved interactive topology dashboard: reports\network_dashboard.html" -ForegroundColor Green

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "       NETWORK MAPPING & TOPOLOGY SCAN COMPLETED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Outputs saved to: $ReportsDir" -ForegroundColor Yellow
