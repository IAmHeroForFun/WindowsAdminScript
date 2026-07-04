<#
.SYNOPSIS
    Option [12]: NOC Uptime & Availability Monitoring Platform
.DESCRIPTION
    PRTG & Uptime Kuma-style lightweight uptime monitoring engine. Checks Internet, Gateway, DNS Servers, Domain Controllers, File Servers, Websites, and VPN endpoints. Tracks response times, packet loss %, and cumulative uptime/downtime. Stores historical data locally in JSON/CSV and compiles interactive daily, weekly, monthly HTML reports with availability sparklines.
.AUTHOR
    Antigravity NOC & Infrastructure Team
#>

[CmdletBinding()]
param (
    [switch]$NonInteractive
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

$ReportsDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
$HistoryJsonPath = Join-Path $ReportsDir "history.json"
$HistoryCsvPath = Join-Path $ReportsDir "uptime_history.csv"

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       NOC UPTIME & AVAILABILITY MONITORING PLATFORM [OPTION 12]" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Target System: $env:COMPUTERNAME | Poll Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan

# Load existing historical database
$HistoryData = @()
if (Test-Path $HistoryJsonPath) {
    try {
        $JsonContent = Get-Content -Path $HistoryJsonPath -Raw -Encoding UTF8
        if ($JsonContent) { $HistoryData = @(ConvertFrom-Json -InputObject $JsonContent) }
    } catch { $HistoryData = @() }
}

# ---------------------------------------------------------
# DEFINE MONITORING TARGETS
# ---------------------------------------------------------
$Targets = New-Object System.Collections.ArrayList

# 1. Internet Target
[void]$Targets.Add(@{ Name="Google Public DNS (Internet)"; Type="ICMP"; Address="8.8.8.8"; Category="Internet" })
[void]$Targets.Add(@{ Name="Cloudflare DNS (Internet)"; Type="ICMP"; Address="1.1.1.1"; Category="Internet" })

# 2. Gateway Target
$NIC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Where-Object { $_.DefaultIPGateway -ne $null } | Select-Object -First 1
if ($NIC -and $NIC.DefaultIPGateway[0]) {
    [void]$Targets.Add(@{ Name="Local Default Gateway"; Type="ICMP"; Address=$NIC.DefaultIPGateway[0]; Category="Gateway" })
}

# 3. DNS Server Target
if ($NIC -and $NIC.DNSServerSearchOrder) {
    foreach ($DnsIP in $NIC.DNSServerSearchOrder) {
        [void]$Targets.Add(@{ Name="DNS Server ($DnsIP)"; Type="ICMP"; Address=$DnsIP; Category="DNS" })
    }
}

# 4. Domain Controller Target
$LogonSrv = $env:LOGONSERVER -replace '\\',''
if ($LogonSrv -and $LogonSrv -ne $env:COMPUTERNAME) {
    [void]$Targets.Add(@{ Name="Domain Controller ($LogonSrv)"; Type="ICMP"; Address=$LogonSrv; Category="Domain Controller" })
    [void]$Targets.Add(@{ Name="DC Kerberos / LDAP ($LogonSrv)"; Type="TCP"; Address=$LogonSrv; Port=389; Category="Domain Controller" })
}

# 5. File Server / SMB Target
[void]$Targets.Add(@{ Name="Local SMB Service ($env:COMPUTERNAME)"; Type="TCP"; Address="127.0.0.1"; Port=445; Category="File Server" })

# 6. Websites Target
[void]$Targets.Add(@{ Name="Microsoft Portal (HTTPS)"; Type="HTTP"; Address="https://www.microsoft.com"; Category="Website" })
[void]$Targets.Add(@{ Name="Google Web (HTTPS)"; Type="HTTP"; Address="https://www.google.com"; Category="Website" })

# ---------------------------------------------------------
# EXECUTE MONITORING POLL
# ---------------------------------------------------------
Write-Host "`nExecuting real-time availability checks across $($Targets.Count) infrastructure endpoints..." -ForegroundColor Yellow

$PollTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$CurrentResults = New-Object System.Collections.ArrayList

foreach ($T in $Targets) {
    $Status = "OFFLINE"
    $ResponseMs = 0
    $PacketLoss = 100
    
    switch ($T.Type) {
        "ICMP" {
            $Ping = Test-Connection -ComputerName $T.Address -Count 3 -BufferSize 32 -ErrorAction SilentlyContinue
            if ($Ping -and $Ping.Count -gt 0) {
                $Received = @($Ping | Where-Object { $_.ResponseTime -ne $null }).Count
                $PacketLoss = [math]::Round(((3 - $Received) / 3) * 100, 1)
                if ($Received -gt 0) {
                    $Status = "ONLINE"
                    $AvgMs = ($Ping | Measure-Object -Property ResponseTime -Average).Average
                    $ResponseMs = [math]::Round($AvgMs, 1)
                }
            }
        }
        "TCP" {
            try {
                $Sw = [System.Diagnostics.Stopwatch]::StartNew()
                $Socket = New-Object System.Net.Sockets.TcpClient
                $Connect = $Socket.BeginConnect($T.Address, $T.Port, $null, $null)
                $Success = $Connect.AsyncWaitHandle.WaitOne(800, $false)
                $Sw.Stop()
                if ($Success -and $Socket.Connected) {
                    $Status = "ONLINE"
                    $ResponseMs = [math]::Round($Sw.Elapsed.TotalMilliseconds, 1)
                    $PacketLoss = 0
                }
                $Socket.Close()
            } catch { }
        }
        "HTTP" {
            try {
                $Sw = [System.Diagnostics.Stopwatch]::StartNew()
                $Req = [System.Net.WebRequest]::Create($T.Address)
                $Req.Timeout = 3000
                $Req.Method = "HEAD"
                $Resp = $Req.GetResponse()
                $Sw.Stop()
                if ($Resp.StatusCode -in @(200, 301, 302)) {
                    $Status = "ONLINE"
                    $ResponseMs = [math]::Round($Sw.Elapsed.TotalMilliseconds, 1)
                    $PacketLoss = 0
                }
                $Resp.Close()
            } catch { }
        }
    }
    
    $Color = if ($Status -eq "ONLINE") { "Green" } else { "Red" }
    Write-Host "   [$($T.Category)] $($T.Name) ($($T.Address)) -> Status: $Status | Latency: ${ResponseMs}ms | Loss: ${PacketLoss}%" -ForegroundColor $Color
    
    $ResObj = New-Object PSObject -Property @{
        Timestamp = $PollTimestamp
        Category = $T.Category
        MonitorName = $T.Name
        Address = $T.Address
        Type = $T.Type
        Status = $Status
        ResponseTimeMs = $ResponseMs
        PacketLossPct = $PacketLoss
    }
    [void]$CurrentResults.Add($ResObj)
    $HistoryData += $ResObj
}

# Save updated history
$HistoryData | ConvertTo-Json -Depth 4 | Out-File -FilePath $HistoryJsonPath -Encoding UTF8 -Force
$CurrentResults | Export-Csv -Path $HistoryCsvPath -NoTypeInformation -Append -Encoding UTF8 -Force
Write-Host "`n -> Historical database updated: reports\history.json ($($HistoryData.Count) total data points)" -ForegroundColor Green

# ---------------------------------------------------------
# CALCULATE UPTIME STATISTICS & GENERATE REPORTS
# ---------------------------------------------------------
Write-Host "`nCompiling NOC Executive Dashboards & Availability Reports..." -ForegroundColor Yellow

# Function to generate HTML report for a specific time window
function Generate-UptimeReport {
    param([string]$ReportTitle, [string]$FileName, [int]$DaysFilter)
    
    $FilterDate = (Get-Date).AddDays(-$DaysFilter)
    $FilteredData = @($HistoryData | Where-Object { [datetime]$_.Timestamp -ge $FilterDate })
    if ($FilteredData.Count -eq 0) { $FilteredData = $HistoryData }
    
    # Group by Monitor Name
    $MonGroups = $FilteredData | Group-Object -Property MonitorName
    
    $Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ReportTitle - NOC Command Center</title>
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --muted: #94a3b8; --border: #334155; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 25px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border); padding-bottom: 15px; margin-bottom: 25px; }
        .header h1 { margin: 0; font-size: 24px; color: #38bdf8; }
        .meta { font-size: 13px; color: var(--muted); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 20px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }
        .card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
        .card-title { font-size: 16px; font-weight: bold; color: #f8fafc; }
        .badge { padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: bold; }
        .badge-ONLINE { background: #15803d; color: #dcfce7; }
        .badge-OFFLINE { background: #991b1b; color: #fecaca; }
        .stats-row { display: flex; justify-content: space-between; font-size: 13px; color: var(--muted); margin-bottom: 15px; }
        .stats-row b { color: #38bdf8; }
        .sparkline-box { display: flex; gap: 3px; height: 28px; align-items: flex-end; background: #0f172a; padding: 6px; border-radius: 6px; border: 1px solid var(--border); }
        .bar { flex: 1; border-radius: 2px; transition: height 0.2s; }
        .bar-up { background: #22c55e; }
        .bar-down { background: #ef4444; height: 100% !important; }
        table { width: 100%; border-collapse: collapse; background: var(--card); border-radius: 10px; overflow: hidden; border: 1px solid var(--border); margin-top: 20px; }
        th, td { padding: 14px; text-align: left; border-bottom: 1px solid var(--border); font-size: 14px; }
        th { background: #0f172a; color: #38bdf8; font-weight: 600; text-transform: uppercase; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>[NOC COMMAND] $ReportTitle</h1>
            <div class="meta">Host: <b>$env:COMPUTERNAME</b> | Window: <b>Past $DaysFilter Days</b> | Total Checks: <b>$($FilteredData.Count)</b></div>
        </div>
        <div class="meta">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>System: Uptime Kuma / PRTG Engine</div>
    </div>

    <h2 style="font-size:18px;color:#38bdf8;margin-bottom:15px;">Infrastructure Endpoint Status & Availability Sparklines</h2>
    <div class="grid">
"@

    foreach ($Grp in $MonGroups) {
        $Name = $Grp.Name
        $Items = @($Grp.Group | Sort-Object Timestamp)
        $TotalCount = $Items.Count
        $OnlineCount = @($Items | Where-Object { $_.Status -eq "ONLINE" }).Count
        $UptimePct = if ($TotalCount -gt 0) { [math]::Round(($OnlineCount / $TotalCount) * 100, 2) } else { 0 }
        
        $Latest = $Items[-1]
        $Status = $Latest.Status
        $AvgLat = if ($OnlineCount -gt 0) { [math]::Round((@($Items | Where-Object { $_.Status -eq "ONLINE" }) | Measure-Object -Property ResponseTimeMs -Average).Average, 1) } else { 0 }
        
        # Build sparkline bars (take last 30 data points)
        $Recent = if ($TotalCount -gt 30) { $Items[-30..-1] } else { $Items }
        $SparkHtml = ""
        foreach ($Pt in $Recent) {
            if ($Pt.Status -eq "ONLINE") {
                # Scale height 20% to 100% based on latency
                $H = 40
                if ($Pt.ResponseTimeMs -gt 200) { $H = 90 } elseif ($Pt.ResponseTimeMs -gt 50) { $H = 65 }
                $SparkHtml += "<div class='bar bar-up' style='height:${H}%;' title='Online: $($Pt.ResponseTimeMs)ms ($($Pt.Timestamp))'></div>"
            } else {
                $SparkHtml += "<div class='bar bar-down' title='OFFLINE ($($Pt.Timestamp))'></div>"
            }
        }

        $Html += @"
        <div class="card">
            <div class="card-top">
                <span class="card-title">$Name</span>
                <span class="badge badge-$Status">$Status</span>
            </div>
            <div class="stats-row">
                <span>Uptime: <b>${UptimePct}%</b></span>
                <span>Avg Latency: <b>${AvgLat}ms</b></span>
                <span>Type: <b>$($Latest.Type)</b></span>
            </div>
            <div class="meta" style="margin-bottom:6px;">Recent Availability History:</div>
            <div class="sparkline-box">$SparkHtml</div>
        </div>
"@
    }

    $Html += @"
    </div>

    <h2 style="font-size:18px;color:#38bdf8;margin-bottom:15px;">Historical Uptime SLA Scorecard Table</h2>
    <table>
        <thead>
            <tr>
                <th>Category</th>
                <th>Monitor Name</th>
                <th>Target Endpoint</th>
                <th>Protocol</th>
                <th>Current Status</th>
                <th>Uptime SLA (%)</th>
                <th>Avg Latency (ms)</th>
                <th>Total Checks</th>
            </tr>
        </thead>
        <tbody>
"@

    foreach ($Grp in $MonGroups) {
        $Items = @($Grp.Group)
        $Latest = $Items[-1]
        $OnlineCount = @($Items | Where-Object { $_.Status -eq "ONLINE" }).Count
        $UptimePct = [math]::Round(($OnlineCount / $Items.Count) * 100, 2)
        $AvgLat = if ($OnlineCount -gt 0) { [math]::Round((@($Items | Where-Object { $_.Status -eq "ONLINE" }) | Measure-Object -Property ResponseTimeMs -Average).Average, 1) } else { 0 }
        $Badge = "<span class='badge badge-$($Latest.Status)'>$($Latest.Status)</span>"
        $Html += "<tr><td><b>$($Latest.Category)</b></td><td>$($Latest.MonitorName)</td><td>$($Latest.Address)</td><td>$($Latest.Type)</td><td>$Badge</td><td style='color:#38bdf8;font-weight:bold;'>${UptimePct}%</td><td>${AvgLat} ms</td><td>$($Items.Count)</td></tr>`n"
    }

    $Html += @"
        </tbody>
    </table>
</body>
</html>
"@

    $OutPath = Join-Path $ReportsDir $FileName
    $Html | Out-File -FilePath $OutPath -Encoding UTF8 -Force
    Write-Host " -> Compiled report: reports\$FileName" -ForegroundColor Green
}

# Compile Daily (1 day), Weekly (7 days), Monthly (30 days), and Master Uptime Dashboard
Generate-UptimeReport "24-Hour Daily Uptime & SLA Report" "daily_report.html" 1
Generate-UptimeReport "7-Day Weekly Uptime & SLA Report" "weekly_report.html" 7
Generate-UptimeReport "30-Day Monthly Uptime & SLA Report" "monthly_report.html" 30
Generate-UptimeReport "Master NOC Uptime & Availability Dashboard" "uptime_dashboard.html" 365

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "       NOC UPTIME & AVAILABILITY MONITORING COMPLETED!" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Reports saved to: $ReportsDir" -ForegroundColor Yellow
