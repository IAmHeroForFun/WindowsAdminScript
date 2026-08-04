# Enables MS SQL Server Browser Service & TCP/IP Network Protocols
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

if (-not (Get-UserApproval "Repair Microsoft SQL Server Browser service & enable TCP/IP Network Protocols?")) {
    Log-Msg "MS SQL Server protocol repairs skipped by user." "WARN"
    return 0
}

Log-Msg "Auditing Microsoft SQL Server services and protocols..."

# 1. Enable and Start SQL Server Browser Service (SQLBrowser)
$BrowserSvc = Get-Service -Name "SQLBrowser" -ErrorAction SilentlyContinue
if ($BrowserSvc) {
    Log-Msg "SQL Server Browser Service status: $($BrowserSvc.Status)"
    if (Get-UserApproval "Set SQL Server Browser Service to Automatic startup & start it (Required for SQLEXPRESS named instances)?") {
        try {
            Set-Service -Name "SQLBrowser" -StartupType Automatic -ErrorAction Stop
            Start-Service -Name "SQLBrowser" -ErrorAction Stop
            Log-Msg "  [OK] SQL Server Browser Service enabled & started successfully."
        } catch {
            Log-Msg "  [ERROR] Failed to start SQL Browser service: $($_.Exception.Message)" "ERROR"
        }
    }
} else {
    Log-Msg "SQL Server Browser Service ('SQLBrowser') is not installed." "WARN"
}

# 2. Enable TCP/IP Protocol in Registry / WMI for SQL Instances
$SqlRegKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server"
)

foreach ($RegPath in $SqlRegKeys) {
    if (Test-Path $RegPath) {
        $InstalledInstances = Get-ItemProperty -Path $RegPath -Name "InstalledInstances" -ErrorAction SilentlyContinue
        if ($InstalledInstances -and $InstalledInstances.InstalledInstances) {
            foreach ($Inst in $InstalledInstances.InstalledInstances) {
                Log-Msg "Detected MS SQL Instance: $Inst"
                if (Get-UserApproval "Enable TCP/IP network protocol for SQL Instance '$Inst'?") {
                    try {
                        # Path for SuperSocketNetLib\Tcp
                        $InstSubkeys = Get-ChildItem -Path $RegPath -ErrorAction SilentlyContinue
                        foreach ($Sub in $InstSubkeys) {
                            $TcpPath = Join-Path $Sub.PSPath "MSSQLServer\SuperSocketNetLib\Tcp"
                            if (Test-Path $TcpPath) {
                                Set-ItemProperty -Path $TcpPath -Name "Enabled" -Value 1 -PropertyType DWord -Force | Out-Null
                                Log-Msg "  [OK] Enabled TCP/IP protocol in registry for '$Inst'."
                            }
                        }
                    } catch {
                        Log-Msg "  [ERROR] Failed to enable TCP/IP for '$Inst': $($_.Exception.Message)" "ERROR"
                    }
                }
            }
        }
    }
}

# 3. Restart SQL Server Services to Apply Protocol Changes
$SqlServices = Get-Service | Where-Object { $_.Name -match "MSSQL|MSSQLSERVER|SQLEXPRESS" }
if ($SqlServices) {
    if (Get-UserApproval "Restart active MS SQL Server services to apply network protocol changes?") {
        foreach ($Svc in $SqlServices) {
            try {
                Restart-Service -Name $Svc.Name -Force -ErrorAction Stop
                Log-Msg "  [OK] Restarted SQL Service: $($Svc.Name)"
            } catch {
                Log-Msg "  [WARN] Could not restart $($Svc.Name): $($_.Exception.Message)" "WARN"
            }
        }
    }
}

Log-Msg "MS SQL Server protocol repairs completed."
return 0
