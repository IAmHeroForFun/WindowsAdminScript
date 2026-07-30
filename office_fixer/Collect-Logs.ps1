# Diagnostics: Collects Windows system, installation, and application event logs for Microsoft Office
$ErrorActionPreference = "SilentlyContinue"

# Try to bypass Execution Policy for the current session/process
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Helper function for user prompts
function Get-UserApproval ($Message) {
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    $Response = Read-Host "Proceed? (Y/N)"
    return ($Response -eq "Y" -or $Response -eq "y")
}

# Logger helper
function Log-Msg ($Msg, $Type="INFO") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Type] $Msg"
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

if (-not (Get-UserApproval "Collect detailed event logs, system diagnostics, and Office logs into the Logs folder?")) {
    Log-Msg "Log collection skipped by user." "WARN"
    return 0
}

Log-Msg "Starting system diagnostics and log collection..."
$LogsDir = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

# 1. Gather Event Logs (Application & System)
Log-Msg "Querying Event Viewer for recent Office application crashes and warnings..."
$EventReportFile = Join-Path $LogsDir "Office_Event_Logs.txt"
$EventReport = [System.Collections.ArrayList]@()
$EventReport.Add("==========================================================================")
$EventReport.Add("OFFICE CRASH & WARNING EVENTS REPORT")
$EventReport.Add("Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$EventReport.Add("==========================================================================")

try {
    $Events = Get-EventLog -LogName Application -EntryType Error, Warning -Newest 100 -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -match "Office|MSI|Application Error|Winword|Excel|Powerpnt|Outlook" }
    
    foreach ($Ev in $Events) {
        $EventReport.Add("")
        $EventReport.Add("TimeGenerated : $($Ev.TimeGenerated)")
        $EventReport.Add("Source        : $($Ev.Source)")
        $EventReport.Add("EntryType     : $($Ev.EntryType)")
        $EventReport.Add("EventID       : $($Ev.EventID)")
        $EventReport.Add("Message       : $($Ev.Message)")
        $EventReport.Add("--------------------------------------------------------------------------")
    }
} catch {
    $EventReport.Add("Failed to query Event Logs: $($_.Exception.Message)")
}
$EventReport | Out-File -FilePath $EventReportFile -Encoding UTF8 -Force
Log-Msg "  [OK] Exported event logs to: $EventReportFile"

# 2. Gather Running Processes
Log-Msg "Gathering list of running Office and Installer processes..."
$ProcFile = Join-Path $LogsDir "Running_Office_Processes.txt"
$ProcList = Get-Process | Where-Object { $_.ProcessName -match "winword|excel|powerpnt|outlook|msaccess|mspub|onenote|msiexec|office" }
if ($ProcList) {
    $ProcList | Select-Object Id, ProcessName, CPU, WorkingSet | Out-File -FilePath $ProcFile -Encoding UTF8 -Force
    Log-Msg "  [OK] Exported active processes list to: $ProcFile"
} else {
    Log-Msg "No active Office processes running currently."
}

# 3. Gather Installed Updates
Log-Msg "Querying installed OS hotfixes..."
$UpdateFile = Join-Path $LogsDir "Installed_Hotfixes.txt"
try {
    Get-HotFix | Select-Object Source, Description, HotFixID, InstalledBy, InstalledOn | Out-File -FilePath $UpdateFile -Encoding UTF8 -Force
    Log-Msg "  [OK] Exported hotfix list to: $UpdateFile"
} catch {}

# 4. Gather Click-to-Run diagnostic log paths
Log-Msg "Locating temporary Click-to-Run installation logs..."
$C2rLogs = Get-ChildItem -Path $env:TEMP -Filter "*ClickToRun*.log" -File -Force -ErrorAction SilentlyContinue
$CollectedC2rCount = 0
foreach ($Log in $C2rLogs) {
    $DestFile = Join-Path $LogsDir $Log.Name
    Copy-Item -Path $Log.FullName -Destination $DestFile -Force
    $CollectedC2rCount++
}
if ($CollectedC2rCount -gt 0) {
    Log-Msg "  [OK] Copied $CollectedC2rCount Click-to-Run temporary installation logs."
}

Log-Msg "Log collection completed."
return 0
