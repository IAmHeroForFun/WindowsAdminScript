# ==========================================================================
#   Clear-Pending-Reboot.ps1 - Windows Update & Package Install Unlocker
#   Clears lingering reboot locks preventing new updates & software installs
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

Log-Action "Inspecting system for pending reboot locks..." "STAGE"

$PendingRebootDetected = $false
$LocksFound = @()

# 1. Component Based Servicing (CBS)
$CbsKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
if (Test-Path $CbsKey) {
    $PendingRebootDetected = $true
    $LocksFound += "CBS (Component Based Servicing) RebootPending"
}

# 2. Windows Update Auto Update
$WuKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
if (Test-Path $WuKey) {
    $PendingRebootDetected = $true
    $LocksFound += "Windows Update Auto-Update RebootRequired"
}

# 3. Session Manager PendingFileRenameOperations
$SmKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$PendingFileRename = (Get-ItemProperty -Path $SmKey -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue).PendingFileRenameOperations
if ($PendingFileRename) {
    $PendingRebootDetected = $true
    $LocksFound += "Session Manager PendingFileRenameOperations ($($PendingFileRename.Count) items)"
}

# 4. Windows Server Manager Reboot Attempt Key
$SmRebootKey = "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts"
if (Test-Path $SmRebootKey) {
    $PendingRebootDetected = $true
    $LocksFound += "ServerManager CurrentRebootAttempts"
}

if (-not $PendingRebootDetected) {
    Log-Action "  [OK] No pending reboot locks detected on this system." "SUCCESS"
    return
}

Log-Action "  [WARN] Found $($LocksFound.Count) active pending reboot lock(s):" "WARN"
foreach ($Lock in $LocksFound) {
    Log-Action "    -> $Lock" "WARN"
}

if (Get-Command Get-UserApproval -ErrorAction SilentlyContinue) {
    $Proceed = Get-UserApproval "Clear active pending reboot locks so updates and installers can proceed?"
} else {
    $Proceed = $true
}

if ($Proceed) {
    Log-Action "Clearing pending reboot registry keys..." "STAGE"

    # Remove CBS Key
    if (Test-Path $CbsKey) {
        try {
            Remove-Item -Path $CbsKey -Recurse -Force -ErrorAction Stop
            Log-Action "  [OK] Cleared CBS RebootPending key." "SUCCESS"
        } catch {
            Log-Action "  [ERROR] Failed to clear CBS key: $($_.Exception.Message)" "ERROR"
        }
    }

    # Remove Windows Update Key
    if (Test-Path $WuKey) {
        try {
            Remove-Item -Path $WuKey -Recurse -Force -ErrorAction Stop
            Log-Action "  [OK] Cleared Windows Update RebootRequired key." "SUCCESS"
        } catch {
            Log-Action "  [ERROR] Failed to clear Windows Update key: $($_.Exception.Message)" "ERROR"
        }
    }

    # Clear PendingFileRenameOperations
    if ($PendingFileRename) {
        try {
            Remove-ItemProperty -Path $SmKey -Name "PendingFileRenameOperations" -Force -ErrorAction Stop
            Log-Action "  [OK] Cleared PendingFileRenameOperations." "SUCCESS"
        } catch {
            Log-Action "  [ERROR] Failed to clear PendingFileRenameOperations: $($_.Exception.Message)" "ERROR"
        }
    }

    # Clear ServerManager key
    if (Test-Path $SmRebootKey) {
        try {
            Remove-Item -Path $SmRebootKey -Recurse -Force -ErrorAction Stop
            Log-Action "  [OK] Cleared ServerManager CurrentRebootAttempts." "SUCCESS"
        } catch {
            Log-Action "  [ERROR] Failed to clear ServerManager key: $($_.Exception.Message)" "ERROR"
        }
    }

    Log-Action "Pending reboot locks cleared successfully." "SUCCESS"
} else {
    Log-Action "Skipped pending reboot clearance." "WARN"
}
