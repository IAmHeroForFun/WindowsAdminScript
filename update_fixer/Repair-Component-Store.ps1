# ==========================================================================
#   Repair-Component-Store.ps1 - DISM Component Store & SFC Integrity Suite
#   Reclaims superseded update space and repairs corrupted system manifests
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

function Log-Action ($Msg, $Type="INFO") {
    if (Get-Command Log-Msg -ErrorAction SilentlyContinue) {
        Log-Msg $Msg $Type
    } else {
        $Color = "Gray"
        if ($Type -eq "ERROR") { $Color = "Red" }
        elseif ($Type -eq "WARN") { $Color = "Yellow" }
        elseif ($Type -eq "SUCCESS") { $Color = "Green" }
        elseif ($Type -eq "STAGE") { $Color = "Cyan" }
        Write-Host "[$Type] $Msg" -ForegroundColor $Color
    }
}

$ParentDir = Split-Path -Parent -Path $PSScriptRoot
$ReportsDir = if ($ParentDir -match "SysMaster") { Join-Path $ParentDir "reports" } else { Join-Path $PSScriptRoot "Logs" }
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

# 1. DISM StartComponentCleanup
if (Get-Command Get-UserApproval -ErrorAction SilentlyContinue) {
    $RunCleanup = Get-UserApproval "Run DISM Component Cleanup (/StartComponentCleanup) to purge superseded updates?"
} else {
    $RunCleanup = $true
}

if ($RunCleanup) {
    Log-Action "Running DISM StartComponentCleanup (this may take 3-5 minutes)..." "STAGE"
    $CleanupLog = Join-Path $ReportsDir "DISM_Cleanup_Output.txt"
    $Output = cmd.exe /c "dism.exe /Online /Cleanup-Image /StartComponentCleanup" 2>&1
    $Output | Out-File -FilePath $CleanupLog -Encoding UTF8 -Force
    Log-Action "  [OK] Component Cleanup finished. Details saved to: $CleanupLog" "SUCCESS"
}

# 2. DISM RestoreHealth
if (Get-Command Get-UserApproval -ErrorAction SilentlyContinue) {
    $RunRestore = Get-UserApproval "Run DISM Health Restoration (/RestoreHealth) to fix corrupted component manifests?"
} else {
    $RunRestore = $true
}

if ($RunRestore) {
    Log-Action "Running DISM RestoreHealth against Windows Component Store..." "STAGE"
    $RestoreLog = Join-Path $ReportsDir "DISM_Restore_Output.txt"
    $Output = cmd.exe /c "dism.exe /Online /Cleanup-Image /RestoreHealth" 2>&1
    $Output | Out-File -FilePath $RestoreLog -Encoding UTF8 -Force
    Log-Action "  [OK] DISM RestoreHealth finished. Details saved to: $RestoreLog" "SUCCESS"
}

# 3. System File Checker (SFC)
if (Get-Command Get-UserApproval -ErrorAction SilentlyContinue) {
    $RunSfc = Get-UserApproval "Run SFC (System File Checker) to verify and fix protected system files?"
} else {
    $RunSfc = $true
}

if ($RunSfc) {
    Log-Action "Running sfc /scannow (verifying system file hashes)..." "STAGE"
    $SfcLog = Join-Path $ReportsDir "SFC_Scan_Output.txt"
    $Output = cmd.exe /c "sfc /scannow" 2>&1
    $Output | Out-File -FilePath $SfcLog -Encoding UTF8 -Force
    Log-Action "  [OK] SFC scan completed. Output saved to: $SfcLog" "SUCCESS"
}
