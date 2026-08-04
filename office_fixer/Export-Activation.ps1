# Diagnostics: Checks license status using OSPP.vbs for installed Office versions
$ErrorActionPreference = "SilentlyContinue"

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
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

if (-not (Get-UserApproval "Check and export Microsoft Office licensing and activation states?")) {
    Log-Msg "Licensing checks skipped by user." "WARN"
    return 0
}

Log-Msg "Searching for Microsoft Office licensing scripts (OSPP.VBS)..."

$PathsToSearch = @(
    "${env:ProgramFiles}\Microsoft Office\Office14"
    "${env:ProgramFiles(x86)}\Microsoft Office\Office14"
    "${env:ProgramFiles}\Microsoft Office\Office15"
    "${env:ProgramFiles(x86)}\Microsoft Office\Office15"
    "${env:ProgramFiles}\Microsoft Office\Office16"
    "${env:ProgramFiles(x86)}\Microsoft Office\Office16"
    "${env:ProgramFiles}\Microsoft Office\root\Office16"
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16"
)

$FoundOspp = @()
foreach ($Path in $PathsToSearch) {
    $OsppFile = Join-Path $Path "OSPP.VBS"
    if (Test-Path $OsppFile) {
        $FoundOspp += $OsppFile
    }
}

if ($FoundOspp.Count -eq 0) {
    Log-Msg "Could not locate OSPP.VBS on this system. Registry-based Office installation might be Click-to-Run / UWP, or Office is not installed." "WARN"
    $Global:ActivationReport = [PSCustomObject]@{ Status = "Not Detected"; Details = "OSPP.vbs not found" }
    return 0
}

$LicenseStatuses = @()

foreach ($Ospp in $FoundOspp) {
    Log-Msg "Running licensing status query on: '$Ospp'..."
    try {
        $CmdOutput = cscript.exe //NoLogo "$Ospp" /dstatus 2>&1
        
        $CleanName = ($Ospp -replace "[\\:]", "_")
        $OutPath = Join-Path $PSScriptRoot "Logs\OSPP_Output_$CleanName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $CmdOutput | Out-File -FilePath $OutPath -Encoding UTF8 -Force
        Log-Msg "  [OK] Saved OSPP output to: $OutPath"

        $Status = "Unknown"
        foreach ($Line in $CmdOutput) {
            if ($Line -match "LICENSE STATUS:\s*(.*)") {
                $Status = $Matches[1].Trim()
                Log-Msg "  -> License Status: $Status"
            }
        }
        
        $LicenseStatuses += [PSCustomObject]@{
            ScriptPath = $Ospp
            Status     = $Status
            LogFile    = $OutPath
        }
    } catch {
        Log-Msg "  [ERROR] Failed to execute OSPP.VBS query: $($_.Exception.Message)" "ERROR"
    }
}

$Global:ActivationReport = $LicenseStatuses
Log-Msg "Office licensing audit completed."
return 0
