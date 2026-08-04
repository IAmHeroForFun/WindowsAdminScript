# Unblocks database engine ports in Windows Defender Firewall
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

if (-not (Get-UserApproval "Audit and unblock database ports in Windows Firewall (SQL Server, MySQL, PostgreSQL, Oracle, etc.)?")) {
    Log-Msg "Database firewall unblocking skipped by user." "WARN"
    return 0
}

Log-Msg "Starting Database Firewall port configuration..."

$PortsToConfigure = @(
    @{ Name = "SQL Server (TCP 1433)"; Port = 1433; Protocol = "TCP"; Engine = "Microsoft SQL Server" }
    @{ Name = "SQL Browser (UDP 1434)"; Port = 1434; Protocol = "UDP"; Engine = "Microsoft SQL Browser" }
    @{ Name = "MySQL / MariaDB (TCP 3306)"; Port = 3306; Protocol = "TCP"; Engine = "MySQL / MariaDB" }
    @{ Name = "PostgreSQL (TCP 5432)"; Port = 5432; Protocol = "TCP"; Engine = "PostgreSQL" }
    @{ Name = "Oracle Listener (TCP 1521)"; Port = 1521; Protocol = "TCP"; Engine = "Oracle Database" }
    @{ Name = "MongoDB (TCP 27017)"; Port = 27017; Protocol = "TCP"; Engine = "MongoDB" }
    @{ Name = "Redis Cache (TCP 6379)"; Port = 6379; Protocol = "TCP"; Engine = "Redis Cache" }
)

foreach ($Rule in $PortsToConfigure) {
    if (Get-UserApproval "Unblock Inbound $($Rule.Protocol) Port $($Rule.Port) for $($Rule.Engine)?") {
        try {
            $ExistingRule = Get-NetFirewallRule -DisplayName $Rule.Name -ErrorAction SilentlyContinue
            if ($ExistingRule) {
                Enable-NetFirewallRule -DisplayName $Rule.Name -ErrorAction Stop
                Log-Msg "  [OK] Enabled existing firewall rule: '$($Rule.Name)'."
            } else {
                New-NetFirewallRule -DisplayName $Rule.Name -Direction Inbound -Action Allow -Protocol $Rule.Protocol -LocalPort $Rule.Port -Profile Any -ErrorAction Stop | Out-Null
                Log-Msg "  [OK] Created & Enabled inbound firewall rule: '$($Rule.Name)'."
            }
        } catch {
            Log-Msg "  [ERROR] Failed to configure firewall rule for '$($Rule.Name)': $($_.Exception.Message)" "ERROR"
        }
    }
}

Log-Msg "Database Firewall port configuration completed."
return 0
