# Diagnostics: Checks and restarts required Microsoft Office licensing and updater services
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

if (-not (Get-UserApproval "Verify, remediate, and restart Microsoft Office & system licensing services?")) {
    Log-Msg "Services verification skipped by user." "WARN"
    return 0
}

Log-Msg "Auditing required system services..."

$ServicesToAudit = @(
    @{ Name = "sppsvc"; DefaultStart = "Automatic"; Display = "Software Protection" }
    @{ Name = "osppsvc"; DefaultStart = "Manual"; Display = "Office Software Protection Platform" }
    @{ Name = "ClickToRunSvc"; DefaultStart = "Automatic"; Display = "Microsoft Office Click-to-Run Service" }
    @{ Name = "msiserver"; DefaultStart = "Manual"; Display = "Windows Installer" }
    @{ Name = "RpcSs"; DefaultStart = "Automatic"; Display = "Remote Procedure Call (RPC)" }
    @{ Name = "EventSystem"; DefaultStart = "Automatic"; Display = "COM+ Event System" }
    @{ Name = "Schedule"; DefaultStart = "Automatic"; Display = "Task Scheduler" }
)

$ServiceStatuses = @()

foreach ($Svc in $ServicesToAudit) {
    $ServiceObj = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    if (-not $ServiceObj) {
        Log-Msg "Service '$($Svc.Name)' ($($Svc.Display)) is not installed on this system." "WARN"
        $ServiceStatuses += [PSCustomObject]@{ Service = $Svc.Name; Status = "Not Installed"; StartType = "N/A" }
        continue
    }

    $Status = $ServiceObj.Status
    $StartType = "Unknown"
    try {
        if ($PSVersionTable.PSVersion.Major -ge 3) {
            $StartType = $ServiceObj.StartType
        } else {
            $WmiSvc = Get-WmiObject -Class Win32_Service -Filter "Name='$($Svc.Name)'"
            if ($WmiSvc) { $StartType = $WmiSvc.StartMode }
        }
    } catch {}

    Log-Msg "Service: $($Svc.Name) ($($Svc.Display)) | Status: $Status | StartType: $StartType"

    $ServiceStatuses += [PSCustomObject]@{ Service = $Svc.Name; Status = $Status.ToString(); StartType = $StartType.ToString() }

    # Remediate disabled services
    if ($StartType -eq "Disabled" -or $StartType -eq "disabled") {
        if (Get-UserApproval "Service '$($Svc.Name)' is Disabled. Enable it and set startup type to $($Svc.DefaultStart)?") {
            try {
                Set-Service -Name $Svc.Name -StartupType $Svc.DefaultStart -ErrorAction Stop
                Log-Msg "  [OK] Successfully changed startup type of '$($Svc.Name)' to $($Svc.DefaultStart)."
            } catch {
                Log-Msg "  [ERROR] Failed to modify startup type of '$($Svc.Name)': $($_.Exception.Message)" "ERROR"
            }
        }
    }

    if ($Status -ne "Running" -and $Svc.Name -ne "osppsvc" -and $Svc.Name -ne "msiserver") {
        if (Get-UserApproval "Service '$($Svc.Name)' is stopped. Start the service now?") {
            try {
                Start-Service -Name $Svc.Name -ErrorAction Stop
                Log-Msg "  [OK] Successfully started service '$($Svc.Name)'."
            } catch {
                Log-Msg "  [ERROR] Failed to start service '$($Svc.Name)': $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

$Global:ServiceReport = $ServiceStatuses

Log-Msg "Services audit completed."
return 0
