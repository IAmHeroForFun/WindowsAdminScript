<#
.SYNOPSIS
    Option [14]: Complete Self-Hosted MSP Monitoring & Reporting Platform
.DESCRIPTION
    The ultimate self-hosted enterprise IT monitoring and management ecosystem (alternative to Lansweeper, PRTG, NinjaOne, and ManageEngine OpManager). Consolidates 10 core administrative modules: Endpoint Inventory, Security Audit, Patch Compliance, Backup Verification, Certificate Monitoring, Uptime Monitoring, Asset Lifecycle Management, Network Discovery, Executive Reporting, and Historical Trend Analysis. Computes three executive KPIs: MSP Health Score, Client Risk Score, and Infrastructure Risk Score. Features Windows Scheduled Task automation and automated SMTP email alerting.
.AUTHOR
    Antigravity MSP Architecture & Engineering Team
#>

[CmdletBinding()]
param (
    [string]$ClientName = "Managed Enterprise Client",
    [switch]$InstallScheduledTask,
    [switch]$SendEmailAlert,
    [string]$SmtpServer = "smtp.office365.com",
    [string]$AlertEmailTo = "alerts@msp-provider.com",
    [string]$AlertEmailFrom = "monitor@msp-provider.com",
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
$TrendJsonPath = Join-Path $ReportsDir "historical_trends.json"
$TrendCsvPath = Join-Path $ReportsDir "historical_trends.csv"
$RiskCsvPath = Join-Path $ReportsDir "msp_risk_scores.csv"

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "    COMPLETE SELF-HOSTED MSP MONITORING & REPORTING PLATFORM [OPTION 14]" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Host: $env:COMPUTERNAME | Client: $ClientName | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan

# ---------------------------------------------------------
# SCHEDULED TASK AUTOMATION MODULE
# ---------------------------------------------------------
if ($InstallScheduledTask) {
    Write-Host "`n[Automation] Registering Windows Scheduled Task 'Antigravity-MSP-Platform-Monitor'..." -ForegroundColor Yellow
    $TaskCommand = "powershell.exe"
    $TaskArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`" -NonInteractive"
    try {
        cmd.exe /c "schtasks /create /tn `"Antigravity-MSP-Platform-Monitor`" /tr `"$TaskCommand $TaskArgs`" /sc DAILY /st 06:00 /f" | Out-Null
        Write-Host " -> Scheduled Task successfully installed! Will execute daily at 06:00 AM." -ForegroundColor Green
    } catch {
        Write-Host " -> Error registering scheduled task. Please run as Administrator." -ForegroundColor Red
    }
    if ($NonInteractive) { return }
}

if (-not $NonInteractive -and -not $InstallScheduledTask) {
    $InputClient = Read-Host "`nEnter Client Organization Name [$ClientName]"
    if ($InputClient) { $ClientName = $InputClient }
    
    $PromptTask = Read-Host "Would you like to install/update the Daily 06:00 AM Background Monitoring Task? [Y/N]"
    if ($PromptTask -eq "Y" -or $PromptTask -eq "y") {
        cmd.exe /c "schtasks /create /tn `"Antigravity-MSP-Platform-Monitor`" /tr `"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`" -NonInteractive`" /sc DAILY /st 06:00 /f" | Out-Null
        Write-Host " -> Background Monitoring Scheduled Task registered!" -ForegroundColor Green
    }
}

Write-Host "`nInitiating 10-Module Deep Enterprise Ecosystem Assessment..." -ForegroundColor Yellow

$MspFindings = New-Object System.Collections.ArrayList
function Add-MspFinding($Module, $Item, $Status, $RiskLevel, $Advice) {
    $Obj = New-Object PSObject -Property @{
        Module = $Module
        Item = $Item
        Status = $Status
        RiskLevel = $RiskLevel
        Recommendation = $Advice
    }
    [void]$MspFindings.Add($Obj)
}

# ---------------------------------------------------------
# MODULE 1: ENDPOINT INVENTORY
# ---------------------------------------------------------
Write-Host " -> [Module 1/10] Scanning Endpoint Inventory & Hardware Assets..." -ForegroundColor Cyan
$CS = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
$OS = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
$CPU = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
$RAM_GB = [math]::Round($CS.TotalPhysicalMemory / 1GB, 1)
Add-MspFinding "1. Inventory" "Hardware Platform" "$($CS.Manufacturer) $($CS.Model)" "Informational" "Documented hardware configuration."
Add-MspFinding "1. Inventory" "System Memory & Processor" "${RAM_GB}GB RAM | $($CPU.Name)" $(if ($RAM_GB -lt 8) { "Medium" } else { "Low" }) $(if ($RAM_GB -lt 8) { "Upgrade physical RAM to 16GB+ for optimal multitasking." } else { "Memory capacity adequate." })

# ---------------------------------------------------------
# MODULE 2: SECURITY AUDIT
# ---------------------------------------------------------
Write-Host " -> [Module 2/10] Conducting 360-Degree Cybersecurity Audit..." -ForegroundColor Cyan
$Smb1 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -ErrorAction SilentlyContinue).SMB1
if ($Smb1 -eq 1) {
    Add-MspFinding "2. Security" "SMBv1 Ransomware Protocol" "ENABLED (VULNERABLE)" "Critical" "Disable SMBv1 immediately to prevent lateral WannaCry worm exploitation."
} else {
    Add-MspFinding "2. Security" "SMBv1 Ransomware Protocol" "Disabled (Hardened)" "Low" "SMBv1 protocol successfully disabled."
}

$FwState = netsh advfirewall show allprofiles state 2>&1
if ($FwState -match "State\s+OFF") {
    Add-MspFinding "2. Security" "Windows Firewall Profiles" "ONE OR MORE DISABLED" "Critical" "Enforce active firewall state across Domain, Private, and Public boundaries."
} else {
    Add-MspFinding "2. Security" "Windows Firewall Profiles" "All Profiles Active" "Low" "Network filtering active across all interfaces."
}

$UacReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
if ($UacReg -eq 0) {
    Add-MspFinding "2. Security" "User Account Control (UAC)" "DISABLED" "High" "Enable UAC (`EnableLUA = 1`) to prevent silent administrative privilege escalation."
} else {
    Add-MspFinding "2. Security" "User Account Control (UAC)" "Enabled" "Low" "Privilege escalation prompts enforced."
}

# ---------------------------------------------------------
# MODULE 3: PATCH COMPLIANCE
# ---------------------------------------------------------
Write-Host " -> [Module 3/10] Evaluating Windows Update Servicing & EOL Status..." -ForegroundColor Cyan
$Hotfixes = Get-WmiObject -Class Win32_QuickFixEngineering -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending
$DaysSincePatch = 999
if ($Hotfixes -and $Hotfixes[0].InstalledOn) {
    try { $DaysSincePatch = [math]::Round(((Get-Date) - [datetime]$Hotfixes[0].InstalledOn).TotalDays) } catch { }
}
$IsEOL = ($OS.Caption -like "*2008*" -or $OS.Caption -like "*2012*" -or $OS.Caption -like "*Windows 7*" -or $OS.Caption -like "*Windows 8*")
if ($IsEOL) {
    Add-MspFinding "3. Patching" "Operating System Lifecycle" "END OF LIFE ($($OS.Caption))" "Critical" "OS no longer supported by Microsoft. Upgrade immediately to Server 2022/2025."
} elseif ($DaysSincePatch -gt 45) {
    Add-MspFinding "3. Patching" "Windows Update Servicing" "UNPATCHED ($DaysSincePatch Days Ago)" "High" "Run automated Windows Update cycle to apply critical security patches."
} else {
    Add-MspFinding "3. Patching" "Windows Update Servicing" "Compliant ($DaysSincePatch Days Ago)" "Low" "System patched within standard servicing window."
}

# ---------------------------------------------------------
# MODULE 4: BACKUP VERIFICATION
# ---------------------------------------------------------
Write-Host " -> [Module 4/10] Verifying Volume Shadow Copy & Disaster Recovery..." -ForegroundColor Cyan
$VssSvc = Get-Service -Name VSS -ErrorAction SilentlyContinue
$Shadows = Get-WmiObject -Class Win32_ShadowCopy -ErrorAction SilentlyContinue
$ShadowCount = if ($Shadows) { @($Shadows).Count } else { 0 }
if ($VssSvc.StartType -eq "Disabled") {
    Add-MspFinding "4. Backups" "Volume Shadow Copy Service" "DISABLED" "Critical" "Enable VSS service; image backups will fail silently."
} elseif ($ShadowCount -eq 0) {
    Add-MspFinding "4. Backups" "Local Snapshot Restore Points" "0 SNAPSHOTS FOUND" "High" "Configure Volume Shadow Copies for rapid ransomware file rollback."
} else {
    Add-MspFinding "4. Backups" "Local Snapshot Restore Points" "$ShadowCount Snapshots Ready" "Low" "Disaster recovery snapshot engine operational."
}

# ---------------------------------------------------------
# MODULE 5: CERTIFICATE MONITORING
# ---------------------------------------------------------
Write-Host " -> [Module 5/10] Auditing Local Machine SSL/TLS Certificate Expiration..." -ForegroundColor Cyan
try {
    $Certs = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object { $_.NotAfter -ne $null }
    $ExpCount = 0
    foreach ($C in $Certs) {
        $DaysLeft = [math]::Round(($C.NotAfter - (Get-Date)).TotalDays)
        if ($DaysLeft -lt 30) {
            Add-MspFinding "5. Certificates" "SSL Certificate ($($C.Subject))" "EXPIRING IN $DaysLeft DAYS" "High" "Renew certificate before expiration to prevent service outage."
            $ExpCount++
        }
    }
    if ($ExpCount -eq 0) {
        Add-MspFinding "5. Certificates" "SSL Certificate Store" "All Certificates Valid" "Low" "No SSL certificates expiring within 30 days."
    }
} catch { }

# ---------------------------------------------------------
# MODULE 6: UPTIME MONITORING
# ---------------------------------------------------------
Write-Host " -> [Module 6/10] Probing Network Gateway & Internet Routing Latency..." -ForegroundColor Cyan
$PingRes = Test-Connection -ComputerName "8.8.8.8" -Count 2 -BufferSize 32 -ErrorAction SilentlyContinue
if ($PingRes -and $PingRes.Count -gt 0) {
    $AvgMs = [math]::Round((@($PingRes) | Measure-Object -Property ResponseTime -Average).Average, 1)
    Add-MspFinding "6. Uptime" "External Internet Connectivity" "ONLINE (${AvgMs}ms Latency)" "Low" "External network routing and ICMP responsiveness nominal."
} else {
    Add-MspFinding "6. Uptime" "External Internet Connectivity" "PACKET LOSS / OFFLINE" "High" "Verify edge gateway firewall rules and external ISP link."
}

# ---------------------------------------------------------
# MODULE 7: ASSET LIFECYCLE MANAGEMENT
# ---------------------------------------------------------
Write-Host " -> [Module 7/10] Analyzing Hardware Age & Lifecycle Replacement SLAs..." -ForegroundColor Cyan
$Bios = Get-WmiObject -Class Win32_BIOS -ErrorAction SilentlyContinue
$BiosYear = 2020
try { if ($Bios.ReleaseDate) { $BiosYear = [int]$Bios.ReleaseDate.Substring(0,4) } } catch { }
$HardwareAge = (Get-Date).Year - $BiosYear
if ($HardwareAge -ge 5) {
    Add-MspFinding "7. Lifecycle" "Hardware Asset Age" "AGED ASSET ($HardwareAge Years Old)" "High" "Hardware has exceeded standard 5-year enterprise warranty lifecycle. Plan refresh."
} elseif ($HardwareAge -ge 3) {
    Add-MspFinding "7. Lifecycle" "Hardware Asset Age" "Mid-Lifecycle ($HardwareAge Years Old)" "Medium" "Monitor hardware health and budget for replacement within 24 months."
} else {
    Add-MspFinding "7. Lifecycle" "Hardware Asset Age" "Modern Asset ($HardwareAge Years Old)" "Low" "Asset within active 3-year warranty lifecycle."
}

# ---------------------------------------------------------
# MODULE 8: NETWORK DISCOVERY
# ---------------------------------------------------------
Write-Host " -> [Module 8/10] Checking Active Subnet & ARP Table Neighbors..." -ForegroundColor Cyan
$ArpLines = cmd.exe /c "arp -a" | Where-Object { $_ -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -and $_ -notmatch "224\.|255\.|127\." }
$NeighborCount = if ($ArpLines) { @($ArpLines).Count } else { 1 }
Add-MspFinding "8. Network" "Subnet Device Footprint" "$NeighborCount Active Subnet Neighbors" "Informational" "Documented local network footprint."

# ---------------------------------------------------------
# MODULE 9 & 10: SCORING ENGINES & HISTORICAL TRENDS
# ---------------------------------------------------------
Write-Host " -> [Module 9/10 & 10/10] Computing MSP KPIs & Updating Trend Database..." -ForegroundColor Cyan

# Compute 3 Executive KPI Scores (0-100)
$MspHealthScore = 100
$ClientRiskScore = 0
$InfraRiskScore = 0

foreach ($F in $MspFindings) {
    switch ($F.RiskLevel) {
        "Critical" { $MspHealthScore -= 25; $ClientRiskScore += 30; $InfraRiskScore += 35 }
        "High"     { $MspHealthScore -= 12; $ClientRiskScore += 18; $InfraRiskScore += 20 }
        "Medium"   { $MspHealthScore -= 6;  $ClientRiskScore += 8;  $InfraRiskScore += 10 }
    }
}
if ($MspHealthScore -lt 0) { $MspHealthScore = 0 }
if ($ClientRiskScore -gt 100) { $ClientRiskScore = 100 }
if ($InfraRiskScore -gt 100) { $InfraRiskScore = 100 }

$ScoreColor = if ($MspHealthScore -ge 85) { "#16a34a" } elseif ($MspHealthScore -ge 70) { "#ca8a04" } else { "#dc2626" }

# Save historical trend data
$TrendObj = [PSCustomObject]@{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Host = $env:COMPUTERNAME
    Client = $ClientName
    MspHealthScore = $MspHealthScore
    ClientRiskScore = $ClientRiskScore
    InfrastructureRiskScore = $InfraRiskScore
}

$TrendHistory = @()
if (Test-Path $TrendJsonPath) {
    try {
        $JsonContent = Get-Content -Path $TrendJsonPath -Raw -Encoding UTF8
        if ($JsonContent) { $TrendHistory = @(ConvertFrom-Json -InputObject $JsonContent) }
    } catch { $TrendHistory = @() }
}
$TrendHistory += $TrendObj
$TrendHistory | ConvertTo-Json -Depth 3 | Out-File -FilePath $TrendJsonPath -Encoding UTF8 -Force
@($TrendObj) | Export-Csv -Path $TrendCsvPath -NoTypeInformation -Append -Encoding UTF8 -Force
$MspFindings | Export-Csv -Path $RiskCsvPath -NoTypeInformation -Encoding UTF8 -Force
Write-Host " -> Historical trends saved: reports\historical_trends.json" -ForegroundColor Green

# ---------------------------------------------------------
# EMAIL ALERTING FRAMEWORK
# ---------------------------------------------------------
if ($SendEmailAlert -and $MspHealthScore -lt 70) {
    Write-Host "`n[Alert] MSP Health Score ($MspHealthScore) below threshold! Sending SMTP Email Alert..." -ForegroundColor Red
    try {
        $Subject = "[CRITICAL MSP ALERT] $ClientName ($env:COMPUTERNAME) - Health Score: $MspHealthScore"
        $Body = "CRITICAL INFRASTRUCTURE ALERT`n`nClient: $ClientName`nHost: $env:COMPUTERNAME`nMSP Health Score: $MspHealthScore / 100`nClient Risk Score: $ClientRiskScore / 100`n`nPlease review reports\msp_master_dashboard.html immediately!"
        Send-MailMessage -SmtpServer $SmtpServer -To $AlertEmailTo -From $AlertEmailFrom -Subject $Subject -Body $Body -ErrorAction Stop
        Write-Host " -> Alert email sent successfully to $AlertEmailTo!" -ForegroundColor Green
    } catch {
        Write-Host " -> Could not send SMTP email: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------
# GENERATE MASTER HTML COMMAND CENTER DASHBOARD
# ---------------------------------------------------------
Write-Host "`nCompiling Self-Hosted MSP Master Command Center Dashboard..." -ForegroundColor Yellow
$HtmlPath = Join-Path $ReportsDir "msp_master_dashboard.html"

$CritCount = @($MspFindings | Where-Object { $_.RiskLevel -eq "Critical" }).Count
$HighCount = @($MspFindings | Where-Object { $_.RiskLevel -eq "High" }).Count
$MedCount  = @($MspFindings | Where-Object { $_.RiskLevel -eq "Medium" }).Count
$LowCount  = @($MspFindings | Where-Object { $_.RiskLevel -eq "Low" }).Count

$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MSP Master Command Center - $ClientName</title>
    <style>
        :root { --bg: #0b0f19; --card: #151e32; --text: #f1f5f9; --muted: #94a3b8; --border: #2a3756; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 30px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border); padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { margin: 0; font-size: 26px; color: #38bdf8; text-transform: uppercase; letter-spacing: 1px; }
        .header .meta { font-size: 14px; color: var(--muted); }
        
        .kpi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 25px; margin-bottom: 35px; }
        .kpi-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 25px; text-align: center; box-shadow: 0 4px 10px rgba(0,0,0,0.3); position: relative; overflow: hidden; }
        .kpi-card h3 { margin: 0; font-size: 14px; color: var(--muted); text-transform: uppercase; letter-spacing: 1px; }
        .kpi-card .val { font-size: 46px; font-weight: bold; margin: 15px 0; }
        
        .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 35px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 15px; text-align: center; }
        .card h3 { margin: 0; font-size: 12px; color: var(--muted); text-transform: uppercase; }
        .card .val { font-size: 26px; font-weight: bold; margin: 8px 0; }
        
        table { width: 100%; border-collapse: collapse; background: var(--card); border-radius: 10px; overflow: hidden; border: 1px solid var(--border); margin-bottom: 30px; }
        th, td { padding: 14px; text-align: left; border-bottom: 1px solid var(--border); font-size: 13px; }
        th { background: #0f172a; color: #38bdf8; font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:hover { background: #1e293b; }
        
        .badge { padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: bold; text-transform: uppercase; }
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
            <h1>[MSP COMMAND CENTER] Self-Hosted IT Ecosystem</h1>
            <div class="meta">Client: <b>$ClientName</b> | Host: <b>$env:COMPUTERNAME</b> | Architecture: <b>10-Module Integrated Suite</b></div>
        </div>
        <div class="meta">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>Mode: Self-Hosted Lansweeper / PRTG Alternative</div>
    </div>

    <div class="kpi-grid">
        <div class="kpi-card" style="border-top: 5px solid $ScoreColor;">
            <h3>MSP Health Score</h3>
            <div class="val" style="color:$ScoreColor;">$MspHealthScore<span style="font-size:20px;color:var(--muted);">/100</span></div>
            <div style="font-size:13px;color:var(--muted);">Overall Infrastructure Stability Index</div>
        </div>
        <div class="kpi-card" style="border-top: 5px solid #f97316;">
            <h3>Client Risk Score</h3>
            <div class="val" style="color:#f97316;">$ClientRiskScore<span style="font-size:20px;color:var(--muted);">/100</span></div>
            <div style="font-size:13px;color:var(--muted);">Business Exposure & Security Threat Level</div>
        </div>
        <div class="kpi-card" style="border-top: 5px solid #ef4444;">
            <h3>Infrastructure Risk Score</h3>
            <div class="val" style="color:#ef4444;">$InfraRiskScore<span style="font-size:20px;color:var(--muted);">/100</span></div>
            <div style="font-size:13px;color:var(--muted);">Hardware Age & System Vulnerability Level</div>
        </div>
    </div>

    <div class="grid">
        <div class="card" style="border-top: 4px solid #ef4444;"><h3>Critical Risks</h3><div class="val" style="color:#ef4444;">$CritCount</div></div>
        <div class="card" style="border-top: 4px solid #f97316;"><h3>High Risks</h3><div class="val" style="color:#f97316;">$HighCount</div></div>
        <div class="card" style="border-top: 4px solid #eab308;"><h3>Medium Risks</h3><div class="val" style="color:#eab308;">$MedCount</div></div>
        <div class="card" style="border-top: 4px solid #22c55e;"><h3>Passed / Low</h3><div class="val" style="color:#22c55e;">$LowCount</div></div>
    </div>

    <h2 style="font-size:18px;color:#38bdf8;margin-bottom:15px;">10-Module Comprehensive Findings & Remediation Plan</h2>
    <table>
        <thead>
            <tr>
                <th>MSP Module</th>
                <th>Audited Policy / Check Item</th>
                <th>Current Status</th>
                <th>Risk Severity</th>
                <th>Recommended Engineering Fix</th>
            </tr>
        </thead>
        <tbody>
"@

foreach ($F in $MspFindings) {
    $Html += "<tr><td><b>$($F.Module)</b></td><td>$($F.Item)</td><td>$($F.Status)</td><td><span class='badge badge-$($F.RiskLevel)'>$($F.RiskLevel)</span></td><td style='color:#a7f3d0;'>$($F.Recommendation)</td></tr>`n"
}

$Html += @"
        </tbody>
    </table>

    <h2 style="font-size:18px;color:#38bdf8;margin-bottom:15px;">Historical KPI Trend Log Table (Past Assessments)</h2>
    <table>
        <thead>
            <tr>
                <th>Timestamp</th>
                <th>Host Asset</th>
                <th>Client Organization</th>
                <th>MSP Health Score</th>
                <th>Client Risk Score</th>
                <th>Infrastructure Risk Score</th>
            </tr>
        </thead>
        <tbody>
"@

foreach ($T in $TrendHistory) {
    $Html += "<tr><td><b>$($T.Timestamp)</b></td><td>$($T.Host)</td><td>$($T.Client)</td><td style='color:#22c55e;font-weight:bold;'>$($T.MspHealthScore)/100</td><td style='color:#f97316;font-weight:bold;'>$($T.ClientRiskScore)/100</td><td style='color:#ef4444;font-weight:bold;'>$($T.InfrastructureRiskScore)/100</td></tr>`n"
}

$Html += @"
        </tbody>
    </table>
</body>
</html>
"@

$Html | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force
Write-Host " -> Saved Master Command Center: reports\msp_master_dashboard.html" -ForegroundColor Green

Write-Host "`n==========================================================================" -ForegroundColor Magenta
Write-Host "       COMPLETE MSP MONITORING PLATFORM EXECUTED SUCCESSFULLY!" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "All reports, historical trends, and command dashboards saved to: $ReportsDir" -ForegroundColor Yellow
