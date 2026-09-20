# Fixes Windows 11 22H2 / 23H2 RDP Disconnects and Random Session Freezes over UDP
# Forces RDP client and server to utilize stable TCP transport protocol
$ErrorActionPreference = "SilentlyContinue"

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
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } elseif ($Type -eq "SUCCESS") { "Green" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

if (-not (Get-UserApproval "Disable RDP UDP transport (fClientDisableUDP = 1) to fix Windows 11 RDP session freezes/disconnects?")) {
    Log-Msg "RDP UDP freeze fix skipped by user." "WARN"
    return 0
}

Log-Msg "Configuring RDP TCP transport enforcement (disabling buggy UDP)..."

$ClientPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client"
try {
    if (-not (Test-Path $ClientPolicyKey)) {
        New-Item -Path $ClientPolicyKey -Force | Out-Null
    }
    Set-ItemProperty -Path $ClientPolicyKey -Name "fClientDisableUDP" -Value 1 -PropertyType DWord -Force | Out-Null
    Log-Msg "  [OK] Successfully configured fClientDisableUDP = 1 on RDP Client." "SUCCESS"
} catch {
    Log-Msg "  [ERROR] Failed to set fClientDisableUDP on Client: $($_.Exception.Message)" "ERROR"
}

# Also configure server side listener if applicable
$ServerPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
try {
    if (-not (Test-Path $ServerPolicyKey)) {
        New-Item -Path $ServerPolicyKey -Force | Out-Null
    }
    Set-ItemProperty -Path $ServerPolicyKey -Name "SelectTransport" -Value 1 -PropertyType DWord -Force | Out-Null # 1 = Use only TCP
    Log-Msg "  [OK] Successfully configured SelectTransport = 1 (TCP only) on Terminal Server." "SUCCESS"
} catch {
    Log-Msg "  [WARN] Failed to set SelectTransport on Server: $($_.Exception.Message)" "WARN"
}

Log-Msg "RDP UDP transport disabled. Sessions will now operate over reliable TCP." "SUCCESS"
return 0
