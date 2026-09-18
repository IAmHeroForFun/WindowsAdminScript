# ==========================================================================
#   Reset-WSUS-Policies.ps1 - WSUS Policy Inspector & Microsoft CDN Bypass
#   Remediates corporate WSUS policy locks preventing off-premise updates
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

Log-Action "Inspecting Group Policy and local WSUS configuration..." "STAGE"

$WuPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$WuAuPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

$HasWsus = $false
$WusServer = $null
$UseWus = $null

if (Test-Path $WuPolicyKey) {
    $WusServer = (Get-ItemProperty -Path $WuPolicyKey -Name "WUServer" -ErrorAction SilentlyContinue).WUServer
}
if (Test-Path $WuAuPolicyKey) {
    $UseWus = (Get-ItemProperty -Path $WuAuPolicyKey -Name "UseWUServer" -ErrorAction SilentlyContinue).UseWUServer
}

if ($WusServer -or $UseWus -eq 1) {
    $HasWsus = $true
    Log-Action "  [INFO] WSUS Server Detected: $WusServer" "WARN"
    Log-Action "  [INFO] UseWUServer Setting  : $UseWus" "WARN"
} else {
    Log-Action "  [OK] System is pointing directly to Microsoft Update (No WSUS override)." "SUCCESS"
    return
}

Write-Host ""
Write-Host ">>> If this machine is unable to contact the internal WSUS server ($WusServer)," -ForegroundColor Yellow
Write-Host "    updates will perpetually fail with error 0x8024402f or 0x8024401c." -ForegroundColor Yellow

if (Get-Command Get-UserApproval -ErrorAction SilentlyContinue) {
    $Bypass = Get-UserApproval "Bypass internal WSUS server and point machine directly to Microsoft Update Cloud CDN?"
} else {
    $Bypass = $false
}

if ($Bypass) {
    # Backup current keys
    $ParentDir = Split-Path -Parent -Path $PSScriptRoot
    $ReportsDir = if ($ParentDir -match "SysMaster") { Join-Path $ParentDir "reports" } else { Join-Path $PSScriptRoot "Logs" }
    if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
    $BackupFile = Join-Path $ReportsDir "WSUS_Policy_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"

    try {
        cmd.exe /c "reg export `"HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`" `"$BackupFile`" /y" | Out-Null
        Log-Action "  [OK] WSUS policy backed up to: $BackupFile" "SUCCESS"
    } catch {
        Log-Action "  [WARN] Could not export WSUS backup reg file." "WARN"
    }

    try {
        Set-ItemProperty -Path $WuAuPolicyKey -Name "UseWUServer" -Value 0 -Type DWord -Force | Out-Null
        Log-Action "  [OK] Successfully configured UseWUServer = 0 (Bypassing WSUS, enabling public CDN)." "SUCCESS"
        
        # Restart wuauserv to take immediate effect
        Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Log-Action "  [OK] Restarted Windows Update service with new policy." "SUCCESS"
    } catch {
        Log-Action "  [ERROR] Failed to update UseWUServer key: $($_.Exception.Message)" "ERROR"
    }
} else {
    Log-Action "WSUS policy configuration unchanged." "WARN"
}
