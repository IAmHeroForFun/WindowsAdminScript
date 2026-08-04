# Repairs Windows SMB Shared Drives, Unauthenticated Guest Access, and Network Discovery
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

if (-not (Get-UserApproval "Repair SMB Shared Folder access (Allow Insecure Guest Auth, SMB signing, and Discovery services)?")) {
    Log-Msg "SMB Shared Folder repairs skipped by user." "WARN"
    return 0
}

Log-Msg "Starting SMB and Shared Folder repairs..."

# 1. Enable Insecure Guest Logons (Fixes 0x800704f8 & 0x80070035)
$LanmanWorkstationKey = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
if (Test-Path $LanmanWorkstationKey) {
    if (Get-UserApproval "Enable Insecure Guest Logons (AllowInsecureGuestAuth = 1) to access unauthenticated NAS/PC shares?") {
        try {
            Set-ItemProperty -Path $LanmanWorkstationKey -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully set AllowInsecureGuestAuth = 1."
        } catch {
            Log-Msg "  [ERROR] Failed to set AllowInsecureGuestAuth: $($_.Exception.Message)" "ERROR"
        }
    }

    if (Get-UserApproval "Disable mandatory SMB Client Signing (RequireSecuritySignature = 0) for legacy NAS compatibility?") {
        try {
            Set-ItemProperty -Path $LanmanWorkstationKey -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force | Out-Null
            Set-ItemProperty -Path $LanmanWorkstationKey -Name "EnableSecuritySignature" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully configured SMB Client Signing requirements."
        } catch {
            Log-Msg "  [ERROR] Failed to configure SMB Signing: $($_.Exception.Message)" "ERROR"
        }
    }
}

# 2. Configure LSA Local Account Password Sharing Policy
$LsaKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (Test-Path $LsaKey) {
    if (Get-UserApproval "Allow network access for local accounts with blank passwords (LimitBlankPasswordUse = 0)?") {
        try {
            Set-ItemProperty -Path $LsaKey -Name "LimitBlankPasswordUse" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Msg "  [OK] Successfully set LimitBlankPasswordUse = 0."
        } catch {
            Log-Msg "  [ERROR] Failed to set LimitBlankPasswordUse: $($_.Exception.Message)" "ERROR"
        }
    }
}

# 3. Enable Network Discovery Services
$DiscoveryServices = @(
    @{ Name = "fdPHost"; Display = "Function Discovery Provider Host" }
    @{ Name = "FDResPub"; Display = "Function Discovery Resource Publication" }
    @{ Name = "SSDPSRV"; Display = "SSDP Discovery" }
    @{ Name = "upnphost"; Display = "UPnP Device Host" }
    @{ Name = "lmhosts"; Display = "TCP/IP NetBIOS Helper" }
)

if (Get-UserApproval "Configure and start Network Discovery services (fdPHost, FDResPub, SSDPSRV, etc.)?") {
    foreach ($Svc in $DiscoveryServices) {
        try {
            Set-Service -Name $Svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $Svc.Name -ErrorAction SilentlyContinue
            Log-Msg "  [OK] Enabled & Started service: $($Svc.Display) ($($Svc.Name))"
        } catch {
            Log-Msg "  [WARN] Could not modify service $($Svc.Name): $($_.Exception.Message)" "WARN"
        }
    }
}

Log-Msg "SMB Shared Folder repairs completed."
return 0
