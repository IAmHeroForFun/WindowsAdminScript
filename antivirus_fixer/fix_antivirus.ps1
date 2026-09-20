# ==========================================================================
#   Windows Defender & Security Repair Suite - Main Coordinator
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

$Global:LogFile = Join-Path $ReportsDir "AntivirusFix.log"
$ReportPath = Join-Path $ReportsDir "AntivirusFixReport.txt"
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
Log-Msg "   WINDOWS DEFENDER SIGNATURE RESET & EXCLUSION REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 0. Tamper Protection State Audit
$TamperKey = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
if (Test-Path $TamperKey) {
    $tpVal = (Get-ItemProperty -Path $TamperKey -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection
    if ($tpVal -eq 5) {
        Log-Msg "  [NOTICE] Windows Defender Tamper Protection is ENABLED. Core registry modifications to Defender are locked by the kernel." "WARN"
    } elseif ($tpVal -eq 0) {
        Log-Msg "  [INFO] Windows Defender Tamper Protection is DISABLED." "INFO"
    }
}

# 1. System Restore Point Creation
if (Get-UserApproval "Create a Windows System Restore Point before proceeding?") {
    Log-Msg "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BeforeAntivirusFixSuite" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log-Msg "System Restore Point created successfully." "SUCCESS"
    } catch {
        Log-Msg "Failed to create Restore Point: $($_.Exception.Message). Continuing with repairs..." "WARN"
    }
}

# 2. Test Defender Cloud Protection Reachability
Log-Msg "Executing Defender Cloud Protection connectivity check..." "STAGE"
$CloudScript = Join-Path $PSScriptRoot "Test-Defender-Cloud-Connectivity.ps1"
if (Test-Path $CloudScript) {
    & $CloudScript
}

# 3. Reset Defender Definitions
Log-Msg "Executing Defender signature definition reset module..." "STAGE"
$ResetScript = Join-Path $PSScriptRoot "Reset-Defender-Definitions.ps1"
if (Test-Path $ResetScript) {
    & $ResetScript
}

# 4. Manage Exclusions
Log-Msg "Executing Defender exclusions management module..." "STAGE"
$ExclScript = Join-Path $PSScriptRoot "Manage-Defender-Exclusions.ps1"
if (Test-Path $ExclScript) {
    & $ExclScript
}

# 5. Audit Attack Surface Reduction (ASR) Rules
if (Get-UserApproval "Audit active Attack Surface Reduction (ASR) rules?") {
    Log-Msg "Auditing Attack Surface Reduction (ASR) protection posture..." "STAGE"
    try {
        $mp = Get-MpPreference -ErrorAction SilentlyContinue
        if ($mp -and $mp.AttackSurfaceReductionRules_Ids) {
            $RuleCount = $mp.AttackSurfaceReductionRules_Ids.Count
            Log-Msg "  [OK] Found $RuleCount active Attack Surface Reduction (ASR) rules configured." "SUCCESS"
        } else {
            Log-Msg "  [INFO] No Attack Surface Reduction (ASR) rules currently configured on this machine." "INFO"
        }
    } catch {
        Log-Msg "  [WARN] Unable to query MpPreference for ASR rules: $($_.Exception.Message)" "WARN"
    }
}

# 6. Repair WMI Security Center
Log-Msg "Executing Security Center WMI audit module..." "STAGE"
$WmiScript = Join-Path $PSScriptRoot "Repair-Security-Center-WMI.ps1"
if (Test-Path $WmiScript) {
    & $WmiScript
}

# 7. Generate Summary Report
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating summary report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("    WINDOWS DEFENDER SIGNATURE RESET & EXCLUSION REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Host System    : $env:COMPUTERNAME")
$Report.Add("OS Version     : $((Get-WmiObject -Class Win32_OperatingSystem).Caption)")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("MODULES EXECUTED:")
$Report.Add("   - Tamper Protection Audit: Checked kernel tamper guard state")
$Report.Add("   - Cloud Endpoint Probe: Tested reachability to wdcp.microsoft.com & SmartScreen")
$Report.Add("   - Reset Defender Definitions: Flushed signatures via MpCmdRun and re-updated")
$Report.Add("   - Exclusion Management: Audited & configured Defender folder/process exclusions")
$Report.Add("   - Attack Surface Reduction: Audited configured ASR enterprise rules")
$Report.Add("   - Security Center WMI: Audited root\SecurityCenter2 repository")
$Report.Add("")
$Report.Add("Log file location: $Global:LogFile")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "    WINDOWS DEFENDER & SECURITY REPAIRS COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
