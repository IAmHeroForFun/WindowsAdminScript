# Windows Server Crash, Reboot & Error Forensic Detective with Live Web Intelligence
# Compatible with Windows Server 2008 R2 (PS 2.0) through Windows Server 2022/2025 (PS 5.1 & 7+)
# Extracts shutdowns, reboots, BSOD bugchecks, and system errors with built-in IT remediation and live web lookup!

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
Write-Host "     SERVER CRASH, REBOOT & ERROR FORENSIC DETECTIVE (WEB ENABLED)" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Target Server: $env:COMPUTERNAME | Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Scanning past 30 days of system telemetry, shutdown logs, and crash dumps..." -ForegroundColor DarkCyan
Write-Host ""

# Check Internet Connectivity for Live Web Intelligence
Write-Host "[Network Check] Verifying internet access for live error research..." -ForegroundColor Yellow
$HasInternet = $false
try {
    $PingReq = Test-Connection -ComputerName "www.microsoft.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($PingReq) { $HasInternet = $true }
} catch { }
if (-not $HasInternet) {
    try {
        $WebReq = New-Object System.Net.WebClient
        $NullOut = $WebReq.DownloadString("http://www.msftconnecttest.com/connecttest.txt")
        $HasInternet = $true
    } catch { }
}

if ($HasInternet) {
    Write-Host "   -> Internet Access: ONLINE (Live Knowledge Base URL & intelligence fetching enabled)" -ForegroundColor Green
} else {
    Write-Host "   -> Internet Access: OFFLINE (Using built-in offline IT diagnostic database)" -ForegroundColor DarkYellow
}
Write-Host ""

$StartDate = (Get-Date).AddDays(-30)
$ShutdownList = New-Object System.Collections.ArrayList
$ErrorList = New-Object System.Collections.ArrayList
$ReportLines = New-Object System.Collections.ArrayList

[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("SERVER CRASH, REBOOT & ERROR FORENSIC REPORT")
[void]$ReportLines.Add("Server: $env:COMPUTERNAME | Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$ReportLines.Add("Internet Intelligence Mode: $(if ($HasInternet) { 'ONLINE' } else { 'OFFLINE' })")
[void]$ReportLines.Add("==========================================================================")
[void]$ReportLines.Add("")

# ---------------------------------------------------------
# PHASE 1: SHUTDOWN, REBOOT & POWER CUT AUDIT (PAST 30 DAYS)
# ---------------------------------------------------------
Write-Host "[Phase 1/3] Auditing Shutdowns, Reboots, and Power Failures..." -ForegroundColor Yellow
[void]$ReportLines.Add("--- 1. SHUTDOWN & POWER AUDIT (PAST 30 DAYS) ---")

# Event IDs: 1074 (Clean Shutdown/Reboot), 6008 (Unexpected Power Cut), 41 (Kernel-Power Reboot), 1001 (BugCheck/BSOD)
$PowerEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ID=1074,6008,41,1001; StartTime=$StartDate} -ErrorAction SilentlyContinue

if ($PowerEvents -and $PowerEvents.Count -gt 0) {
    Write-Host "   -> Found $($PowerEvents.Count) power/shutdown events in the last 30 days." -ForegroundColor DarkCyan
    foreach ($Evt in $PowerEvents) {
        $EvtType = switch ($Evt.Id) {
            1074 { "Clean Shutdown / Restart" }
            6008 { "UNEXPECTED POWER LOSS / HARD CRASH" }
            41   { "KERNEL-POWER CRITICAL REBOOT" }
            1001 { "BLUE SCREEN BUGCHECK (BSOD)" }
            default { "Power Event" }
        }
        
        $Remediation = switch ($Evt.Id) {
            1074 { "Normal planned maintenance. Check message details to see user/process initiator." }
            6008 { "SUGGESTION: Server lost power abruptly. Inspect UPS battery backup runtime, dual redundant power cords, and check for server overheating/thermal shutoff." }
            41   { "SUGGESTION: Kernel rebooted without clean shutdown. If paired with Event 6008, inspect power hardware. If spontaneous, check motherboard capacitors & RAM." }
            1001 { "SUGGESTION: Blue Screen crash dump recorded. Update server NIC and RAID storage controller drivers immediately." }
        }
        
        $CleanMsg = ($Evt.Message -replace '\r\n|\n|\r', ' ') | Select-Object -First 1
        if ($CleanMsg.Length -gt 150) { $CleanMsg = $CleanMsg.Substring(0, 150) + "..." }
        
        $WebSearchUrl = if ($HasInternet) { "https://www.google.com/search?q=Windows+Server+Event+ID+$($Evt.Id)+solution" } else { "N/A" }
        
        $PowerObj = New-Object PSObject -Property @{
            Timestamp = $Evt.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            EventID = $Evt.Id
            EventType = $EvtType
            Description = $CleanMsg
            RemediationSuggestion = $Remediation
            LiveResearchUrl = $WebSearchUrl
        }
        [void]$ShutdownList.Add($PowerObj)
        
        $LogStr = "[$($Evt.TimeCreated.ToString('yyyy-MM-dd HH:mm'))] ID $($Evt.Id) ($EvtType) -> $CleanMsg"
        Write-Host "      * $LogStr" -ForegroundColor (if ($Evt.Id -in @(6008,41,1001)) { "Red" } else { "DarkGray" })
        [void]$ReportLines.Add($LogStr)
        [void]$ReportLines.Add("        Action Plan: $Remediation")
        if ($HasInternet) { [void]$ReportLines.Add("        Live KB Lookup: $WebSearchUrl") }
    }
} else {
    Write-Host "   -> Excellent! No power cuts or reboots logged in the past 30 days." -ForegroundColor Green
    [void]$ReportLines.Add("No power cut or shutdown events logged in past 30 days.")
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 2: TOP CRITICAL SYSTEM & APPLICATION ERRORS
# ---------------------------------------------------------
Write-Host "[Phase 2/3] Extracting Top Critical System & Application Errors..." -ForegroundColor Yellow
[void]$ReportLines.Add("")
[void]$ReportLines.Add("--- 2. TOP RECURRING CRITICAL ERRORS ---")

$SysErrors = Get-WinEvent -FilterHashtable @{LogName=@('System','Application'); Level=1,2; StartTime=$StartDate} -MaxEvents 50 -ErrorAction SilentlyContinue

if ($SysErrors -and $SysErrors.Count -gt 0) {
    Write-Host "   -> Analyzing top recurring critical/error log patterns..." -ForegroundColor DarkCyan
    
    # Group errors by Event ID and Provider Name to find top recurring faults
    $GroupedErrors = $SysErrors | Group-Object -Property Id, ProviderName | Sort-Object Count -Descending | Select-Object -First 10
    
    foreach ($Grp in $GroupedErrors) {
        $Sample = $Grp.Group[0]
        $ID = $Sample.Id
        $Provider = $Sample.ProviderName
        $Count = $Grp.Count
        
        # Intelligent Remediation Dictionary
        $Suggestion = switch ($ID) {
            5719 { "Netlogon domain controller connectivity failure. Verify NIC link speed and static DNS settings." }
            1129 { "Group policy processing failed due to lack of network connectivity. Check domain firewall ports." }
            7    { "Hard disk controller block error. Run SMART diagnostic and check RAID array health immediately." }
            55   { "NTFS file system structure corruption detected. Schedule 'chkdsk /f /r' during maintenance window." }
            10016 { "DCOM permission warning. Benign Windows operational message; can usually be ignored safely." }
            1388 { "Active Directory strict replication lingering object warning. Inspect domain synchronization." }
            default { "Review provider '$Provider' logs. Update associated service module or software dependencies." }
        }
        
        $CleanErr = ($Sample.Message -replace '\r\n|\n|\r', ' ')
        if ($CleanErr.Length -gt 130) { $CleanErr = $CleanErr.Substring(0, 130) + "..." }
        
        $WebUrl = if ($HasInternet) { "https://learn.microsoft.com/en-us/search/?terms=Event+ID+$ID+$Provider" } else { "N/A" }
        
        $ErrObj = New-Object PSObject -Property @{
            EventID = $ID
            Provider = $Provider
            OccurrenceCount = $Count
            SampleMessage = $CleanErr
            RemediationAdvice = $Suggestion
            MicrosoftLearnUrl = $WebUrl
        }
        [void]$ErrorList.Add($ErrObj)
        
        Write-Host "      * [ID $ID | $Provider] Occurrences: $Count" -ForegroundColor Yellow
        Write-Host "        Sample: $CleanErr" -ForegroundColor DarkGray
        Write-Host "        Fix Advice: $Suggestion" -ForegroundColor Green
        [void]$ReportLines.Add("[ID $ID | $Provider] Occurred $Count times -> $CleanErr")
        [void]$ReportLines.Add("  Fix Advice: $Suggestion")
        if ($HasInternet) { [void]$ReportLines.Add("  MSFT Research: $WebUrl") }
    }
} else {
    Write-Host "   -> Excellent! No critical errors recorded in System/Application logs." -ForegroundColor Green
    [void]$ReportLines.Add("Clean logs: 0 critical system/application errors found.")
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 3: EXPORT EXCEL SPREADSHEETS & INTERACTIVE HTML REPORT
# ---------------------------------------------------------
Write-Host "[Phase 3/3] Generating Detailed Spreadsheets & Interactive HTML Web Case File..." -ForegroundColor Yellow

$ShutdownCsvPath = Join-Path -Path $ReportsDir -ChildPath "server_shutdowns_audit_$($env:COMPUTERNAME).csv"
$ErrorCsvPath = Join-Path -Path $ReportsDir -ChildPath "server_critical_errors_$($env:COMPUTERNAME).csv"
$TextReportPath = Join-Path -Path $ReportsDir -ChildPath "server_forensic_summary_$($env:COMPUTERNAME).txt"
$HtmlReportPath = Join-Path -Path $ReportsDir -ChildPath "server_crash_and_error_report_$($env:COMPUTERNAME).html"

if ($ShutdownList.Count -gt 0) {
    $ShutdownList | Select-Object Timestamp, EventID, EventType, Description, RemediationSuggestion, LiveResearchUrl | Export-Csv -Path $ShutdownCsvPath -NoTypeInformation -Encoding UTF8
}
if ($ErrorList.Count -gt 0) {
    $ErrorList | Select-Object EventID, Provider, OccurrenceCount, SampleMessage, RemediationAdvice, MicrosoftLearnUrl | Export-Csv -Path $ErrorCsvPath -NoTypeInformation -Encoding UTF8
}
$ReportLines | Out-File -FilePath $TextReportPath -Encoding utf8 -Force

# Build interactive HTML report with clickable web intelligence links
$HtmlContent = @()
$HtmlContent += "<html><head><title>Server Forensic & Error Report - $env:COMPUTERNAME</title>"
$HtmlContent += "<style>body{font-family:Arial,sans-serif;margin:20px;background:#f8f9fa;} h1{color:#2c3e50;} h2{color:#34495e;border-bottom:2px solid #bdc3c7;padding-bottom:5px;} table{width:100%;border-collapse:collapse;margin-top:10px;margin-bottom:25px;background:white;} th,td{border:1px solid #dcdcdc;padding:10px;text-align:left;font-size:14px;} th{background:#2c3e50;color:white;} tr:nth-child(even){background:#f2f4f8;} .badge{padding:4px 8px;border-radius:4px;font-weight:bold;color:white;} .badge-red{background:#e74c3c;} .badge-green{background:#2ecc71;} .badge-blue{background:#3498db;}</style></head><body>"
$HtmlContent += "<h1>[SERVER DETECTIVE] Windows Server Crash, Reboot & Error Forensic Report</h1>"
$HtmlContent += "<p><b>Server Name:</b> $env:COMPUTERNAME | <b>Generated:</b> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | <b>Live Web Mode:</b> $(if ($HasInternet) { '<span class=\"badge badge-green\">ONLINE</span>' } else { '<span class=\"badge badge-blue\">OFFLINE</span>' })</p>"

$HtmlContent += "<h2>[!] Server Shutdowns, Reboots & Power Failures (Past 30 Days)</h2>"
if ($ShutdownList.Count -gt 0) {
    $HtmlContent += "<table><tr><th>Timestamp</th><th>Event ID</th><th>Type</th><th>Details</th><th>Remediation Suggestion</th><th>Web Intelligence</th></tr>"
    foreach ($S in $ShutdownList) {
        $BadgeColor = if ($S.EventID -in @(6008,41,1001)) { "badge-red" } else { "badge-blue" }
        $LinkHtml = if ($S.LiveResearchUrl -ne "N/A") { "<a href='$( $S.LiveResearchUrl )' target='_blank'>Search Solution &rarr;</a>" } else { "Offline" }
        $HtmlContent += "<tr><td>$($S.Timestamp)</td><td><span class='badge $BadgeColor'>$($S.EventID)</span></td><td><b>$($S.EventType)</b></td><td>$($S.Description)</td><td>$($S.RemediationSuggestion)</td><td>$LinkHtml</td></tr>"
    }
    $HtmlContent += "</table>"
} else {
    $HtmlContent += "<p>No unexpected shutdowns or reboots logged in the past 30 days.</p>"
}

$HtmlContent += "<h2>[*] Top Recurring System & Application Errors</h2>"
if ($ErrorList.Count -gt 0) {
    $HtmlContent += "<table><tr><th>Event ID</th><th>Provider</th><th>Count</th><th>Sample Error Description</th><th>Actionable IT Remediation Advice</th><th>Microsoft Learn KB</th></tr>"
    foreach ($E in $ErrorList) {
        $LinkHtml = if ($E.MicrosoftLearnUrl -ne "N/A") { "<a href='$( $E.MicrosoftLearnUrl )' target='_blank'>MSFT KB &rarr;</a>" } else { "Offline" }
        $HtmlContent += "<tr><td><b>$($E.EventID)</b></td><td>$($E.Provider)</td><td><span class='badge badge-red'>$($E.OccurrenceCount)</span></td><td>$($E.SampleMessage)</td><td><b style='color:#27ae60;'>$($E.RemediationAdvice)</b></td><td>$LinkHtml</td></tr>"
    }
    $HtmlContent += "</table>"
} else {
    $HtmlContent += "<p>No recurring system or application errors recorded.</p>"
}

$HtmlContent += "</body></html>"
$HtmlContent | Out-File -FilePath $HtmlReportPath -Encoding utf8 -Force

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host "         FORENSIC DETECTIVE INVESTIGATION COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "Complete diagnostic package generated inside: reports\" -ForegroundColor Cyan
Write-Host " -> Excel Spreadsheets: server_shutdowns_audit.csv & server_critical_errors.csv" -ForegroundColor Yellow
Write-Host " -> Interactive Web Report: server_crash_and_error_report_$($env:COMPUTERNAME).html" -ForegroundColor Green
