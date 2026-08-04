# Scans active local listening sockets and correlates database server processes
$ErrorActionPreference = "SilentlyContinue"

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

if (-not (Get-UserApproval "Scan active TCP/UDP listening sockets for database engines?")) {
    Log-Msg "Connectivity audit skipped by user." "WARN"
    return 0
}

Log-Msg "Auditing database sockets and active listeners..."

$DatabasePorts = @(1433, 1434, 3306, 5432, 1521, 27017, 6379)
$AuditResults = @()

try {
    $NetConns = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    foreach ($Conn in $NetConns) {
        if ($DatabasePorts -contains $Conn.LocalPort) {
            $Proc = Get-Process -Id $Conn.OwningProcess -ErrorAction SilentlyContinue
            $ProcName = if ($Proc) { $Proc.ProcessName } else { "Unknown" }
            
            Log-Msg "  [LISTENING] Port: $($Conn.LocalPort) | PID: $($Conn.OwningProcess) | Process: $ProcName" "SUCCESS"
            $AuditResults += [PSCustomObject]@{
                Port        = $Conn.LocalPort
                Protocol    = "TCP"
                PID         = $Conn.OwningProcess
                ProcessName = $ProcName
                Status      = "Listening"
            }
        }
    }
} catch {
    Log-Msg "  [WARN] Could not query NetTCPConnection: $($_.Exception.Message)" "WARN"
}

$Global:SqlAuditReport = $AuditResults
Log-Msg "Database socket audit completed."
return 0
