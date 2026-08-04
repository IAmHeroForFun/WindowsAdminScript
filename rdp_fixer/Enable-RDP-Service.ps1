# Enables Remote Desktop Service, Network Level Authentication, and Firewall rules
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
    Write-Host $Formatted -ForegroundColor (if ($Type -eq "ERROR") { "Red" } elseif ($Type -eq "WARN") { "Yellow" } else { "Gray" })
    if ($Global:LogFile) {
        $Formatted | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
}

if (-not (Get-UserApproval "Enable Remote Desktop Service (fDenyTSConnections = 0) and Windows Firewall rules?")) {
    Log-Msg "Enable RDP Service skipped by user." "WARN"
    return 0
}

Log-Msg "Enabling Remote Desktop Service and Firewall..."

# 1. Enable RDP in Registry
$TSKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
if (Test-Path $TSKey) {
    try {
        Set-ItemProperty -Path $TSKey -Name "fDenyTSConnections" -Value 0 -PropertyType DWord -Force | Out-Null
        Log-Msg "  [OK] Successfully set fDenyTSConnections = 0 (Remote Desktop Enabled)." "SUCCESS"
    } catch {
        Log-Msg "  [ERROR] Failed to set fDenyTSConnections: $($_.Exception.Message)" "ERROR"
    }
    
    # Configure Network Level Authentication (NLA)
    $WinStationsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    if (Test-Path $WinStationsKey) {
        if (Get-UserApproval "Disable Network Level Authentication (NLA) requirement to allow connections from legacy OS clients?") {
            try {
                Set-ItemProperty -Path $WinStationsKey -Name "UserAuthentication" -Value 0 -PropertyType DWord -Force | Out-Null
                Log-Msg "  [OK] Set UserAuthentication = 0 (NLA requirement disabled)."
            } catch {
                Log-Msg "  [ERROR] Failed to modify NLA setting: $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# 2. Enable Windows Firewall Remote Desktop Rules
if (Get-UserApproval "Enable Windows Firewall rules for Remote Desktop?") {
    try {
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop
        Log-Msg "  [OK] Enabled Windows Firewall rule group: Remote Desktop." "SUCCESS"
    } catch {
        Log-Msg "  [WARN] Could not enable Remote Desktop firewall group: $($_.Exception.Message)" "WARN"
    }
}

# 3. Restart TermService
if (Get-UserApproval "Restart Terminal Services (TermService) to apply changes?") {
    try {
        Restart-Service -Name "TermService" -Force -ErrorAction Stop
        Log-Msg "  [OK] Terminal Services restarted successfully." "SUCCESS"
    } catch {
        Log-Msg "  [WARN] Could not restart TermService: $($_.Exception.Message)" "WARN"
    }
}

Log-Msg "Remote Desktop Service configuration completed."
return 0
