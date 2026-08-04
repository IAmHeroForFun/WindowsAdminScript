# ==========================================================================
#   Database & SQL Server Port & Protocol Repair Suite - Main Coordinator
# ==========================================================================
$ErrorActionPreference = "SilentlyContinue"

# Ensure $PSScriptRoot is defined
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Definition) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $PSScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Centralized report directory handling
$ReportsDir = $null
$ParentDir = Split-Path -Parent -Path $PSScriptRoot
if ($ParentDir -match "SysMaster") {
    $ReportsDir = Join-Path $ParentDir "reports"
} else {
    $ReportsDir = Join-Path $PSScriptRoot "Logs"
}
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

$Global:LogFile = Join-Path $ReportsDir "SqlFix.log"
$ReportPath = Join-Path $ReportsDir "SqlFixReport.txt"
$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
} catch {}

# Helper function for user prompts
function Get-UserApproval ($Message) {
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    $Response = Read-Host "Proceed? (Y/N, Q to Cancel)"
    if ($Response -eq "Q" -or $Response -eq "q") {
        Write-Host "Operation cancelled by user. Returning..." -ForegroundColor Yellow
        exit 0
    }
    return ($Response -eq "Y" -or $Response -eq "y")
}

# Logger helper
function Log-Msg ($Msg, $Type="INFO") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Type] $Msg"
    
    $Color = "Gray"
    if ($Type -eq "ERROR") { $Color = "Red" }
    elseif ($Type -eq "WARN") { $Color = "Yellow" }
    elseif ($Type -eq "SUCCESS") { $Color = "Green" }
    elseif ($Type -eq "STAGE") { $Color = "Cyan" }
    
    Write-Host $Formatted -ForegroundColor $Color
    $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
}

Clear-Host
Log-Msg "==========================================================================" "STAGE"
Log-Msg "     DATABASE & SQL SERVER PORT & PROTOCOL REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 1. System Restore Point Creation
if (Get-UserApproval "Create a Windows System Restore Point before proceeding?") {
    Log-Msg "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BeforeSqlPortAndProtocolFix" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log-Msg "System Restore Point created successfully." "SUCCESS"
    } catch {
        Log-Msg "Failed to create Restore Point: $($_.Exception.Message). Continuing with repairs..." "WARN"
    }
}

# 2. Fix Firewall Ports
Log-Msg "Executing Database Firewall port unblocking module..." "STAGE"
$FwScript = Join-Path $PSScriptRoot "Fix-SQL-Firewall-Ports.ps1"
if (Test-Path $FwScript) {
    & $FwScript
}

# 3. Fix MS SQL Server Protocols & Services
Log-Msg "Executing MS SQL Server protocol & service repair module..." "STAGE"
$MssqlScript = Join-Path $PSScriptRoot "Fix-MSSQL-Services-Protocols.ps1"
if (Test-Path $MssqlScript) {
    & $MssqlScript
}

# 4. Audit Active Listening Sockets
Log-Msg "Executing socket audit module..." "STAGE"
$AuditScript = Join-Path $PSScriptRoot "Audit-SQL-Connectivity.ps1"
if (Test-Path $AuditScript) {
    & $AuditScript
}

# 5. Generate Summary Report
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("        DATABASE & SQL SERVER PORT & PROTOCOL REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("OS Version     : $((Get-WmiObject -Class Win32_OperatingSystem).Caption)")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("CONFIGURED FIREWALL PORTS:")
$Report.Add("   - MS SQL Server (TCP 1433)")
$Report.Add("   - MS SQL Browser (UDP 1434)")
$Report.Add("   - MySQL / MariaDB (TCP 3306)")
$Report.Add("   - PostgreSQL (TCP 5432)")
$Report.Add("   - Oracle Listener (TCP 1521)")
$Report.Add("   - MongoDB (TCP 27017)")
$Report.Add("   - Redis Cache (TCP 6379)")
$Report.Add("")
$Report.Add("ACTIVE LISTENING SOCKETS FOUND:")
if ($Global:SqlAuditReport -and $Global:SqlAuditReport.Count -gt 0) {
    foreach ($Res in $Global:SqlAuditReport) {
        $Report.Add("   - Port $($Res.Port) ($($Res.Protocol)) | PID: $($Res.PID) | Process: $($Res.ProcessName)")
    }
} else {
    $Report.Add("   - No active database listening sockets detected on standard ports.")
}
$Report.Add("")
$Report.Add("Log file location: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "    DATABASE & SQL PORT & PROTOCOL REPAIRS COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
