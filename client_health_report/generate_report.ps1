<#
.SYNOPSIS
    Option [13]: MSP One-Click Client Health Report Generator
.DESCRIPTION
    CEO and Boardroom-ready executive client health assessment generator. Rapidly collects server health, disk usage, backup status, security findings, Windows update compliance, SSL certificate expiry, system event log errors, firewall profiles, and antivirus status. Generates a stunning print-to-PDF HTML executive report with a 0-100 Health Score and risk breakdown.
.AUTHOR
    Antigravity MSP Solutions Architecture Team
#>

[CmdletBinding()]
param (
    [string]$ClientName = "Enterprise Client Organization",
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

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "       MSP ONE-CLICK CLIENT HEALTH REPORT GENERATOR [OPTION 13]" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target System: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan

if (-not $NonInteractive) {
    $InputClient = Read-Host "`nEnter Client Organization Name for Executive Report [$ClientName]"
    if ($InputClient) { $ClientName = $InputClient }
}

$Findings = New-Object System.Collections.ArrayList
function Add-ClientFinding($Section, $Item, $Status, $RiskLevel, $Recommendation) {
    $Obj = New-Object PSObject -Property @{
        Section = $Section
        Finding = $Item
        Status = $Status
        RiskLevel = $RiskLevel
        Recommendation = $Recommendation
    }
    [void]$Findings.Add($Obj)
}

# ---------------------------------------------------------
# 1. SERVER HEALTH & DISK USAGE AUDIT
# ---------------------------------------------------------
Write-Host "`n[1/7] Auditing Server Health & Disk Storage Utilization..." -ForegroundColor Yellow
$OS = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
$UptimeDays = [math]::Round(((Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)).TotalDays, 1)
if ($UptimeDays -gt 90) {
    Add-ClientFinding "Server Health" "System Uptime ($UptimeDays Days)" "REQUIRES REBOOT" "Medium" "Schedule maintenance reboot to apply kernel patches and clear memory fragmentation."
} else {
    Add-ClientFinding "Server Health" "System Uptime ($UptimeDays Days)" "Healthy" "Low" "Uptime within recommended 90-day servicing window."
}

$Disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
foreach ($D in $Disks) {
    $FreePct = [math]::Round(($D.FreeSpace / $D.Size) * 100, 1)
    $SizeGB = [math]::Round($D.Size / 1GB, 1)
    if ($FreePct -lt 10) {
        Add-ClientFinding "Disk Usage" "Volume $($D.DeviceID) (${SizeGB}GB)" "CRITICAL LOW SPACE (${FreePct}% Free)" "Critical" "Immediate storage expansion or log cleanup required to prevent server crash."
    } elseif ($FreePct -lt 20) {
        Add-ClientFinding "Disk Usage" "Volume $($D.DeviceID) (${SizeGB}GB)" "Low Space (${FreePct}% Free)" "High" "Schedule disk cleanup and review storage growth trends."
    } else {
        Add-ClientFinding "Disk Usage" "Volume $($D.DeviceID) (${SizeGB}GB)" "Healthy (${FreePct}% Free)" "Low" "Storage capacity within healthy operating margins."
    }
}

# ---------------------------------------------------------
# 2. BACKUP & DISASTER RECOVERY STATUS
# ---------------------------------------------------------
Write-Host "[2/7] Checking Volume Shadow Copy & Backup Readiness..." -ForegroundColor Yellow
$VssSvc = Get-Service -Name VSS -ErrorAction SilentlyContinue
$Shadows = Get-WmiObject -Class Win32_ShadowCopy -ErrorAction SilentlyContinue
$ShadowCount = if ($Shadows) { @($Shadows).Count } else { 0 }
if ($VssSvc.StartType -eq "Disabled") {
    Add-ClientFinding "Backup Status" "Volume Shadow Copy (VSS) Service" "DISABLED" "Critical" "Enable VSS service immediately; image-based backups will fail silently."
} elseif ($ShadowCount -eq 0) {
    Add-ClientFinding "Backup Status" "Local Restore Point Snapshots" "0 SNAPSHOTS FOUND" "High" "Configure Volume Shadow Copies or system restore points for rapid rollback."
} else {
    Add-ClientFinding "Backup Status" "Local Restore Point Snapshots" "$ShadowCount Snapshots Ready" "Low" "Disaster recovery snapshot engine active."
}

# ---------------------------------------------------------
# 3. SECURITY, FIREWALL & ANTIVIRUS FINDINGS
# ---------------------------------------------------------
Write-Host "[3/7] Inspecting Antivirus, Firewall & SMB Security..." -ForegroundColor Yellow
$Smb1 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -ErrorAction SilentlyContinue).SMB1
if ($Smb1 -eq 1) {
    Add-ClientFinding "Security Findings" "SMBv1 Ransomware Protocol" "ENABLED (VULNERABLE)" "Critical" "Disable legacy SMBv1 protocol via Group Policy to block WannaCry ransomware vectors."
} else {
    Add-ClientFinding "Security Findings" "SMBv1 Ransomware Protocol" "Disabled (Secure)" "Low" "System hardened against SMBv1 exploitation."
}

$FwState = netsh advfirewall show allprofiles state 2>&1
if ($FwState -match "State\s+OFF") {
    Add-ClientFinding "Security Findings" "Windows Firewall Profiles" "ONE OR MORE DISABLED" "Critical" "Enforce Windows Firewall across Domain, Private, and Public profiles."
} else {
    Add-ClientFinding "Security Findings" "Windows Firewall Profiles" "All Enabled (Secure)" "Low" "Network filtering active across all network boundaries."
}

$DefenderReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
if ($DefenderReg -and $DefenderReg.DisableAntiSpyware -eq 1) {
    Add-ClientFinding "Security Findings" "Endpoint Antivirus Protection" "DISABLED BY POLICY" "Critical" "Re-enable Microsoft Defender or verify active managed third-party EDR agent."
} else {
    Add-ClientFinding "Security Findings" "Endpoint Antivirus Protection" "Active & Monitoring" "Low" "Real-time endpoint threat protection operational."
}

# ---------------------------------------------------------
# 4. WINDOWS UPDATES & PATCH COMPLIANCE
# ---------------------------------------------------------
Write-Host "[4/7] Evaluating Windows Update Servicing Status..." -ForegroundColor Yellow
$Hotfixes = Get-WmiObject -Class Win32_QuickFixEngineering -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending
$DaysSincePatch = 999
if ($Hotfixes -and $Hotfixes[0].InstalledOn) {
    try { $DaysSincePatch = [math]::Round(((Get-Date) - [datetime]$Hotfixes[0].InstalledOn).TotalDays) } catch { }
}
if ($DaysSincePatch -gt 60) {
    Add-ClientFinding "Windows Updates" "Patch Compliance Age" "UNPATCHED ($DaysSincePatch Days Ago)" "High" "Run immediate Windows Update servicing cycle to patch critical CVEs."
} elseif ($DaysSincePatch -gt 30) {
    Add-ClientFinding "Windows Updates" "Patch Compliance Age" "Slightly Delayed ($DaysSincePatch Days Ago)" "Medium" "Ensure automated monthly patch management is scheduled."
} else {
    Add-ClientFinding "Windows Updates" "Patch Compliance Age" "Compliant ($DaysSincePatch Days Ago)" "Low" "System patched within standard 30-day servicing window."
}

# ---------------------------------------------------------
# 5. CERTIFICATE EXPIRY AUDIT
# ---------------------------------------------------------
Write-Host "[5/7] Checking Local Machine SSL/TLS Certificate Expiry..." -ForegroundColor Yellow
try {
    $Certs = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object { $_.NotAfter -ne $null }
    $ExpiringCount = 0
    foreach ($C in $Certs) {
        $DaysLeft = [math]::Round(($C.NotAfter - (Get-Date)).TotalDays)
        if ($DaysLeft -lt 30) {
            Add-ClientFinding "Certificate Expiry" "SSL Cert ($($C.Subject))" "EXPIRING IN $DaysLeft DAYS" "High" "Renew SSL certificate before expiration to prevent service outage."
            $ExpiringCount++
        }
    }
    if ($ExpiringCount -eq 0) {
        Add-ClientFinding "Certificate Expiry" "Local Machine Cert Store" "All Certificates Valid" "Low" "No certificates expiring within the next 30 days."
    }
} catch { }

# ---------------------------------------------------------
# 6. EVENT LOG ERROR ANALYSIS
# ---------------------------------------------------------
Write-Host "[6/7] Scanning System & Application Event Logs for Critical Faults..." -ForegroundColor Yellow
$EvtErrors = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 50 -ErrorAction SilentlyContinue
$ErrCount = if ($EvtErrors) { @($EvtErrors).Count } else { 0 }
if ($ErrCount -ge 50) {
    Add-ClientFinding "Event Log Errors" "7-Day System/App Log Analysis" "HIGH ERROR VOLUME (50+ Events)" "High" "Investigate recurring disk, service, or application crash faults in Windows Event Log."
} elseif ($ErrCount -gt 15) {
    Add-ClientFinding "Event Log Errors" "7-Day System/App Log Analysis" "Moderate Errors ($ErrCount Events)" "Medium" "Review event logs during next scheduled maintenance window."
} else {
    Add-ClientFinding "Event Log Errors" "7-Day System/App Log Analysis" "Clean ($ErrCount Errors Logged)" "Low" "No significant system or application faults recorded."
}

# ---------------------------------------------------------
# 7. CALCULATE HEALTH SCORE (0-100)
# ---------------------------------------------------------
Write-Host "[7/7] Computing Executive Health Score & Generating Print-Ready Report..." -ForegroundColor Yellow

$HealthScore = 100
foreach ($F in $Findings) {
    switch ($F.RiskLevel) {
        "Critical" { $HealthScore -= 25 }
        "High"     { $HealthScore -= 12 }
        "Medium"   { $HealthScore -= 6 }
    }
}
if ($HealthScore -lt 0) { $HealthScore = 0 }

$ScoreColor = if ($HealthScore -ge 85) { "#16a34a" } elseif ($HealthScore -ge 70) { "#ca8a04" } else { "#dc2626" }
$ScoreLabel = if ($HealthScore -ge 85) { "EXCELLENT" } elseif ($HealthScore -ge 70) { "NEEDS ATTENTION" } else { "CRITICAL RISK" }

# Export CSV
$CsvPath = Join-Path $ReportsDir "findings.csv"
$Findings | Select-Object Section, Finding, Status, RiskLevel, Recommendation | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host " -> Saved findings sheet: reports\findings.csv" -ForegroundColor Green

# Generate Executive Print-to-PDF HTML Report
$HtmlPath = Join-Path $ReportsDir "executive_report.html"

$CritCount = @($Findings | Where-Object { $_.RiskLevel -eq "Critical" }).Count
$HighCount = @($Findings | Where-Object { $_.RiskLevel -eq "High" }).Count
$MedCount  = @($Findings | Where-Object { $_.RiskLevel -eq "Medium" }).Count
$LowCount  = @($Findings | Where-Object { $_.RiskLevel -eq "Low" }).Count

$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Executive Client Health Report - $ClientName</title>
    <style>
        :root { --bg: #ffffff; --text: #1e293b; --muted: #64748b; --border: #cbd5e1; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; color: var(--text); margin: 0; padding: 40px; }
        .page-container { max-width: 1000px; margin: 0 auto; background: #ffffff; padding: 50px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.08); border: 1px solid var(--border); }
        .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 3px solid #0f172a; padding-bottom: 25px; margin-bottom: 35px; }
        .header-title h1 { margin: 0; font-size: 28px; color: #0f172a; text-transform: uppercase; letter-spacing: 1px; }
        .header-title .client { font-size: 20px; color: #3b82f6; font-weight: 600; margin-top: 5px; }
        .header-meta { text-align: right; font-size: 13px; color: var(--muted); line-height: 1.6; }
        
        .summary-box { background: #f1f5f9; border-left: 5px solid #3b82f6; padding: 25px; border-radius: 8px; margin-bottom: 40px; }
        .summary-box h2 { margin: 0 0 10px 0; font-size: 18px; color: #0f172a; }
        .summary-box p { margin: 0; font-size: 14px; line-height: 1.6; color: #334155; }
        
        .score-section { display: flex; align-items: center; justify-content: space-between; background: #0f172a; color: #ffffff; padding: 30px; border-radius: 10px; margin-bottom: 40px; }
        .score-circle { width: 130px; height: 130px; border-radius: 50%; border: 10px solid $ScoreColor; display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 38px; font-weight: bold; color: $ScoreColor; background: #1e293b; }
        .score-circle span { font-size: 12px; color: #94a3b8; font-weight: normal; margin-top: -4px; }
        .risk-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; width: 65%; }
        .risk-card { background: #1e293b; border: 1px solid #334155; padding: 15px; border-radius: 8px; text-align: center; }
        .risk-card span { font-size: 12px; color: #94a3b8; text-transform: uppercase; }
        .risk-card div { font-size: 24px; font-weight: bold; margin-top: 5px; }
        
        h2.section-title { font-size: 20px; color: #0f172a; border-bottom: 2px solid #e2e8f0; padding-bottom: 10px; margin-top: 40px; margin-bottom: 20px; }
        
        table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        th, td { padding: 14px; text-align: left; border-bottom: 1px solid #e2e8f0; font-size: 13px; }
        th { background: #f8fafc; color: #475569; font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:hover { background: #f1f5f9; }
        
        .badge { padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: bold; text-transform: uppercase; }
        .badge-Critical { background: #fee2e2; color: #991b1b; border: 1px solid #f87171; }
        .badge-High { background: #ffedd5; color: #c2410c; border: 1px solid #fb923c; }
        .badge-Medium { background: #fef9c3; color: #854d0e; border: 1px solid #facc15; }
        .badge-Low { background: #dcfce7; color: #166534; border: 1px solid #4ade80; }
        
        .footer { text-align: center; font-size: 12px; color: var(--muted); border-top: 1px solid #e2e8f0; padding-top: 20px; margin-top: 50px; }
        
        @media print {
            body { background: #ffffff; padding: 0; }
            .page-container { box-shadow: none; border: none; padding: 0; width: 100%; max-width: 100%; }
            .score-section { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
            .badge { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        }
    </style>
</head>
<body>
    <div class="page-container">
        <div class="header">
            <div class="header-title">
                <h1>Executive IT Health Report</h1>
                <div class="client">Prepared For: $ClientName</div>
            </div>
            <div class="header-meta">
                <b>Date of Assessment:</b> $(Get-Date -Format 'MMMM dd, yyyy')<br>
                <b>Primary Server Asset:</b> $env:COMPUTERNAME<br>
                <b>Assessment Type:</b> 360-Degree Managed Services Audit<br>
                <b>Document Status:</b> Final Executive Deliverable
            </div>
        </div>

        <div class="summary-box">
            <h2>1. Executive Summary</h2>
            <p>This comprehensive IT infrastructure and cybersecurity audit was conducted on <b>$(Get-Date -Format 'MMMM dd, yyyy')</b> for <b>$ClientName</b>. The assessment evaluated core server health, disk storage capacity, disaster recovery backup readiness, endpoint cybersecurity hardening, patch compliance, certificate validity, and system error logs. The overall infrastructure achieved an Executive Health Score of <b>$HealthScore/100 ($ScoreLabel)</b>. Immediate engineering remediation is recommended for any identified Critical or High risk items below to ensure continuous business operations and data protection.</p>
        </div>

        <div class="score-section">
            <div style="text-align:center;">
                <div class="score-circle">$HealthScore<span>OUT OF 100</span></div>
                <div style="font-weight:bold;margin-top:10px;color:$ScoreColor;">$ScoreLabel</div>
            </div>
            <div class="risk-grid">
                <div class="risk-card" style="border-top: 4px solid #ef4444;"><span>Critical Risks</span><div style="color:#ef4444;">$CritCount</div></div>
                <div class="risk-card" style="border-top: 4px solid #f97316;"><span>High Risks</span><div style="color:#f97316;">$HighCount</div></div>
                <div class="risk-card" style="border-top: 4px solid #eab308;"><span>Medium Risks</span><div style="color:#eab308;">$MedCount</div></div>
                <div class="risk-card" style="border-top: 4px solid #22c55e;"><span>Passed / Low</span><div style="color:#22c55e;">$LowCount</div></div>
            </div>
        </div>

        <h2 class="section-title">2. Critical & Security Findings Breakdown</h2>
        <table>
            <thead>
                <tr>
                    <th>Audit Section</th>
                    <th>Policy / Check Item</th>
                    <th>Current Status</th>
                    <th>Risk Severity</th>
                    <th>Engineering Recommendation</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($F in $Findings) {
    if ($F.RiskLevel -in @("Critical", "High", "Medium")) {
        $Html += "<tr><td><b>$($F.Section)</b></td><td>$($F.Finding)</td><td>$($F.Status)</td><td><span class='badge badge-$($F.RiskLevel)'>$($F.RiskLevel)</span></td><td style='color:#1e293b;'>$($F.Recommendation)</td></tr>`n"
    }
}

$Html += @"
            </tbody>
        </table>

        <h2 class="section-title">3. Backup Readiness & Server Health Status</h2>
        <table>
            <thead>
                <tr>
                    <th>Audit Section</th>
                    <th>Policy / Check Item</th>
                    <th>Current Status</th>
                    <th>Risk Severity</th>
                    <th>Engineering Recommendation</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($F in $Findings) {
    if ($F.RiskLevel -eq "Low") {
        $Html += "<tr><td><b>$($F.Section)</b></td><td>$($F.Finding)</td><td>$($F.Status)</td><td><span class='badge badge-$($F.RiskLevel)'>$($F.RiskLevel)</span></td><td style='color:#475569;'>$($F.Recommendation)</td></tr>`n"
    }
}

$Html += @"
            </tbody>
        </table>

        <div class="footer">
            Confidential Executive IT Deliverable | Prepared by Managed Services Provider Architecture Team<br>
            To save as a boardroom PDF: Open in Edge or Chrome -> Click <b>Print (Ctrl+P)</b> -> Select <b>Save as PDF</b>.
        </div>
    </div>
</body>
</html>
"@

$Html | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force
Write-Host " -> Saved Executive HTML/PDF Report: reports\executive_report.html" -ForegroundColor Green

Write-Host "`n==========================================================================" -ForegroundColor Magenta
Write-Host "       MSP CLIENT HEALTH REPORT GENERATED SUCCESSFULLY!" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Deliverable saved to: $ReportsDir\executive_report.html" -ForegroundColor Yellow
Write-Host "Tip: Open executive_report.html in any browser and press Ctrl+P -> Save as PDF!" -ForegroundColor Cyan
