# ==========================================================================
#   MS Office Diagnostic & Repair Suite - Main Coordinator
#   Compatible with Windows 10 & 11 | Office 2010 - 365
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

# Create Logs directory
$LogsDir = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

$Global:LogFile = Join-Path $LogsDir "Repair.log"
$ReportPath = Join-Path $LogsDir "RepairReport.txt"
$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

# Try to bypass Execution Policy for the current session/process
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
Log-Msg "        MICROSOFT OFFICE & OUTLOOK DIAGNOSTIC & REPAIR SUITE" "STAGE"
Log-Msg "==========================================================================" "STAGE"
Log-Msg "Execution started on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 1. System Restore Point Creation
if (Get-UserApproval "Create a Windows System Restore Point before proceeding?") {
    Log-Msg "Creating System Restore Point..."
    try {
        $EnableStatus = Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BeforeOfficeRepairSuite" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log-Msg "System Restore Point created successfully." "SUCCESS"
    } catch {
        Log-Msg "Failed to create Restore Point: $($_.Exception.Message). Continuing with repairs..." "WARN"
    }
} else {
    Log-Msg "System Restore Point creation skipped." "WARN"
}

# 2. Dynamic Environment Detection
Log-Msg "Detecting OS version and Microsoft Office details..." "STAGE"

# Detect OS
$OsVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption
Log-Msg "Operating System: $OsVersion"

# Detect Office Installation & Architecture
$OfficeVersion = "Not Detected"
$OfficeArch = "Unknown"
$OfficePath = ""

$RegistrySearches = @(
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Office\Common\InstallRoot"; Arch = "64-bit / Native" }
    @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office\Common\InstallRoot"; Arch = "32-bit (on 64-bit OS)" }
)

foreach ($Search in $RegistrySearches) {
    if (Test-Path $Search.Path) {
        $RegVal = Get-ItemProperty -Path $Search.Path -ErrorAction SilentlyContinue
        $Subkeys = Get-ChildItem -Path ($Search.Path -replace "\\Common\\InstallRoot", "") -Name
        foreach ($Key in $Subkeys) {
            if ($Key -match "14\.0|15\.0|16\.0") {
                $OfficeVersion = $Key
                $OfficeArch = $Search.Arch
                $InstallPathReg = Get-ItemProperty -Path (Join-Path ($Search.Path -replace "\\Common\\InstallRoot", "") "$Key\Common\InstallRoot") -Name "Path" -ErrorAction SilentlyContinue
                if ($InstallPathReg) {
                    $OfficePath = $InstallPathReg.Path
                }
            }
        }
    }
}

if ($OfficeVersion -ne "Not Detected") {
    $VersionFriendly = "Unknown"
    if ($OfficeVersion -eq "14.0") { $VersionFriendly = "Office 2010" }
    elseif ($OfficeVersion -eq "15.0") { $VersionFriendly = "Office 2013" }
    elseif ($OfficeVersion -eq "16.0") { $VersionFriendly = "Office 2016 / 2019 / 2021 / 365" }
    Log-Msg "Microsoft Office Detected: $VersionFriendly (Registry key version $OfficeVersion) | Arch: $OfficeArch | Path: $OfficePath" "SUCCESS"
} else {
    Log-Msg "No standard Microsoft Office registry installations detected. Running generic repairs..." "WARN"
}

# 3. Dependency Check
Log-Msg "Executing dependency checking module..." "STAGE"
$DepScript = Join-Path $PSScriptRoot "Install-Dependencies.ps1"
if (Test-Path $DepScript) {
    & $DepScript
}

# 4. Service Audit
Log-Msg "Executing licensing and system services audit module..." "STAGE"
$SvcScript = Join-Path $PSScriptRoot "Check-Services.ps1"
if (Test-Path $SvcScript) {
    & $SvcScript
}

# 5. Permissions Repair
Log-Msg "Executing directory and registry permissions repair module..." "STAGE"
$PermScript = Join-Path $PSScriptRoot "Fix-Permissions.ps1"
if (Test-Path $PermScript) {
    & $PermScript
}

# 6. Profile & Settings Reset
Log-Msg "Executing profile, cache, and settings reset module..." "STAGE"
$ResetScript = Join-Path $PSScriptRoot "Reset-Office.ps1"
if (Test-Path $ResetScript) {
    & $ResetScript
}

# 7. Licensing Status check
Log-Msg "Executing licensing and activation audit module..." "STAGE"
$LicScript = Join-Path $PSScriptRoot "Export-Activation.ps1"
if (Test-Path $LicScript) {
    & $LicScript
}

# 8. Run System File Scans (SFC & DISM)
if (Get-UserApproval "Run SFC (System File Checker) to verify and fix system file corruptions?") {
    Log-Msg "Running sfc /scannow (this may take several minutes)..." "STAGE"
    $SfcOutput = cmd.exe /c "sfc /scannow" 2>&1
    $SfcOutput | Out-File -FilePath (Join-Path $LogsDir "SFC_Output.txt") -Encoding UTF8 -Force
    Log-Msg "SFC Scan complete. Log saved to SFC_Output.txt." "SUCCESS"
}

if (Get-UserApproval "Run DISM (Deployment Image Servicing and Management) system image repair?") {
    Log-Msg "Running DISM /Online /Cleanup-Image /RestoreHealth (this may take several minutes)..." "STAGE"
    $DismOutput = cmd.exe /c "dism.exe /Online /Cleanup-Image /RestoreHealth" 2>&1
    $DismOutput | Out-File -FilePath (Join-Path $LogsDir "DISM_Output.txt") -Encoding UTF8 -Force
    Log-Msg "DISM Repair complete. Log saved to DISM_Output.txt." "SUCCESS"
}

# 9. Log Collection
Log-Msg "Executing Event Viewer and diagnostics log collector..." "STAGE"
$LogScript = Join-Path $PSScriptRoot "Collect-Logs.ps1"
if (Test-Path $LogScript) {
    & $LogScript
}

# 10. Generate Final Report
$StartTime.Stop()
$ElapsedTime = $StartTime.Elapsed

Log-Msg "Generating final diagnostic report..." "STAGE"
$Report = [System.Collections.ArrayList]@()
$Report.Add("==========================================================================")
$Report.Add("           MICROSOFT OFFICE & OUTLOOK DIAGNOSTIC & REPAIR REPORT")
$Report.Add("==========================================================================")
$Report.Add("Generated on   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("Execution Time : $($ElapsedTime.ToString('hh\:mm\:ss'))")
$Report.Add("Operating Sys  : $OsVersion")
$Report.Add("Office Version : $OfficeVersion")
$Report.Add("Office Arch    : $OfficeArch")
$Report.Add("Office Path    : $OfficePath")
$Report.Add("==========================================================================")
$Report.Add("")
$Report.Add("1. SYSTEM DEPENDENCY SUMMARY:")
if ($Global:DependencyReport) {
    $Report.Add("   - .NET Framework Version: $($Global:DependencyReport.DotNetVersion)")
    $Report.Add("   - Windows Installer     : $($Global:DependencyReport.MsiVersion)")
    $Report.Add("   - Missing VC++ Runtimes : $($Global:DependencyReport.MissingRedists)")
    $Report.Add("   - KB2817430 Installed   : $($Global:DependencyReport.Sp1Installed)")
} else {
    $Report.Add("   - Dependency checks skipped or failed.")
}
$Report.Add("")
$Report.Add("2. SERVICE AUDIT SUMMARY:")
if ($Global:ServiceReport) {
    foreach ($Svc in $Global:ServiceReport) {
        $Report.Add("   - Service: $($Svc.Service) | Status: $($Svc.Status) | Startup: $($Svc.StartType)")
    }
} else {
    $Report.Add("   - Services audit skipped or failed.")
}
$Report.Add("")
$Report.Add("3. ACTIVATION & LICENSING STATUS:")
if ($Global:ActivationReport) {
    foreach ($Lic in $Global:ActivationReport) {
        $Report.Add("   - License Script: $($Lic.ScriptPath) | Status: $($Lic.Status)")
    }
} else {
    $Report.Add("   - Activation checks skipped or failed.")
}
$Report.Add("")
$Report.Add("4. PERMISSION RESTORATION ERRORS:")
if ($Global:PermissionErrors -and $Global:PermissionErrors.Count -gt 0) {
    foreach ($Err in $Global:PermissionErrors) {
        $Report.Add("   - ERROR: $Err")
    }
} else {
    $Report.Add("   - All directory & registry permissions successfully restored.")
}
$Report.Add("")
$Report.Add("5. RECOMMENDED NEXT STEPS:")
if ($Global:DependencyReport -and (($Global:DependencyReport.MissingRedists -ne "") -or ($Global:DependencyReport.Sp1Installed -eq $false))) {
    $Report.Add("   -> RECOMMENDATION: Install missing Visual C++ dependencies or KB2817430 SP1 updates.")
} else {
    $Report.Add("   -> RECOMMENDATION: Repairs have been applied. Restart your system and attempt to launch Office.")
    $Report.Add("                      If crash persists, run a full 'Online Repair' or perform a clean reinstall.")
}
$Report.Add("")
$Report.Add("Detailed execution logs: Logs\Repair.log")
$Report.Add("==========================================================================")

$Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "         MS OFFICE DIAGNOSTICS & REPAIRS COMPLETED!" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "  Process Log      : $Global:LogFile" -ForegroundColor DarkCyan
Write-Host "  Elapsed Time     : $($ElapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor DarkCyan
Write-Host ""
